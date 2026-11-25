# RUST ENTERPRISE MESSENGER — FEATURE REGISTRY

**Version:** 1.1 seed | **Date:** 2026-11-24 | **Classification:** proposed capabilities; **NOT verified 100% Telegram parity**.

> Governed by [PROJECT_SPEC.md](PROJECT_SPEC.md) and [AGENT_HARNESS.md](AGENT_HARNESS.md). **Stable ID** is the anchor for requirements, source evidence, tests, work packets and release logs. Never silently reuse/reassign IDs. An entry here states *coverage intent*, not implementation or verified reference behavior.

## How the AI agent must extend this registry

1. Investigate official Telegram FAQ, evolution history, official client source, Bot/Mini App specs and observable UI behavior. Record `source_url`, date, client/version/platform, steps/screenshots or code location; mark `OFFICIAL`, `OBSERVED`, `INFERRED`, `UNKNOWN`.
2. Expand every capability into atomic behavioral requirements and cases: happy path, permissions, invalid inputs, offline, concurrency, platform variance, recovery, accessibility, abuse and policy deviations. Some entries are umbrella categories, not one story each.
3. Append structured fields in its own controlled registry: priority, dependencies, owner, UX contract, API/event contract, privacy implications, stage, acceptance, verification evidence and parity gaps. Maintain `FEATURE -> REQUIREMENT -> DESIGN -> CODE -> TEST -> EVIDENCE` traceability.
4. Treat Telegram's future releases as change requests subject to review. No assumption every social/crypto feature belongs in enterprise edition. For `P4`, justify commercial value before implementation.
5. User-visible parity claims require direct evidence from the target version and supported platform. Do not reverse-engineer private server internals by assertion. Document `ENTERPRISE_DEVIATION` for policy differences.

**Phase legend:** P0 = discovery/prototypes, P1 = deployable MVP, P2 = broad core UX, P3 = enterprise/advanced comms, P4 = optional ecosystem. Every capability includes research in P0 whether or not implementation is deferred. Phase assigned is a **target**, not promise.

## Capability-level inventory

### IDENTITY

| ID | Capability | Target |
|---|---|---|
| `ID-001` | registration and invitation/onboarding | P1 |
| `ID-002` | login/logout, passwords and recovery | P1 |
| `ID-003` | session/device list and revocation | P1 |
| `ID-004` | profiles, display names, avatars, bios | P1 |
| `ID-005` | organization membership and join policies | P1 |
| `ID-006` | account deletion/deactivation/export | P1 |
| `ID-007` | account switching and multiple accounts | P2 |
| `ID-008` | usernames and profile links | P2 |
| `ID-009` | passkeys, MFA, SSO/OIDC, SCIM | P3 |
| `ID-010` | contact import/discovery/privacy | P2 |
| `ID-011` | blocked users and restricted contacts | P2 |
| `ID-012` | last-seen/online visibility and privacy | P2 |

### DIRECT CHAT

| ID | Capability | Target |
|---|---|---|
| `DM-001` | 1:1 text messages and markdown/rich formatting | P1 |
| `DM-002` | send state, pending/failed/retry/ACK | P1 |
| `DM-003` | reply, quote, edit and versioned revisions | P1 |
| `DM-004` | delete for self/everyone and retention exceptions | P1 |
| `DM-005` | forward/copy/share and attribution controls | P1 |
| `DM-006` | message pin/unpin and saved/bookmarks | P1 |
| `DM-007` | reactions, custom reactions and effects | P2 |
| `DM-008` | typing and recording indicators | P1 |
| `DM-009` | read receipts and unread counts | P1 |
| `DM-010` | scheduled/quiet/send-when-online messages | P2 |
| `DM-011` | disappearing messages and timers | P3 |
| `DM-012` | mentions, links, URL previews and hashtags | P1 |
| `DM-013` | polls, checklists and interactive content | P3 |
| `DM-014` | message translations and transcription | P4 |

### GROUPS

| ID | Capability | Target |
|---|---|---|
| `GRP-001` | create/update/delete group | P1 |
| `GRP-002` | join/leave/invite/revoke invitations | P1 |
| `GRP-003` | membership permissions and ACL | P1 |
| `GRP-004` | owner/admin/moderator roles and transfer | P1 |
| `GRP-005` | member removals, bans and timeouts | P1 |
| `GRP-006` | join requests and approval | P1 |
| `GRP-007` | group description, photos, links and settings | P1 |
| `GRP-008` | replies/mentions and group notification preferences | P1 |
| `GRP-009` | topics/forum mode and topic moderation | P2 |
| `GRP-010` | large-group performance and slow mode | P2 |
| `GRP-011` | moderation logs, anti-spam, reports | P3 |
| `GRP-012` | anonymous admin or protected content options | P3 |
| `GRP-013` | member tags and welcome messages | P3 |
| `GRP-014` | group stories, boosts and appearance options | P4 |

### CHANNELS

| ID | Capability | Target |
|---|---|---|
| `CHN-001` | broadcast channel creation and configuration | P2 |
| `CHN-002` | public/private discovery and subscriptions | P2 |
| `CHN-003` | channel posts with edit/delete/scheduling | P2 |
| `CHN-004` | post views, reactions and forwarding | P2 |
| `CHN-005` | linked discussion/comments | P2 |
| `CHN-006` | channel admin roles and analytics | P2 |
| `CHN-007` | direct messages to channels and routing | P2 |
| `CHN-008` | live channel broadcasts and streaming | P2 |
| `CHN-009` | suggested posts, monetization options | P2 |

### SYNC & REALTIME

| ID | Capability | Target |
|---|---|---|
| `SYN-001` | WebSocket connect/auth/reconnect | P1 |
| `SYN-002` | persistent message/operation IDs | P1 |
| `SYN-003` | conversation sequence and concurrency control | P1 |
| `SYN-004` | transactional outbox and durable ACK | P1 |
| `SYN-005` | idempotent replay and event reducers | P1 |
| `SYN-006` | device-specific cursor/catch-up | P1 |
| `SYN-007` | offline client outbox and retries | P1 |
| `SYN-008` | gap detection and snapshot recovery | P1 |
| `SYN-009` | membership revocation and history authorization | P1 |
| `SYN-010` | read-position synchronization | P1 |
| `SYN-011` | ephemeral presence/typing distribution | P1 |
| `SYN-012` | multi-node fan-out and backpressure | P2 |
| `SYN-013` | protocol evolution and compatibility | P1 |
| `SYN-014` | clock skew, duplicate/out-of-order and recovery testing | P1 |

### MEDIA

| ID | Capability | Target |
|---|---|---|
| `MED-001` | photo/video/document attachment | P1 |
| `MED-002` | file upload validation, quotas and content-type | P1 |
| `MED-003` | resumable/chunked upload and download | P2 |
| `MED-004` | thumbnails, previews and metadata | P2 |
| `MED-005` | streaming media playback | P2 |
| `MED-006` | voice notes and round video | P2 |
| `MED-007` | stickers, GIFs, emoji packs | P3 |
| `MED-008` | media galleries and shared media | P2 |
| `MED-009` | image editor, cropping and annotations | P4 |
| `MED-010` | file download permissions and signed URLs | P1 |
| `MED-011` | storage lifecycle, malware scanning, retention | P2 |
| `MED-012` | transcoding, compression and optimization | P3 |
| `MED-013` | large files and interrupted transfer recovery | P2 |

### CALLS

| ID | Capability | Target |
|---|---|---|
| `CALL-001` | one-to-one voice calling | P3 |
| `CALL-002` | one-to-one video calling | P3 |
| `CALL-003` | group calls and voice rooms | P3 |
| `CALL-004` | screen sharing and presenter controls | P3 |
| `CALL-005` | call permissions, invite/mute/kick | P3 |
| `CALL-006` | network traversal and TURN/STUN | P3 |
| `CALL-007` | recording/transcription policy | P3 |
| `CALL-008` | streaming and stage broadcasts | P3 |
| `CALL-009` | call quality and diagnostics | P3 |
| `CALL-010` | encryption/security controls | P3 |
| `CALL-011` | live reactions and group-call comments | P3 |

### SEARCH & ORGANIZATION

| ID | Capability | Target |
|---|---|---|
| `ORG-001` | conversation list, sort and pin | P1 |
| `ORG-002` | archive, mute, unread badges | P1 |
| `ORG-003` | personal and shared folders | P2 |
| `ORG-004` | search conversations/messages | P1 |
| `ORG-005` | search by sender/date/media/type | P2 |
| `ORG-006` | saved messages and bookmarks | P2 |
| `ORG-007` | hashtags, tags and filters | P2 |
| `ORG-008` | chat history pagination and jump-to-message | P2 |
| `ORG-009` | recent search and indexing policy | P2 |
| `ORG-010` | public/global content discovery | P2 |

### NOTIFICATIONS

| ID | Capability | Target |
|---|---|---|
| `NTF-001` | in-app unread notifications | P1 |
| `NTF-002` | desktop OS notifications | P2 |
| `NTF-003` | mobile push delivery | P2 |
| `NTF-004` | mute, mentions and custom exceptions | P2 |
| `NTF-005` | previews and privacy settings | P2 |
| `NTF-006` | cross-device read/dismiss state | P2 |
| `NTF-007` | notification rate limiting and bundling | P2 |
| `NTF-008` | quiet hours and Do Not Disturb | P2 |
| `NTF-009` | call and urgent alerts | P2 |

### PRIVACY & SECURITY

| ID | Capability | Target |
|---|---|---|
| `SEC-001` | TLS, transport security, storage encryption | P1 |
| `SEC-002` | session/device lifecycle and revocation | P1 |
| `SEC-003` | fine-grained authorization; IDOR/BOLA defenses | P1 |
| `SEC-004` | org and conversation isolation | P1 |
| `SEC-005` | retention/deletion semantics and legal holds | P3 |
| `SEC-006` | encryption key and secrets management | P1 |
| `SEC-007` | optional E2EE secret chat architecture | P3 |
| `SEC-008` | device verification and key recovery | P3 |
| `SEC-009` | abuse prevention, anti-spam and rate limits | P1 |
| `SEC-010` | media safety, malware and unsafe link policy | P1 |
| `SEC-011` | audit events and anomaly response | P2 |
| `SEC-012` | data export, account deletion, privacy settings | P2 |
| `SEC-013` | security monitoring and vulnerability disclosures | P1 |

### BOTS & AUTOMATION

| ID | Capability | Target |
|---|---|---|
| `BOT-001` | bot identity, bot creation and credentials | P3 |
| `BOT-002` | bot commands and updates/webhooks | P3 |
| `BOT-003` | bot permissions/scopes per conversation | P3 |
| `BOT-004` | interactive buttons and inline interaction | P3 |
| `BOT-005` | workflow triggers and automation | P3 |
| `BOT-006` | integration auth/rate limits and audit | P3 |
| `BOT-007` | bot-to-bot and AI assistants | P3 |
| `BOT-008` | business auto-replies and greeting bots | P3 |

### MINI APPS & EXTENSIBILITY

| ID | Capability | Target |
|---|---|---|
| `APP-001` | embedded mini-app environment | P4 |
| `APP-002` | app SDK and interface contracts | P4 |
| `APP-003` | mini-app auth and consent | P4 |
| `APP-004` | sandbox and permission scopes | P4 |
| `APP-005` | web app callbacks and UI integration | P4 |
| `APP-006` | app catalog and discovery | P4 |
| `APP-007` | developer portal and API versioning | P4 |
| `APP-008` | business system integrations and outgoing webhooks | P4 |

### STORIES & SOCIAL

| ID | Capability | Target |
|---|---|---|
| `STORY-001` | story capture, publish, expiry | P4 |
| `STORY-002` | audience/privacy and close friends | P4 |
| `STORY-003` | story viewer/react/reply | P4 |
| `STORY-004` | story pinning/highlights/albums | P4 |
| `STORY-005` | story editing and repost | P4 |
| `STORY-006` | channel/group story support | P4 |
| `STORY-007` | live stories and interactive broadcasts | P4 |

### UI/UX & ACCESSIBILITY

| ID | Capability | Target |
|---|---|---|
| `UX-001` | responsive layout and viewport behavior | P1 |
| `UX-002` | desktop navigation and keyboard shortcuts | P2 |
| `UX-003` | themes and dark/light modes | P1 |
| `UX-004` | localization, IME, RTL support | P2 |
| `UX-005` | screen-reader labels and accessibility | P1 |
| `UX-006` | virtualized long lists and smooth scrolling | P1 |
| `UX-007` | loading, empty, error and retry states | P1 |
| `UX-008` | drag/drop, paste and attachments | P1 |
| `UX-009` | context menus, selection and bulk actions | P1 |
| `UX-010` | animations and reduced-motion | P2 |
| `UX-011` | custom chat appearance, backgrounds | P3 |
| `UX-012` | deep links and share targets | P1 |

### ENTERPRISE ADMIN

| ID | Capability | Target |
|---|---|---|
| `ENT-001` | organization admin bootstrap | P1 |
| `ENT-002` | roles, policies and member lifecycle | P1 |
| `ENT-003` | SSO, SCIM and directory sync | P3 |
| `ENT-004` | audit log and export | P3 |
| `ENT-005` | retention, data residency and compliance | P3 |
| `ENT-006` | tenant isolation and policy enforcement | P1 |
| `ENT-007` | backup/restore administration | P1 |
| `ENT-008` | white-label branding and domain | P3 |
| `ENT-009` | features, entitlements and license handling | P3 |
| `ENT-010` | admin analytics, support diagnostics | P1 |
| `ENT-011` | air-gap/offline operations | P3 |
| `ENT-012` | permission change review and approval | P1 |

### PLATFORM CLIENTS

| ID | Capability | Target |
|---|---|---|
| `CLI-001` | Web: React/TypeScript (WASM), typed browser binding and shared Rust sync | P1 |
| `CLI-002` | desktop application and installers | P1 |
| `CLI-003` | shared Rust client SDK and FFI/WASM | P1 |
| `CLI-004` | durable local cache/migrations (native SQLite; browser adapter validated in P0) | P1 |
| `CLI-005` | Android native application | P3 |
| `CLI-006` | iOS native application | P3 |
| `CLI-007` | push and background sync restrictions | P3 |
| `CLI-008` | desktop OS integration and updates | P1 |
| `CLI-009` | client version negotiation and upgrade | P1 |
| `CLI-010` | multi-device compatibility test matrix | P1 |
| `CLI-011` | offline UX and conflict feedback | P1 |

### INFRASTRUCTURE & OPERATIONS

| ID | Capability | Target |
|---|---|---|
| `OPS-001` | single-tenant Docker/Podman deployment | P1 |
| `OPS-002` | PostgreSQL schema migrations and rollback | P1 |
| `OPS-003` | object storage and disaster recovery | P1 |
| `OPS-004` | health endpoints, metrics and traces | P1 |
| `OPS-005` | logging privacy and observability | P1 |
| `OPS-006` | automated backup/restore verification | P1 |
| `OPS-007` | upgrade compatibility and rollback | P1 |
| `OPS-008` | CI, signed artifacts and SBOM | P1 |
| `OPS-009` | performance tests, load and soak | P1 |
| `OPS-010` | HA/redundancy and failover | P3 |
| `OPS-011` | secrets, environment and TLS automation | P1 |
| `OPS-012` | air-gapped install and update packages | P3 |
| `OPS-013` | operator runbooks and incident response | P1 |

### BUSINESS, PREMIUM, MONETIZATION

| ID | Capability | Target |
|---|---|---|
| `BIZ-001` | business profile/hours/location | P4 |
| `BIZ-002` | greetings, quick replies and away messages | P4 |
| `BIZ-003` | business chat routing and customer support | P4 |
| `BIZ-004` | premium feature entitlements | P4 |
| `BIZ-005` | digital goods, gifts, virtual currency | P4 |
| `BIZ-006` | channel/creator subscriptions and revenue | P4 |
| `BIZ-007` | payments, billing, invoicing integration | P4 |
| `BIZ-008` | white-label commercial licensing | P4 |
| `BIZ-009` | usage/quota-based licensing and reporting | P4 |

### COMPLIANCE & PRODUCT DELIVERY

| ID | Capability | Target |
|---|---|---|
| `CMP-001` | customer security questionnaire and DPA review | P3 |
| `CMP-002` | third-party licenses and attribution | P3 |
| `CMP-003` | backup/restore and migration SLA | P3 |
| `CMP-004` | support tiers, incident notification policy | P3 |
| `CMP-005` | accessibility acceptance and remediation | P3 |
| `CMP-006` | performance/cost benchmarks and SLOs | P3 |
| `CMP-007` | releases, deprecation and compatibility support | P3 |
| `CMP-008` | trial/pilot onboarding and documentation | P3 |

## Reconciling the discovery PDF with this registry

The 46-page *Xây dựng nền tảng chat Rust* records successive design discussions. Pages 18–20 use early example IDs and pages 26–30 describe an intermediate inventory. Page 43 identifies the four-file baseline. Match by behavior before assigning IDs; even identical-looking early IDs may mean something different. Pages 38–41 include a teaching-app prompt used as a writing example. REM's own scope and phase gates govern delivery.

| PDF topic | Stable destination and disposition |
|---|---|
| Offline outbox, lost ACK, replay and multi-device catch-up (pp. 13–19) | SYN-002 through SYN-010 and DM-002. Verify observable state after restart and reconnect on both native and WASM clients. |
| Threads, ephemeral group messages, Communities (pp. 18, 27) | Investigate under GRP-009, DM-011 and the GROUPS domain respectively. Distinguish threads from forum topics and group expiry from private-chat timers. Record source/version, roles and policy. Allocate a new ID after research if a behavior has independent scope. |
| Buttons, rich text, tags, welcomes, AI bots (pp. 27–29) | BOT-004, DM-001, GRP-013 and BOT-007. Record distinctions between user messages and bot interactions. |
| Public discovery, paid posts, gifts and Stars (pp. 28–30) | ORG-010 and CHN-002 cover discovery; CHN-009 covers the channel surface. Broad public discovery and financial execution require P4 product review under BIZ-005/006/007. P2 can research or deliver policy-scoped discovery without enabling a public network or payments. |
| Federation (p. 20), Telegram compatibility and bridging (pp. 3–11) | Federation remains a research candidate outside the committed roadmap. The PO chose an independent backend. A bridge requires a separate product decision. |
| Deployment and commercial delivery (pp. 23–30) | ENT, OPS, CMP and BIZ own single-tenant installation, restore, upgrades, audit, licensing and pilots. Record phase dependencies such as mobile push delivery on an available mobile client. |

For CLI-001/003/004, tie one P1 browser journey to the WASM binding, local persistence and compatible events. For OPS-008, link CI selection rules, required gate outcomes and retention evidence from the harness. Track engineering controls against existing IDs without inflating the product feature count.

## Required cross-cutting behavior matrix (apply to EVERY relevant feature)

| Dimension | Minimum investigation |
|---|---|
| Identity/authorization | Who can do/see it, membership changes, admin policy, guest/bot access, blocked users |
| Online/offline | Pending, retry, failed, reconnect, device switching, conflicts, duplicate commands |
| Realtime/state | Ordering, event versions, race conditions, replay, read synchronization, cross-node fan-out |
| Multi-platform UX | Web, desktop, mobile, accessibility, keyboard, IME, low bandwidth, touch, small viewport |
| Error & resilience | Timeouts, partial upload, network disconnect, server restarts, corrupt local cache |
| Security/privacy | Threat cases, abuse, logging redaction, file access, retention, identity disclosure |
| Operations | Migration, observability, backup, compatibility, supportability and cost |
| Verification | Requirement IDs, deterministic tests, approved screenshots or traces, known limitations |

### Sample decomposition: DM-003 reply/edit/revisions

- `DM-003-R01`: Reply to an authorized existing message; validate deleted and unavailable targets.
- `DM-003-R02`: Edit permitted message; define actor, time and policy restrictions.
- `DM-003-R03`: Versioned edit conflicts: reject/rebase according to approved policy, never silent lost update.
- `DM-003-R04`: Propagate edit to all authorized devices and update caches/search/notifications.
- `DM-003-R05`: Retry same client operation safely after lost ACK; no duplicate edits.
- `DM-003-R06`: Audit and retention semantics; record enterprise deviations and erasure requirements.
- `DM-003-R07`: Accessibility and compact/responsive UI behavior.

### Release completeness rule

No feature may be called `VERIFIED` solely because tests pass or UI resembles Telegram. Require a reviewed feature contract, source reference or explicitly independent design, code/tests linked to immutable revision, passing relevant quality gates and acknowledged limitations. `UNKNOWN` is legitimate progress, not failure.

## Official reference entry points

- https://telegram.org/faq
- https://telegram.org/evolution
- https://core.telegram.org/bots/features
- https://github.com/telegramdesktop/tdesktop

**Registry size:** 207 proposed capability IDs across 19 domains. The agent MUST refine this baseline and discover missing/misclassified capabilities rather than treating the count as proof of completeness.
