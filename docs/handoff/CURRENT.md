# CURRENT — active handoff packet

**Packet:** HO-2026-11-25-02 · **Written by:** Lead, session P0-PT-03 · **Phase:** P0 · **PO authority:** planning, documentation and throwaway `spike/*` prototypes only. **P1 implementation is NOT authorized** (PD-07, PO-Q8 not yet asked).

## 1. Revision state

| Item | Value |
|---|---|
| Repository | local `/home/deb/App_sources/REM`; remote `origin` = the **private** GitHub repository `duochou042004/REM` (PO-Q2 = A, [E-16](../plan/evidence.md#e-16-private-github-remote)), default branch `master`; a new device clones it ([bootstrap §2](../engineering/bootstrap.md#2-new-device-bootstrap-receiver-procedure)) |
| Branches | `master` = seed baseline `bd3312d`; `develop` = integration, holding the `--no-ff` merges of `p0/pt-03-results` (P0-PT-03 results, LD-42) and `p0/seed-relocation` (seeds moved to `docs/seeds/`, LD-43); `spike/pt-03-ci-selection` = the PT-03 throwaway spike at `6dea8c8`, **never merged** |
| Tested revision | spike `6dea8c8` for the PT-03 cases ([E-14](../plan/evidence.md#e-14-p0-pt-03-ci-selection-spike)); the docs check runs at the checkpoint below |
| Checkpoint | the newest commit on **`develop`** that touches this file: `git log -1 --format=%H develop -- docs/handoff/CURRENT.md`. `develop` HEAD is its `--no-ff` merge, with an empty diff to it |
| Working tree at handoff | clean apart from the ignored `docs/seeds/Xây dựng nền tảng chat Rust.pdf`, `.claude/settings.local.json`, `graphify-out/` and `.claude/state/` |
| Spec versions | in [docs/seeds/](../seeds/PROJECT_SPEC.md) (LD-43): PROJECT_SPEC v1.1, FEATURE_REGISTRY v1.1 (207 IDs), AGENT_HARNESS v1.2, START_PROMPT 2026-11-24 |
| Rollback point | `bd3312d` (seed baseline); `e44d928` (`develop` before P0-PT-03) |

## 2. Done in this packet

- Earlier packets: P0-INIT-01, P0-RES-01, P0-REV-01 and P0-REV-02, as recorded in [backlog §1](../plan/backlog.md#1-p0-packets).
- **P0-PT-03 DONE (local):** cases C1–C5 observed on a fixture workspace with emulated GitHub job semantics. Every run's selected lanes and its `required` verdict match [testing-ci §6](../engineering/testing-ci.md#6-p0-acceptance-cases-for-ci-selection-synthetic-walkthrough--not-an-observed-execution): C1 pass (exit 0), C2 pass (0), C2 with `wasm-web` skipped fail (1), C3 pass (0), C3 with a failing widened lane fail (1), C4 pass (0), C5 fail (1). One independent reviewer found no BLOCKING or MAJOR defect ([E-14](../plan/evidence.md#e-14-p0-pt-03-ci-selection-spike)).
- **Seed relocation (LD-43):** the four seeds and the discovery PDF moved to `docs/seeds/`, with content and hashes unchanged ([E-15](../plan/evidence.md#e-15-seed-relocation)).
- **Remote (PO-Q2 = A):** the private `duochou042004/REM` holds every branch ([E-16](../plan/evidence.md#e-16-private-github-remote)). Push merged `develop` and `master` after each checkpoint. Never force-push either one.

## 3. Gate and decisions

- **P0 gate: NOT PASSED.** 8 PASS (items 1–6, 10, 11), 3 PENDING (item 7 on P0-SEC-01 and PO-Q9; item 8 on PT-01 and PT-02; item 9 on a host run, the workflows of P1-00 and PO-Q13), 0 BLOCKED. H5 stays PENDING on the same items. See [p0-gate.md](../plan/p0-gate.md).
- **Outstanding PO decisions:** **PO-Q13** (GitHub Pro for branch protection on the private repository; it blocks C6 and the §4.1 checks of gate item 9), **PO-Q9** (admin reset power; gate item 7 and P1-09), **PO-Q10** (dormant store; before P1-06), and PO-Q3..Q7 (non-blocking). See [decisions §3](../plan/decisions.md#3-po-question-queue).
- PO-Q1 = A, PO-Q2 = A (private GitHub repository) and PO-Q12 = A, all 2026-11-25. PT-01 and PT-02 install their own tools in their own sessions (user-level, no `sudo`; Playwright system libraries that need `sudo apt` are asked separately).
- Lead decisions LD-01..LD-43 are in [decisions §2](../plan/decisions.md#2-lead-decisions-reversible). LD-42 sets the packet order below.

## 4. Known failures, risks and constraints

No failing checks. **Known open items:** the E-14 omissions (emulated host semantics, stand-in lanes, untested classifier paths) and its 5 MINOR review findings, which the P1-00 classifier inherits. The MINOR residuals of E-09c and E-09d remain, and the P1-00 review re-reads sync, contracts and threat-model. Open risks R-01..R-17 ([risks.md](../plan/risks.md)). Tool constraints: no wasm32 target, wasm-pack, Playwright or DB images yet; PO-Q1 approves installing them. Podman, not Docker. No `sudo`. A `rust-anything` plugin is configured in the user environment but fails to start (R-17); do not use it.

## 5. Next task: P0-PT-02 (READY) — PostgreSQL sequencing, outbox and durable ACK spike

- **Goal:** the scope in the [backlog §1 P0-PT-02 row](../plan/backlog.md#1-p0-packets), measured against the [ADR-0005](../architecture/adr.md#adr-0005-conversation-sequencing-outbox-and-durable-ack) validation list and [sync §3](../architecture/sync.md#3-server-write-path-durable-ack).
- **Base:** `develop` at the checkpoint. **Branches:** `spike/pt-02-pg-sequencing` for the throwaway code (never merged), and `p0/pt-02-results` for the docs results (merged with `--no-ff`). **Owner:** Architecture role, run by the Lead.
- **Tools (PO-Q1 = A):** pull one pinned PostgreSQL image with Podman, user-level and recorded by digest in [bootstrap §1](../engineering/bootstrap.md#1-observed-environment-2026-11-24); Rust crates for the spike only. No `sudo`, no remotes.
- **First action:** write the P0-PT-02 packet detail in backlog §1 (IDs, owner, scope, allowlist, acceptance, verification budget), the same way as [backlog §1.1](../plan/backlog.md#11-p0-pt-03-packet-detail).
- **Acceptance:** `python3 scripts/check_docs.py` prints `OK`; an evidence row with the tested SHA, the image digest, the hardware, the commands and a result per scenario; ADR-0005 accepted or revised with measurements; R-02 and R-15 updated; gate item 8 re-assessed (it also needs PT-01).
- **Budget:** inline by default; at most one independent reviewer (LD-39).
- **Alongside or after it:** P0-PT-01 (READY, its own session, disjoint paths; may need a `sudo apt` question for Playwright libraries). Then P0-SEC-01 (ASVS mapping, gate item 7), then P0-GATE-02.

## 6. Read list for the receiver (in order)

1. This file. 2. [backlog §1, the P0-PT-02 row](../plan/backlog.md#1-p0-packets) and [§1.1](../plan/backlog.md#11-p0-pt-03-packet-detail) as the template. 3. [ADR-0005](../architecture/adr.md#adr-0005-conversation-sequencing-outbox-and-durable-ack). 4. [sync §3 and §3.1](../architecture/sync.md#3-server-write-path-durable-ack). 5. [p0-gate item 8](../plan/p0-gate.md#1-exit-items). 6. [lessons.md](../plan/lessons.md).

## 7. Context and handoff reason

The P0-PT-03 session read 130,198 tokens before its one reviewer ([E-11](../plan/evidence.md#e-11-context-readings)), well below the 300K preparation point. It hands off at the packet boundary, because P0-PT-02 is new work with its own tools and starts in a fresh session. The checkpoint is the newest `develop` commit touching this file. The next command is [GOAL.md](GOAL.md).
