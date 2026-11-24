# REM — Product requirements and P1 acceptance criteria

**Owner:** Lead (product) · **Status:** Specified (P0 draft r1, 2026-11-24) · **Governed by:** [PROJECT_SPEC.md](../../PROJECT_SPEC.md), [FEATURE_REGISTRY.md](../../FEATURE_REGISTRY.md)

This file is the single home of REM scope, non-goals, status vocabulary, enterprise deviations and **P1 acceptance criteria**. The traceability, packets and verification for each ID are in [backlog.md](../plan/backlog.md). Telegram evidence is in [reference-behavior.md](reference-behavior.md). Capability IDs come from the registry and are never reused.

## 1. Scope and non-goals

**In scope (P1):** a deployable, single-tenant, self-hosted messaging foundation. It covers invite-based identity, sessions and devices, direct and group chats, the message lifecycle, durable offline sync on web (React/TypeScript + Rust WASM) and desktop, basic files, basic admin, backup/restore and operator tooling. Later phases follow [PROJECT_SPEC §6](../../PROJECT_SPEC.md#6-phase-strategy-and-explicit-gates).

**Non-goals (all phases unless the PO decides otherwise):** Telegram protocol (MTProto) compatibility, Telegram accounts or cloud, server emulation, federation, and Telegram bridging. Also excluded are Telegram trademarks or assets, public social-network operation, global discovery by default, a crypto/gift economy, mandatory SaaS, always-online license checks, and any E2EE claim before ADR-0009 conditions are met.

**Non-goals for P1 specifically:** mobile apps (P3), calls (P3), SSO/SCIM (P3), channels (P2), topics (P2), reactions (P2), server-side thumbnails/transcoding (P2/P3), multi-node HA (P3), multi-tenant SaaS (separate decision), phone-number identity.

## 2. Personas and critical journeys

Personas and journeys are defined once in [PROJECT_SPEC §3](../../PROJECT_SPEC.md#3-personas-core-journeys-and-release-quality). P1 journeys, with their verification owner in [testing-ci.md](../engineering/testing-ci.md#5-p1-journey-set):

| Journey | IDs |
|---|---|
| J1 Sign in, list devices, revoke a device | ID-002, ID-003, SEC-002 |
| J2 Create DM and group, invite, leave, remove | DM-001, GRP-001..006 |
| J3 Send, retry after lost ACK, edit, delete | DM-002..004, SYN-002..005 |
| J4 Attach and download a file | MED-001, MED-002, MED-010 |
| J5 Reconnect after network loss; two devices converge | SYN-001, SYN-006..010, CLI-011 |
| J6 Search within permissions | ORG-004, SEC-003 |
| J7 Backup, restore, upgrade, rollback | OPS-002, OPS-006, OPS-007, ENT-007 |
| J8 Diagnose an incident without message content in logs | OPS-004, OPS-005, ENT-010 |

## 3. Status vocabulary (four separate measures)

A capability or requirement row carries one **lifecycle** value: `Discovered → Specified → Reviewed → Implemented → Verified → Released`. Optional flags are `UNKNOWN`, `BLOCKED` and `DEVIATION`. Reference evidence strength is separate: `OFFICIAL | OBSERVED | INFERRED | UNKNOWN`. The four measures stay distinct and are never merged into one percentage:

1. **Reference coverage**: evidence rows in [reference-behavior.md](reference-behavior.md).
2. **Implementation**: lifecycle reaches `Implemented`, linked to an immutable commit.
3. **Verified correctness**: `Verified` needs a reviewed contract, passing relevant gates at a recorded SHA and acknowledged limitations ([registry release rule](../../FEATURE_REGISTRY.md#release-completeness-rule)).
4. **Operational/commercial readiness**: tracked in [operations.md](../operations.md) and [commercial.md](../commercial.md).

## 4. Enterprise deviations register

Each deviation states its user-facing effect, rationale and the tests that prove it. Tests are named in the backlog.

| ID | Affects | Reference behavior | REM behavior | Rationale |
|---|---|---|---|---|
| DEV-01 | ID-001, ID-002 | Phone-number sign-up with SMS/app codes | Org invite or admin-created accounts, with username/email and password. No phone numbers. | Self-hosted orgs control membership. Phone numbers are PII. |
| DEV-02 | ID-006, DM-004 | User deletes the account, and their messages can be removed | Admin-governed deactivation and deletion. Messages follow org retention, and the author is shown as a tombstone. | Org retention and compliance (SEC-005 P3) |
| DEV-03 | DM-003 | Only the latest edit is visible | Members see the latest revision. Revision history is retained server-side and visible only to roles allowed by org policy (default: none in P1). | Audit readiness without leaking history to members |
| DEV-04 | DM-004 | In private chats either side can delete sent **or received** messages for both, with no time limit and no trace ([ref](reference-behavior.md#reference-table)) | Only the author (within a *policy* window) or a permitted group admin deletes for everyone. A tombstone event remains. Content leaves every member view and the primary store. Until legal hold arrives in P3, backups keep it until rotation, and this is disclosed to admins. | Accountability, and honest deletion semantics before SEC-005 |
| DEV-05 | DM-012 | Link previews generated by the service | Server-side URL previews are **off** by default. An admin can enable them only with the SSRF controls in SEC-010. | SSRF and privacy |
| DEV-06 | GRP-002, ID-005 | Public links and usernames reachable by anyone | Invite links work only for authenticated org members in P1. There are no guests. | Private enterprise default |
| DEV-07 | GRP-004, ID-006 | Ownership transfer needs the owner's 2FA password, at least 24 h old. A deleted creator can leave a group ownerless. | The owner transfers after re-authentication. An org admin can also reassign ownership (break-glass, audited). Deprovisioning never leaves a group without an owner. | Org continuity |

## 5. P1 acceptance criteria

Criteria are numbered `<ID>.a`, `<ID>.b`, and so on. Those numbers are the traceability anchors that test names cite. **Cross-cutting criteria XC-1..XC-8 apply to every P1 ID** and are not repeated:

- **XC-1 Authorization:** the server checks every command and read against current membership and role. A non-member receives `not_found`, never `forbidden` that confirms the object exists.
- **XC-2 Offline/retry:** a mutating command carries `operation_id`. A retry returns the original result. A different payload under the same id returns `operation_conflict`.
- **XC-3 Realtime:** each state change is a sequenced event ([sync.md](../architecture/sync.md)). Clients converge after duplicates, reordering and reconnects.
- **XC-4 Multi-platform:** the behavior works in the supported web browsers and on desktop, by keyboard alone, at a 320 px width, with IME input.
- **XC-5 Resilience:** a timeout, a disconnect or a server restart never loses a committed effect or duplicates one.
- **XC-6 Privacy:** no message bodies, tokens, passwords or file names in logs or metrics ([threat-model.md](../security/threat-model.md#5-data-classification-and-logging)).
- **XC-7 Operations:** a schema change ships with forward migration and a documented rollback.
- **XC-8 Verification:** each criterion maps to a named test at the cheapest sufficient tier ([testing-ci.md](../engineering/testing-ci.md#2-test-ladder-applied-to-rem)).

Numbers marked *policy* are org-configurable defaults. A value marked *TBD-measure* is fixed only after a measured baseline (OPS-009) and is never invented.

### Identity (ID)

| ID | Acceptance criteria |
|---|---|
| ID-001 | a) Self-registration is off by default. Accounts come only from an admin-issued invite or admin creation. b) An invite has an expiry, a use limit and revocation. An expired, revoked or exhausted invite returns `invite_invalid` and creates nothing. Concurrent redemption never exceeds the use limit. c) Onboarding sets a display name and a policy-compliant password and registers the first device. d) Invite tokens have ≥128 random bits, are stored hashed and are never logged. Deviation: DEV-01. |
| ID-002 | a) Login uses username or email plus password, hashed with Argon2id (ADR-0010). Unknown user and wrong password give the same response. Attempts are rate-limited per account and per IP. b) Logout revokes the session server-side and clears local credentials. If unsent operations exist, the client warns before discarding them. c) A password change revokes the other sessions by default. d) Recovery is an admin-issued, single-use, expiring reset link. Self-service email recovery works only when SMTP is configured. |
| ID-003 | a) The user lists their own sessions with device name, platform, created time and last-active time. b) Revoking a session commits server-side. That session's open sockets close and its later requests fail with `session_revoked` within *TBD-measure* seconds. c) A revoked client clears its credentials and says that unsent items were not delivered. d) An admin can revoke any member's sessions. e) Idle sessions expire per *policy* (ADR-0010). |
| ID-004 | a) Display name has 1–64 Unicode scalars, NFC-normalized, with no control characters. Bio length is set by *policy*. The avatar goes through MED-002 validation. b) Profiles are visible to org members (P1 privacy scope). c) A change reaches every device of affected users. Avatars are cache-busted by content hash. |
| ID-005 | a) An instance has one organization (ENT-001). Membership is created by invite or by an admin. b) Deactivating a member revokes all their sessions. Their content stays and is labelled as a deactivated user. c) The join policy is invite-only in P1. Domain auto-join waits for SSO (ID-009, P3). |
| ID-006 | a) An admin deactivates and reactivates accounts. A deletion request is approved by an admin per *policy* (DEV-02). b) Deletion erases profile PII, revokes sessions and tombstones the author label. Messages follow retention. c) A user can export their profile and their own messages as a JSON archive. The archive is built asynchronously, served behind authorization and its link expires. |

### Direct chat (DM)

| ID | Acceptance criteria |
|---|---|
| DM-001 | a) Opening a DM between two org members is idempotent: one DM per pair. b) Text holds up to a *policy* length. Formatting is typed entity ranges (bold, italic, underline, strikethrough, inline code, code block, link, mention), with offsets in UTF-16 code units (ADR-0006). The server rejects overlapping or out-of-range entities. c) Rendering never interprets HTML or script, and XSS payload fixtures render inert. d) Empty or whitespace-only bodies are rejected. |
| DM-002 | a) Visible states are `pending`, `sent` (ACK with a sequence number), `read` and `failed` (retryable or permanent). b) A pending message survives an app restart or browser reload. c) After a lost ACK, a retry with the same `operation_id` yields the same `message_id`, and no device shows a duplicate. d) A permanent failure shows the reason and offers retry or discard. |
| DM-003 | a) A reply targets an existing message the sender can read in the same conversation. A deleted target renders as a placeholder (DM-003-R01). b) Only the author edits, within a *policy* window. Each edit creates revision n+1 and marks the message edited (R02). c) An edit carries `expected_revision`. A stale value returns `revision_conflict` with the current revision, so no update is silently lost (R03). d) An edit reaches all authorized devices and updates search and unread state (R04). e) Retrying the same edit operation creates no extra revision (R05). f) Revision history is retained per DEV-03 (R06). g) Accessibility and compact layout follow UX-005 and UX-001 (R07). |
| DM-004 | a) Delete-for-self hides the message on all of the user's own devices. b) Delete-for-everyone is allowed to the author within a *policy* window, and to group admins with that right. It emits a tombstone event, and synced devices remove the content. c) The deleted body leaves search and primary storage per DEV-04. |
| DM-005 | a) Forwarding creates a new message in the target conversation with attribution (original author, and the source conversation when the recipient may see it). b) It needs read access to the source and post permission in the target. c) Attachments are referenced, not copied, and access is re-checked per target. d) Forwarding without attribution is allowed when org *policy* permits it. |
| DM-006 | a) A permitted role pins and unpins messages. Pins are ordered, sequenced events visible to members. b) "Saved messages" is a personal self-conversation that can receive forwards. Bookmarks and tags stay in ORG-006 (P2). |
| DM-008 | a) Typing indicators are ephemeral, never persisted and carry no sequence. b) The client sends at most one per 3 s per conversation, and the server drops any excess. c) An indicator expires after 6 s without a refresh. d) Only current members receive them. |
| DM-009 | a) Read position is the highest sequence read per user per conversation. It only moves forward, and concurrent device updates converge to the maximum. b) Unread count is the number of messages by others above the read position, excluding deleted ones. It agrees across devices after sync. c) In a DM, the sender sees `read` once the recipient's position reaches the message. In a group, `read` means at least one other member has read it. Per-member read lists are capped by *policy*; the reference caps them at 100 members and 7 days. Hiding read receipts is P2 (ID-012). |
| DM-012 | a) A mention entity references a `user_id`, and members mentioned get a mention badge (NTF-001). b) The client detects URLs and hashtags and stores them as entities. c) Server-side previews are off by default (DEV-05). With previews enabled, fetching meets the SSRF controls of SEC-010. d) Hashtags are searchable through ORG-004. |

### Groups (GRP)

| ID | Acceptance criteria |
|---|---|
| GRP-001 | a) A group is created with a title and initial org members, and the creator becomes owner. b) A permitted role updates the title, photo and description, and each change is a sequenced event. c) When the owner deletes the group, members lose access and new events stop. Retained data follows *policy*. d) The member limit is a *policy* value no greater than the measured, supported size (*TBD-measure*). |
| GRP-002 | a) An invite link has an expiry, a use limit, an optional approval requirement (GRP-006) and revocation. A revoked or expired link fails immediately. b) Leaving emits a membership event and applies SYN-009. c) Members with the right can add members directly. d) Links are usable only by authenticated org members (DEV-06). |
| GRP-003 | a) Each group has default member rights (send, send media, add members, pin, change info), which roles can override. b) The server enforces them on every command. c) A permission change is a sequenced, audited event. The matrix is [threat-model §4](../security/threat-model.md#4-authorization-matrix-p1). |
| GRP-004 | a) There is exactly one owner, plus admins with granular rights. b) Promote and demote are sequenced, audited events. c) Ownership transfer needs the owner's re-authentication. Any added delay is *policy*. An org admin can reassign ownership with an audit record (DEV-07). d) The owner cannot leave without transferring ownership or deleting the group, and deactivating an owner reassigns ownership. |
| GRP-005 | a) Removing a member applies SYN-009 revocation. b) A ban blocks rejoining through any link until lifted. c) A timeout blocks sending until a server-time deadline. d) All three are audited. |
| GRP-006 | a) A link that needs approval creates a pending request visible to admins. b) Approve or decline is idempotent, and the requester's devices learn the outcome. c) Pending requests expire per *policy*. |
| GRP-007 | a) Settings cover title, description (*policy* length), photo, history visibility for new members (`from_join` \| `full`, default `full`) and invite-link management. b) Each change is a sequenced event. |
| GRP-008 | a) A per-conversation notification level (all, mentions only, muted until a time) is stored per user and synced. b) A mention of a member who chose mentions-only still raises their mention badge. |

### Sync and realtime (SYN)

Normative design: [sync.md](../architecture/sync.md). Criteria here are what the tests must show.

| ID | Acceptance criteria |
|---|---|
| SYN-001 | a) The WebSocket authenticates with a short-lived ticket obtained over HTTPS. No long-lived token appears in any URL. b) Heartbeat timeouts and reconnects use exponential backoff with jitter. c) After a reconnect, the client completes catch-up before it trusts pushed events. d) The server closes sockets of revoked sessions. e) Protocol negotiation follows SYN-013. |
| SYN-002 | a) The client generates `operation_id` (UUID) and the server assigns `message_id` (UUIDv7). b) An idempotency record is kept for at least `IDEMPOTENCY_TTL` (*policy*, default 30 days). A duplicate returns the stored result with `duplicate=true`. c) The same id with a different payload returns `operation_conflict`. |
| SYN-003 | a) Within a conversation, sequence numbers are contiguous from 1 with no gaps or repeats, including under concurrent senders and aborted transactions. b) A property test with N concurrent writers yields exactly 1..N. |
| SYN-004 | a) The ACK is sent only after the message, event, idempotency record and outbox row commit together. b) Fault injection: a crash before commit leads to exactly one message after retry. A crash after commit but before the ACK leads to the same result on retry. c) The dispatcher delivers at least once and resumes after its own crash. |
| SYN-005 | a) The client reducer is deterministic. Applying an event twice equals applying it once. b) From any valid snapshot, applying events in sequence order gives the same state. A property test covers duplicated, reordered and dropped deliveries. |
| SYN-006 | a) Each device persists its user cursor and per-conversation sequence. b) Paginated catch-up returns every authorized event after the cursor. c) After catch-up, the local projection equals the server projection in a model-based test. |
| SYN-007 | a) A pending operation is persisted before the UI shows it. b) Each conversation drains its queue first-in, first-out. Retries use capped backoff with jitter, and errors are classed as retryable or permanent. c) The queue survives a restart. An operation older than `IDEMPOTENCY_TTL` is not retried automatically and is shown as needing confirmation. |
| SYN-008 | a) A sequence gap triggers a range fetch. b) A cursor below the retention floor returns `cursor_expired`. A snapshot reset keeps the pending operations. c) A corrupt or unmigratable local store is detected and recovered through the reset path. |
| SYN-009 | a) A removed member never receives events at or after `left_seq`, even with a forged cursor (negative test). b) History visibility for new members follows GRP-007. c) Attachments of messages after removal are denied (MED-010). d) A send and a removal on the same conversation are serialized ([sync.md §6](../architecture/sync.md#6-revocation-and-history-authorization)). |
| SYN-010 | a) A read position is a monotonic maximum. b) It reaches the user's other devices through the user stream and the other party through receipt events (DM-009). |
| SYN-011 | a) Presence and typing go through the `Presence` port, using an in-process adapter in P1 (ADR-0011). b) Nothing is persisted, and loss on restart is accepted. c) Fan-out and rate are bounded. |
| SYN-013 | a) Client and server negotiate a protocol version, and the server supports the current and previous minor version. b) Golden JSON fixtures per version pass in CI. c) Unknown fields are ignored, and unknown event types are stored as unsupported without a crash. d) A client below the minimum gets `upgrade_required`. |
| SYN-014 | a) The test harness injects clock skew (±24 h), duplication, reordering, drops and delay. b) Ordering relies only on sequence numbers, never on client clocks. c) Timeouts use a monotonic clock. |

### Media (MED)

| ID | Acceptance criteria |
|---|---|
| MED-001 | a) Uploading creates a pending attachment. A message may reference only finalized attachments the sender owns. b) A message can carry several attachments, up to a *policy* count. c) Images display inline, scaled on the client. There are no server-side thumbnails in P1. |
| MED-002 | a) Maximum size and per-user quota are *policy* values. b) The server checks magic bytes against the declared type and applies an allow- or deny-list. c) File names are sanitized, and downloads use `Content-Disposition: attachment` with `nosniff`. d) A `MalwareScanner` port exists. Scanning is off by default, and this is disclosed to admins. |
| MED-010 | a) A download is authorized when the user is a member of a conversation where a visible, undeleted message references the attachment. b) Delivery uses an unguessable signed URL with a short TTL (≤5 min), or a proxied stream. c) After removal, no new URL is issued. An already-issued URL expires within its TTL, and this limitation is disclosed. |

### Search and organization (ORG)

| ID | Acceptance criteria |
|---|---|
| ORG-001 | a) Conversations sort by last activity, with pinned chats first. The pin count limit is *policy*. b) Pins and their order sync across the user's devices. |
| ORG-002 | a) Archive and mute-until-time are per user and synced. b) Whether an archived chat returns on a new message follows the reference row, unless it is muted. c) Unread badges follow DM-009. |
| ORG-004 | a) Search finds conversations by title or member name, and messages by full text, only where the user may read them, respecting membership intervals. b) Deleted or edited content leaves the index or updates by the next query after commit. c) Results are paginated. A non-member probing for a term gets nothing (negative test). |

### Notifications (NTF)

| ID | Acceptance criteria |
|---|---|
| NTF-001 | a) In-app badges show per-conversation and total unread counts, plus mention badges. b) A non-focused conversation shows an in-app notice unless it is muted. c) Counts agree across devices after a read. |

### Privacy and security (SEC)

| ID | Acceptance criteria |
|---|---|
| SEC-001 | a) External traffic uses TLS 1.2 or later (1.3 preferred) with HSTS. Internal links use TLS or a documented local-only network. b) The encryption-at-rest strategy (volume, object storage and backups) is documented and checked by the release checklist. c) No E2EE claim is made anywhere (ADR-0009). |
| SEC-002 | a) Session tokens are opaque, have ≥256 random bits, are stored hashed and are rotated per ADR-0010. b) The web uses HttpOnly + Secure cookies with CSRF defenses, or an equivalent the ADR settles. c) Revocation follows ID-003. |
| SEC-003 | a) Every endpoint authorizes object access through membership or role. b) IDs are non-sequential. c) An automated negative suite per endpoint covers other users' conversations, messages, attachments and sessions. |
| SEC-004 | a) Org-scoped rows carry `organization_id` and every query is scoped by it. b) There is one tenant per instance. c) Tests show conversation-to-conversation isolation. |
| SEC-006 | a) Secrets come from environment variables or secret files, never from images, the repository or logs. b) Signing keys and the token pepper have a documented rotation procedure. |
| SEC-009 | a) Rate limits per user, device and IP cover login, send, upload, invite creation and WebSocket connects. b) An exceeded limit returns 429 with `retry_after`, and the client honors it. |
| SEC-010 | a) Untrusted media is never rendered server-side in P1. b) External links show the full target before navigation. c) The server fetches no URLs by default (DEV-05). Enabling previews needs an allow-list, private-range blocking, size and time caps, and redirect re-validation. |
| SEC-013 | a) A `SECURITY.md` disclosure policy exists. b) CI runs a dependency audit (RustSec, npm) and license/ban checks. c) Security events (failed logins, revocations, permission changes) are logged without content. |

### UI/UX and accessibility (UX)

Design detail: [ux.md](ux.md).

| ID | Acceptance criteria |
|---|---|
| UX-001 | a) The layout works from a 320 px width to desktop: single pane when narrow, two or three panes when wide, with no horizontal scroll. b) It is verified at three viewports. |
| UX-003 | a) Light and dark themes follow the OS, and the user can override. b) Tokens meet WCAG AA contrast in both themes. |
| UX-005 | a) P1 screens target WCAG 2.2 AA. b) The message list is an accessible feed, with polite announcements for incoming messages. c) Every action is reachable by keyboard. d) Automated a11y checks report zero serious or critical violations on P1 screens. |
| UX-006 | a) The chat list and message history are virtualized. b) A 10k-message history scrolls with frame time within the measured budget (*TBD-measure*). c) Scroll anchoring holds when older messages load, and jump-to-latest is available. |
| UX-007 | a) Every P1 screen defines loading, empty, error, offline and retry states. b) An offline banner appears whenever the transport is down. |
| UX-008 | a) Dragging or pasting files and images into the composer shows a preview before sending. b) Size and type are validated before upload where possible. |
| UX-009 | a) The message context menu (reply, edit, delete, forward, pin, copy) works by keyboard. b) Multi-select supports delete and forward. |
| UX-012 | a) Instance URLs to conversations and messages resolve only for authorized users. b) Invite-link URLs open the join flow. c) The desktop registers its protocol handler (CLI-008). |

### Enterprise admin (ENT)

| ID | Acceptance criteria |
|---|---|
| ENT-001 | a) On first run, a one-time bootstrap token, read from the operator console or a secret file, creates the organization and its first admin. b) Bootstrap is idempotent and disabled after use. |
| ENT-002 | a) Org roles are owner, admin and member. The operator acts outside the app. b) Admins invite, deactivate, reset passwords and revoke sessions. c) The P1 policy set is the edit window, the delete-for-everyone window, upload limits, the history-visibility default and the session idle timeout. |
| ENT-006 | a) Policy is evaluated server-side. Policies are versioned and changes are audited. b) The deployment enforces one tenant per instance (SEC-004). |
| ENT-007 | a) The operator can back up the database and object storage to a consistent point, and restore from it. b) The release lane rehearses a restore (OPS-006). |
| ENT-010 | a) The admin view shows user, session and storage counts and service health. b) A support bundle contains redacted logs and configuration without secrets or message content. |
| ENT-012 | a) When `require_dual_approval` is on (*policy*, default off), granting an org admin role creates a pending change that a different admin must approve. b) Every role change is audited. |

### Platform clients (CLI)

| ID | Acceptance criteria |
|---|---|
| CLI-001 | a) React calls a typed TypeScript binding generated from the Rust SDK (ADR-0002). Sync and the outbox run in WASM. b) A browser journey passes in each supported engine: cold load, login, offline send, reload, reconnect, ACK reconciled. c) The supported browsers are the latest two stable versions of Chromium, Firefox and WebKit (*default*, PO-confirmable). |
| CLI-002 | a) A Tauri shell reuses the web UI (ADR-0007). b) Installers exist for Linux, Windows and macOS. Signing depends on certificates (PO-Q5). |
| CLI-003 | a) `rem-client-core` builds for native targets and for `wasm32-unknown-unknown`, with no UI, framework, thread or tokio-runtime dependencies. b) The same reducer and outbox tests run on both targets. |
| CLI-004 | a) Native storage is SQLite with versioned migrations. The browser adapter is chosen by ADR-0003. b) A migration failure falls back to the SYN-008 reset path and keeps pending operations when they can be read. |
| CLI-008 | a) The desktop integrates with the OS (protocol handler, single instance). b) Updates are signed and point at a customer-hosted endpoint, or are disabled for air-gapped installs. |
| CLI-009 | a) The client sends its version. b) The server advertises the minimum and current versions. c) A client below the minimum shows a blocking upgrade screen and keeps its pending data. |
| CLI-010 | a) The documented matrix is engines × desktop operating systems × protocol versions (current, previous). b) The scenario set covers two devices of one user, one of them offline, converging. |
| CLI-011 | a) The UI shows the offline state, pending and failed badges, an edit-conflict dialog with the server version, and a notice after a cursor-expired reset. |

### Infrastructure and operations (OPS)

Operational design: [operations.md](../operations.md).

| ID | Acceptance criteria |
|---|---|
| OPS-001 | a) A compose bundle (server, PostgreSQL, S3-compatible store, reverse proxy) runs under Podman and Docker. b) A clean-host install is documented, and health checks pass. |
| OPS-002 | a) Migrations are versioned and forward-only, with expand/contract for breaking changes. b) Each release states its rollback path. c) A migration test runs from the previous release's schema with data. |
| OPS-003 | a) Each instance has its own bucket. Objects are included in backups. b) A disaster-recovery runbook exists. |
| OPS-004 | a) `/healthz` (liveness) and `/readyz` (dependencies) exist. b) Prometheus metrics and OpenTelemetry traces exist. c) Metrics cover ACK latency, socket count and outbox lag. |
| OPS-005 | a) Logs are structured. A test proves message bodies, tokens, passwords and file names are absent (XC-6). |
| OPS-006 | a) Backup → restore into a scratch instance → consistency checks (row counts, latest sequence per conversation, attachment checksums) passes in the release lane. |
| OPS-007 | a) An upgrade from the previous to the current version is rehearsed with data. b) Rollback goes through a restore point. c) The client compatibility window follows SYN-013. |
| OPS-008 | a) CI follows [testing-ci.md](../engineering/testing-ci.md). b) Release artifacts are signed and carry an SBOM. c) Required-check reliability is demonstrated by the P0 simulation cases. |
| OPS-009 | a) A load harness runs a declared workload on recorded hardware and reports p50/p95/p99 ACK latency and reconnect time. b) A 24 h soak shows no unbounded growth. c) SLOs are set only from this baseline. |
| OPS-011 | a) Configuration is validated at startup. There are no default passwords. b) TLS uses ACME or customer-provided certificates, and works offline. |
| OPS-013 | a) Runbooks cover install, upgrade, backup, restore, secret rotation, compromised-session response and disk-full. b) An incident template exists. |
