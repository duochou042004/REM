# REM — Backlog, work packets and P1 traceability

**Owner:** Lead (the only writer of assignments) · **Revision:** r1, 2026-11-24 · **Phase:** P0. Implementation is **not authorized** ([p0-gate.md](p0-gate.md)). The chain is FEATURE → REQUIREMENT ([requirements.md](../product/requirements.md#5-p1-acceptance-criteria)) → DESIGN (ports and contracts below) → CODE → TEST → EVIDENCE ([evidence.md](evidence.md)). CODE and TEST links are added when packets land.

Packet contract ([AGENT_HARNESS §3](../../AGENT_HARNESS.md#3-task-packets-and-iterative-work)): every packet row names its IDs, owner, dependencies, scope, acceptance and verification budget. Each packet's detail is written when it becomes `READY`.

## 1. P0 packets

| Packet | Goal | Owner | Depends | Status | Acceptance / evidence | Dispatch note |
|---|---|---|---|---|---|---|
| P0-INIT-01 | Planning baseline: index, requirements, architecture, security, CI design, backlog, gate, handoff | Lead | — | DONE (r1) | [evidence E-01..E-10](evidence.md) | solo lead plus 2 research helpers plus 1 independent reviewer (parallel research, critical review) |
| P0-RES-01 | Telegram reference for the 33 P1 IDs with user-visible behavior | Research | — | DONE (Discovered) | [reference-behavior.md](../product/reference-behavior.md) | 1 helper, parallel with architecture writing |
| P0-REV-01 | Independent review: sync invariants, revocation, threat model, gate claims | Independent QA | P0-INIT-01 | DONE | [evidence E-09](evidence.md#e-09-independent-review) | separate agent, no authoring role |
| **P0-PT-03** | **CI selection spike:** classifier plus aggregate verdict on a throwaway fixture workspace; observe cases C1–C5 | DevOps | P0-INIT-01 | **READY (next)** | [testing-ci §6](../engineering/testing-ci.md#6-p0-acceptance-cases-for-ci-selection-synthetic-walkthrough--not-an-observed-execution) rows observed with exit codes; artifact-expiry column stays pending until a CI host exists | solo: one shared contract |
| P0-SEC-01 | Map P1 controls to ASVS 5.0 requirement IDs from the official OWASP release | Security | P0-INIT-01 | READY | a mapping table in threat-model §7; every P1 SEC criterion maps or is justified | solo or 1 helper |
| P0-PT-01 | Browser persistence plus WASM binding spike (ADR-0002 sub-decisions, ADR-0003): cold reload, queued send, reconnect, lost ACK on 3 engines; bundle and load cost; storage cleared | Client | PO-Q1 | BLOCKED (tools) | ADR-0003 decided with measured results | 1 helper possible alongside PT-02 (disjoint paths) |
| P0-PT-02 | PostgreSQL sequencing, outbox and durable ACK spike (ADR-0004/0005): concurrent writers, crash before or after commit, duplicates, send racing a removal, throughput per hot conversation, bytes per message | Architecture | PO-Q1 | BLOCKED (image pull) | ADR-0005 accepted or revised with measurements | parallel with PT-01 |
| P0-PT-04 | Desktop shell benchmark: Tauri WebView with WASM SDK vs native SDK; GPUI probe (RAM, startup, a11y, IME, packaging) | Client | PT-01, PO-Q1 | PENDING | ADR-0007 confirmed or revised | — |
| P0-RES-02 | OBSERVED evidence for UNKNOWN reference rows (edit and delete windows, pending clock state, archive-unarchive, URL previews) in a current official client | Research | PO account/device (PO-Q7) | BLOCKED | rows upgraded to OBSERVED with version and steps | — |
| P0-RES-03 | Customer discovery plan (interview guide, pilot criteria) | PO + Lead | — | PROPOSED (PO-owned) | plan in commercial §3 | — |
| P0-RES-04 | Research rows for P2 IDs (before P2 planning; registry rule "every capability researched in P0") | Research | — | QUEUED (not gating P1) | rows in reference-behavior.md | — |
| P0-GATE-02 | Re-assess the P0 gate after PT-01, PT-02, PT-03 and SEC-01; ask the PO for implementation authorization | Lead | PT-01, PT-02, PT-03, SEC-01 | PENDING | [p0-gate.md](p0-gate.md) all PASS; PO authorization recorded separately | — |

## 2. P1 packets (dependency order; all `NOT AUTHORIZED` until the gate passes and the PO authorizes)

| Packet | Scope (primary IDs) | Depends on | Key ports / contracts |
|---|---|---|---|
| P1-00 | Workspace skeleton, toolchain pin, CI workflows activated, dependency-direction check (OPS-008) | gate, PO-Q2 | [architecture §2](../architecture/architecture.md#2-workspace-layout-created-by-packet-p1-00-not-before), [testing-ci §4](../engineering/testing-ci.md#4-ci-design) |
| P1-01 | Domain core: IDs, membership intervals, sequence and permission rules (SYN-002, SYN-003) | P1-00 | `rem-domain` |
| P1-02 | PostgreSQL adapter: SendMessage transaction, idempotency, outbox, migrations (SYN-004, OPS-002) | P1-01, PT-02 | `ConversationLog`, `OutboxSource` |
| P1-03 | Bootstrap, invites, login, sessions, revocation (ENT-001, ID-001..003, SEC-002) | P1-02 | `IdentityStore`, `PasswordHasher`, ADR-0010 |
| P1-04 | Protocol v1, HTTP/WS adapters, golden fixtures, version negotiation (SYN-001, SYN-013, CLI-009) | P1-02, P1-03 | [contracts.md](../architecture/contracts.md) |
| P1-05 | Catch-up, gaps, snapshot reset, history authorization, isolation (SYN-006, 008, 009, SEC-003, 004) | P1-04 | `EventReader` |
| P1-06 | Client core plus native store: reducer, outbox, sync state machine, fault harness (CLI-003, CLI-004, SYN-005, 007, 014, DM-002) | P1-04 | `LocalStore`, `Transport`, `Clock` |
| P1-07 | Web app on the WASM SDK: shell, IA, states, a11y, themes, virtualization (CLI-001, CLI-011, UX-001, 003, 005, 006, 007, 009) | P1-05, P1-06, PT-01 | ADR-0002/0003, [ux.md](../product/ux.md) |
| P1-08 | Message lifecycle: text and entities, reply, edit, delete, forward, pin, mentions (DM-001, 003..006, 012) | P1-05, P1-06 | `ConversationLog` events |
| P1-09 | Groups, roles, rights, links, join requests, org admin roles (GRP-001..008, ID-005, ENT-002, 006, 012) | P1-05 | `ConversationLog`, `AuditSink` |
| P1-10 | Read positions, unread, typing, presence, chat list prefs (DM-008, 009, SYN-010, 011, NTF-001, ORG-001, 002) | P1-08, P1-09 | `Presence`, user stream |
| P1-11 | Attachments: upload, validation, quotas, signed download, media safety (MED-001, 002, 010, SEC-010, UX-008) | P1-08 | `BlobStore`, `MalwareScanner` |
| P1-12 | Search (ORG-004) | P1-08 | `SearchIndex` |
| P1-13 | Desktop shell, OS integration, deep links (CLI-002, CLI-008, UX-012) | P1-07, PT-04 | ADR-0007 |
| P1-14 | Deployment package, backup and restore, observability, upgrade, runbooks (OPS-001, 003..007, 011, 013, ENT-007, ENT-010) | P1-02 (can start partly), P1-04 | [operations.md](../operations.md) |
| P1-15 | Security baseline and independent review (SEC-001, 006, 009, 013) | P1-03, P1-05, P1-11 | [threat-model.md](../security/threat-model.md) |
| P1-16 | Profiles and account lifecycle (ID-004, ID-006) | P1-03, P1-11 | `IdentityStore`, `BlobStore` |
| P1-17 | Performance baseline and multi-device compatibility matrix (OPS-009, CLI-010) | P1-07, P1-14 | load harness |

Parallelism once authorized: after P1-04, packets P1-05 and P1-06 can run in parallel (server and client paths are disjoint). After P1-05, packets P1-08, P1-09 and P1-14 can too. `rem-protocol` and the migrations have one owner, the lead (harness §2.2).

## 3. Domain ownership (role owners; one role may be filled by the same agent sequentially)

| Domains | Owner role |
|---|---|
| ID, ENT, CMP, BIZ | Lead (product) |
| DM, GRP, CHN, ORG, NTF, STORY, BOT, APP, CALL | Product spec: Research; design: Architecture |
| SYN, protocol, data | Architecture |
| SEC | Security, with independent QA review |
| CLI, UX, MED (client parts) | Client |
| OPS, MED (storage) | DevOps/Release |

## 4. P1 traceability matrix (84 IDs; lifecycle: all `Specified`)

Ref: **O** = OFFICIAL, **O~** = OFFICIAL (partial), **N** = REM-native (no Telegram reference), **U** = UNKNOWN. Verification names the planned decisive test(s) and tier. The XC criteria apply to every row.

| ID | Packet | Depends on | Ports / contracts | Decisive verification (tier) | Ref |
|---|---|---|---|---|---|
| ID-001 | P1-03 | ENT-001 | IdentityStore (invites) | T2 concurrent invite redemption ≤ max_uses; T3 J1 onboarding | O |
| ID-002 | P1-03 | ID-001 | IdentityStore, PasswordHasher, RateLimiter | T2 login negatives and rate limit; T3 J1 | O~ |
| ID-003 | P1-03 | ID-002, SYN-001 | IdentityStore, Fanout | T2 revoke closes socket and later 401; time measured | O~ |
| ID-004 | P1-16 | ID-002, MED-002 | IdentityStore, BlobStore | T1 name normalization; T2 profile event propagation | O~ |
| ID-005 | P1-09 | ENT-001 | IdentityStore | T2 deactivate revokes all sessions | U |
| ID-006 | P1-16 | ID-005, ENT-002 | IdentityStore, AuditSink | T2 deletion tombstones author, export authorization | O~ |
| DM-001 | P1-08 | SYN-004 | ConversationLog; contracts §1 entities | T1 entity validation (UTF-16); T3 XSS fixtures inert | O |
| DM-002 | P1-06 | SYN-004, SYN-007 | LocalStore, Transport | T2 lost-ACK retry same message_id; T3 J3 reload while pending | O~ |
| DM-003 | P1-08 | DM-001, SYN-005 | ConversationLog (revisions) | T1 revision rules; T2 `revision_conflict`; edit retry no extra revision | O~ |
| DM-004 | P1-08 | DM-001, ORG-004 | ConversationLog, SearchIndex | T2 tombstone removes from index and views; window policy | O~ |
| DM-005 | P1-08 | DM-001, MED-010 | ConversationLog, BlobStore refs | T2 forward needs source read and target post | O |
| DM-006 | P1-08 | DM-001, GRP-003 | ConversationLog | T2 pin rights; self-conversation idempotent | O |
| DM-008 | P1-10 | SYN-011 | Presence | T1 expiry 6 s; T2 rate cap, non-member gets nothing | O~ |
| DM-009 | P1-10 | SYN-010 | user stream, EventReader | T1 unread computation; T2 two-device convergence | O~ |
| DM-012 | P1-08 | DM-001 | ConversationLog; SEC-010 | T1 mention entity; T2 preview off by default | O~ |
| GRP-001 | P1-09 | SYN-003 | ConversationLog | T2 create/update/delete events; owner invariant | O~ |
| GRP-002 | P1-09 | GRP-001 | ConversationLog, IdentityStore | T2 link expiry, use limit, revoke immediate | O |
| GRP-003 | P1-09 | GRP-001 | ConversationLog; authz matrix | T2 per-right negative matrix | O |
| GRP-004 | P1-09 | GRP-003 | ConversationLog, AuditSink | T2 single owner; transfer re-auth; break-glass audited | O |
| GRP-005 | P1-09 | GRP-003, SYN-009 | ConversationLog | T2 ban blocks rejoin; timeout uses server time | O~ |
| GRP-006 | P1-09 | GRP-002 | ConversationLog | T2 approve idempotent; expiry | O |
| GRP-007 | P1-09 | GRP-001 | ConversationLog | T2 history visibility applied to new member | O~ |
| GRP-008 | P1-09 | NTF-001 | user stream (prefs) | T1 notify-level rules incl. mention-only | O~ |
| SYN-001 | P1-04 | ID-002 | Transport, ws ticket | T2 ticket single-use; reconnect then catch-up before push | N |
| SYN-002 | P1-01 | — | IdempotencyRecord | T1 property: replay → same result; conflicting payload | N |
| SYN-003 | P1-01 | — | ConversationLog | T1 model plus T2 N concurrent writers → 1..N (PT-02) | N |
| SYN-004 | P1-02 | SYN-002, SYN-003 | ConversationLog, OutboxSource | T2 crash before/after commit; dispatcher crash | N |
| SYN-005 | P1-06 | SYN-004 | rem-client-core reducer | T1 property duplicate/reorder/drop, native and wasm32 | N |
| SYN-006 | P1-05 | SYN-004 | EventReader | T2 model-based projection equality after catch-up | N |
| SYN-007 | P1-06 | SYN-002 | LocalStore | T2 restart with queue; FIFO; expired op not retried | N |
| SYN-008 | P1-05 | SYN-006 | EventReader, LocalStore | T2 gap fetch; `cursor_expired` reset keeps pending | N |
| SYN-009 | P1-05 | GRP-005 | EventReader | T2 forged cursor after removal → nothing; send racing removal | N |
| SYN-010 | P1-10 | SYN-006 | user stream | T1 monotonic max; T2 two devices converge | N |
| SYN-011 | P1-10 | SYN-001 | Presence (in-process, ADR-0011) | T2 bounded fanout; TTL | O~ |
| SYN-013 | P1-04 | — | contracts §1; fixtures v1 | T2 golden fixtures current and previous; `upgrade_required` | N |
| SYN-014 | P1-06 | SYN-005, SYN-007 | Clock, fault transport | T2 ±24 h skew and dup/reorder/drop simulation; T5 soak | N |
| MED-001 | P1-11 | DM-001 | BlobStore | T2 only finalized, owned attachments referenced | O |
| MED-002 | P1-11 | MED-001 | BlobStore, MalwareScanner | T2 magic-byte mismatch rejected; quota | O |
| MED-010 | P1-11 | MED-001, SYN-009 | BlobStore (signed GET) | T2 removed member denied new URL; TTL ≤ 5 min | O~ |
| ORG-001 | P1-10 | SYN-010 | user stream (prefs) | T2 pin order syncs | O~ |
| ORG-002 | P1-10 | ORG-001 | user stream (prefs) | T2 archive/mute sync; unarchive rule | O~ |
| ORG-004 | P1-12 | DM-001, SYN-009 | SearchIndex | T2 non-member probe → nothing; delete leaves index | O |
| NTF-001 | P1-10 | DM-009 | user stream | T2 badge equality across devices | O~ |
| SEC-001 | P1-15 | OPS-001 | proxy config | T5 TLS config scan; release checklist | N |
| SEC-002 | P1-03 | ID-002 | IdentityStore; ADR-0010 | T2 token hashing, CSRF, rotation | N |
| SEC-003 | P1-05 | all endpoints | authz in use cases | T2 per-endpoint negative suite (generated from contracts) | N |
| SEC-004 | P1-05 | ENT-001 | all pg queries | T2 cross-conversation isolation | N |
| SEC-006 | P1-15 | OPS-011 | config loader | T0 secret scan; T2 startup refuses defaults | N |
| SEC-009 | P1-15 | SYN-001 | RateLimiter | T2 429 with retry_after per action | N |
| SEC-010 | P1-11 | MED-002 | BlobStore, (preview fetcher off) | T2 active types never inline; SSRF suite if enabled | N |
| SEC-013 | P1-15 | OPS-008 | CI audit jobs | T0/T5 audit and deny jobs observed | N |
| UX-001 | P1-07 | CLI-001 | ux.md §1 | T3 visual at 3 viewports | N |
| UX-003 | P1-07 | CLI-001 | tokens | T0 contrast check; T3 visual both themes | N |
| UX-005 | P1-07 | CLI-001 | ux.md §4 | T3 a11y scan zero serious; manual SR pass before release | O |
| UX-006 | P1-07 | CLI-001 | virtual list | T3 10k-message scroll budget (measured) | N |
| UX-007 | P1-07 | CLI-011 | ux.md §2 | T3 component states per screen | N |
| UX-008 | P1-11 | MED-002 | composer | T3 drag/paste preview | N |
| UX-009 | P1-07 | DM-003..006 | context menu | T3 keyboard-only actions | N |
| UX-012 | P1-13 | CLI-008 | routes (ux.md §1) | T3 unauthorized deep link → "not available" | O |
| ENT-001 | P1-03 | OPS-001 | IdentityStore | T2 bootstrap idempotent, disabled after use | N |
| ENT-002 | P1-09 | ENT-001 | IdentityStore, policy | T2 admin actions; policy set | N |
| ENT-006 | P1-09 | ENT-002 | policy evaluator, AuditSink | T2 policy versioned and audited | N |
| ENT-007 | P1-14 | OPS-006 | backup tooling | T5 restore rehearsal | N |
| ENT-010 | P1-14 | OPS-004 | admin overview, bundle | T2 bundle has no content or secrets (scan) | N |
| ENT-012 | P1-09 | ENT-002 | AuditSink | T2 dual approval when enabled | N |
| CLI-001 | P1-07 | CLI-003, PT-01 | ADR-0002/0003 binding | T3 journey J3+J5 on 3 engines | N |
| CLI-002 | P1-13 | CLI-001 | ADR-0007 | T4 desktop smoke per OS | N |
| CLI-003 | P1-06 | SYN-005 | rem-client-core | T2 same tests on native and wasm32 | N |
| CLI-004 | P1-06 | CLI-003 | LocalStore (SQLite; browser per ADR-0003) | T2 migration failure → reset keeps pending | N |
| CLI-008 | P1-13 | CLI-002 | updater config | T4 signed update verify; disabled mode | N |
| CLI-009 | P1-04 | SYN-013 | version headers | T2 below-min client → upgrade screen state | N |
| CLI-010 | P1-17 | CLI-001, CLI-002 | matrix doc | T5 matrix run recorded | N |
| CLI-011 | P1-07 | SYN-007, SYN-008 | ux.md §2 | T3 offline, failed, conflict and reset states | N |
| OPS-001 | P1-14 | — | compose bundle | T5 clean-host install under podman and docker | N |
| OPS-002 | P1-02 | — | migrations | T2 migrate from previous release with data | N |
| OPS-003 | P1-14 | MED-001 | BlobStore, backup | T5 object restore checksums | N |
| OPS-004 | P1-14 | — | /healthz /readyz /metrics | T2 readiness reflects dependency loss | N |
| OPS-005 | P1-14 | — | logging | T2 log-scan redaction test | N |
| OPS-006 | P1-14 | ENT-007 | backup tooling | T5 backup → restore → consistency | N |
| OPS-007 | P1-14 | OPS-002 | release process | T5 upgrade rehearsal N-1→N with data | N |
| OPS-008 | P1-00 | PO-Q2 | CI workflows | P0-PT-03 cases C1–C5 observed; T5 signing and SBOM | N |
| OPS-009 | P1-17 | OPS-001 | load harness | T5 declared workload on recorded hardware | N |
| OPS-011 | P1-14 | — | config, proxy | T2 startup validation; offline TLS | N |
| OPS-013 | P1-14 | OPS-001..007 | runbooks | review: runbook dry run recorded | N |

Count check: the 84 rows above are exactly the P1 IDs in the registry. `scripts/check_docs.py` enforces this, and its result is recorded in [evidence E-08](evidence.md#e-08-docs-check).
