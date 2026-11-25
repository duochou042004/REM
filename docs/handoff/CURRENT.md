# CURRENT — active handoff packet

**Packet:** HO-2026-11-25-01 · **Written by:** Lead, session P0-REV-02 (final verification) · **Phase:** P0 · **PO authority:** planning, documentation and throwaway `spike/*` prototypes only. **P1 implementation is NOT authorized** (PD-07, PO-Q8 not yet asked).

## 1. Revision state

| Item | Value |
|---|---|
| Repository | local `/home/deb/App_sources/REM`; **no remote** (PO-Q2); device transfer uses a git bundle ([bootstrap §2](../engineering/bootstrap.md#2-new-device-bootstrap-receiver-procedure)) |
| Branches | `master` = seed baseline `bd3312d`; `develop` = integration, holding the `--no-ff` merge of `p0/review-round-2` (P0-REV-02, LD-17..LD-41, the LD-39 harness) |
| Tested revision | the checkpoint below; checks recorded in [E-09c](../plan/evidence.md#e-09c-final-verification-of-p0-rev-02) |
| Checkpoint | the newest commit on **`develop`** that touches this file: `git log -1 --format=%H develop -- docs/handoff/CURRENT.md`. `develop` HEAD is its `--no-ff` merge, with an empty diff to it |
| Working tree at handoff | clean apart from the ignored `Xây dựng nền tảng chat Rust.pdf`, `.claude/settings.local.json`, `graphify-out/` and `.claude/state/` |
| Spec versions | PROJECT_SPEC v1.1, FEATURE_REGISTRY v1.1 (207 IDs), AGENT_HARNESS v1.2, START_PROMPT 2026-11-24 |
| Rollback point | `bd3312d` (seed baseline); `9d5f691` (`develop` before P0-REV-02) |

## 2. Done in this packet

- P0-INIT-01, P0-RES-01 and P0-REV-01, as recorded in [backlog §1](../plan/backlog.md#1-p0-packets).
- **P0-REV-02:** all 38 round-2 rows resolved and verified, the 6 final-critic MAJOR findings fixed (LD-40) and re-checked, and a bounded close-out critic's 3 MAJOR findings fixed (LD-41) and re-checked, with no BLOCKING or MAJOR residual ([E-09c](../plan/evidence.md#e-09c-final-verification-of-p0-rev-02), [E-09d](../plan/evidence.md#e-09d-p0-rev-02-close-out)).
- graphify repaired with PO approval; all its commands run ([E-13](../plan/evidence.md#e-13-graphify-repair), LD-33).

## 3. Gate and decisions

- **P0 gate: NOT PASSED.** 8 PASS (items 1–6, 10, 11), 3 PENDING (item 7 on P0-SEC-01 and PO-Q9; item 8 on PT-01 and PT-02; item 9 on PT-03 and PO-Q2), 0 BLOCKED. See [p0-gate.md](../plan/p0-gate.md).
- **Outstanding PO decisions:** **PO-Q12** (accept P0-REV-02 with its recorded deviations; recommendation A; under C, P0-PT-03 waits), **PO-Q2** (remote and CI host, blocking CI evidence and remote handoff), **PO-Q9** (admin reset power; gate item 7 and P1-09), **PO-Q10** (dormant store; before P1-06), and PO-Q3..Q7 (non-blocking). See [decisions §3](../plan/decisions.md#3-po-question-queue).
- **PO-Q1 answered 2026-11-25: approve all (A).** PT-01 and PT-02 install their own tools in their own sessions (user-level, no `sudo`; Playwright system libraries that need `sudo apt` are asked separately).
- Lead decisions LD-01..LD-41 are in [decisions §2](../plan/decisions.md#2-lead-decisions-reversible).

## 4. Known failures, risks and constraints

No failing checks. **Known open items:** the MINOR residuals recorded in E-09c and E-09d. Whether the close-out critic's 3 findings were the 2 candidates E-09c counted cannot be shown (E-09d omission 1), so the P1-00 review should look again at sync, contracts and threat-model. Open risks R-01..R-17 ([risks.md](../plan/risks.md)). Tool constraints: no wasm32 target, wasm-pack, Playwright or DB images. Podman, not Docker. No `sudo`. A `rust-anything` plugin is configured in the user environment but fails to start (R-17); do not use it.

## 5. Next task: P0-PT-03 (READY) — CI selection spike

- **Goal:** observe cases C1–C5 of [testing-ci §6](../engineering/testing-ci.md#6-p0-acceptance-cases-for-ci-selection-synthetic-walkthrough--not-an-observed-execution) by running the classifier and aggregate-verdict logic of testing-ci §3–4 against a throwaway fixture workspace.
- **Base:** `develop` at the checkpoint. **Branches:** `spike/pt-03-ci-selection` for the throwaway code (never merged), and `p0/pt-03-results` for the docs results (merged with `--no-ff`). **Owner:** DevOps role, run by the Lead.
- **Write allowlist:** the spike branch's fixture directory, and `docs/**` on the results branch. **Excluded:** seeds, product code in the main tree, installs, image pulls, remotes.
- **First action:** write the P0-PT-03 packet detail in [backlog §1](../plan/backlog.md#1-p0-packets) (IDs, owner, scope, allowlist, acceptance, verification budget), then build the fixture workspace with installed tools only.
- **Acceptance:** `python3 scripts/check_docs.py` prints `OK`; an evidence row per case with the tested SHA, command, selected lanes, verdict and exit code; testing-ci §6 statuses updated; gate item 9 and H5 re-assessed. C6 and artifact expiry stay PENDING on PO-Q2.
- **Budget:** inline by default; at most one independent reviewer of the observed results (LD-39).
- **After it:** P0-SEC-01 (ASVS mapping, gate item 7). P0-PT-01 and P0-PT-02 (READY since PO-Q1 = A; they lead under LD-13 once PT-03 is done). Then P0-GATE-02.

## 6. Read list for the receiver (in order)

1. This file. 2. [backlog §1, the P0-PT-03 row](../plan/backlog.md#1-p0-packets). 3. [testing-ci §3–4 and §6](../engineering/testing-ci.md#3-impact-map-and-selection). 4. [p0-gate item 9 and H5](../plan/p0-gate.md#1-exit-items). 5. [lessons.md](../plan/lessons.md). Read E-09c only if a P0-REV-02 result is needed.

## 7. Context and handoff reason

The verification session read 279,558 tokens before the close-out records and merge ([E-11](../plan/evidence.md#e-11-context-readings)), below the 300K preparation point. It hands off at the packet boundary: P0-PT-03 is new work and starts in a fresh session. The checkpoint is the newest `develop` commit touching this file. The next command is [GOAL.md](GOAL.md).
