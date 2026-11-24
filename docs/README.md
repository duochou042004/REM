# REM — Planning index

**Rust Enterprise Messenger** (working title) is a Rust-first, independent, self-hosted enterprise messenger. Telegram is used only as a behavioral reference. **Phase:** P0 (planning). **Production implementation is not authorized**, see [p0-gate.md](plan/p0-gate.md). **Start every session at [handoff/CURRENT.md](handoff/CURRENT.md).**

## Authority order

1. Current PO decisions ([decisions.md §1](plan/decisions.md#1-po-decisions-binding))
2. The four seeds, unedited, at the repository root: [PROJECT_SPEC.md](../PROJECT_SPEC.md), [FEATURE_REGISTRY.md](../FEATURE_REGISTRY.md), [AGENT_HARNESS.md](../AGENT_HARNESS.md), [START_PROMPT.md](../START_PROMPT.md)
3. This planning set. Each fact has one home, listed below, and other files link to it.
4. The discovery PDF, for provenance only ([sources.md](plan/sources.md))

## Documents

| Concern | Home | Owner | Status |
|---|---|---|---|
| Scope, non-goals, status vocabulary, enterprise deviations, **P1 acceptance criteria** | [product/requirements.md](product/requirements.md) | Lead | Specified |
| Telegram reference behavior (evidence log) | [product/reference-behavior.md](product/reference-behavior.md) | Research | Discovered |
| UX, IA, accessibility | [product/ux.md](product/ux.md) | Client | Specified |
| Hexagon, workspace, ports, domain model | [architecture/architecture.md](architecture/architecture.md) | Architecture | Specified |
| Messaging and sync contract (ACK, replay, revocation) | [architecture/sync.md](architecture/sync.md) | Architecture | Specified, reviewed in E-09 |
| API, event, binding contracts and errors | [architecture/contracts.md](architecture/contracts.md) | Architecture | Specified |
| Architecture decision records | [architecture/adr.md](architecture/adr.md) | Architecture | 2 Accepted, 9 Proposed, 3 Open |
| Threat model and authorization matrix | [security/threat-model.md](security/threat-model.md) | Security | Specified, reviewed in E-09 |
| Deployment, backup, observability, upgrade | [operations.md](operations.md) | DevOps | Specified |
| Commercial readiness | [commercial.md](commercial.md) | Lead / PO | Discovered |
| Test ladder, impact selection, CI design, retention | [engineering/testing-ci.md](engineering/testing-ci.md) | QA / DevOps | Specified; execution pending |
| Environment and new-device bootstrap | [engineering/bootstrap.md](engineering/bootstrap.md) | DevOps | Observed 2026-11-24 |
| **Backlog, packets, P1 traceability** | [plan/backlog.md](plan/backlog.md) | Lead | r1 |
| **P0 gate assessment** | [plan/p0-gate.md](plan/p0-gate.md) | Lead | NOT PASSED |
| Decisions and PO question queue | [plan/decisions.md](plan/decisions.md) | Lead | r1 |
| Risk register | [plan/risks.md](plan/risks.md) | Lead | r1 |
| Sources, provenance, conflicts, unknowns | [plan/sources.md](plan/sources.md) | Lead | r1 |
| Commands and results (evidence index) | [plan/evidence.md](plan/evidence.md) | Lead | r1 |
| Lessons learned | [plan/lessons.md](plan/lessons.md) | Lead | r1 |
| Active handoff packet | [handoff/CURRENT.md](handoff/CURRENT.md) | Lead | active |
| Resolved `/goal` command for the next session | [handoff/GOAL.md](handoff/GOAL.md) | Lead | active |

## How to change these docs

- Keep IDs stable: capability IDs come from the registry. Sub-IDs are `ID.a` (criteria), `DEV-nn`, `ADR-nnnn`, `PD-`/`LD-`/`PO-Q`, `R-nn`, `E-nn`, `P0-*` and `P1-nn` packets. Never reuse an ID. Mark superseded items instead of deleting them.
- Before committing any doc change, run `python3 scripts/check_docs.py`, which must print `OK`. It checks links, anchors, index reachability, registry IDs, P1 coverage and the goal length.
- A claim of passing, running or verified needs a row in [evidence.md](plan/evidence.md) with SHA, command and result.
