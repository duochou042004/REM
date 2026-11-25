# REM — Backlog, work packets and P1 traceability

**Owner:** Lead (the only writer of assignments) · **Revision:** r1, 2026-11-24 · **Phase:** P0. Implementation is **not authorized** ([p0-gate.md](p0-gate.md)). The chain is FEATURE → REQUIREMENT ([requirements.md](../product/requirements.md#5-p1-acceptance-criteria)) → DESIGN (ports and contracts below) → CODE → TEST → EVIDENCE ([evidence.md](evidence.md)). CODE and TEST links are added when packets land.

Packet contract ([AGENT_HARNESS §3](../../AGENT_HARNESS.md#3-task-packets-and-iterative-work)): every packet row names its IDs, owner, dependencies, scope, acceptance and verification budget. Each packet's detail is written when it becomes `READY`.

## 1. P0 packets

| Packet | Goal | Owner | Depends | Status | Acceptance / evidence | Dispatch note |
|---|---|---|---|---|---|---|
| P0-INIT-01 | Planning baseline: index, requirements, architecture, security, CI design, backlog, gate, handoff | Lead | — | DONE (r1) | [evidence E-01..E-10](evidence.md) | solo lead plus 2 research helpers plus 1 independent reviewer (parallel research, critical review) |
| P0-RES-01 | Telegram reference for the 33 P1 IDs with user-visible behavior | Research | — | DONE (Discovered) | [reference-behavior.md](../product/reference-behavior.md) | 1 helper, parallel with architecture writing |
| P0-REV-01 | Independent review: sync invariants, revocation, threat model, gate claims; rework round 1 plus adversarial verification | Independent QA, then file owners | P0-INIT-01 | DONE (14/16 resolved; residuals become P0-REV-02) | [evidence E-09](evidence.md#e-09-independent-review), [E-09b](evidence.md#e-09b-review-rework-and-adversarial-verification) | separate reviewer; workflow LD-15 |
| P0-REV-02 | Review round 2: resolve the 10 MAJOR and the MINOR rows in [E-09b](evidence.md#e-09b-review-rework-and-adversarial-verification) across sync, contracts, threat-model, requirements and testing-ci, then verify on fresh contexts | Lead (arbiter) plus file owners | P0-REV-01 | DONE (38/38 resolved and verified; gate items 3–6 PASS, 7 PENDING) | [E-09c](evidence.md#e-09c-final-verification-of-p0-rev-02): every R2 row resolved with its file and section, no BLOCKING or MAJOR residual; `check_docs.py` OK | rounds 1–3 as LD-32; final check under LD-39 (1 verifier, 1 critic, lead fixes LD-40, 1 targeted re-check) |
| **P0-PT-03** | **CI selection spike:** classifier plus aggregate verdict on a throwaway fixture workspace; observe cases C1–C5 | DevOps | P0-INIT-01 | **READY (next)** | [testing-ci §6](../engineering/testing-ci.md#6-p0-acceptance-cases-for-ci-selection-synthetic-walkthrough--not-an-observed-execution) rows observed with exit codes; artifact-expiry column stays pending until a CI host exists | solo: one shared contract |
| P0-SEC-01 | Map P1 controls to ASVS 5.0 requirement IDs from the official OWASP release | Security | P0-INIT-01 | READY | a mapping table in threat-model §7; every P1 SEC criterion maps or is justified | solo or 1 helper |
| P0-PT-01 | Browser persistence plus WASM binding spike (ADR-0002 sub-decisions, ADR-0003): cold reload, queued send, reconnect, lost ACK on 3 engines; bundle and load cost; storage cleared | Client | PO-Q1 | BLOCKED (tools) | ADR-0003 decided with measured results | 1 helper possible alongside PT-02 (disjoint paths) |
| P0-PT-02 | PostgreSQL sequencing, outbox and durable ACK spike (ADR-0004/0005): concurrent writers, crash before or after commit, duplicates, send racing a removal, a send and a duplicate racing a session revocation, two admins revoking each other's sessions (global lock order, no deadlock), throughput per hot conversation, large-group membership transaction cost, bytes per message | Architecture | PO-Q1 | BLOCKED (image pull) | ADR-0005 accepted or revised with measurements | parallel with PT-01 |
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
| P1-03 | Bootstrap, invites, login, sessions, revocation (ENT-001, ID-001, ID-002.a–c, ID-003.a–c, e, SEC-002) | P1-02 | `IdentityStore`, `PasswordHasher`, ADR-0010 |
| P1-04 | Protocol v1, HTTP/WS adapters, golden fixtures, version negotiation (SYN-001, SYN-013, CLI-009) | P1-02, P1-03 | [contracts.md](../architecture/contracts.md) |
| P1-05 | Catch-up, gaps, snapshot reset, history authorization, isolation (SYN-006, 008, 009, SEC-003, 004) | P1-04 | `EventReader` |
| P1-06 | Client core plus native store: reducer, outbox, sync state machine, fault harness (CLI-003, CLI-004, SYN-005, 007, 014, DM-002) | P1-04 | `LocalStore`, `Transport`, `Clock` |
| P1-07 | Web app on the WASM SDK: shell, IA, states, a11y, themes, virtualization (CLI-001, CLI-011, UX-001, 003, 005, 006, 007, 009) | P1-05, P1-06, PT-01 | ADR-0002/0003, [ux.md](../product/ux.md) |
| P1-08 | Message lifecycle: text and entities, reply, edit, delete, forward, pin, mentions (DM-001, 003..006, 012) | P1-05, P1-06 | `ConversationLog` events |
| P1-09 | Groups, roles, rights, links, join requests, org admin roles, the rank rule and admin recovery (GRP-001..008, ID-002.d/e, ID-003.d, ID-005, ENT-002, 006, 012). PO-Q9 must be answered before acceptance | P1-05 | `ConversationLog`, `IdentityStore`, `AuditSink` |
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
| ID-001 | P1-03 | ENT-001 | IdentityStore (invites) | T2 concurrent invite redemption ≤ max_uses; two concurrent bootstraps under different `operation_id`s create one org, and the other gets `invite_invalid`; admin creation (`POST /v1/admin/users`, [contracts §2.1](../architecture/contracts.md#21-idempotent-mutations-and-operation-lookup)) creates the account with its one self conversation, and a replay creates no second account; the created account cannot log in until its onboarding token is redeemed, a replay returns no token, a re-issued token invalidates the earlier one, and `onboarding_token` is refused once the account has set a password; an org invite always creates a member: a create-invite request carrying `org_role` mints no admin, and org admin comes only from the Grant org admin action (ENT-012); T3 J1 onboarding | O |
| ID-002 | P1-03 (a–c); P1-09 (d, e) | ID-001; d, e: ENT-002, ENT-012 | IdentityStore, PasswordHasher, RateLimiter; d, e: AuditSink | T2 login negatives and rate limit; logout deletes the local store after the unsent-ops warning; a re-login with the stored `device_id` keeps that id and revokes that device's previous session (`replaced`), and an unknown or retired id gets a new device with no error; two concurrent logins for one device leave one live session, also when the device had no live session before them; a store without a bound `device_id` sends its persisted `device_nonce`, so a lost first-login response followed by a retry binds the retry to the same device and revokes the first session (`replaced`), leaving no orphan device, while eviction recovery starts a new store with a new nonce ([sync §5.4](../architecture/sync.md#54-store-identity-and-browser-storage)); a login racing a password change, or (d) a reset redemption, leaves no live session that the change or reset did not revoke. d, e ([threat-model §4.2](../security/threat-model.md#42-admin-recovery-powers-po-q9)): with SMTP the link goes only to the registered email, without SMTP to the admin (dual approval: ENT-012); every reset revokes all sessions with reason `password_reset`, which another device sees on its next request, is audited and sets the login `notice`; a reset of an account of equal or higher org rank is denied; T3 J1 | O~ |
| ID-003 | P1-03 (a–c, e); P1-09 (d) | ID-002, SYN-001; d: ENT-002 | IdentityStore, Fanout | T2 revoke closes socket and later 401; time measured; the `session_revoked` detail carries its `reason`; the revoked client keeps its unsent ops dormant and sends them after the same user signs in again, and a lost-ACK op deduplicates across that re-login; d: an admin revoke on an account of equal or higher org rank is denied (rank rule, [threat-model §4.1](../security/threat-model.md#41-rank-direct-chats-and-ownership-continuity)) | O~ |
| ID-004 | P1-16 | ID-002, MED-002 | IdentityStore, BlobStore | T1 name normalization; T2 profile event propagation | O~ |
| ID-005 | P1-09 | ENT-001 | IdentityStore | T2 deactivate revokes all sessions (reason `deactivated`), and a login racing the deactivation leaves no live session; deactivation (ENT-002.b) is denied on an account of equal or higher org rank ([threat-model §4.1](../security/threat-model.md#41-rank-direct-chats-and-ownership-continuity)); deactivating a sole group owner starts the succession tested under GRP-004 | U |
| ID-006 | P1-16 | ID-005, ENT-002 | IdentityStore, AuditSink | T2 deletion tombstones author, export authorization; a deletion request (`POST /v1/me/deletion-request`) and its admin approval each get a duplicate and a conflict test ([contracts §2.1](../architecture/contracts.md#21-idempotent-mutations-and-operation-lookup), SYN-002); deactivation, reactivation and deletion approval (ID-006.a) are denied on an account of equal or higher org rank ([threat-model §4.1](../security/threat-model.md#41-rank-direct-chats-and-ownership-continuity)); `admin.user_update` with `status: deleted` is rejected, so deletion happens only through an approved deletion request, and a deleted account cannot be reactivated | O~ |
| DM-001 | P1-08 | SYN-004 | ConversationLog; contracts §1 entities | T1 entity validation (UTF-16); T2 one DM per pair: two members opening the same DM at once get one conversation, and a reopen returns it with `created: false`; one self conversation per user, created with the account; T3 XSS fixtures inert | O |
| DM-002 | P1-06 | SYN-004, SYN-007 | LocalStore, Transport | T2 lost-ACK retry same message_id; T3 J3 reload while pending | O~ |
| DM-003 | P1-08 | DM-001, SYN-005 | ConversationLog (revisions) | T1 revision rules; T2 `revision_conflict`; edit retry no extra revision | O~ |
| DM-004 | P1-08 | DM-001, ORG-004 | ConversationLog, SearchIndex | T2 tombstone removes from index and views; window policy | O~ |
| DM-005 | P1-08 | DM-001, MED-010 | ConversationLog, BlobStore refs | T2 forward needs source read and target post; a forward whose source is invisible to the reader keeps the body and `forwarded_from.author_id`, with the source ids `{unavailable: true}`; with attribution hidden by policy (DM-005.d), no `author_id` | O |
| DM-006 | P1-08 | DM-001, GRP-003 | ConversationLog | T2 pin rights; the self conversation exists from account creation, one per user, and forwards into it are idempotent (`message.forward` row) | O |
| DM-008 | P1-10 | SYN-011 | Presence | T1 expiry 6 s; T2 rate cap, non-member gets nothing | O~ |
| DM-009 | P1-10 | SYN-010 | user stream, EventReader | T1 unread computation; T2 two-device convergence | O~ |
| DM-012 | P1-08 | DM-001 | ConversationLog; SEC-010 | T1 mention entity; T2 preview off by default | O~ |
| GRP-001 | P1-09 | SYN-003 | ConversationLog | T2 create/update/delete events; owner invariant | O~ |
| GRP-002 | P1-09 | GRP-001 | ConversationLog, IdentityStore | T2 link expiry, use limit, revoke immediate; `GET …/links` returns the token only to holders of the link right (decrypted copy); lookup by keyed hash; link events reach others as redacted stubs; link-key rotation re-encrypts the stored copies | O |
| GRP-003 | P1-09 | GRP-001 | ConversationLog; authz matrix | T2 per-right negative matrix | O |
| GRP-004 | P1-09 | GRP-003 | ConversationLog, AuditSink | T2 single owner; transfer re-auth; break-glass ([threat-model §4.2](../security/threat-model.md#42-admin-recovery-powers-po-q9)): audited, the new owner is an existing current member, no read access granted, denied on a GO of equal or higher org rank, self-assignment denied without dual approval, and with dual approval on it waits for a different admin (ENT-012); while that approval is pending, the GO is promoted, transferred or deactivated, or the new owner leaves, and approve is then denied; sole-owner succession: the longest-tenured admin, else the longest-tenured member, else the group is archived and org admins are notified | O |
| GRP-005 | P1-09 | GRP-003, SYN-009 | ConversationLog | T2 ban blocks rejoin; timeout uses server time | O~ |
| GRP-006 | P1-09 | GRP-002 | ConversationLog | T2 approve idempotent; expiry | O |
| GRP-007 | P1-09 | GRP-001 | ConversationLog | T2 history visibility applied to new member; a `full`→`from_join` (and `from_join`→`full`) change leaves existing members' and former members' `visible_ranges` unchanged, and a later join or rejoin records the new setting in its interval | O~ |
| GRP-008 | P1-09 | NTF-001 | user stream (prefs) | T1 notify-level rules incl. mention-only | O~ |
| SYN-001 | P1-04 | ID-002 | Transport, ws ticket | T2 ticket single-use; reconnect then catch-up before push | N |
| SYN-002 | P1-01 | — | IdempotencyRecord | T1 property: replay → same result; conflicting payload; the canonical hash is equal across field normalization (NFC display name), id-list order and omitted defaults, while message bodies that differ only in Unicode normalization conflict; T2, as each kind lands: a duplicate and a conflict test for every idempotent row of the [contracts §2.1](../architecture/contracts.md#21-idempotent-mutations-and-operation-lookup) table (pre-session rows: a replay returns `duplicate: true` and no session, and the same id with another token is a new command); a route check fails when a mutating endpoint is missing from that table | N |
| SYN-003 | P1-01 | — | ConversationLog | T1 model plus T2 N concurrent writers → 1..N (PT-02) | N |
| SYN-004 | P1-02 | SYN-002, SYN-003 | ConversationLog, OutboxSource | T2 crash before/after commit; dispatcher crash | N |
| SYN-005 | P1-06 | SYN-004 | rem-client-core reducer | T1 property duplicate/reorder/drop, native and wasm32 | N |
| SYN-006 | P1-05 | SYN-004 | EventReader | T2 model-based projection equality after catch-up; final head ([sync §4](../architecture/sync.md#4-catch-up-and-realtime)): listed with `last_seq: left_seq − 1` and `left: true` while `user_cursor` is below the `user_seq` of the leave's `user.membership_changed`, one final head per conversation when several are left, and after a leave, a rejoin and a second leave only the latest leave's head; the client persists `local_user_seq` past a leave only after it has caught that conversation up to `left_seq − 1` or durably marked it owed; an owed catch-up of a conversation deleted after the leave gets `not_found`, clears the owed mark and marks the conversation deleted; absent once the cursor is at or past that event, and for a conversation never joined | N |
| SYN-007 | P1-06 | SYN-002 | LocalStore | T2 restart with queue; FIFO; expired op not retried; dependents ([sync §5.2](../architecture/sync.md#52-dependent-operations)): a cross-queue wait with the id rewrite, a folded edit and delete, and each cascade (from a stuck, an expired, a failed and a discarded source, and from a folded delete), after which the queue continues; a dependent created after its source already left `pending` without an ACK (an edit, reply or forward of a failed bubble) never holds its FIFO position longer than its source's stuck bound; a user retry re-enters at the FIFO tail with its dependents after it; a user retry of a stuck op whose last attempt committed with a lost ACK deduplicates; the stuck bound by N and by T (server time from the first failed attempt); a user switch leaves the first user's ops dormant, never drained under the other user; eviction recovery revokes the session, reports the loss, logs in without `device_id` and retires the old device (`device_lost`) | N |
| SYN-008 | P1-05 | SYN-006 | EventReader, LocalStore | T2 gap fetch; `cursor_expired` reset keeps pending, for a conversation and for the user stream; after pruning removes every retained event of a conversation or of a user, a cursor from before those events still gets `cursor_expired`, never an empty page; user-state reset: a cached conversation missing from the list gives a former member the capped state, and a deleted one gets `not_found` and is marked deleted; a leave committed during list paging is applied after the reset; reset convergence: after an edit and a delete for everyone in the pruned window, no cached row shows the old body, and a history page drops a cached row in its span that it omits; a history page read at `as_of_seq` S and applied after a pushed edit and a delete for everyone at S+1 leaves the cached row at the newer revision and the tombstone; the reset rebuilds the roster from `GET …/members` and sets `covered_through` to the state's `last_seq`; history page shape ([contracts §2](../architecture/contracts.md#2-http-surface-p1-v1)): exclusive `before`, newest first, current revisions, tombstones, hidden-for-self omitted, `next_before` null at the start; a rejoin under `full` lowers `covered_through` and fetches the absent span | N |
| SYN-009 | P1-05 | GRP-005 | EventReader | T2 forged cursor after removal → nothing; send racing removal; read endpoints ([threat-model §4](../security/threat-model.md#4-authorization-matrix-p1)): a former member's state, event and history pages show nothing at or after `left_seq`, an event page past it is empty with `last_seq` and `covered_to` at `left_seq − 1` so paging ends, the roster and links return `not_found`, and search returns no hit at or after `left_seq` and none outside `visible_ranges`, and a word added by an edit after the removal finds nothing while the pre-removal wording still matches (ORG-004.b); the content is as of `left_seq − 1` ([sync §6.1](../architecture/sync.md#61-visible-ranges)): an edit committed after the removal is never shown, a pin or setting change after it is not shown, and a delete for everyone after it shows only a tombstone with no deletion time, on event pages too (its `message.created` carries `{message_id, deleted: true}`); a non-member gets `not_found` from every read endpoint; a member without the link right is denied links; under `from_join` a history page returns nothing before `joined_seq`, a pre-join pin arrives as a stub and a pre-join reply quote renders as unavailable; paging a multi-interval reader (a `from_join` rejoin) ends with `next_before` null and returns no message outside `visible_ranges`; push ([sync §3.3](../architecture/sync.md#33-push-path-ordered-dispatch-and-fanout-authorization)): after a removal at r, the event at r+1 is not pushed to the removed member; a removal or revocation with an unknown commit outcome stays denied until the rebuild, which sends a `head` frame to each still-authorized session; a member add racing a removal, and a rebuild racing an in-flight removal, never re-admit the removed member | N |
| SYN-010 | P1-10 | SYN-006 | user stream | T1 monotonic max; T2 two devices converge | N |
| SYN-011 | P1-10 | SYN-001 | Presence (in-process, ADR-0011) | T2 bounded fanout; TTL | O~ |
| SYN-013 | P1-04 | — | contracts §1; fixtures v1 | T2 golden fixtures current and previous; `upgrade_required` | N |
| SYN-014 | P1-06 | SYN-005, SYN-007 | Clock, fault transport | T2 ±24 h skew and dup/reorder/drop simulation; device clock changed while offline, with no automatic retry past the cut-off ([sync §5.3](../architecture/sync.md#53-expiry-and-stuck-operations)); T5 soak | N |
| MED-001 | P1-11 | DM-001 | BlobStore | T2 only finalized, owned attachments referenced | O |
| MED-002 | P1-11 | MED-001 | BlobStore, MalwareScanner | T2 magic-byte mismatch rejected; quota | O |
| MED-010 | P1-11 | MED-001, SYN-009 | BlobStore (signed GET) | T2 removed member denied new URL, also for a message from before the removal; TTL ≤ 5 min; under `from_join` a pre-join attachment is denied | O~ |
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
| ENT-002 | P1-09 | ENT-001 | IdentityStore, policy | T2 admin actions; policy set; rank negatives per [threat-model §4.1](../security/threat-model.md#41-rank-direct-chats-and-ownership-continuity) (see ID-005) | N |
| ENT-006 | P1-09 | ENT-002 | policy evaluator, AuditSink | T2 policy versioned and audited; `PATCH /v1/admin/policies` gets a duplicate and a conflict test ([contracts §2.1](../architecture/contracts.md#21-idempotent-mutations-and-operation-lookup), SYN-002); turning `require_dual_approval` off while it is on waits for approval by a different admin (ENT-012) | N |
| ENT-007 | P1-14 | OPS-006 | backup tooling | T5 restore rehearsal | N |
| ENT-010 | P1-14 | OPS-004 | admin overview, bundle | T2 bundle has no content or secrets (scan) | N |
| ENT-012 | P1-09 | ENT-002 | AuditSink | T2 with `require_dual_approval` on, granting org admin, an admin-delivered reset link, a break-glass reassignment and turning `require_dual_approval` off each wait for approval by a different admin, and an approval by the actor or the target is denied; a break-glass approval is denied when, while it was pending, the GO was promoted, transferred or deactivated or the new owner left; a decline leaves no effect; each request and decision is audited; with it off, the first three apply at once | N |
| CLI-001 | P1-07 | CLI-003, PT-01 | ADR-0002/0003 binding | T3 journey J3+J5 on 3 engines | N |
| CLI-002 | P1-13 | CLI-001 | ADR-0007 | T4 desktop smoke per OS | N |
| CLI-003 | P1-06 | SYN-005 | rem-client-core | T2 same tests on native and wasm32 | N |
| CLI-004 | P1-06 | CLI-003 | LocalStore (SQLite; browser per ADR-0003) | T2 migration failure → reset keeps pending | N |
| CLI-008 | P1-13 | CLI-002 | updater config | T4 signed update verify; disabled mode | N |
| CLI-009 | P1-04 | SYN-013 | version headers | T2 below-min client → upgrade screen state | N |
| CLI-010 | P1-17 | CLI-001, CLI-002 | matrix doc | T5 matrix run recorded | N |
| CLI-011 | P1-07 | SYN-007, SYN-008 | ux.md §2 | T3 offline, failed, `failed(stuck)`, expired (needs confirmation), conflict, reset and "Message unavailable" states ([ux.md §2](../product/ux.md#2-state-model-shown-to-users)) | N |
| OPS-001 | P1-14 | — | compose bundle | T5 clean-host install under podman and docker | N |
| OPS-002 | P1-02 | — | migrations | T2 migrate from previous release with data | N |
| OPS-003 | P1-14 | MED-001 | BlobStore, backup | T5 object restore checksums | N |
| OPS-004 | P1-14 | — | /healthz /readyz /metrics | T2 readiness reflects dependency loss | N |
| OPS-005 | P1-14 | — | logging | T2 log-scan redaction test | N |
| OPS-006 | P1-14 | ENT-007 | backup tooling | T5 backup → restore → consistency | N |
| OPS-007 | P1-14 | OPS-002 | release process | T5 upgrade rehearsal N-1→N with data | N |
| OPS-008 | P1-00 | PO-Q2 | CI workflows | P0-PT-03 cases C1–C5 observed; C6 and branch protection on the host; T5 signing and SBOM | N |
| OPS-009 | P1-17 | OPS-001 | load harness | T5 declared workload on recorded hardware | N |
| OPS-011 | P1-14 | — | config, proxy | T2 startup validation; offline TLS | N |
| OPS-013 | P1-14 | OPS-001..007 | runbooks | review: runbook dry run recorded | N |

Count check: the 84 rows above are exactly the P1 IDs in the registry. `scripts/check_docs.py` enforces this, and its result is recorded in [evidence E-08](evidence.md#e-08-docs-check).
