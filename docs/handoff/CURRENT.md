# CURRENT — active handoff packet

**Packet:** HO-2026-11-25-01 · **Written by:** Lead, session P0-REV-02 (final verification) · **Phase:** P0 · **PO authority:** planning, documentation and throwaway `spike/*` prototypes only. **P1 implementation is NOT authorized** (PD-07, PO-Q8 not yet asked).

## 1. Revision state

| Item | Value |
|---|---|
| Repository | local `/home/deb/App_sources/REM`; **no remote** (PO-Q2); device transfer uses a git bundle ([bootstrap §2](../engineering/bootstrap.md#2-new-device-bootstrap-receiver-procedure)) |
| Branches | `master` = seed baseline `bd3312d`; `develop` = integration, holding the `--no-ff` merge of `p0/review-round-2` (P0-REV-02, LD-17..LD-40, the LD-39 harness) |
| Tested revision | the checkpoint below; checks recorded in [E-09c](../plan/evidence.md#e-09c-final-verification-of-p0-rev-02) |
| Checkpoint | the newest commit on **`develop`** that touches this file: `git log -1 --format=%H develop -- docs/handoff/CURRENT.md`. `develop` HEAD is its `--no-ff` merge, with an empty diff to it |
| Working tree at handoff | clean apart from the ignored `Xây dựng nền tảng chat Rust.pdf`, `.claude/settings.local.json`, `graphify-out/` and `.claude/state/` |
| Spec versions | PROJECT_SPEC v1.1, FEATURE_REGISTRY v1.1 (207 IDs), AGENT_HARNESS v1.2, START_PROMPT 2026-11-24 |
| Rollback point | `bd3312d` (seed baseline); `9d5f691` (`develop` before P0-REV-02) |

## 2. Done in this packet

- P0-INIT-01, P0-RES-01 and P0-REV-01, as recorded in [backlog §1](../plan/backlog.md#1-p0-packets).
- **P0-REV-02:** all 38 round-2 rows resolved and verified, the 6 final-critic MAJOR findings fixed (LD-40) and re-checked, with no BLOCKING or MAJOR residual in the verified scope ([E-09c](../plan/evidence.md#e-09c-final-verification-of-p0-rev-02)).
- graphify repaired with PO approval; all its commands run ([E-13](../plan/evidence.md#e-13-graphify-repair), LD-33).

## 3. Gate and decisions

- **P0 gate: NOT PASSED.** 8 PASS (items 1–6, 10, 11), 2 PENDING (item 7 on P0-SEC-01 and PO-Q9; item 9 on PT-03 and PO-Q2), 1 BLOCKED (item 8, on PO-Q1). See [p0-gate.md](../plan/p0-gate.md).
- **Outstanding PO decisions:** **PO-Q1** (tool installs, blocking gate item 8; deferred on 2026-11-24 and asked again at this checkpoint), **PO-Q2** (remote and CI host, blocking CI evidence and remote handoff), **PO-Q9** (admin reset power; gate item 7 and P1-09), **PO-Q10** (dormant store; before P1-06), and PO-Q3..Q7 (non-blocking). See [decisions §3](../plan/decisions.md#3-po-question-queue).
- Lead decisions LD-01..LD-40 are in [decisions §2](../plan/decisions.md#2-lead-decisions-reversible).

## 4. Known failures, risks and constraints

No failing checks. **Known open items:** the MINOR residuals recorded in E-09c, and 2 BLOCKING-or-MAJOR candidates that the final critic counted but did not describe (E-09c omission 1); a reviewer of P1-facing work should look again at sync, contracts and threat-model before P1-00. Open risks R-01..R-17 ([risks.md](../plan/risks.md)). Tool constraints: no wasm32 target, wasm-pack, Playwright or DB images. Podman, not Docker. No `sudo`. A `rust-anything` plugin is configured in the user environment but fails to start (R-17); do not use it.

## 5. Next task: P0-PT-03 (READY) — CI selection spike

- **Goal:** observe cases C1–C5 of [testing-ci §6](../engineering/testing-ci.md#6-p0-acceptance-cases-for-ci-selection-synthetic-walkthrough--not-an-observed-execution) by running the classifier and aggregate-verdict logic of testing-ci §3–4 against a throwaway fixture workspace.
- **Base:** `develop` at the checkpoint. **Branches:** `spike/pt-03-ci-selection` for the throwaway code (never merged), and `p0/pt-03-results` for the docs results (merged with `--no-ff`). **Owner:** DevOps role, run by the Lead.
- **Write allowlist:** the spike branch's fixture directory, and `docs/**` on the results branch. **Excluded:** seeds, product code in the main tree, installs, image pulls, remotes.
- **First action:** write the P0-PT-03 packet detail in [backlog §1](../plan/backlog.md#1-p0-packets) (IDs, owner, scope, allowlist, acceptance, verification budget), then build the fixture workspace with installed tools only.
- **Acceptance:** `python3 scripts/check_docs.py` prints `OK`; an evidence row per case with the tested SHA, command, selected lanes, verdict and exit code; testing-ci §6 statuses updated; gate item 9 and H5 re-assessed. C6 and artifact expiry stay PENDING on PO-Q2.
- **Budget:** inline by default; at most one independent reviewer of the observed results (LD-39).
- **After it:** P0-SEC-01 (ASVS mapping, gate item 7). P0-PT-01 and P0-PT-02 follow PO-Q1. Then P0-GATE-02.

## 6. Read list for the receiver (in order)

1. This file. 2. [backlog §1, the P0-PT-03 row](../plan/backlog.md#1-p0-packets). 3. [testing-ci §3–4 and §6](../engineering/testing-ci.md#3-impact-map-and-selection). 4. [p0-gate item 9 and H5](../plan/p0-gate.md#1-exit-items). 5. [lessons.md](../plan/lessons.md). Read E-09c only if a P0-REV-02 result is needed.

## 7. Context and handoff reason

The verification session read 221,163 tokens before the records and the merge ([E-11](../plan/evidence.md#e-11-context-readings)), below the 300K preparation point. It hands off at the packet boundary: P0-PT-03 is new work and starts in a fresh session. The checkpoint is the newest `develop` commit touching this file. The next command is [GOAL.md](GOAL.md).
