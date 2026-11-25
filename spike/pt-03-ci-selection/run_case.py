"""P0-PT-03 throwaway spike: run one testing-ci §6 case end to end. Not production code.

usage: python3 -I run_case.py OUT_DIR CASE [LANE=skip | LANE=exit:N ...]
CASE is C1..C4 (C5 = C2 with wasm-web=exit:1). Each run builds a fresh scratch git repo from
fixture/ in OUT_DIR, commits the base on `main`, applies the case change on `case`, then:
classify -> each registry lane (selected: run its command; else skipped) -> aggregate.
shortcut: the GitHub `if:`/`needs` semantics are emulated here, not observed on a host (PO-Q2).
"""
import json, os, shutil, subprocess, sys, tomllib

HERE = os.path.dirname(os.path.abspath(__file__))


def sh(cmd, cwd, check=True):
    return subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True, text=True, check=check)


def mutate(case, repo):
    if case == "C1":
        with open(f"{repo}/docs/plan/backlog.md", "a") as f:
            f.write("- another item\n")
    elif case == "C2":
        with open(f"{repo}/crates/rem-client-core/src/outbox.rs", "w") as f:
            f.write("pub fn enqueue() -> u32 {\n    2\n}\n")
    elif case == "C3":
        shutil.rmtree(f"{repo}/crates/rem-client-native")
        sh("cargo generate-lockfile --offline", repo)
    elif case == "C4":
        os.makedirs(f"{repo}/tools/new-thing")
        with open(f"{repo}/tools/new-thing/x.bin", "wb") as f:
            f.write(bytes(range(256)))
    else:
        sys.exit(f"unknown case {case}")


def main(out, case, *forces):
    force = dict(f.split("=", 1) for f in forces)
    repo = os.path.join(out, "repo")
    shutil.rmtree(out, ignore_errors=True)
    shutil.copytree(os.path.join(HERE, "fixture"), repo, ignore=shutil.ignore_patterns("target"))
    sh("git init -q -b main && git add -A && git -c user.name=spike -c user.email=spike@invalid commit -qm base", repo)
    sh("git switch -qc case", repo)
    mutate(case, repo)
    sh("git add -A && git -c user.name=spike -c user.email=spike@invalid commit -qm case", repo)
    print("diff:", sh("git diff --name-status main case", repo).stdout.strip().replace("\n", "; "))

    cls = subprocess.run([sys.executable, "-I", f"{HERE}/classify.py", repo, "main", "case"],
                         capture_output=True, text=True)
    plan_f = os.path.join(out, "plan.json")
    open(plan_f, "w").write(cls.stdout)
    needs = {"classify": {"result": "success" if cls.returncode == 0 else "failure"}}
    print("classify exit:", cls.returncode)
    reg = tomllib.load(open(f"{repo}/ci/lanes.toml", "rb"))
    plan = json.loads(cls.stdout) if cls.returncode == 0 else {"lanes": {}}
    if plan.get("widened"):
        print("widen reasons:", "; ".join(plan["widen_reasons"]))
    print("packages:", plan.get("packages"))
    for lane, spec in reg["lanes"].items():
        sel = plan["lanes"].get(lane, {}).get("selected", False)
        f = force.get(lane)
        if not sel or f == "skip":
            result = "skipped"
        else:
            cmd = f"exit {f[5:]}" if f and f.startswith("exit:") else spec["run"].replace(
                "{packages}", " ".join(f"-p {p}" for p in plan["packages"]))
            r = sh(cmd, repo, check=False)
            result = "success" if r.returncode == 0 else "failure"
            print(f"  ran {lane}: `{cmd}` -> exit {r.returncode}")
        needs[spec["job"]] = {"result": result}
        print(f"lane {lane:14} selected={str(sel).lower():5} result={result}" + (f"  (forced {f})" if f else ""))
    needs_f = os.path.join(out, "needs.json")
    json.dump(needs, open(needs_f, "w"))
    agg = subprocess.run([sys.executable, "-I", f"{HERE}/aggregate.py", plan_f, f"{repo}/ci/lanes.toml", needs_f,
                          ",".join(s["job"] for s in reg["lanes"].values())], capture_output=True, text=True)
    print(agg.stdout.strip())
    print("aggregate exit:", agg.returncode)
    return agg.returncode


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
