# REM — Environment and new-device bootstrap

**Owner:** DevOps · **Status:** observed 2026-11-24 (commands in [evidence.md](../plan/evidence.md#e-02-environment-inventory)). Never put secret values in this file.

## 1. Observed environment (2026-11-24)

| Item | Observed | Needed for | Status |
|---|---|---|---|
| OS / arch / CPU / RAM / disk free | Debian GNU/Linux 13 (trixie), x86_64, 16 threads, 22 GiB, 104 GB free | all | OK |
| git / gh / glab | 2.47.3 / 2.105.0 (authenticated to github.com) / present | VCS, CI host | OK; remote `origin` = private `duochou042004/REM` (PO-Q2 = A) |
| Rust | rustup, stable 1.100.0 (rustc 2026-11-09), cargo 1.100.0; installed targets: `x86_64-unknown-linux-gnu` only | server, SDK | OK for native; **missing `wasm32-unknown-unknown`** |
| wasm-pack / wasm-bindgen-cli | missing | ADR-0002, PT-01 | **needs PO approval** (PO-Q1) |
| Node / npm / pnpm / yarn | v24.22.3 (nvm) / 11.19.1 / present / present | web app | OK; the package manager is chosen and pinned at P1-00 |
| Playwright + browsers | missing | T3, PT-01 | **needs PO approval** (PO-Q1); browser OS dependencies may need `sudo` (not done) |
| Containers | podman 5.4.2; docker CLI missing | PostgreSQL and S3 for T2, OPS-001 | OK with Podman (harness: Podman OR Docker) |
| PostgreSQL client / server, sqlx-cli | not on the host; image `docker.io/library/postgres:19` at `sha256:aaa10f7b…a4d1` (PostgreSQL 19.0), pulled 2026-11-25 for PT-02 (PO-Q1 = A); `sqlx-cli` missing | T2, PT-02 | OK as a container ([E-17](../plan/evidence.md#e-17-p0-pt-02-postgresql-sequencing-spike)). Local storage also holds `postgres:18` and an untagged image with a stopped container from another project; REM does not use them |
| python3 | 3.13.5 | `scripts/check_docs.py` | OK |
| jq / shellcheck / pdftotext | present | tooling | OK |
| Claude Code | 2.1.329; `DISABLE_AUTO_COMPACT` set for the project via `.claude/settings.json` (takes effect in new sessions after the folder is trusted) | harness §5 | configured; the effect is verified in the restart test ([evidence E-07](../plan/evidence.md#e-07-restart-path-and-receiver-cases)) |

## 2. New-device bootstrap (receiver procedure)

1. **Get the repository.** Run `git clone https://github.com/duochou042004/REM.git REM && cd REM && git switch develop`. This needs access to the private repository (PO-Q2 = A). Without access, use the private bundle: the sender runs `git bundle create rem.bundle --all` and verifies it with `git bundle verify rem.bundle`. The bundle travels by an approved private channel, then the receiver runs `git clone rem.bundle REM && cd REM && git switch develop`.
2. **Check the checkpoint.** Resolve it with `git log -1 --format=%H develop -- docs/handoff/CURRENT.md`; it must equal the SHA in the delivery message. `HEAD` may be a later `--no-ff` merge or evidence-only commit: `git diff --stat <checkpoint> HEAD` must be empty or touch only the evidence follow-up files named in CURRENT §1. `git status --short` must be clean.
3. **Check tools.** Rerun the inventory commands in [evidence E-02](../plan/evidence.md#e-02-environment-inventory) and compare against §1. Record drift in `evidence.md`. Do not install anything without approval.
4. **Out-of-band inputs.** The discovery PDF `Xây dựng nền tảng chat Rust.pdf` (sha256 `97caf2ba…0604332`) is not in Git (PO-Q3). Place it at `docs/seeds/` (LD-43), where `*.pdf` keeps it ignored. It is needed only for provenance questions. Verify its hash if it is supplied.
5. **Smoke check.** Run `python3 scripts/check_docs.py` → `OK` with exit 0. Record the result.
6. **Claude Code.** Open the folder and accept the trust prompt, which applies `.claude/settings.json`. In a Bash tool call, `printenv DISABLE_AUTO_COMPACT` should print `1`. Then paste the command from [GOAL.md](../handoff/GOAL.md).
7. Required environment variable names for later packets (values come through approved provisioning, never Git): none for P0. P1-00 adds `DATABASE_URL`, `REM_SESSION_PEPPER_FILE`, `REM_URL_SIGNING_KEY_FILE` and `S3_*`.

There are no submodules, LFS objects or large fixtures in P0.
