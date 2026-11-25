# CURRENT — active handoff packet

**Packet:** HO-2026-11-25-03 · **Written by:** Lead, session P0-PT-03 / P0-PT-02 · **Phase:** P0 · **PO authority:** planning, documentation and throwaway `spike/*` prototypes only. **P1 implementation is NOT authorized** (PD-07, PO-Q8 not yet asked).

## 1. Revision state

| Item | Value |
|---|---|
| Repository | local `/home/deb/App_sources/REM`; remote `origin` = the **private** GitHub repository `duochou042004/REM` (PO-Q2 = A, [E-16](../plan/evidence.md#e-16-private-github-remote)), default branch `master`; a new device clones it ([bootstrap §2](../engineering/bootstrap.md#2-new-device-bootstrap-receiver-procedure)) |
| Branches | `master` = seed baseline `bd3312d`; `develop` = integration, holding the `--no-ff` merge of `p0/pt-02-results` (P0-PT-02, LD-45); merged branches are deleted locally and on `origin` (LD-44). Kept unmerged as evidence: `spike/pt-03-ci-selection` (`6dea8c8`, E-14) and `spike/pt-02-pg-sequencing` (`f84c55a`, E-17) |
| Tested revision | spike `f84c55a` for the PT-02 scenarios ([E-17](../plan/evidence.md#e-17-p0-pt-02-postgresql-sequencing-spike)); the docs check runs at the checkpoint below |
| Checkpoint | the newest commit on **`develop`** that touches this file: `git log -1 --format=%H develop -- docs/handoff/CURRENT.md`. `develop` HEAD is its `--no-ff` merge, with an empty diff to it, and `origin/develop` equals it |
| Working tree at handoff | clean apart from the ignored `docs/seeds/Xây dựng nền tảng chat Rust.pdf`, `.claude/settings.local.json`, `graphify-out/` and `.claude/state/` |
| Spec versions | in [docs/seeds/](../seeds/PROJECT_SPEC.md) (LD-43): PROJECT_SPEC v1.1, FEATURE_REGISTRY v1.1 (207 IDs), AGENT_HARNESS v1.2, START_PROMPT 2026-11-24 |
| Rollback point | `bd3312d` (seed baseline); `7e83f79` (`develop` before P0-PT-02) |

## 2. Done in this packet

- Earlier packets: P0-INIT-01, P0-RES-01, P0-REV-01, P0-REV-02 and P0-PT-03 (local), as recorded in [backlog §1](../plan/backlog.md#1-p0-packets).
- **Repository housekeeping:** the seeds and the PDF moved to `docs/seeds/` (LD-43, E-15); a private GitHub remote holds every branch (PO-Q2 = A, E-16); merged branches are deleted (LD-44).
- **P0-PT-02 DONE:** every ADR-0005 validation item held on PostgreSQL 19.0 except the outbox dispatcher, which was not run. A SIGKILL under load lost none of 929 ACKed sends; there were no seq holes; a duplicate storm produced one write; no removed member or revoked session committed later; mutual revocation never deadlocked in the §3.1 order (20/20), while the control deadlocked 20/20. Measured: about 850 sends/s per hot conversation, about 9,300/s spread, at most 1,276 bytes per message. **ADR-0005 Accepted** ([E-17](../plan/evidence.md#e-17-p0-pt-02-postgresql-sequencing-spike)).

## 3. Gate and decisions

- **P0 gate: NOT PASSED.** 8 PASS (items 1–6, 10, 11), 3 PENDING (item 7 on P0-SEC-01 and PO-Q9; item 8 on **P0-PT-01** only; item 9 on a host run, the P1-00 workflows and PO-Q13), 0 BLOCKED. See [p0-gate.md](../plan/p0-gate.md).
- **Outstanding PO decisions:** **PO-Q13** (GitHub Pro for branch protection; C6 and the §4.1 checks), **PO-Q9** (admin reset power; gate item 7 and P1-09), **PO-Q10** (dormant store; before P1-06), and PO-Q3..Q7 (non-blocking). See [decisions §3](../plan/decisions.md#3-po-question-queue).
- PO-Q1 = A, PO-Q2 = A and PO-Q12 = A, all 2026-11-25. Lead decisions LD-01..LD-45 are in [decisions §2](../plan/decisions.md#2-lead-decisions-reversible).

## 4. Known failures, risks and constraints

No failing checks. **Known open items:** the E-14 and E-17 omissions and their MINOR review findings; the E-09c/E-09d MINOR residuals (the P1-00 review re-reads sync, contracts and threat-model). Open risks are in [risks.md](../plan/risks.md); R-02 and R-15 are now MITIGATED. Tool constraints: no wasm32 target, wasm-pack or Playwright yet (PO-Q1 approves them; Playwright system libraries that need `sudo apt` are a separate question). Podman, not Docker. No `sudo`. The `rust-anything` plugin fails to start (R-17); do not use it. The PT-02 container `rem-pt02-pg` was removed after the review; the `postgres:19` image stays for reruns.

## 5. Next task: P0-PT-01 (READY) — browser persistence and WASM binding spike

- **Goal:** the scope in the [backlog §1 P0-PT-01 row](../plan/backlog.md#1-p0-packets): a cold reload, a queued send, a reconnect and a lost ACK on Chromium, Firefox and WebKit; bundle and load cost; storage availability (private mode, quota) and recovery after storage is cleared. It decides [ADR-0003](../architecture/adr.md#adr-0003-browser-persistence) and the [ADR-0002](../architecture/adr.md#adr-0002-web-client-reacttypescript-with-rust-wasm-sdk) sub-decisions.
- **Base:** `develop` at the checkpoint. **Branches:** `spike/pt-01-browser-persistence` (never merged, kept while its evidence row cites it) and `p0/pt-01-results` (merged with `--no-ff`, then deleted locally and on `origin`, LD-44). **Owner:** Client role, run by the Lead.
- **Tools (PO-Q1 = A):** `rustup target add wasm32-unknown-unknown`, a pinned `wasm-pack` or `wasm-bindgen-cli`, and npm devDependencies including `@playwright/test` and its browsers in the spike directory only, all user-level and recorded in [bootstrap §1](../engineering/bootstrap.md#1-observed-environment-2026-11-24). If the browsers need `sudo apt` system libraries, stop and ask the PO.
- **First action:** write the P0-PT-01 packet detail in backlog §1, as in [§1.2](../plan/backlog.md#12-p0-pt-02-packet-detail).
- **Acceptance:** `python3 scripts/check_docs.py` prints `OK`; an evidence row with the tested SHA, tool versions, browser versions and a result per scenario and engine; ADR-0003 decided and ADR-0002 (a) and (b) decided or narrowed with measurements; R-01 updated; gate item 8 re-assessed.
- **Budget:** inline by default; at most one independent reviewer (LD-39).
- **After it:** P0-SEC-01 (ASVS mapping, gate item 7), then P0-GATE-02.

## 6. Read list for the receiver (in order)

1. This file. 2. [backlog §1, the P0-PT-01 row](../plan/backlog.md#1-p0-packets) and [§1.2](../plan/backlog.md#12-p0-pt-02-packet-detail) as the template. 3. [ADR-0002 and ADR-0003](../architecture/adr.md#adr-0002-web-client-reacttypescript-with-rust-wasm-sdk). 4. [sync §5](../architecture/sync.md#5-client-outbox-and-pending-state). 5. [p0-gate item 8](../plan/p0-gate.md#1-exit-items). 6. [lessons.md](../plan/lessons.md).

## 7. Context and handoff reason

This session ran P0-PT-03, the repository housekeeping and P0-PT-02. Its reading was 287,523 tokens after the PT-02 reviewer ([E-11](../plan/evidence.md#e-11-context-readings)), approaching the 300K preparation point. P0-PT-01 installs a new toolchain and runs three browser engines, so it starts in a fresh session at this packet boundary. The checkpoint is the newest `develop` commit touching this file. The next command is [GOAL.md](GOAL.md).
