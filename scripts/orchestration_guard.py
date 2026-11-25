#!/usr/bin/env python3
"""Orchestration budget guard for Claude Code hooks (decision LD-39, CLAUDE.md "Orchestration budget").

Hook events (wired in .claude/settings.json):
  PreToolUse  Workflow -> deny without a budget line; ask above the routine budget; else no decision.
  PreToolUse  Agent    -> ask once a session has spawned more than AGENT_CAP direct subagents.
  SubagentStart        -> ledger only; warns the user once a session passes SUBAGENT_WARN.
CLI: `report` prints the ledger per session; `--self-test` runs the built-in checks.
"""
import json, os, re, sys, tempfile, time

AGENTS_MAX, ROUNDS_MAX = 5, 1          # routine budget (policy: 3-5 concurrent agents, one verify round)
AGENT_CAP, SUBAGENT_WARN = 5, 15       # direct Agent calls per session; total subagents before a warning
EXEMPT_TYPES = {"web-fetch"}           # stands in for a fetch tool, not delegation
BUDGET_RE = re.compile(r"orchestration-budget:\s*agents=(\d+)\s+rounds=(\d+)")
HINT = ("Add one line to the script: `// orchestration-budget: agents=N rounds=R` "
        "(N = total agent() calls it can make, R = fix/verify rounds). "
        f"Routine budget: agents<={AGENTS_MAX}, rounds<={ROUNDS_MAX}; above it needs the PO's approval.")


def state_dir():
    d = os.environ.get("REM_GUARD_STATE") or os.path.join(
        os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()), ".claude", "state")
    os.makedirs(d, exist_ok=True)
    return d


def ledger(rec=None):
    path = os.path.join(state_dir(), "orchestration.jsonl")
    if rec is not None:
        with open(path, "a", encoding="utf-8") as f:
            f.write(json.dumps({"ts": int(time.time()), **rec}) + "\n")
    try:
        with open(path, encoding="utf-8") as f:
            return [json.loads(l) for l in f if l.strip()]
    except FileNotFoundError:
        return []


def count(session, event, tool=None):
    return sum(1 for r in ledger() if r.get("session") == session and r.get("event") == event
               and (tool is None or r.get("tool") == tool))


def pre(decision, reason):
    return {"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                   "permissionDecision": decision, "permissionDecisionReason": reason}}


def workflow_decision(ti):
    if ti.get("name") and not (ti.get("script") or ti.get("scriptPath")):
        return "ask", f"Saved workflow '{ti['name']}': its size is not declared here. {HINT}"
    script = ti.get("script") or ""
    if not script and ti.get("scriptPath"):
        try:
            script = open(ti["scriptPath"], encoding="utf-8").read()
        except OSError:
            return "deny", f"Cannot read scriptPath to check its budget. {HINT}"
    m = BUDGET_RE.search(script)
    if not m:
        return "deny", f"Workflow has no orchestration budget. {HINT}"
    agents, rounds = int(m.group(1)), int(m.group(2))
    calls = len(re.findall(r"\bagent\(", script))
    looped = bool(re.search(r"\bwhile\s*\(", script))
    if agents > AGENTS_MAX or rounds > ROUNDS_MAX:
        return "ask", f"Budget agents={agents} rounds={rounds} exceeds the routine budget. Approve only if the risk justifies it."
    if looped and rounds <= ROUNDS_MAX:
        return "ask", "Script has a while-loop (possible fix/verify cycle) but declares one round. Approve or rewrite."
    if calls > agents:
        return "ask", f"Script has {calls} agent() call sites but declares agents={agents}."
    return None, f"within budget (agents={agents}, rounds={rounds})"


def handle(inp):
    ev, tool, sess = inp.get("hook_event_name"), inp.get("tool_name"), inp.get("session_id", "?")
    ti = inp.get("tool_input") or {}
    if ev == "PreToolUse" and tool == "Workflow":
        decision, reason = workflow_decision(ti)
        ledger({"session": sess, "event": ev, "tool": tool, "decision": decision or "pass", "detail": reason[:200]})
        return pre(decision, reason) if decision else {}
    if ev == "PreToolUse" and tool == "Agent":
        if ti.get("subagent_type") in EXEMPT_TYPES:
            return {}
        n = count(sess, ev, "Agent") + 1
        decision = "ask" if n > AGENT_CAP else None
        ledger({"session": sess, "event": ev, "tool": tool, "decision": decision or "pass", "detail": f"direct agent #{n}"})
        return pre("ask", f"Direct subagent #{n} this session exceeds {AGENT_CAP}. Batch the work or approve.") if decision else {}
    if ev == "SubagentStart":
        ledger({"session": sess, "event": ev, "detail": inp.get("agent_type", "")})
        n = count(sess, ev)
        if n == SUBAGENT_WARN + 1 or (n > SUBAGENT_WARN and n % 10 == 0):
            return {"systemMessage": f"Orchestration guard: {n} subagents started this session (warning threshold {SUBAGENT_WARN}). Check for over-delegation."}
    return {}


def report():
    per = {}
    for r in ledger():
        s = per.setdefault(r.get("session", "?"), {})
        k = f"{r.get('event')}:{r.get('tool', '')}:{r.get('decision', '')}"
        s[k] = s.get(k, 0) + 1
    print(json.dumps(per, indent=1) if per else "ledger empty")


def self_test():
    os.environ["REM_GUARD_STATE"] = tempfile.mkdtemp()
    wf = lambda s: handle({"hook_event_name": "PreToolUse", "tool_name": "Workflow", "session_id": "t", "tool_input": {"script": s}})
    dec = lambda out: out.get("hookSpecificOutput", {}).get("permissionDecision")
    assert dec(wf("agent('x')")) == "deny"
    assert dec(wf("// orchestration-budget: agents=3 rounds=1\nagent('a'); agent('b')")) is None
    assert dec(wf("// orchestration-budget: agents=20 rounds=1\nagent('a')")) == "ask"
    assert dec(wf("// orchestration-budget: agents=3 rounds=1\nwhile (x) { agent('a') }")) == "ask"
    assert dec(wf("// orchestration-budget: agents=1 rounds=1\nagent('a'); agent('b')")) == "ask"
    ag = lambda: handle({"hook_event_name": "PreToolUse", "tool_name": "Agent", "session_id": "t", "tool_input": {}})
    assert [dec(ag()) for _ in range(AGENT_CAP)] == [None] * AGENT_CAP and dec(ag()) == "ask"
    assert dec(handle({"hook_event_name": "PreToolUse", "tool_name": "Agent", "session_id": "t", "tool_input": {"subagent_type": "web-fetch"}})) is None
    outs = [handle({"hook_event_name": "SubagentStart", "session_id": "t"}) for _ in range(SUBAGENT_WARN + 1)]
    assert "systemMessage" in outs[-1] and all(not o for o in outs[:-1])
    print("self-test: OK")


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        self_test()
    elif sys.argv[1:] == ["report"]:
        report()
    else:
        print(json.dumps(handle(json.load(sys.stdin))))
