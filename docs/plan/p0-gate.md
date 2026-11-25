# REM — P0 exit gate assessment

**Owner:** Lead · **Revision:** r3, 2026-11-25 · **Assessed revision:** the checkpoint named in [CURRENT §1](../handoff/CURRENT.md#1-revision-state), with checks in [E-08](evidence.md#e-08-docs-check) and the review in [E-09/E-09b](evidence.md#e-09b-review-rework-and-adversarial-verification) and [E-09c](evidence.md#e-09c-final-verification-of-p0-rev-02). **Criteria:** [PROJECT_SPEC §6 P0 exit review](../../PROJECT_SPEC.md#p0-exit-review) plus the harness conformance checks in §2. Statuses are only `PASS`, `PENDING` and `BLOCKED`.

**Overall: NOT PASSED.** 8 PASS, 2 PENDING, 1 BLOCKED. **Implementation authorization: NOT REQUESTED / NOT GRANTED.** PO-Q8 is asked only after all 11 items pass. A planned prototype counts only as a plan, so a decision that depends on one stays open.

## 1. Exit items

| # | Item | Status | Owner | Evidence | Blocker or resolution criterion |
|---|---|---|---|---|---|
| 1 | Scope and non-goals | PASS | Lead | [requirements §1](../product/requirements.md#1-scope-and-non-goals), [decisions §1](decisions.md#1-po-decisions-binding) | Derived only from PO-locked inputs; no scope added |
| 2 | Registry IDs and ownership | PASS | Lead | [E-03](evidence.md#e-03-registry-integrity): 207 IDs, no duplicates; [backlog §3](backlog.md#3-domain-ownership-role-owners-one-role-may-be-filled-by-the-same-agent-sequentially) | — |
| 3 | Acceptance criteria for each P1 capability | PASS | Lead | 84/84 rows exist ([E-08](evidence.md#e-08-docs-check)); the criteria named by the R2 rows (SYN-006.d, GRP-007.a, GRP-004.c, ID-002.b) and by LD-40 (ID-001.c, ORG-004.b) are resolved and verified with no BLOCKING or MAJOR residual ([E-09c](evidence.md#e-09c-final-verification-of-p0-rev-02)) | [E-09c](evidence.md#e-09c-final-verification-of-p0-rev-02) omissions: 2 unreported critic candidates, MINOR residuals recorded |
| 4 | Reviewed domain invariants | PASS | Architecture | Reviewed in E-09; R2-C1, R2-C2, R2-C5 and R2-C8 resolved and verified, the push cache rebuild fixed (R3-K3) ([E-09c](evidence.md#e-09c-final-verification-of-p0-rev-02)) | Empirical validation of sequencing and the outbox is item 8 (PT-02) |
| 5 | Versioned API and event contracts | PASS | Architecture | [contracts.md](../architecture/contracts.md): R2-C3 (pre-session idempotency keys) and R2-C4 (the closed mutation table) resolved and verified; event-page tombstones defined (R3-K5) ([E-09c](evidence.md#e-09c-final-verification-of-p0-rev-02)) | — |
| 6 | Offline replay and idempotency | PASS | Architecture | [sync.md](../architecture/sync.md): R2-V1, V22, V28 and V29 (dependents of a stuck op) and R2-V2, V11 and V23 (device binding across re-login) resolved and verified ([E-09c](evidence.md#e-09c-final-verification-of-p0-rev-02)) | Empirical validation is item 8 |
| 7 | Threat model and authorization matrix | PENDING | Security | [threat-model.md](../security/threat-model.md): R2-C7 (break-glass bounds), R2-V2 (logout and the shared browser) and the R3-K1/K4 admin powers resolved and verified ([E-09c](evidence.md#e-09c-final-verification-of-p0-rev-02)) | Open: R-13 (ASVS mapping, **P0-SEC-01**) and **PO-Q9** answered. R-12 (human review) stays open into P1-15 and does not block P0 |
| 8 | Risk-bearing ADRs and necessary prototype evidence | **BLOCKED** | Architecture / Client | [adr.md](../architecture/adr.md): ADR-0003 Open; ADR-0005 and the ADR-0002 sub-decisions await PT-01 and PT-02 | **Blocker: PO-Q1** (tool installs and image pulls). Resolved when the PT-01 and PT-02 evidence is in E-rows and the ADRs are updated |
| 9 | QA/CI and release gates | PENDING | QA / DevOps | [testing-ci.md](../engineering/testing-ci.md): selection, aggregate validated against a lane registry, CODEOWNERS, retention 3/5/7, caches (F15 verified) | Cases C1–C5 observed in P0-PT-03. C6, the host checks in [testing-ci §4.1](../engineering/testing-ci.md#41-protecting-the-ci-definitions) (code-owner enforcement, the pinned check source, who can bypass) and the artifact-expiry evidence need a CI host (**PO-Q2**) |
| 10 | Dependency-ordered packets | PASS | Lead | [backlog §1–2](backlog.md#2-p1-packets-dependency-order-all-not-authorized-until-the-gate-passes-and-the-po-authorizes) | — |
| 11 | Restart packet and evidence index | PASS | Lead | [CURRENT](../handoff/CURRENT.md), [evidence.md](evidence.md), [E-07](evidence.md#e-07-restart-path-and-receiver-cases) | PASS only if E-07 records a fresh-context restart that passed. If E-07 says otherwise, this row is PENDING |

## 2. Harness conformance checks

| # | Check | Status | Evidence |
|---|---|---|---|
| H1 | Handoff packet carries every field of the AGENT_HARNESS §5 packet contract | PASS | [CURRENT](../handoff/CURRENT.md) |
| H2 | Resolved `/goal` command is at most 4,000 characters | PASS | E-08 (the checker prints the length) |
| H3 | Auto-compaction disabled where supported | PASS | `.claude/settings.json` sets `DISABLE_AUTO_COMPACT=1`; a new top-level session printed `1` for `printenv DISABLE_AUTO_COMPACT` in its own shell ([E-07](evidence.md#e-07-restart-path-and-receiver-cases), P0-REV-02 session start) |
| H4 | Affected-crate and WASM selection, required aggregate, scheduled and release coverage, cache boundaries, 3/5/7-day retention documented | PASS (design) | [testing-ci §3–4](../engineering/testing-ci.md#3-impact-map-and-selection) |
| H5 | Required checks are reliable (skipped ≠ pass; a missing lane fails; CI definitions protected) | PENDING | the design is verified in E-09b (F15); observation needs PT-03 (C1–C5) and a host (C6) |
| H6 | Context readings recorded before large waves | PASS | [E-11](evidence.md#e-11-context-readings) |
| H7 | Subagent dispatch justified | PASS | LD-12, LD-15 |
| H8 | Learning loop exists, with one real lesson | PASS | [lessons.md](lessons.md) |
| H9 | Independent review of critical claims (sync, revocation, authorization) | PASS | E-09, E-09b and [E-09c](evidence.md#e-09c-final-verification-of-p0-rev-02): P0-REV-02 resolved and verified all 38 round-2 rows |
| H10 | New-device bootstrap documented, with a verified bundle path | see E-10 | [bootstrap §2](../engineering/bootstrap.md#2-new-device-bootstrap-receiver-procedure) |
