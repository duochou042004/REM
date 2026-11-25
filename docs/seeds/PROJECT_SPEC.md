# RUST ENTERPRISE MESSENGER — PROJECT SPECIFICATION

**Version:** 1.1 baseline | **Date:** 2026-11-24 | **Status:** Product intent locked; Hexagonal Architecture and Web: React/TypeScript (WASM) confirmed; other stack defaults subject to P0 validation.

> **Read with:** [FEATURE_REGISTRY.md](FEATURE_REGISTRY.md), [AGENT_HARNESS.md](AGENT_HARNESS.md), and [START_PROMPT.md](START_PROMPT.md). These four documents are the initial handoff package. They are NOT a substitute for evidence-based architecture research. The planning agent owns the subsequent document structure, not this package.

## 1. Purpose and mission

Build a **commercializable, independent, self-hosted, Rust-first enterprise messaging platform** with broad Telegram-inspired feature parity. Telegram is a **product/behavior reference**, never our backend, dependency, network, identity provider, protocol, or brand. We own our API, sync rules, data and product. Intended customers: companies requiring private messaging, data control, deployment in customer infrastructure, adaptable policy, and optional white-label licensing.

Broad parity means **inventory comprehensively, implement incrementally**; not a claim that all Telegram behavior is known or that an AI can guarantee exact parity. Preserve separate measures of (1) reference coverage, (2) behavior implementation, (3) independently verified correctness, (4) operational/commercial readiness. Unknown behavior MUST remain UNKNOWN.

**Identity:** working title *Rust Enterprise Messenger (REM)*; final brand TBD. No copying Telegram trademarks, protected assets or marketing identity. Reuse code ONLY after license and dependency compliance review. Do not impersonate or claim official Telegram compatibility. No MTProto compatibility, Telegram-account login, Telegram Cloud use, server emulation or federation required. Telegram bridging is a future independent decision, not an implicit requirement.

## 2. Product boundaries

**In scope:** direct chat, groups, channels, topics, media, search, local/offline sync, multiple sessions/devices, privacy, notifications, native-quality web/desktop/mobile, admin control, observability, secure self-hosting, extensibility, and later advanced communication and optional enterprise/commercial modules.

**Not assumed:** Telegram protocol-level compatibility; a complete implementation of all Telegram product details by MVP; public social network operations; global discovery by default; crypto token/gift economy; third-party platform integration by default; a mandatory public SaaS; automatic cloud license checks; AI-generated claims of security or parity.

**Enterprise policy deviations:** Whenever reference behavior conflicts with retention, compliance, administrative access, security or privacy, record a deliberate `ENTERPRISE_DEVIATION` with user-facing effect, rationale and tests. Deletion semantics, legal hold and E2EE are classic examples. No silent divergence.

**Tenancy:** start with single-tenant customer-owned instances and database/storage isolation, with organization-scoped data model. Multi-tenant SaaS is a separately approved architecture and product decision.

**Security default:** TLS in transit and audited encryption-at-rest strategy; server-managed data access for initial MVP. **Do NOT advertise E2EE** until approved protocol implementation, independent reviews, device/key lifecycle and interoperable recovery are completed. Consider standard cryptographic protocols (e.g. MLS) but do not invent cryptography.

## 3. Personas, core journeys, and release quality

Personas: Employee, group owner/moderator, organization admin, IT operator, compliance/security admin, integration developer, and support/operator with strictly limited privileged access. Guest/bot/public identities are opt-in policies.

Critical journeys: sign in and revoke a device; create direct/group chats; send/retry/edit/delete; invite/leave/remove members; attach/download file; reconnect after network loss; keep multiple devices consistent; search within permissions; backup/restore; upgrade/rollback; diagnose incidents without exposing message content in logs.

**Definition of production-ready:** not simply a matching UI or passing tests. Must pass authorization/security review, reliability and recovery scenarios, accessibility baseline, performance against declared workloads, threat mitigation, documentation, migrations and release/rollback checks. Performance SLOs must be derived from measured hardware and representative workload, not invented.

## 4. Hexagonal Architecture (Ports and Adapters)

**Confirmed by the PO:** Hexagonal Architecture governs dependency direction. **Web: React/TypeScript (WASM)**. React renders the interface, TypeScript calls a versioned browser binding, and the shared Rust client SDK compiles to WebAssembly for sync, replay and pending operations. The modular monolith remains the proposed initial deployment shape. A hexagon can live inside one process.

| Boundary | REM responsibility | P0 acceptance evidence |
|---|---|---|
| Domain | Conversation membership, message revision and ordering rules | Domain tests run without a web server, database or UI. |
| Application | Use cases such as SendMessage and CatchUp. Own inbound commands and outbound interfaces for transactions, authorization data, time and event delivery. | A test driver invokes the use case with an in-memory port implementation. |
| Driving adapters | Axum HTTP/WebSocket handlers and worker entry points decode versioned wire DTOs, call a use case and translate the result. | Contract fixtures cover a valid command, denial, retry and version mismatch. |
| Driven adapters | SQLx/PostgreSQL implements the message/event/outbox transaction. Redis handles ephemeral presence. S3-compatible storage handles attachment bytes. | Real-adapter tests cover rollback, concurrent retries and failure after commit. |
| Composition root | An executable wires adapters to ports. Core code imports domain types and contracts. Frameworks and drivers stay outside. | Review the dependency graph for inward dependencies and cycles before accepting the slice. |

**SendMessage example.** The driving adapter authenticates the transport and passes actor, device, conversation and operation ID to the application. The use case enforces membership and idempotency inside a consistent transaction boundary. A single persistence port commits the canonical message, sequence, event and outbox entry. Only then can the adapter return success. The dispatcher can retry independently. Document how concurrent revocation and duplicate commands are serialized.

**Client boundary.** Keep the Rust reducer independent of React, browser APIs and native storage. The web adapter maps commands, typed errors and state updates across the WASM boundary. Native SQLite is the proposed desktop/mobile store. P0 compares browser persistence (e.g. IndexedDB or SQLite/WASM on OPFS) using a cold reload, queued send, reconnect and lost ACK on supported browsers. Record bundle/load cost, storage availability and recovery if local storage is cleared. The browser storage choice, binding generator and worker placement are ADR decisions.

**Remaining defaults to validate.** Pinned stable Rust/Cargo workspace, Axum/Tokio, SQLx/PostgreSQL, HTTPS/WebSocket, Tauri with shared web UI, Kotlin/Swift with UniFFI after P1, Docker/Podman, OpenTelemetry. Evaluate GPUI by desktop benchmark. Introduce a broker or services only when workload or failure-isolation evidence warrants it. Define ports around behavior and transactional boundaries. A port does not require a crate per interface.

Design reference: [Cockburn's original Ports and Adapters article](https://alistair.cockburn.us/hexagonal-architecture).

### 4.1 Messaging and synchronization contract

**Core invariant:** Persist message/event + outbox atomically before success ACK; idempotency key per actor/device/operation; monotonically increasing sequence inside a conversation; client reconciles local pending operations to canonical server messages; concurrent modification uses clear version/authorization semantics.

- Each device has stable identity, durable platform-local state, pending outbox and synchronization cursor(s).
- Reconnect: authenticate, send cursor, receive authorized events or safe snapshot/reset path; detect gaps and retention expiration; replay idempotently.
- WebSocket is a notification/transport path, not the source of truth. Network delivery is at-least-once; business effects are idempotent. Explicitly handle duplicates, out-of-order events, retries, missed ACKs, revocations, cursor expiration and server crash after DB commit.
- Membership/ACL decisions are server authoritative. Design revocation and historical message visibility with explicit policy; a removed member must not gain future events by guessing a cursor.
- Message edits, deletes, read positions, replies, forwards, attachments, search indexing, notifications and retention are independently specified and testable.
- Event log retention, event schema evolution, indexing and storage growth are P0 design questions; don't assume indefinite append-only storage.

### 4.2 Security architecture

Define trust boundaries, data classification, least privilege, abuse controls, authentication and MFA/SSO options, session revocation, quotas and rate limits, SSRF-safe media ingestion, malware scanning policy, secure file access, signed URLs, secrets handling, PII-safe telemetry, backup encryption, cross-organization isolation, operational RBAC, audit integrity and vulnerability response. Use OWASP ASVS and applicable current guidance as requirements inputs, not automatic compliance certification.

### 4.3 Commercial architecture

Single-tenant Docker/Podman deployment packages, upgrade and rollback, backup/restore rehearsal, observability, white-label boundaries, feature entitlements, version compatibility, supply-chain/security updates and operator docs. Offline/air-gapped licensing should be possible; never require always-online license verification without explicit product decision. Customer pilots and product-market validation should start well before implementing P4 ecosystem features.

## 5. Domain and model sketch — not final SQL schema

Entities/aggregates: Organization, User, Membership, Device, Session, Conversation, ConversationMembership, Message, MessageRevision, ConversationEvent, ReadPosition, Attachment, NotificationPreference, RetentionPolicy, AuditEvent, OutboxEvent, BotIdentity, Integration, License/Entitlement. Validate ownership, cardinality and lifecycles. Pin down ordered messages and consistency under concurrent sends before finalizing schema. Do not overbuild table-per-concept without workload/queries.

## 6. Phase strategy and explicit gates

| Phase | Objective | Exit evidence |
|---|---|---|
| **P0** | Behavioral research, requirements, P1 contracts, domain/protocol/sync/security ADRs, key prototypes | Unresolved risks catalogued; P1 acceptance criteria and migration-safe design; no product features coded |
| **P1** | Deployable messaging foundation: identity, DM/group, message lifecycle, offline/reconnect, web+desktop, files, basic admin, backup | Durable/idempotent sync, basic secure self-hosted deployment and restore tested |
| **P2** | Telegram core UX: permissions, topics, channels, reactions, search, folders, notifications, more media | Behavioral comparison plus multi-device regression across supported browsers/desktop |
| **P3** | Enterprise and advanced communication: mobile, calls, SSO, audit, retention, bots, HA, white-label | Security/ops review, failure recovery and pilot readiness; E2EE only after separate approval |
| **P4** | Optional ecosystem: stories, mini apps, advanced automation, creator-style features and monetization | Product evidence and independent scope/legal/security gates |

An earlier partial commercial pilot is possible only with disclosed limitations and the required security/recovery gates. P0 may run **isolated throwaway prototypes** to test architecture; do not start production feature implementation until the P0 gate is passed.

### P0 exit review

The lead records PASS, PENDING or BLOCKED, owner and Markdown evidence for each item: (1) scope/non-goals, (2) registry IDs and ownership, (3) acceptance criteria for each P1 capability, (4) reviewed domain invariants, (5) versioned API/event contracts, (6) offline replay and idempotency, (7) threat model and authorization matrix, (8) risk-bearing ADRs and any necessary prototype evidence, (9) QA/CI and release gates, (10) dependency-ordered packets, (11) restart packet and evidence index. An open risk includes an impact, owner and resolution criterion. A planned prototype counts only as a plan; any decision depending on its result stays open. Record the PO's implementation authorization separately.

## 7. What the planning agent must produce (autonomous document design)

The agent MUST inspect these three source documents plus the startup prompt; inspect the repository and credible external references; then **decide its own maintainable doc layout**. Do NOT blindly instantiate a giant preselected docs tree. Generate what is needed for: scope and product requirements; feature traceability and behavioral references; acceptance criteria; architecture/ADRs; domain/data/API/event/sync; UI IA/UX/accessibility; security and privacy; engineering/testing/CI; release/operations; commercial readiness; decision/risk logs and agent governance. Keep authoritative content in one place and link from elsewhere; avoid duplicate specs.

Suggested P0 research queue: canonical Telegram feature documentation and official clients; independent protocol/server research only for insight; Rust UI feasibility; high-risk sync proof; self-host operator realities; license/IP review; customer discovery. Record exact source URL, retrieval/version date, platform/version, evidence strength and uncertainty; do not treat a competitor's private implementation as observable fact.

## 8. Reference materials (research seeds, not binding dependencies)

- Telegram FAQ: https://telegram.org/faq
- Telegram evolution/change history: https://telegram.org/evolution
- Telegram Bot Features: https://core.telegram.org/bots/features
- Telegram Desktop source: https://github.com/telegramdesktop/tdesktop
- Matrix specifications: https://spec.matrix.org/
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- Rust rewrite/migration reference: https://github.com/erkamyaman/rust-anything

### rust-anything positioning

`rust-anything` focuses on converting an **existing executable/codebase** to Rust by recording real behavior, porting units, replay/diff and gating. This is NOT a full Telegram reconstruction engine and cannot discover unobservable backend behavior. Research the README, current license, compatibility, trust/supply-chain implications and integration instructions before optionally installing its CLI, skill or MCP. Prefer borrowing its **record → compare → gate** methodology for our own reference testing. Do not run record/replay against production credentials or live business data: recorded cases can execute side-effecting operations.

## 9. Decision and authority rules

Current confirmed intent: independent Telegram-inspired product; broad inventory, phased implementation; Rust-first; commercial self-hosted orientation; minimal seed-document bundle; Claude chooses downstream docs/skills/harness; efficient QA; evidence-based no-compaction handoff. The two confirmed decisions in §4 are binding. Record remaining implementation defaults and their evidence in ADRs. Where options are reversible, document chosen default and proceed. Escalate product trade-offs, meaningful scope improvements and decisions outside delegated authority under the harness. Never claim deployment, security or product parity without evidence.
