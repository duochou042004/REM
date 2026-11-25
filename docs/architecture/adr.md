# REM — Architecture decision records

**Owner:** Architecture (lead approves) · One section per ADR. The status is `Accepted` (binding), `Proposed` (a reversible default the lead adopted, to be confirmed by its validation) or `Open` (awaiting a prototype or a PO decision). A superseded ADR stays here, marked `Superseded by ADR-NNNN`. PO decisions are in [decisions.md](../plan/decisions.md). Prototype packets PT-xx are in [backlog.md](../plan/backlog.md#1-p0-packets).

| ADR | Topic | Status | Validation |
|---|---|---|---|
| [0001](#adr-0001-hexagonal-modular-monolith) | Hexagonal modular monolith | Accepted (hexagon, by the PO) / Proposed (monolith) | Dependency check in P1-00 |
| [0002](#adr-0002-web-client-reacttypescript-with-rust-wasm-sdk) | Web client: React/TS + Rust WASM SDK | Accepted (by the PO); binding generator and worker placement Open | PT-01 |
| [0003](#adr-0003-browser-persistence) | Browser persistence | Open | PT-01 |
| [0004](#adr-0004-server-runtime-and-persistence) | Axum/Tokio, SQLx/PostgreSQL, toolchain | Proposed | P1-00 version pin; PT-02 |
| [0005](#adr-0005-conversation-sequencing-outbox-and-durable-ack) | Sequencing, outbox, durable ACK | **Accepted** (PT-02, [E-17](../plan/evidence.md#e-17-p0-pt-02-postgresql-sequencing-spike)) | — |
| [0006](#adr-0006-wire-format-and-versioning) | Wire format and versioning | Proposed | P1-04 fixtures |
| [0007](#adr-0007-desktop-shell) | Desktop shell (Tauri; GPUI benchmark) | Proposed | PT-04 |
| [0008](#adr-0008-deployment-and-tenancy) | Single-tenant Podman/Docker deployment | Proposed | P1-14 |
| [0009](#adr-0009-encryption-posture) | Encryption posture; no E2EE claim | Accepted (spec default) | Release checklist |
| [0010](#adr-0010-p1-authentication-and-sessions) | P1 authentication and sessions | Proposed | P1-03 security review |
| [0011](#adr-0011-ephemeral-presence-in-p1) | In-process presence in P1 (Redis deferred) | Proposed | PT-02 load note; SYN-012 |
| [0012](#adr-0012-media-storage-and-delivery) | Media storage and delivery | Proposed; store product Open | P1-11; license review |
| [0013](#adr-0013-p1-search) | P1 search on PostgreSQL FTS | Proposed | P1-12 |
| [0014](#adr-0014-ci-host-and-selection) | CI host and selection model | Proposed; host GitHub, private repository (PO-Q2 = A); branch protection PO-Q13 | PT-03 |

## ADR-0001 Hexagonal modular monolith

**Context:** The PO confirmed Hexagonal Architecture (PROJECT_SPEC §4). Workload is single-tenant, at most thousands of users per instance (PDF pp. 12–13), with no evidence yet for services or a broker. **Decision:** one server binary built from the hexagonal workspace in [architecture.md §2](architecture.md#2-workspace-layout-created-by-packet-p1-00-not-before), with ports as traits and no message broker. **Consequences:** simple to operate and back up. Scale is a single node until SYN-012/OPS-010. Splitting later is possible along the use-case and port seams. **Revisit when** measured load or failure isolation requires it (OPS-009 evidence).

## ADR-0002 Web client: React/TypeScript with Rust WASM SDK

**Accepted by the PO:** React renders the UI and TypeScript calls a versioned binding. `rem-client-core` is compiled to `wasm32-unknown-unknown` and runs sync, replay and the pending outbox. **Open sub-decisions:** (a) binding generator: wasm-bindgen + wasm-pack, versus wasm-bindgen with a TS-type generator (for example tsify), versus a hand-written TS facade over a minimal ABI. Criteria: typed errors as a discriminated union, async support, bundle size, build reproducibility. (b) Placement: the SDK in a dedicated worker (UI thread stays free; a store like OPFS sync access needs a worker) versus the main thread. **Validation:** PT-01 measures bundle and load cost, type quality and the four persistence scenarios. **Tooling gap:** `wasm-pack`, `wasm-bindgen-cli`, the `wasm32-unknown-unknown` target and Playwright are not installed ([bootstrap.md §1](../engineering/bootstrap.md#1-observed-environment-2026-11-24)), and installing them needs PO approval (PO-Q1).

## ADR-0003 Browser persistence

**Options:** (1) IndexedDB, via a thin wrapper from Rust (works everywhere, async, no SQL, larger code for queries). (2) SQLite compiled to WASM on OPFS (shares the SQL schema with native, needs a worker, larger bundle, maturity and browser coverage vary). (3) A hybrid, with IndexedDB for the outbox and cursors and an in-memory projection. **Decision:** Open. PT-01 runs a cold reload, a queued send, a reconnect and a lost ACK on Chromium, Firefox and WebKit, records bundle and load cost, storage availability (including private mode and quota), and recovery after storage is cleared. **Default if PT-01 is inconclusive:** IndexedDB, as the most portable option. This default is not a decision.

## ADR-0004 Server runtime and persistence

**Proposed:** pinned stable Rust via `rust-toolchain.toml` (observed locally: rustc 1.100.0; pin chosen at P1-00), Tokio, Axum for HTTP and WS, SQLx with PostgreSQL (compile-time-checked queries in an offline-prepared mode so CI needs no database for `cargo check`). The PostgreSQL major version is pinned at P1-00 from the versions upstream currently supports. **Why:** the PDF and seed defaults, a mature ecosystem, and fit with the transaction-per-command model. **Validation:** PT-02 uses the same stack, so its results confirm or reject this ADR. PT-02 exercised PostgreSQL 19.0 only, not SQLx or Axum ([E-17](../plan/evidence.md#e-17-p0-pt-02-postgresql-sequencing-spike)); the SQLx path is confirmed in P1-02.

## ADR-0005 Conversation sequencing, outbox and durable ACK

**Proposed:** design in [sync.md §3](sync.md#3-server-write-path-durable-ack): a conversation row lock, a `last_seq` counter, a single transaction for the message, event, idempotency, outbox, index and audit rows, ACK after commit, and an at-least-once dispatcher. **Review additions (LD-14):** the transaction order is session → conversation lock → idempotency → right. Every transaction follows the global lock order of [sync.md §3.1](sync.md#31-lock-order-user-sequence-and-retries), from device and session rows to attachment rows (widened by LD-30), with a bounded retry on 40P01/40001. Outbox dispatch is ordered per conversation, and the application role runs with `synchronous_commit=on`. Details are in [sync.md](sync.md). **Rejected:** a PostgreSQL `SEQUENCE` per conversation (gaps on rollback break I3) and Redis as source of truth (not durable). **Validation (PT-02, disposable):** concurrent writers producing a contiguous seq, injected crashes before and after commit, a duplicate storm, a send racing a removal, a send and a duplicate racing a session revocation, two admins revoking each other's sessions at once without a deadlock, the transaction cost of a large-group membership change (one user row per member), and throughput per hot conversation and bytes per message on recorded hardware. A decision that depends on these results stays open until PT-02 evidence exists.

**Accepted 2026-11-25 on PT-02 evidence ([E-17](../plan/evidence.md#e-17-p0-pt-02-postgresql-sequencing-spike)), PostgreSQL 19.0:** every validation item above held, except the outbox dispatcher, which was not run (E-17 omission 5). Concurrent writers left no seq hole. A SIGKILL under load lost no ACKed send. A duplicate storm produced one write. No removed member or revoked session committed a later send. Mutual revocation in the §3.1 order never deadlocked, while the actor-first control always did. **Measured limits:** about 850 sends/s per hot conversation over a local socket (lower over a network), about 9,300/s spread over 64 conversations; a membership change locks the conversation for about 0.7 s at 50,000 members (linear); at most 1,276 bytes per message stored and about 2.3 KB of WAL per send. The P2 GRP-010 slow-mode policy and the GRP-001 member limit are set from these numbers ([R-02](../plan/risks.md)).

## ADR-0006 Wire format and versioning

**Proposed:** JSON v1, version carriers and compatibility window as in [contracts.md §1](contracts.md#1-versioned-boundaries), UTF-16 entity offsets, stable error codes. **Consequence:** a protocol change touches `rem-protocol`, and the PR-risk lane runs compatibility fixtures for both versions.

## ADR-0007 Desktop shell

**Proposed:** Tauri, reusing `apps/web`, for P1 desktop (CLI-002, CLI-008). The open question is whether the desktop runs the WASM SDK inside the WebView or the native SDK over Tauri IPC. Native gives SQLite and background sync but needs a second binding path. **GPUI:** evaluated only by benchmark (PT-04, after PT-01) on RAM, startup, accessibility, IME and packaging; no commitment because of trends (PDF p. 17). **Default:** the WASM SDK inside the WebView for P1, which means one binding.

## ADR-0008 Deployment and tenancy

**Proposed:** single-tenant instances. Each customer has its own server, database and bucket. The package is an OCI image plus a compose file that runs under Podman (observed locally: podman 5.4.2) and Docker. The data model stays organization-scoped. Multi-tenant SaaS needs a separate approved decision (PROJECT_SPEC §2).

## ADR-0009 Encryption posture

**Accepted (PROJECT_SPEC §2 security default):** TLS in transit, a documented encryption-at-rest strategy (volume or disk at the host, server-side encryption in object storage, encrypted backups), and server-managed access in P1. **Never** advertise E2EE until an approved protocol (MLS/OpenMLS as the candidate), an independent review, a device and key lifecycle, and recovery are complete (SEC-007/008, P3). **Consequence:** server-side search and admin policy are possible. Marketing and docs must say "encrypted in transit and at rest", nothing more.

## ADR-0010 P1 authentication and sessions

**Proposed:** username or email plus password with Argon2id (parameters tuned on reference hardware to a measured target), opaque random session tokens (≥256 bits, stored as a keyed hash with a server pepper), and per-device sessions. On the web, an HttpOnly, Secure, SameSite=Lax session cookie plus a CSRF token on mutations; native uses a bearer token in the OS keychain. WS ticket: single-use, 60 s. Idle timeout and absolute lifetime are *policy*. MFA, passkeys and SSO wait for P3 (ID-009). Admin-initiated reset follows [threat-model §4.2](../security/threat-model.md#42-admin-recovery-powers-po-q9) and [DEV-08](../product/requirements.md#4-enterprise-deviations-register) until the PO answers PO-Q9: email to the user when SMTP is configured, otherwise a single-use link delivered to the admin, after a different admin approves when `require_dual_approval` is on (ENT-012.a). **Validation:** the P1-03 independent security review covers login and sessions (ID-002.a–c); the admin-initiated reset (ID-002.d/e) is reviewed when P1-09 is accepted. Both reviews check against [threat-model.md](../security/threat-model.md).

## ADR-0011 Ephemeral presence in P1

**Proposed:** typing and presence go through the `Presence` port with an in-process adapter. P1 runs one server node (ADR-0001), so Redis would add an operated service with no benefit. The Redis adapter arrives with multi-node fan-out (SYN-012, P2). **Deviation from the PROJECT_SPEC §4 adapter table** (which lists Redis), recorded as reversible lead decision LD-06 in [decisions.md](../plan/decisions.md#2-lead-decisions-reversible).

## ADR-0012 Media storage and delivery

**Proposed:** S3-compatible API only. Uploads go direct to the store with a presigned PUT, or through the server for small files. Downloads use short-lived presigned GET URLs issued after authorization (MED-010). The bucket is private and served with `nosniff` and attachment headers. **Open:** which store to bundle for on-premise installs (for example MinIO, Garage, SeaweedFS, Ceph RGW, or the customer's own S3). Licenses and distribution have changed in this space, so the choice needs a current license and maintenance review (risk R-07). P1-11 does not depend on the product, only on the S3 API.

## ADR-0013 P1 search

**Proposed:** PostgreSQL full-text search maintained in the same transaction as the message (ORG-004), with authorization joined in SQL against membership intervals. Language configuration is `simple` by default. A dedicated engine (for example Meilisearch) is considered only on measured need (PDF p. 16).

## ADR-0014 CI host and selection

**Proposed:** GitHub Actions, following the harness ([AGENT_HARNESS §4.4](../seeds/AGENT_HARNESS.md#44-ci-scheduling-and-gates)), with one PR entry workflow, internal classification and an aggregate required job ([testing-ci.md §4](../engineering/testing-ci.md#4-ci-design)). **Open:** the repository has no remote. `gh` is authenticated for github.com and `glab` exists, so the hosting choice is PO-Q2. If GitLab is chosen, the same lanes map to `rules:changes` plus a final `needs`-based aggregate job, and this ADR gets a superseding version.
