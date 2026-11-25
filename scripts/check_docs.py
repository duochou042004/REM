#!/usr/bin/env python3
"""REM docs lane check (T0 for prose changes; see docs/engineering/testing-ci.md §3).

Checks: (1) relative Markdown links and heading anchors resolve; (2) every docs/**/*.md is
reachable from docs/README.md; (3) capability IDs cited in docs exist in docs/seeds/FEATURE_REGISTRY.md;
(4) the P1 traceability matrix and the requirements cover exactly the registry's P1 IDs, once each;
(5) the /goal command in docs/handoff/GOAL.md is at most 4,000 characters.
Usage: check_docs.py [ROOT] | check_docs.py --self-test   Exit 0 = OK, 1 = findings.
"""
import re
import sys
import tempfile
from pathlib import Path

ID_RE = re.compile(r"\b([A-Z]{2,5}-\d{3})\b")
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
GOAL_MAX = 4000


def strip_code(text):
    """Remove fenced blocks and inline code so their contents are not parsed as links/IDs."""
    text = re.sub(r"^```.*?^```", "", text, flags=re.S | re.M)
    return re.sub(r"`[^`\n]*`", "", text)


def slugs(text):
    seen, out = {}, set()
    for h in re.findall(r"^#{1,6}\s+(.+?)\s*#*$", re.sub(r"^```.*?^```", "", text, flags=re.S | re.M), re.M):
        s = re.sub(r"[^\w\- ]", "", h.strip().lower()).replace(" ", "-")
        n = seen.get(s, 0)
        out.add(s if n == 0 else f"{s}-{n}")
        seen[s] = n + 1
    return out


def registry_ids(root):
    reg = (root / "docs" / "seeds" / "FEATURE_REGISTRY.md").read_text(encoding="utf-8")
    rows = re.findall(r"^\| `([A-Z]+-\d{3})` \|.*\| (P[0-4]) \|$", reg, re.M)
    return {i for i, _ in rows}, {i for i, p in rows if p == "P1"}


def table_ids(text, start_heading):
    """IDs in the first column of table rows after the heading that starts with start_heading."""
    part = text.split(start_heading, 1)[1] if start_heading in text else ""
    return re.findall(r"^\| ([A-Z]+-\d{3}) \|", part, re.M)


def check(root):
    root = Path(root).resolve()
    errors = []
    md_files = [p for p in root.rglob("*.md") if ".git" not in p.parts and "node_modules" not in p.parts]
    texts = {p: p.read_text(encoding="utf-8") for p in md_files}
    anchor_cache = {}
    linked_from_index = set()
    index = root / "docs" / "README.md"

    for path, text in texts.items():
        for target in LINK_RE.findall(strip_code(text)):
            if re.match(r"^[a-z]+:", target):
                continue  # external URL or mailto
            file_part, _, anchor = target.partition("#")
            dest = (path.parent / file_part).resolve() if file_part else path
            if not dest.exists():
                errors.append(f"{path.relative_to(root)}: broken link {target}")
                continue
            if path == index and dest.suffix == ".md":
                linked_from_index.add(dest)
            if anchor and dest.suffix == ".md":
                if dest not in anchor_cache:
                    anchor_cache[dest] = slugs(dest.read_text(encoding="utf-8"))
                if anchor not in anchor_cache[dest]:
                    errors.append(f"{path.relative_to(root)}: missing anchor {target}")

    docs = [p for p in md_files if (root / "docs") in p.parents and p != index]
    for p in docs:
        if p not in linked_from_index:
            errors.append(f"docs/README.md: does not link {p.relative_to(root)}")

    all_ids, p1 = registry_ids(root)
    for path, text in texts.items():
        if path.name == "FEATURE_REGISTRY.md":
            continue
        for i in set(ID_RE.findall(strip_code(text))):
            if i.split("-")[0] in {x.split("-")[0] for x in all_ids} and i not in all_ids:
                errors.append(f"{path.relative_to(root)}: unknown capability ID {i}")

    for rel, heading in (("docs/plan/backlog.md", "## 4. P1 traceability matrix"),
                         ("docs/product/requirements.md", "## 5. P1 acceptance criteria")):
        f = root / rel
        if not f.exists():
            errors.append(f"{rel}: missing")
            continue
        ids = table_ids(f.read_text(encoding="utf-8"), heading)
        dup = sorted({i for i in ids if ids.count(i) > 1})
        missing, extra = sorted(p1 - set(ids)), sorted(set(ids) - p1)
        for label, vals in (("duplicate", dup), ("missing P1", missing), ("non-P1", extra)):
            if vals:
                errors.append(f"{rel}: {label} IDs {', '.join(vals)}")

    goal = root / "docs" / "handoff" / "GOAL.md"
    if goal.exists():
        m = re.search(r"^```text\n(.*?)\n^```", goal.read_text(encoding="utf-8"), re.S | re.M)
        if not m or not m.group(1).startswith("/goal "):
            errors.append("docs/handoff/GOAL.md: no ```text block starting with '/goal '")
        elif len(m.group(1)) > GOAL_MAX:
            errors.append(f"docs/handoff/GOAL.md: goal is {len(m.group(1))} chars > {GOAL_MAX}")
        else:
            print(f"goal command length: {len(m.group(1))} chars")
    else:
        errors.append("docs/handoff/GOAL.md: missing")
    return errors


def self_test():
    """Each seeded defect must be reported; the clean fixture must pass."""
    def build(d, *, link="sync.md#2-rules", rid="SYN-001", goal="/goal Resume.", rows=("SYN-001",)):
        (d / "docs/handoff").mkdir(parents=True)
        (d / "docs/plan").mkdir()
        (d / "docs/product").mkdir()
        (d / "docs/seeds").mkdir(parents=True, exist_ok=True)
        (d / "docs/seeds/FEATURE_REGISTRY.md").write_text("| `SYN-001` | x | P1 |\n| `SYN-002` | y | P2 |\n")
        (d / "docs/README.md").write_text("[s](sync.md) [b](plan/backlog.md) [r](product/requirements.md) [g](handoff/GOAL.md) [f](seeds/FEATURE_REGISTRY.md)\n")
        (d / "docs/sync.md").write_text(f"## 2. Rules\nSee [x]({link}) and {rid}. `ignored [a](nope.md)`\n")
        body = "".join(f"| {r} | t |\n" for r in rows)
        (d / "docs/plan/backlog.md").write_text("## 4. P1 traceability matrix\n" + body)
        (d / "docs/product/requirements.md").write_text("## 5. P1 acceptance criteria\n" + body)
        (d / "docs/handoff/GOAL.md").write_text(f"```text\n{goal}\n```\n")
        return d

    cases = {
        "clean": ({}, 0),
        "broken link": ({"link": "missing.md"}, 1),
        "missing anchor": ({"link": "sync.md#nope"}, 1),
        "unknown ID": ({"rid": "SYN-999"}, 1),
        "goal too long": ({"goal": "/goal " + "x" * GOAL_MAX}, 1),
        "missing P1 row": ({"rows": ()}, 2),
        "duplicate row": ({"rows": ("SYN-001", "SYN-001")}, 2),
    }
    ok = True
    for name, (kw, expected) in cases.items():
        with tempfile.TemporaryDirectory() as t:
            got = check(build(Path(t), **kw))
            if len(got) != expected:
                ok = False
                print(f"SELF-TEST FAIL {name}: expected {expected} findings, got {got}")
    print("self-test:", "OK" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        sys.exit(self_test())
    root = sys.argv[1] if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
    errs = check(root)
    for e in errs:
        print("FAIL", e)
    print("OK" if not errs else f"{len(errs)} finding(s)")
    sys.exit(1 if errs else 0)
