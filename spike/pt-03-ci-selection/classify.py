"""P0-PT-03 throwaway spike: testing-ci §3 classifier. Not production code.

usage: python3 -I classify.py REPO BASE HEAD   -> JSON plan on stdout, exit 0
A non-zero exit means classify failed; the aggregate must then fail.
"""
import fnmatch, json, subprocess, sys, tarfile, tempfile, tomllib, io, os


def git(repo, *args, check=True):
    return subprocess.run(["git", "-C", repo, *args], capture_output=True, check=check)


def metadata(repo, rev):
    """cargo metadata for one side, or None when it fails (§3 rule 1: then widen)."""
    with tempfile.TemporaryDirectory() as tmp:
        tar = git(repo, "archive", "--format=tar", rev).stdout
        tarfile.open(fileobj=io.BytesIO(tar)).extractall(tmp, filter="data")
        r = subprocess.run(["cargo", "metadata", "--locked", "--offline", "--format-version", "1",
                            "--manifest-path", os.path.join(tmp, "Cargo.toml")], capture_output=True)
        if r.returncode != 0:
            return None
        md = json.loads(r.stdout)
        members = set(md["workspace_members"])
        pkgs = {p["id"]: p for p in md["packages"] if p["id"] in members}
        dirs = {p["name"]: os.path.relpath(os.path.dirname(p["manifest_path"]), tmp) for p in pkgs.values()}
        rdeps = {p["name"]: set() for p in pkgs.values()}
        for node in md["resolve"]["nodes"]:  # documented field (§3 rule 2)
            if node["id"] in pkgs:
                for dep in node["dependencies"]:
                    if dep in pkgs:
                        rdeps[pkgs[dep]["name"]].add(pkgs[node["id"]]["name"])
        return {"dirs": dirs, "rdeps": rdeps}


def owner(path, md):
    hits = [n for n, d in (md or {"dirs": {}})["dirs"].items() if path.startswith(d + "/")]
    return max(hits, key=lambda n: len(md["dirs"][n]), default=None)


def classify(repo, base, head):
    reg = tomllib.loads(git(repo, "show", f"{head}:ci/lanes.toml").stdout.decode())
    lanes = list(reg["lanes"])
    widen, picked, pkgs = [], {}, set()

    mb = git(repo, "merge-base", base, head, check=False)
    if mb.returncode != 0:
        return plan(lanes, ["missing merge-base"], {}, set())
    mb = mb.stdout.decode().strip()

    md_base, md_head = metadata(repo, mb), metadata(repo, head)
    if md_base is None or md_head is None:
        widen.append("cargo metadata failed on the " + ("base" if md_base is None else "head") + " side")
    else:
        for n in sorted(set(md_base["dirs"]) - set(md_head["dirs"])):
            widen.append(f"workspace member removed or renamed: {n}")
        for n in sorted(set(md_head["dirs"]) - set(md_base["dirs"])):
            widen.append(f"workspace member added: {n}")

    raw = git(repo, "diff", "--raw", "--no-renames", "-z", mb, head).stdout.decode().split("\0")
    for meta, path in zip(raw[0::2], raw[1::2]):
        new_mode = meta.split()[1]
        rows = [r for r in reg["rows"] if any(fnmatch.fnmatchcase(path, p) for p in r["paths"])]
        if new_mode == "100755":  # rule 3: an embedded executable takes the engineering path
            widen.append(f"executable file: {path}")
        elif any(r.get("widen") for r in rows):
            widen.append(f"build input: {path}")
        elif not rows:
            widen.append(f"unmatched path: {path}")
        for r in rows:
            for lane in r.get("lanes", []):
                picked.setdefault(lane, []).append(path)
        pkg = owner(path, md_head) or owner(path, md_base)
        if pkg and md_head and pkg in md_head["dirs"]:
            pkgs.add(pkg)

    if widen:
        return plan(lanes, widen, {}, set())
    closure, todo = set(), list(pkgs)
    while todo:
        n = todo.pop()
        if n not in closure:
            closure.add(n)
            todo += md_head["rdeps"].get(n, ())
    return plan(lanes, [], picked, closure if "rust-affected" in picked else set())


def plan(lanes, widen, picked, pkgs):
    out = {"widened": bool(widen), "widen_reasons": widen, "packages": sorted(pkgs), "lanes": {}}
    for lane in lanes:
        if widen:
            sel = lane != "rust-affected"
            why = ("widened: " + "; ".join(widen)) if sel else "widened: rust-all covers every package"
        else:
            sel = lane in picked
            why = ("paths: " + ", ".join(sorted(set(picked[lane])))) if sel else "no changed path maps to this lane"
        out["lanes"][lane] = {"selected": sel, "reason": why}
    return out


if __name__ == "__main__":
    print(json.dumps(classify(*sys.argv[1:4]), indent=2))
