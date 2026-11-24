# CURRENT — active handoff packet

**Packet:** HO-2026-11-24-01 (r2) · **Written by:** Lead, session P0-INIT-01 · **Phase:** P0 · **PO authority:** planning, documentation and throwaway `spike/*` prototypes only. **P1 implementation is NOT authorized** (PD-07, PO-Q8 not yet asked).

## 1. Revision state

| Item | Value |
|---|---|
| Repository | local `/home/deb/App_sources/REM`; **no remote** (PO-Q2); device transfer uses a git bundle ([bootstrap §2](../engineering/bootstrap.md#2-new-device-bootstrap-receiver-procedure)) |
| Branches | `master` = seed baseline `bd3312d`; `develop` = integration (P0 work merged from `p0/planning-baseline` with `--no-ff`) |
| Tested revision | the checkpoint below; checks recorded in [E-08](../plan/evidence.md#e-08-docs-check) and [E-07](../plan/evidence.md#e-07-restart-path-and-receiver-cases) |
| Checkpoint | the newest `develop` commit touching this file: `git log -1 --format=%H develop -- docs/handoff/CURRENT.md`. Later commits that touch only `docs/plan/evidence.md`, `p0-gate.md` or `backlog.md` are expected evidence follow-ups |
| Working tree at handoff | clean apart from the ignored `Xây dựng nền tảng chat Rust.pdf` and `.claude/settings.local.json` |
| Spec versions | PROJECT_SPEC v1.1, FEATURE_REGISTRY v1.1 (207 IDs), AGENT_HARNESS v1.2, START_PROMPT 2026-11-24 |
| Rollback point | `bd3312d` (seed baseline); `8fddc5a` (planning baseline r1, before the review rework) |

## 2. Done in this packet

- P0-INIT-01: the planning baseline indexed in [docs/README.md](../README.md), and `scripts/check_docs.py` with its self-test.
- P0-RES-01: the Telegram reference (33 rows).
- P0-REV-01: the independent review (17 findings, E-09), then rework round 1 and adversarial verification (E-09b). 14 of the 16 addressed findings were resolved. The residuals and 8 new MAJOR defects make up P0-REV-02.

## 3. Gate and decisions

- **P0 gate: NOT PASSED.** 5 PASS, 5 PENDING (items 3–7 and 9), 1 BLOCKED (item 8, on PO-Q1). See [p0-gate.md](../plan/p0-gate.md).
- **Outstanding PO decisions:** **PO-Q1** (tool installs, blocking gate item 8), **PO-Q2** (remote and CI host, blocking CI evidence and remote handoff), **PO-Q9** (admin reset power, needed before P1-03 is accepted), and PO-Q3..Q7 (non-blocking). See [decisions §3](../plan/decisions.md#3-po-question-queue).
- Lead decisions LD-01..LD-16 are in [decisions §2](../plan/decisions.md#2-lead-decisions-reversible).

## 4. Known failures, risks and constraints

No failing checks. **Known open defects:** the 10 MAJOR rows and the MINOR rows in [E-09b](../plan/evidence.md#e-09b-review-rework-and-adversarial-verification). Open risks R-01..R-17 ([risks.md](../plan/risks.md)). Tool constraints: no wasm32 target, wasm-pack, Playwright or DB images. Podman, not Docker. No `sudo`. A `rust-anything` plugin is configured in the user environment but fails to start (R-17); do not use it.

## 5. Next task: P0-REV-02 (READY) — review round 2

- **Goal:** resolve every row of the [E-09b table](../plan/evidence.md#e-09b-review-rework-and-adversarial-verification) in its home file, then verify on fresh contexts with no BLOCKING or MAJOR residual.
- **Base:** `develop` at the checkpoint. **Branch:** `p0/review-round-2`. **Owner:** Lead as arbiter, with one writer per file (as LD-15).
- **Write allowlist:** `docs/**`. **Excluded:** seeds, code, installs.
- **First unfinished action:** write one binding resolution per E-09b row as new LD rows in `docs/plan/decisions.md`. Rows that need a product choice go to the PO queue instead.
- **Acceptance:** `python3 scripts/check_docs.py` prints `OK`. A new evidence row E-09c lists each row as resolved, with file and section, judged by two refuters, and a critic reports no new BLOCKING or MAJOR defect. Gate items 3–7 are re-assessed.
- **Verification budget:** docs only; run the rework as a workflow so the lead context stays below about 150K. **Stop:** all rows resolved, or a PO question raised for each row that remains. **Rollback:** delete the branch.
- **After it:** P0-PT-03 (CI selection spike), then P0-SEC-01. P0-PT-01 and P0-PT-02 follow PO-Q1.

## 6. Read list for the receiver (in order)

1. This file. 2. [evidence E-09, E-09b](../plan/evidence.md#e-09-independent-review). 3. [decisions LD-14..16, PO-Q9](../plan/decisions.md#2-lead-decisions-reversible). 4. [p0-gate items 3–7](../plan/p0-gate.md#1-exit-items). 5. [lessons.md](../plan/lessons.md). Then open only the files each E-09b row names.

## 7. Context and handoff reason

Readings are in [E-11](../plan/evidence.md#e-11-context-readings). This session reached about 350K tokens (the AGENT_HARNESS §5 point to checkpoint and transfer), so it ends at the goal boundary instead of starting round 2. The next command is [GOAL.md](GOAL.md).
