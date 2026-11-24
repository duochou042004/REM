# CURRENT — active handoff packet

**Packet:** HO-2026-11-24-01 · **Written by:** Lead, session P0-INIT-01 · **Phase:** P0 · **PO authority:** planning, documentation and throwaway `spike/*` prototypes only. **P1 implementation is NOT authorized** (PD-07, PO-Q8 not yet asked).

## 1. Revision state

| Item | Value |
|---|---|
| Repository | local `/home/deb/App_sources/REM`; **no remote** (PO-Q2); device transfer uses a git bundle ([bootstrap §2](../engineering/bootstrap.md#2-new-device-bootstrap-receiver-procedure)) |
| Branches | `master` = seed baseline `bd3312d`; `develop` = integration; P0 work merged from `p0/planning-baseline` |
| Tested revision | see [evidence E-08](../plan/evidence.md#e-08-docs-check) (the docs commit the checks ran on) |
| Checkpoint | the newest `develop` commit touching this file: `git log -1 --format=%H develop -- docs/handoff/CURRENT.md` |
| Working tree at handoff | clean apart from untracked, ignored `Xây dựng nền tảng chat Rust.pdf` and `.claude/settings.local.json` |
| Spec versions | PROJECT_SPEC v1.1, FEATURE_REGISTRY v1.1 (207 IDs), AGENT_HARNESS v1.2, START_PROMPT 2026-11-24 |
| Rollback point | `develop` before the P0 merge equals `bd3312d` (seed baseline) |

## 2. Done in this packet (P0-INIT-01)

The planning baseline in [docs/README.md](../README.md): requirements and acceptance criteria for 84/84 P1 IDs, Telegram reference for 33 IDs, architecture (hexagon, ports, workspace, domain model), sync contract, API and event contracts, 14 ADRs, threat model and authorization matrix, operations, commercial, test and CI design, bootstrap, backlog and traceability, decisions, risks, sources and conflicts, lessons, the gate assessment, and `scripts/check_docs.py` with its self-test. Also `CLAUDE.md` and `.claude/settings.json` (`DISABLE_AUTO_COMPACT=1`).

## 3. Gate and decisions

- **P0 gate: NOT PASSED.** Item 8 is BLOCKED on PO-Q1 and item 9 is PENDING on PT-03 and PO-Q2 ([p0-gate.md](../plan/p0-gate.md)).
- **Outstanding PO decisions:** PO-Q1 (tool installs for the prototypes, **blocking**), PO-Q2 (remote and CI host, **blocking** CI evidence and remote handoff), PO-Q3..Q7 (non-blocking). See [decisions §3](../plan/decisions.md#3-po-question-queue).
- New lead decisions LD-01..LD-13 are in [decisions §2](../plan/decisions.md#2-lead-decisions-reversible).

## 4. Known failures, risks and constraints

No failing checks. Open risks are R-01..R-15 ([risks.md](../plan/risks.md)), led by R-01 (browser persistence), R-02 (hot-conversation throughput), R-05 (no remote) and R-06 (tools). Tool constraints: no wasm32 target, wasm-pack, Playwright or DB images. Podman, not Docker. No `sudo`.

## 5. Next task: P0-PT-03 (READY) — CI selection spike (OPS-008)

- **Goal:** observed evidence for cases C1–C5 in [testing-ci §6](../engineering/testing-ci.md#6-p0-acceptance-cases-for-ci-selection-synthetic-walkthrough--not-an-observed-execution).
- **Base:** `develop` at the checkpoint. **Branch:** `spike/pt-03-ci-selection`. **Owner:** DevOps (single agent; a shared contract, so no parallel workers).
- **Write allowlist:** `spikes/pt-03/**`, plus updates to `docs/plan/evidence.md`, `docs/plan/backlog.md`, `docs/plan/p0-gate.md` (item 9, H5), `docs/engineering/testing-ci.md` §6 status column, `docs/plan/lessons.md` and this file. **Excluded:** `crates/`, `apps/`, `.github/` (no remote), any install, image pull or network use.
- **First unfinished action:** create the branch and a dependency-free fixture workspace (`spikes/pt-03/fixture`, crates mirroring [architecture §2](../architecture/architecture.md#2-workspace-layout-created-by-packet-p1-00-not-before)). Use `cargo generate-lockfile --offline`.
- **Acceptance:** for each of C1–C5, the record shows the command, exit code, plan JSON (selected lanes plus reason) and aggregate verdict, and these match the expected columns. C3 must use base- versus head-side `cargo metadata --locked`. C5 must fail. A self-test covers "selected but skipped ⇒ fail". The artifact-expiry column stays PENDING without a CI host.
- **Verification budget:** T0/T1 only (python3, cargo metadata); about 60K tokens forecast. **Stop:** all five rows observed, or a blocker recorded with its unblock condition. **Rollback:** delete the spike branch.
- **After it:** P0-SEC-01 (ASVS mapping) is READY. If PO-Q1 is approved, P0-PT-01 and P0-PT-02 lead (they can run in parallel on disjoint paths).

## 6. Read list for the receiver (in order)

1. This file. 2. [backlog §1](../plan/backlog.md#1-p0-packets). 3. [testing-ci §3, §4, §6](../engineering/testing-ci.md#3-impact-map-and-selection). 4. [lessons.md](../plan/lessons.md). 5. [AGENT_HARNESS §4.4](../../AGENT_HARNESS.md#rust-workspace-and-github-actions-execution-policy). Read other files only when a specific dependency requires it.

## 7. Context and handoff reason

Readings are in [E-11](../plan/evidence.md#e-11-context-readings). This handoff happens because P0-INIT-01 reached its goal boundary and a phase-internal task switch is due, not because of the token cap. The next command is [GOAL.md](GOAL.md).
