# REM — API, event and binding contracts (v1 draft)

**Owner:** Architecture (protocol) · **Status:** Specified (P0 r1, 2026-11-24). Golden fixtures are produced in packet P1-04. **Semantics:** [sync.md](sync.md). **Decisions:** ADR-0006 in [adr.md](adr.md#adr-0006-wire-format-and-versioning).

## 1. Versioned boundaries

| Boundary | Version carrier | Compatibility rule |
|---|---|---|
| HTTP API | path prefix `/v1/`, header `REM-Client-Version` | The server supports the current and previous minor version. A breaking change means `/v2/` running alongside. |
| WebSocket | subprotocol `rem.v1` plus `hello.protocol` | Negotiate the highest common version, otherwise `upgrade_required`. |
| Event payloads | `schema_version` per event `type` | Additive changes keep the version. A breaking change bumps it, and both versions are emitted during the window. |
| WASM binding (TS API) | `BINDING_VERSION` constant plus the npm package version | The web app pins one exact SDK build, so they ship together. |
| Native FFI (UniFFI, after P1) | crate version | Same rule as WASM. |
| Client local store | `local_schema_version` | Forward migrations. On failure, the SYN-008 reset. |
| Server database | migration version (sqlx) | Expand/contract (OPS-002). |

Wire format: JSON (UTF-8) for v1. It is debuggable, easy for browsers, and has golden fixtures. A binary encoding is a later ADR, adopted only if PT-02 or OPS-009 shows payload cost matters. Text entity offsets are in **UTF-16 code units**, matching both the JS strings the UI edits and the reference model ([reference DM-001](../product/reference-behavior.md#reference-table)). Rust converts at the edge.

## 2. HTTP surface (P1, v1)

Every mutating request carries `operation_id`. Responses use the error model in §4. Authentication uses a session cookie (web) or a bearer token (native), per ADR-0010.

| Area | Endpoints (method path → use case) | IDs |
|---|---|---|
| Bootstrap and identity | `POST /v1/bootstrap`, `POST /v1/invites`, `POST /v1/invites/{token}/redeem`, `POST /v1/sessions` (login), `DELETE /v1/sessions/{id}`, `GET /v1/sessions`, `POST /v1/password`, `POST /v1/password-resets` | ENT-001, ID-001..003, SEC-002 |
| Profile and account | `GET/PATCH /v1/me`, `GET /v1/users/{id}`, `POST /v1/me/export`, admin `PATCH /v1/admin/users/{id}` | ID-004..006, ENT-002 |
| Sync | `GET /v1/sync`, `GET /v1/conversations/{id}/events`, `POST /v1/ws-ticket`, `GET /v1/ws` (upgrade) | SYN-001, 006, 008 |
| Conversations | `POST /v1/conversations` (dm/group), `PATCH /v1/conversations/{id}`, `DELETE /v1/conversations/{id}`, `POST/DELETE /v1/conversations/{id}/members/{user}`, `PATCH …/members/{user}` (role, rights, ban, timeout), invite links `POST/DELETE /v1/conversations/{id}/links`, `POST /v1/links/{token}/join`, join requests `POST …/requests/{id}/approve\|decline` | DM-001, GRP-001..007 |
| Messages | `POST /v1/conversations/{id}/messages`, `PATCH …/messages/{mid}` (edit, `expected_revision`), `DELETE …/messages/{mid}?scope=self\|everyone`, `POST …/messages/{mid}/forward`, `PUT/DELETE …/pins/{mid}` | DM-001..006 |
| State | `PUT /v1/conversations/{id}/read` (`seq`), `PUT …/prefs` (mute, archive, pin, notify level), typing over WS `typing` frame | DM-008, 009, ORG-001, 002, GRP-008 |
| Media | `POST /v1/attachments` (create, returns upload target), `POST /v1/attachments/{id}/finalize`, `GET /v1/attachments/{id}/url` | MED-001, 002, 010 |
| Search | `GET /v1/search?q=&scope=` | ORG-004 |
| Admin and ops | `GET /v1/admin/overview`, `POST /v1/admin/support-bundle`, `/healthz`, `/readyz`, `/metrics` (internal listener only) | ENT-010, OPS-004 |

## 3. Event catalog (conversation stream unless noted, all `schema_version: 1`)

`message.created`, `message.edited`, `message.deleted` (tombstone), `message.pinned`, `message.unpinned`, `conversation.created`, `conversation.updated`, `conversation.deleted`, `member.added`, `member.removed`, `member.role_changed`, `member.restricted`, `link.created`, `link.revoked`, `join_request.created`, `join_request.resolved`. On the user stream: `user.membership_changed`, `user.read_position`, `user.prefs_changed`, `user.profile_changed`, `user.session_revoked`, `user.message_hidden` (delete-for-self). Ephemeral, never sequenced: `typing`, `presence`.

Envelope (matches the PDF discovery sketch, with `seq` naming):

```json
{ "event_id": "0192…", "conversation_id": "0192…", "seq": 1042, "type": "message.created",
  "schema_version": 1, "actor_id": "0192…", "device_id": "0192…", "operation_id": "6f1c…",
  "server_time": "2026-11-24T08:00:00Z", "payload": { "message_id": "0192…", "body": "…", "entities": [] } }
```

`operation_id` and `device_id` appear only to the actor's own devices. Other recipients get the envelope without them, which hides device metadata.

## 4. Error model

Each error is `{"error": {"code": "<stable_snake_case>", "retryable": bool, "retry_after_ms"?: n, "detail"?: {...}}}` with a matching HTTP status. Stable codes: `unauthenticated`, `session_revoked`, `not_found` (also used for unauthorized object access, XC-1), `forbidden_action` (a member lacking a right), `payload_invalid`, `too_large`, `rate_limited`, `operation_conflict`, `revision_conflict`, `invite_invalid`, `cursor_expired`, `upgrade_required`, `unavailable`. Across the WASM boundary the same codes become a TS discriminated union `{ kind: code, … }`. The binding generator must produce that union, and PT-01 checks it.

## 5. Contract fixtures (P0 acceptance)

For each driving adapter and each P1 use case there is a golden fixture set under `crates/rem-protocol/fixtures/v1/`, created in P1-04. It covers: (1) a valid command and its ACK, (2) a denial (`not_found` for a non-member, `forbidden_action` for a missing right), (3) a retry with the same `operation_id` returning `duplicate: true`, and (4) a version mismatch giving `upgrade_required`. Both server tests and client SDK tests consume the same fixtures, which is how drift is caught. Fixture changes are reviewed like schema changes ([testing-ci.md §3](../engineering/testing-ci.md#3-impact-map-and-selection)).
