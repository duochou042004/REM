# REM — Threat model and authorization matrix (P1)

**Owner:** Security · **Status:** Specified (P0 r1, 2026-11-24). An independent review is required before `Reviewed` ([evidence.md](../plan/evidence.md)). **Inputs:** [PROJECT_SPEC §4.2](../../PROJECT_SPEC.md#42-security-architecture), OWASP ASVS as the requirement source (version 5.0 per the PDF discovery notes; chapter mapping is pending, see §7), [sync.md](../architecture/sync.md). This document does not claim compliance or certification.

## 1. Assets

Message bodies and attachments (confidential), membership and conversation metadata (confidential), credentials, session tokens, invite and invite-link tokens, password-reset links and the bootstrap token (secret), signing keys, the token pepper and the link-token encryption key (secret), audit log (integrity-critical), backups and export archives (confidential, at full scope), local device stores, dormant ones included (confidential, held by the user, T20).

## 2. Trust boundaries

| # | Boundary | Crossing | Primary controls |
|---|---|---|---|
| B1 | Internet or LAN → reverse proxy | HTTPS/WSS | TLS (SEC-001), rate limits (SEC-009), request size caps |
| B2 | Proxy → `rem-server` | HTTP, auth headers or cookies | authentication in the driving adapter, CSRF for the cookie session, origin checks on WS |
| B3 | `rem-server` → PostgreSQL | SQL | least-privilege DB role; TLS or a private network; parameterized queries (SQLx) |
| B4 | `rem-server` → object store | S3 API | per-instance bucket and credentials; private bucket; presigned URLs with short TTL |
| B5 | Browser or desktop ↔ local store | OS or browser storage | per-origin isolation; an explicit logout deletes that user's local store (ID-002.b); a session that ends without a logout leaves the store dormant (T20, PO-Q10); no secrets in IndexedDB beyond the session (cookie is HttpOnly) |
| B6 | WASM binding ↔ React UI | JS calls | the UI is untrusted for authorization; all checks are on the server; the binding validates inputs |
| B7 | Operator ↔ host | shell, compose, secrets | operator is outside the app RBAC; secrets come from files or env; support bundles are redacted |
| B8 | Outbound fetch (previews, scanners) | HTTP egress | off by default (DEV-05); SSRF controls when enabled |

## 3. Threats and mitigations (STRIDE, messaging-specific)

| ID | Threat | Mitigation | Verified by |
|---|---|---|---|
| T1 | IDOR/BOLA: read another conversation, message, attachment or session by ID | Membership check in every use case; `not_found` for non-members; UUIDv7 IDs | SEC-003 negative suite |
| T2 | Removed member reads new messages by guessing a cursor | Membership intervals enforced in `EventReader` (I4) | SYN-009 forged-cursor test |
| T3 | Revoked session keeps acting through an open WebSocket | Revocation closes sockets; every command re-checks the session in its transaction | ID-003 test with timing measurement |
| T4 | Replay or duplication of commands | Idempotency records for every command the [contracts.md §2.1](../architecture/contracts.md#21-idempotent-mutations-and-operation-lookup) table marks idempotent (I2, XC-2); login, the self-service reset request, `ws-ticket` and `typing` are not idempotent, for the table's reasons; conflict on a canonical server-built command hash, never raw bytes | SYN-002 property test |
| T5 | Event tampering by a client | Clients never write events; the server derives events from validated commands | contract fixtures |
| T6 | Attachment URL leak | Short-TTL presigned URLs; no new URL through a conversation the user has left (MED-010.c), while access through a conversation where they are still a current member follows MED-010.a; disclosed TTL window | MED-010 tests |
| T7 | Malicious upload (polyglot, XSS via SVG/HTML, zip bomb) | Magic-byte check; deny inline rendering of active types; `Content-Disposition: attachment` and `nosniff`; size caps; no server-side decoding in P1; scanner port | MED-002 fixtures |
| T8 | XSS through message text or entities | Typed entities, no HTML rendering; CSP on the web app; React escaping; fixtures | DM-001 XSS fixtures |
| T9 | SSRF via URL previews | Off by default; allow-list, private-IP blocking, DNS rebinding guard, redirect re-validation, size and time caps when on | SEC-010 tests (when enabled) |
| T10 | Credential stuffing, brute force | Argon2id, per-account and per-IP rate limits, generic errors | ID-002 tests |
| T11 | Invite token brute force or reuse | ≥128-bit tokens; expiry, use limits, atomic redemption; one `invite_invalid` for every unknown, used, expired or revoked token. Org invite tokens are stored only as a keyed hash (HMAC with the token pepper) and shown once. An invite-link token is stored as that keyed hash for lookup, plus a copy encrypted with the separate link-token encryption key for the authorized re-read (GRP-002.e, T24, §5) | ID-001, GRP-002 tests |
| T12 | Realtime abuse (socket floods, typing spam) | Connection caps per user and IP, frame size caps, typing rate limits, bounded fanout queues | SEC-009, SYN-011 tests |
| T13 | Privilege escalation in groups | Server-side permission checks; rank rule and sole-owner succession (§4.1); owner invariant; audited role changes; dual approval option | GRP-003/004, ID-003, ID-005, ID-006, ENT-002, ENT-012 tests (rank negatives for each admin power, sole-owner succession order) |
| T14 | Sensitive data in logs or telemetry | Redaction by construction (typed log fields), a log-scan test | OPS-005 test |
| T15 | Secrets in images, repo or support bundles | Secret files and env only; CI secret scanning; redacted bundles | SEC-006, ENT-010 |
| T16 | Backup theft | Encrypted backups; key held separately; restore rehearsal | ENT-007, OPS-006 |
| T17 | Supply chain (crates, npm, actions, images) | Lockfiles with `--locked`; RustSec and npm audit; cargo-deny licenses and bans; actions pinned by SHA; image digests; SBOM | SEC-013, OPS-008 |
| T18 | Cross-org data mix in future multi-tenant use | `organization_id` scoping now; single-tenant deployment | SEC-004 tests |
| T19 | Operator or support overreach | Operator works outside the app; support bundle has no content; privileged admin actions audited | ENT-010 review |
| T20 | Local device compromise or shared browser | An explicit logout revokes the session, clears the credentials, warns when unsent ops exist and deletes that user's local store (ID-002.b). A revoked or expired session, or another user signing in without a logout, leaves the store dormant until the same user signs in again on that device (interim default, PO-Q10, [sync.md §5.4](../architecture/sync.md#54-store-identity-and-browser-storage)). **Residual, disclosed:** a dormant store stays readable to anyone using that browser profile or OS account. Session list and remote revoke; no E2EE claim (ADR-0009) | ID-002, ID-003 tests (logout deletes the store, switching users), UX copy review |
| T21 | An org admin takes over an account through an admin-initiated password reset | Reset rules in §4.2 and the rank rule in §4.1: email delivery over TLS when SMTP is configured, approval by a different admin for an admin-delivered link when dual approval is on (ENT-012.a), all sessions revoked with reason `password_reset`, audit record, user notified at next login and on their other devices. The residual power is disclosed (DEV-08, PO-Q9) | ID-002.d/e and ENT-012 tests (SMTP routing, sessions revoked with a reason, rank rule, dual approval, audit, login notice) |
| T22 | Break-glass ownership reassignment used to reach a group's content or to take a group from a peer or higher-ranked owner | Allowed only when the current GO's org rank is strictly lower than the actor's; a deactivated GO is handled by succession (§4.1), not break-glass; the new owner is an existing current member; the actor names themselves only with dual approval on and a different admin's approval; the admin gains no read access unless already a member; audited (§4.2) | GRP-004.c tests (peer or higher-ranked GO denied, self-assignment without dual approval denied, no read access) |
| T23 | The push path delivers an event to a removed member or a revoked session | `Fanout` authorizes each event per recipient: the recipient's current membership interval contains the event's seq and the session is not in the revocation set. On the single P1 node, a removal or revocation is applied to the in-memory authorization cache before `COMMIT` and never reverted blindly: on any commit error, an unknown outcome included, the affected entries stay denied until they are rebuilt from the database. An addition is applied only after a confirmed commit or by that rebuild. After a rebuild, `Fanout` sends a `head` frame to the still-authorized sessions that [sync.md §3.3](../architecture/sync.md#33-push-path-ordered-dispatch-and-fanout-authorization) names (for a session revocation, that user's conversations), so gap detection repairs a spurious denial. Dispatch is ordered per conversation. WS ticket redemption re-checks the session ([sync.md §3.3](../architecture/sync.md#33-push-path-ordered-dispatch-and-fanout-authorization)) | SYN-009.f push tests, including an unknown commit outcome |
| T24 | An invite-link token leaks to members who lack the link right | No event carries a token; `link.created` and `link.revoked` carry `link_id` and metadata only; the token goes only to its creator and to holders of the link right through an authorized read (`GET …/links`, §4), from a copy encrypted at rest (T11) ([contracts.md §3](../architecture/contracts.md#3-event-catalog-conversation-stream-unless-noted-all-schema_version-1)) | GRP-002.e tests |
| T25 | Metadata leaks through sync heads or scoped events (conversations left long ago, moderation activity, edits of messages the reader cannot see) | `conversation_heads` lists current memberships plus one final head (`last_seq: left_seq − 1`, `left: true`) per conversation whose leave event has a `user_seq` above the request's `user_cursor`; it reveals nothing after the leave, and the user-stream retention floor bounds the listing ([sync.md §4](../architecture/sync.md#4-catch-up-and-realtime)); link and join-request events reach other members as redacted stubs; events that reference a message follow that message's visibility | SYN-006.d (cursor below the leave event; negatives at or past it and never a member), SYN-009.e, GRP-006.d tests |
| T26 | Theft of the bootstrap token before or after first use | Shown only on the operator console or read from a secret file (B7); never logged; single use, and bootstrap is disabled once it commits; the first-admin creation is audited (ENT-001) | ENT-001 tests, OPS-005 log scan |
| T27 | Interception of a password-reset link (mailbox, admin channel, referrer, logs) | Single use, short expiry (*policy*), stored hashed, never logged; a newer reset or a password change invalidates it; redemption revokes all sessions (§4.2 says which transaction) and notifies the user, so a takeover is visible | ID-002.d tests |
| T28 | Export-archive leakage (ID-006) | Built asynchronously into the private bucket; served only to the requesting user's authenticated session through a short-TTL link; deleted after expiry; never in support bundles; creation and download audited | ID-006.c tests |
| T29 | An ACKed effect is lost in a database crash because the commit was not yet durable | `synchronous_commit=on` is pinned for the application role and checked at startup ([operations.md §1](../operations.md#1-deployment-shape-single-tenant-p1)); the durable ACK (I1) depends on it | OPS-011 startup configuration test |

## 4. Authorization matrix (P1)

Roles: **O** org owner, **A** org admin, **M** org member; inside a group: **GO** group owner, **GA** group admin (with the listed right), **GM** group member (default rights per GRP-003). **DM** is either participant of a direct chat, and **Self** is the owner of their Saved messages conversation (DM-006). **Op** is the operator (host access, no in-app role). ✓ allowed, ✗ denied, *r* allowed when the right or policy grants it, — not applicable.

| Action | O | A | M | GO | GA | GM | DM | Self | Op |
|---|---|---|---|---|---|---|---|---|---|
| Bootstrap org | — | — | — | — | — | — | — | — | ✓ (one-time token) |
| Invite or create users (`POST /v1/invites`, `POST /v1/admin/users`); the new account is always an org member (§4.1) | ✓ | ✓ | ✗ | | | | | | ✗ |
| Deactivate or reactivate an account, approve its deletion, reset its password | ✓ | ✓ (lower rank; reset per §4.2) | ✗ | | | | | | ✗ |
| Grant org admin (`PATCH /v1/admin/users/{id}` with `org_role`, the only way to make an org admin) | ✓ | *r* (dual approval if on) | ✗ | | | | | | ✗ |
| Request own account deletion (`POST /v1/me/deletion-request`; approval per the row above) | ✓ | ✓ | ✓ | | | | | | |
| Change org policies (`PATCH /v1/admin/policies`, ENT-002.c, ENT-006.a; audited) | ✓ | ✓ (turning `require_dual_approval` off while it is on needs dual approval, §4.2) | ✗ | | | | | | ✗ |
| Approve or decline a pending dual-approval change (§4.2) | ✓ (neither actor nor target) | ✓ (neither actor nor target) | ✗ | | | | | | ✗ |
| List or read approvals (`GET /v1/admin/approvals`, `GET /v1/admin/approvals/{id}`) | ✓ (only approvals the caller initiated or may approve) | ✓ (same) | ✗ | | | | | | ✗ |
| Receive an approved reset link (`POST /v1/admin/approvals/{id}/link`) | ✓ (original actor only, per §4.2) | ✓ (original actor only, per §4.2) | ✗ | | | | | | ✗ |
| Revoke own sessions | ✓ | ✓ | ✓ | | | | | | |
| Revoke others' sessions | ✓ | ✓ (lower rank) | ✗ | | | | | | ✗ |
| Create DM or group | ✓ | ✓ | ✓ | | | | | | |
| List own conversations (`GET /v1/conversations`) | own memberships only | same | same | | | | | | ✗ |
| Read conversation state, event pages and history pages (`GET /v1/conversations/{id}`, `…/events`, `…/messages`) | member only | member only | member only | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| Read the member roster (`GET …/members`) | member only | member only | member only | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| Read invite links and their tokens (`GET …/links`) | — (group role only) | — (group role only) | — (group role only) | ✓ | *r* | *r* | — | — | ✗ |
| Send text or media | | | | ✓ | ✓ | *r* | ✓ | ✓ | |
| Edit own message (within window) | | | | ✓ | ✓ | ✓ | ✓ | ✓ | |
| Delete own message for everyone (within window) | | | | ✓ | ✓ | ✓ | ✓ | ✓ | |
| Delete others' messages | | | | ✓ | *r* (lower rank) | ✗ | ✗ (DEV-04) | — | |
| Pin or unpin | | | | ✓ | *r* | *r* | ✓ | ✓ | |
| Change info or settings | | | | ✓ | *r* | *r* | — | — | |
| Add members or create invite links | | | | ✓ | *r* | *r* | ✗ | ✗ | |
| Remove, ban or timeout members | | | | ✓ | *r* (lower rank) | ✗ | ✗ | ✗ | |
| Promote or demote admins | | | | ✓ | *r* (lower rank) | ✗ | — | — | |
| Transfer group ownership | ✓ (break-glass on a GO of lower org rank, DEV-07, §4.2) | ✓ (break-glass on a GO of lower org rank, §4.2) | | ✓ (re-auth) | ✗ | ✗ | — | — | |
| Delete group | | | | ✓ | ✗ | ✗ | — | — | |
| Approve join requests | | | | ✓ | *r* | ✗ | — | — | |
| Download attachment | | | | per MED-010 | per MED-010 | per MED-010 | per MED-010 | per MED-010 | ✗ |
| Search messages (`GET /v1/search`) | own memberships only | same | same | | | | | | ✗ |
| View admin overview or support bundle | ✓ | ✓ | ✗ | | | | | | ✓ (host logs, redacted) |

**Former members and non-members on the read rows.** A former member gets the conversation state, event pages and history pages capped at `left_seq − 1` of their final leave (nothing at or after `left_seq`), inside their `visible_ranges`, with content as of `left_seq − 1`: each message at its last revision committed before `left_seq`, pins and settings as of that seq, and a message deleted for everyone at any time as a tombstone with no deletion time. No edit, pin or setting change made at or after `left_seq` reaches them ([sync.md §6.1](../architecture/sync.md#61-visible-ranges)). Search (`GET /v1/search`) spans the caller's conversations, so it never answers `not_found`: for a former member it returns only hits on messages created before `left_seq` inside `visible_ranges`, matched and shown at the same pre-leave revision, and nothing at or after `left_seq`. The roster and the links return `not_found`. The O/A/M marks in the table describe current members; this note is the only grant to former members. A non-member gets `not_found` from every read endpoint (T1). The negative tests are in the SYN-008 and SYN-009 rows of [backlog §4](../plan/backlog.md#4-p1-traceability-matrix-84-ids-lifecycle-all-specified).

Org roles grant **no** implicit read access to conversations they are not members of. An admin content-access or eDiscovery capability is ENT-004/005 (P3), needs an explicit, audited policy, and is a PO product decision.

That rule limits access by role, not by account. In a server-managed system, an org admin who can reset a user's password can sign in as that user and read whatever that user can read. Admin-initiated reset is therefore an **account-takeover-capable power**. It is an account-recovery power, not a content-access policy, and it is bounded by §4.2. Whether P1 keeps it is PO decision PO-Q9.

### 4.1 Rank, direct chats and ownership continuity

- **Rank** is owner > admin > member, in the org and in each group. An admin acts only on accounts or members of strictly lower rank. A GA never removes, restricts or demotes another GA or the GO. The rule bounds every org-admin power over an account: revoking sessions (ID-003.d); deactivating, resetting a password and revoking (ENT-002.b); deactivating, reactivating and approving deletion (ID-006.a). An org admin therefore never acts on another org admin or the org owner. Inviting and admin account creation are not rank-bound, because each always creates an org member: `org_role` is not an invite field, and org admin is granted only through the Grant org admin action (§4, ENT-012.a). Break-glass is judged by the current GO's org rank (§4.2).
- **Direct chat:** exactly two participants. Both send, edit and delete their own messages, and pin. There is no member management, no invite link and no role, and neither participant deletes the other's messages for everyone (DEV-04).
- **Self conversation** (Saved messages): the owner alone reads and acts on it. Nobody else is ever a member.
- **Sole-owner deactivation:** ownership passes to the longest-tenured admin (earliest current `joined_seq`), else to the longest-tenured member. Candidates are active accounts that are current members; deactivated accounts are skipped. A group with no other member is archived and org admins are notified. The change is a sequenced, audited event (DEV-07, GRP-004.d). A deactivated GO is handled by this succession, never by break-glass (§4.2).

### 4.2 Admin recovery powers (PO-Q9)

The stance is PO decision PO-Q9 ([decisions.md](../plan/decisions.md#3-po-question-queue)): A) reset link by email only, B) an admin-delivered link with audit, notification and dual approval, or C) reset through the operator CLI only. The recommendation is A, with B as the fallback when no SMTP is configured. Until the PO answers, the interim default below applies, recorded as DEV-08 ([requirements §4](../product/requirements.md#4-enterprise-deviations-register)).

- **Dual approval (ENT-012.a).** When `require_dual_approval` is on, these actions create a pending change that a different admin, neither the actor nor the target, must approve: granting org admin, an admin-delivered reset link, a break-glass reassignment, and turning `require_dual_approval` off. The target is every account the change acts on: the user for a role grant or a reset, and both the current GO and the named new owner for a break-glass, so a peer admin named as new owner never approves their own appointment. The approval endpoints are in [contracts.md §2](../architecture/contracts.md#2-http-surface-p1-v1), and the approver is recorded in the action's audit record. The server re-checks the action's conditions when the approval is applied, not only when it is requested: the rank rule (§4.1), the target's state and, for break-glass, that the GO is unchanged and still active, the new owner is still an active account and a current member, and the actor is still an admin of higher rank. If a condition fails, the approval applies nothing and the change is refused.
- **Admin-initiated password reset.** When SMTP is configured, the single-use, expiring link goes only to the user's registered email, over TLS ([operations.md §2](../operations.md#2-configuration-and-secrets) lists the SMTP settings). Without SMTP, an admin may receive the link, and only after dual approval when it is on. Only the original actor receives it, never the approver, once per approval; at issue time the server re-checks the rank rule (§4.1) and the target's state, and refuses with `forbidden_action` if either fails ([contracts.md §2.1](../architecture/contracts.md#21-idempotent-mutations-and-operation-lookup)). Every reset revokes all of the user's sessions with reason `password_reset`, in the transaction that redeems the link (`POST /v1/password-resets/{token}/redeem`). Issuing or approving a reset revokes no session, so `approval.approve` locks no target session rows, only the approver's own session `FOR SHARE` in the [sync.md §3.1](../architecture/sync.md#31-lock-order-user-sequence-and-retries) lock order; an admin who must cut off sessions at once revokes them separately (ID-003.d). Every reset writes an audit record (actor, target, delivery channel, approver). The user's next login carries a notice of the admin reset. Their other devices learn the reason from the `session_revoked` error, because nothing is pushed after a revocation ([contracts.md §4](../architecture/contracts.md#4-error-model)). The rank rule (§4.1) applies.
- **Break-glass group ownership reassignment.** It is allowed only when the current GO's org rank is strictly lower than the actor's, so an org owner may act on any GO other than themselves. A deactivated GO is handled by automatic succession (§4.1), not by break-glass. The new owner is an active account and an existing current member of that group. The actor may name themselves only when `require_dual_approval` is on and a different admin approves. It is audited. It never grants the admin read access: an admin who is not a member stays a non-member.

## 5. Data classification and logging

| Class | Examples | Log or metric rule |
|---|---|---|
| Secret | passwords, tokens, invite and link tokens, reset links, the bootstrap token, keys | never logged; passwords and tokens stored hashed and tokens shown once, except that an invite-link token also keeps a copy encrypted with the link-token encryption key for the authorized re-read (T11); keys come from secret files (B7) |
| Content | message bodies, entities, file names, attachment bytes, search queries | never logged or traced; spans carry IDs only |
| Metadata | conversation and user IDs, seq, sizes, timings, status codes | allowed in logs and traces; never IP and user ID together beyond the security log |
| Security events | login failure, revocation, role change, rate-limit trip | security log with actor and target IDs, no content |

## 6. Abuse controls and quotas (P1 defaults are *policy*)

Rate limits on login, sends, uploads, invite creation and WS connects; per-user storage quota; maximum message length and attachment count; frame and payload caps; slow consumers dropped to catch-up.

## 7. Open security work

- Map each P1 control to ASVS 5.0 requirement IDs after confirming the published 5.0 chapter structure from the official OWASP source (packet P0-SEC-01, ready).
- An independent review of this file and of the sync revocation rules is required before `Reviewed`.
- SEC-005 (legal hold) is P3, and until then deletion semantics carry DEV-04.
- A vulnerability disclosure contact needs a PO-provided mailbox (PO-Q6).
- The admin recovery stance (§4.2) needs the PO's answer to PO-Q9 before P1-09 is accepted (R-16). P1-09 delivers ID-002.d/e together with ENT-002, ENT-012 and the rank rule ([backlog §2](../plan/backlog.md#2-p1-packets-dependency-order-all-not-authorized-until-the-gate-passes-and-the-po-authorizes)).
