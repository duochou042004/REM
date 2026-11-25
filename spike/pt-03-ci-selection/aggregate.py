"""P0-PT-03 throwaway spike: the testing-ci §4 `required` aggregate verdict. Not production code.

usage: python3 -I aggregate.py PLAN.json REGISTRY.toml NEEDS.json NEEDS_LIST   (exit 0 pass, 1 fail)
       python3 -I aggregate.py --self-test
NEEDS.json emulates the GitHub `needs` context: {"job": {"result": "success|failure|cancelled|skipped"}}.
NEEDS_LIST is the aggregate's own comma-separated `needs:` list.
"""
import json, sys, tomllib


def verdict(plan, registry, needs, needs_list):
    errs = []
    if needs.get("classify", {}).get("result") != "success":
        return ["classify did not succeed"]
    reg = set(registry["lanes"])
    keys = set(plan.get("lanes", {}))
    errs += [f"plan names a lane not in the registry: {k}" for k in sorted(keys - reg)]
    errs += [f"plan omits registry lane: {k}" for k in sorted(reg - keys)]
    for lane in sorted(keys & reg):
        job = registry["lanes"][lane]["job"]
        result = needs.get(job, {}).get("result")
        if plan["lanes"][lane]["selected"]:
            if job not in needs_list:
                errs.append(f"selected lane {lane} is not in the aggregate's needs")
            elif result is None:
                errs.append(f"selected lane {lane} has no result in needs")
            elif result != "success":
                errs.append(f"selected lane {lane} result is {result}")
        elif result not in ("skipped", None):
            errs.append(f"unselected lane {lane} ran with result {result}")
    return errs


def self_test():
    reg = {"lanes": {"a": {"job": "a"}, "b": {"job": "b"}}}
    ok_plan = {"lanes": {"a": {"selected": True}, "b": {"selected": False}}}
    ok = {"classify": {"result": "success"}, "a": {"result": "success"}, "b": {"result": "skipped"}}
    cases = [
        (ok_plan, ok, ["a", "b"], True),
        (ok_plan, {**ok, "classify": {"result": "failure"}}, ["a", "b"], False),
        ({"lanes": {**ok_plan["lanes"], "x": {"selected": False}}}, ok, ["a", "b"], False),
        ({"lanes": {"a": {"selected": True}}}, ok, ["a", "b"], False),
        (ok_plan, ok, ["b"], False),
        (ok_plan, {k: v for k, v in ok.items() if k != "a"}, ["a", "b"], False),
        *[(ok_plan, {**ok, "a": {"result": r}}, ["a", "b"], False) for r in ("failure", "cancelled", "skipped")],
    ]
    for i, (p, n, nl, want) in enumerate(cases):
        assert (not verdict(p, reg, n, nl)) == want, (i, verdict(p, reg, n, nl))
    print(f"self-test: OK ({len(cases)} cases)")


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        sys.exit(0)
    plan_f, reg_f, needs_f, needs_list = sys.argv[1:5]
    try:
        plan = json.load(open(plan_f))
    except (OSError, ValueError):
        plan = {}
    errs = verdict(plan, tomllib.load(open(reg_f, "rb")), json.load(open(needs_f)), needs_list.split(","))
    for e in errs:
        print("FAIL:", e)
    print("required:", "fail" if errs else "pass")
    sys.exit(1 if errs else 0)
