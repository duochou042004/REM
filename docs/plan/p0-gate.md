# REM — P0 exit gate assessment

**Owner:** Lead · **Revision:** r1, 2026-11-24 · **Assessed revision:** see [evidence E-08](evidence.md#e-08-docs-check) · **Criteria:** [PROJECT_SPEC §6 P0 exit review](../../PROJECT_SPEC.md#p0-exit-review) plus the harness conformance checks below.

**Overall: NOT PASSED.** Items 8 and 9 are open. **Implementation authorization: NOT REQUESTED / NOT GRANTED** (PO-Q8 is asked only after every item passes). A planned prototype counts only as a plan, so a decision that depends on one stays open.

## 1. Exit items

| # | Item | Status | Owner | Evidence | Open risk / resolution criterion |
|---|---|---|---|---|---|
| 1 | Scope and non-goals | PASS | Lead | [requirements §1](../product/requirements.md#1-scope-and-non-goals), [decisions §1](decisions.md#1-po-decisions-binding) | Derived only from PO-locked inputs; no scope added |
| 2 | Registry IDs and ownership | PASS | Lead | [E-03](evidence.md#e-03-registry-integrity) (207 IDs, no duplicates); [backlog §3](backlog.md#3-domain-ownership-role-owners-one-role-may-be-filled-by-the-same-agent-sequentially) | — |
| 3 | Acceptance criteria for each P1 capability | PASS-PENDING-REVIEW | Lead | 84/84 rows ([E-08](evidence.md#e-08-docs-check)); [requirements §5](../product/requirements.md#5-p1-acceptance-criteria) | Becomes PASS once E-09 reports no blocking finding |
| 4 | Reviewed domain invariants | PASS-PENDING-REVIEW | Architecture | [architecture §4](../architecture/architecture.md#4-domain-model-sketch-validated-against-invariants-not-a-final-schema), [sync §1](../architecture/sync.md#1-invariants-each-becomes-a-property-or-integration-test) | Needs the independent review E-09 |
| 5 | Versioned API and event contracts | PASS | Architecture | [contracts.md](../architecture/contracts.md), ADR-0006 | Golden fixtures are the P1-04 acceptance, not P0 |
| 6 | Offline replay and idempotency | PASS-PENDING-REVIEW | Architecture | [sync §3–5](../architecture/sync.md#3-server-write-path-durable-ack) | Specification only; empirical validation is item 8 (PT-01, PT-02) |
| 7 | Threat model and authorization matrix | PASS-PENDING-REVIEW | Security | [threat-model.md](../security/threat-model.md) | R-13 (ASVS 5.0 mapping, P0-SEC-01) and R-12 (human review before release) stay open |
| 8 | Risk-bearing ADRs and necessary prototype evidence | **BLOCKED** | Architecture / Client | [adr.md](../architecture/adr.md): ADR-0003 Open, ADR-0005 needs PT-02, ADR-0002 sub-decisions need PT-01 | Blocker: PO-Q1 (tooling). Resolved when PT-01 and PT-02 evidence is in E-rows and the ADRs are updated |
| 9 | QA/CI and release gates | **PENDING** | QA / DevOps | [testing-ci.md](../engineering/testing-ci.md) (design, retention 3/5/7, caches, aggregate) | C1–C5 not observed yet. P0-PT-03 is READY. The artifact-expiry evidence needs a CI host (PO-Q2) |
| 10 | Dependency-ordered packets | PASS | Lead | [backlog §1–2](backlog.md#2-p1-packets-dependency-order-all-not-authorized-until-the-gate-passes-and-the-po-authorizes) | — |
| 11 | Restart packet and evidence index | PASS-PENDING-TEST | Lead | [CURRENT](../handoff/CURRENT.md), [evidence.md](evidence.md), [E-07](evidence.md#e-07-restart-path-and-receiver-cases) | Becomes PASS once the fresh-context restart and the three receiver cases are recorded |

## 2. Harness conformance checks

| # | Check | Status | Evidence |
|---|---|---|---|
| H1 | Handoff packet carries every field of the AGENT_HARNESS §5 packet contract | PASS | [CURRENT](../handoff/CURRENT.md) |
| H2 | Resolved `/goal` command is at most 4,000 characters | PASS | E-08 (length printed by the checker) |
| H3 | Auto-compaction disabled where supported | PENDING | `.claude/settings.json` sets `DISABLE_AUTO_COMPACT=1`; the effect can only be observed in a new session (E-07 receiver step) |
| H4 | Affected-crate and WASM selection, required aggregate, scheduled and release coverage, cache boundaries, 3/5/7-day retention documented | PASS (design) | [testing-ci §3–4](../engineering/testing-ci.md#3-impact-map-and-selection) |
| H5 | Required checks are reliable (skipped ≠ pass) | PENDING | design in testing-ci §4; observation in PT-03 C5 |
| H6 | Context readings recorded before large waves | PASS | [E-11](evidence.md#e-11-context-readings) |
| H7 | Subagent dispatch justified | PASS | LD-12 |
| H8 | Learning loop exists, with one real lesson | PASS | [lessons.md](lessons.md) |
| H9 | Independent review of critical claims (sync, revocation, authorization) | PENDING | E-09 |
| H10 | New-device bootstrap documented, with a verified bundle path | PASS-PENDING-TEST | [bootstrap §2](../engineering/bootstrap.md#2-new-device-bootstrap-receiver-procedure), E-10 |
