# REM — Architecture: hexagon, ports, workspace and domain model

**Owner:** Architecture · **Status:** Specified (P0 r1, 2026-11-24), review recorded in [evidence.md](../plan/evidence.md) · **Binding inputs:** [PROJECT_SPEC §4](../../PROJECT_SPEC.md#4-hexagonal-architecture-ports-and-adapters) (Hexagonal Architecture and Web: React/TypeScript (WASM) are PO-confirmed). Decisions: [adr.md](adr.md). Sync semantics: [sync.md](sync.md). Wire contracts: [contracts.md](contracts.md).

## 1. Shape

A **modular monolith** (ADR-0001): one server executable built from a Rust workspace, one PostgreSQL database, one S3-compatible bucket, and clients that share one Rust SDK. Each side is a hexagon. Dependencies point inward: adapters → application → domain. Only the composition root sees everything.

```text
 driving adapters                 application (use cases + ports)              driven adapters
 ───────────────                  ─────────────────────────────                ───────────────
 Axum HTTP  ─┐                    SendMessage, EditMessage, DeleteMessage,     ┌─ PostgreSQL (SQLx): ConversationLog,
 Axum WS    ─┼─► wire DTO ──►     CatchUp, ManageMembership, Login,       ──►  │   IdentityStore, OutboxSource, SearchIndex
 Workers    ─┘   (rem-protocol)   RevokeSession, Upload/Download, Search       ├─ S3-compatible: BlobStore
 (outbox dispatcher, jobs)                       │                             ├─ in-process: Presence, Fanout (P1)
                                         domain (rem-domain)                   └─ system: Clock, Ids, PasswordHasher
                                   membership, revisions, ordering rules

 client: React UI ─► TS binding (wasm-bindgen) ─► rem-client-core (reducer, outbox, sync) ─► LocalStore + Transport ports
                                                                     ├─ browser: IndexedDB or SQLite-WASM/OPFS (ADR-0003), fetch/WebSocket
                                                                     └─ native:  SQLite, tokio transport (desktop now, mobile P3)
```

## 2. Workspace layout (created by packet P1-00, not before)

| Crate / app | Role | May depend on | Must not depend on |
|---|---|---|---|
| `crates/rem-domain` | Server domain: IDs, Conversation, Membership intervals, Message/Revision, sequence and permission rules. Pure. | `std`, small pure crates (`thiserror`, `uuid`) | tokio, sqlx, axum, serde_json, wasm-bindgen, any IO |
| `crates/rem-protocol` | Versioned wire DTOs and event schemas shared by server and client (serde). | `serde`, `uuid` | rem-domain (wire stays stable while the domain evolves), IO |
| `crates/rem-server-app` | Use cases plus **driven port traits**, and transaction and authorization boundaries. | rem-domain | adapters, frameworks, rem-protocol |
| `crates/rem-server-adapters` | Modules `pg` (SQLx), `http` (Axum HTTP/WS, DTO mapping), `blob` (S3), `presence` (in-process). | rem-server-app, rem-domain, rem-protocol, frameworks | — |
| `crates/rem-server` | Binary and **composition root**: config, wiring, workers, migrations. | everything server-side | — |
| `crates/rem-client-core` | Client reducer, pending outbox, sync state machine, plus **client ports** (`LocalStore`, `Transport`, `Clock`). Executor-agnostic and `wasm32`-clean. | rem-protocol, `futures` | tokio runtime, threads, web-sys, rusqlite, UI |
| `crates/rem-client-native` | SQLite `LocalStore` and tokio `Transport`. Native composition. | rem-client-core | — |
| `crates/rem-client-wasm` | wasm-bindgen binding (typed TS API), browser `LocalStore` and `Transport`, worker entry. | rem-client-core | — |
| `crates/rem-test-support` | In-memory port implementations, fixture builders, property generators, fault-injecting transport and clock. | app/core crates | production use |
| `apps/web` | React + TypeScript UI. It consumes only the generated binding package. | rem-client-wasm package | direct HTTP/WS calls bypassing the SDK |
| `apps/desktop` | Tauri shell reusing `apps/web` (ADR-0007). | apps/web, rem-client-native or the WASM SDK (ADR-0007 decides) | — |

**Why so few crates:** crate boundaries exist where Cargo must *enforce* direction: domain, application, adapters and root, plus client core and its two platforms. A port is a trait, not a crate ([PROJECT_SPEC §4](../../PROJECT_SPEC.md#4-hexagonal-architecture-ports-and-adapters)). Adapters split into crates only when compile time or ownership justifies it (measure first).

**Dependency check (P1-00 acceptance):** a CI test reads `cargo metadata --locked --format-version 1` and fails on (1) any edge from the table's "must not" column, (2) any cycle, and (3) an adapter crate depended on by a core crate. Design: [testing-ci.md §4](../engineering/testing-ci.md#4-ci-design).

## 3. Ports (versioned contracts)

How ports are versioned: in-process Rust traits are versioned with the workspace revision. A breaking change to a trait that crosses a crate boundary needs an ADR note and lands with all its implementations in one change. **Out-of-process and cross-language boundaries carry explicit version numbers:** wire protocol `v1`, a `schema_version` per event type, `BINDING_VERSION` for the WASM API, the local-store schema version, and the server migration version ([contracts.md §1](contracts.md#1-versioned-boundaries)). When two versions must coexist, the new one is a new module (`v2`) that runs alongside the old one until removal.

### 3.1 Server driven ports (owned by `rem-server-app`)

| Port | Behavior and transactional boundary | P1 adapter | Real-adapter tests (P0 acceptance: rollback, concurrent retries, failure after commit) |
|---|---|---|---|
| `ConversationLog` | `append(cmd) -> Appended \| Duplicate \| Denied \| Conflict`. **One transaction:** lock the conversation row, check membership and permission, check idempotency, assign the next `seq`, write the message or revision, the event, the idempotency record and the outbox row. Also covers membership changes, so sends and removals serialize ([sync.md §3](sync.md#3-server-write-path-durable-ack)). | `pg` | concurrent N writers → contiguous seq; crash before/after commit; duplicate op ids; send racing a removal |
| `EventReader` | `events_after(conversation, seq, actor) -> page` authorized by membership intervals. `user_events_after(user_cursor)` for the user stream. | `pg` | forged cursor after removal returns nothing; retention floor → `cursor_expired` |
| `IdentityStore` | Users, credentials, sessions, devices, invites. Atomic invite redemption. Session revocation commit. | `pg` | concurrent redemption never exceeds use limit |
| `OutboxSource` | `claim(batch)` with `FOR UPDATE SKIP LOCKED`, `mark_dispatched`. At-least-once. | `pg` | dispatcher crash → redelivery |
| `Fanout` | Push sequenced notifications to connected sockets of authorized users. Best-effort, not durable. | in-process | slow consumer is bounded and dropped to catch-up |
| `Presence` | Ephemeral typing and online state, with TTL. | in-process (Redis when multi-node, SYN-012) | TTL expiry, rate cap |
| `BlobStore` | Put, finalize, signed GET with TTL, delete. Bytes never pass through the domain. | S3-compatible | failed upload leaves pending row collectable |
| `SearchIndex` | Index and unindex message bodies inside the `ConversationLog` transaction (P1: PostgreSQL FTS); authorized query. | `pg` | deleted message not returned; non-member gets nothing |
| `AuditSink` | Append audit events (actor, action, target, policy version) inside the same transaction as the change. | `pg` | rollback leaves no audit row |
| `Clock`, `IdGenerator`, `PasswordHasher`, `RateLimiter`, `MalwareScanner` | System capabilities, injectable for tests. | system / Argon2id / in-process / no-op | fixed clocks and ids in tests |

### 3.2 Driving ports (use cases)

These are the commands and queries listed in §1, each taking an `Actor { user_id, device_id, session_id }` that the driving adapter has authenticated, plus `operation_id` for mutations. P0 acceptance per adapter: contract fixtures for a valid command, a denial, a retry and a version mismatch ([contracts.md §5](contracts.md#5-contract-fixtures-p0-acceptance)).

### 3.3 Client ports (owned by `rem-client-core`)

| Port | Behavior | Native | Browser |
|---|---|---|---|
| `LocalStore` | Transactional: pending outbox, cursors, cached projection, local schema version. `persist_pending` must be durable before the UI shows pending. | SQLite | ADR-0003 (IndexedDB vs SQLite-WASM on OPFS) |
| `Transport` | HTTPS requests plus a WebSocket notification stream. Reports connectivity. | tokio + reqwest/tungstenite (ADR-0004 confirms) | fetch + WebSocket via web-sys |
| `Clock` | Monotonic time for timeouts, wall time for display only. | system | `performance.now` / `Date` |

The UI talks to the SDK only through **commands** (send, edit, delete, mark read…) and **state subscriptions** (projection diffs). Typed errors cross the WASM boundary as a discriminated union ([contracts.md §4](contracts.md#4-error-model)).

## 4. Domain model (sketch, validated against invariants, not a final schema)

| Aggregate / entity | Owns | Key invariants (tests in [backlog](../plan/backlog.md)) |
|---|---|---|
| Organization | policies, roles | exactly one per instance in P1 (SEC-004) |
| User, Device, Session | credentials, device identity, session tokens | a revoked session never authorizes a command whose transaction starts after the revocation commit |
| Invite | token hash, expiry, uses | redemptions ≤ max_uses under concurrency |
| **Conversation** (aggregate root, row lock) | `last_seq`, kind (dm/group/self), settings, history visibility | seq is contiguous; a DM pair is unique; at all times exactly one owner per group |
| ConversationMembership | intervals `[joined_seq, left_seq)`, role, permission overrides | a member reads events only inside their intervals, under the history-visibility rule |
| Message, MessageRevision | body, entities, attachments, revision n | revision increments by 1; an edit is accepted only from the author in the window, with `expected_revision` |
| ConversationEvent | `(conversation_id, seq)`, type, `schema_version`, payload | append-only within the retention window; unique `(conversation_id, seq)` |
| UserEvent (user stream) | `(user_id, user_seq)`: membership added/removed, read positions, prefs, sessions | per-user contiguous; drives multi-device state |
| ReadPosition | max seq per user × conversation | monotonic max |
| Attachment | blob key, size, type, owner, state | referenced only when finalized and owned by the sender |
| IdempotencyRecord | `(actor_user, device, operation_id)` → result hash | unique; TTL ≥ `IDEMPOTENCY_TTL` |
| OutboxEvent | pending notification per event | written in the same transaction as the event |
| AuditEvent | actor, action, target, before/after policy version | written in the same transaction as the change |
| NotificationPreference, RetentionPolicy, License/Entitlement, BotIdentity, Integration | — | P1 has only NotificationPreference. The others are later-phase design questions, kept out of the P1 schema. |

**Ordering decision:** the conversation **event** sequence orders every conversation state change (messages, edits, deletes, pins, membership, settings). Account-level state (read positions, conversation-list prefs, membership notices, sessions) goes on a per-user stream. This avoids fan-out-on-write per message: catch-up is per conversation, which suits enterprise group sizes. Validation is in PT-02 ([backlog](../plan/backlog.md#1-p0-packets)).

**Storage growth:** events are about messages × (1 + edits + deletes) plus membership churn. The event log is retained for `EVENT_RETENTION` (*policy*); older cursors take the snapshot path. Message rows follow message retention. PT-02 measures bytes per message and index cost before the schema is final.
