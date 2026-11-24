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

Every mutating request carries `operation_id` and is idempotent (§2.1). Every response, errors included, carries `server_time`. Responses use the error model in §4. Authentication uses a session cookie (web) or a bearer token (native), per ADR-0010.

| Area | Endpoints (method path → use case) | IDs |
|---|---|---|
| Bootstrap and identity | `POST /v1/bootstrap`, `POST /v1/invites`, `POST /v1/invites/{token}/redeem`, `POST /v1/sessions` (login), `DELETE /v1/sessions/{id}`, `GET /v1/sessions`, `POST /v1/password`, `POST /v1/password-resets` | ENT-001, ID-001..003, SEC-002 |
| Profile and account | `GET/PATCH /v1/me`, `GET /v1/users/{id}`, `POST /v1/me/export`, admin `PATCH /v1/admin/users/{id}` | ID-004..006, ENT-002 |
| Sync | `GET /v1/sync`, `GET /v1/conversations/{id}/events`, `POST /v1/ws-ticket`, `GET /v1/ws` (upgrade), `GET /v1/operations/{operation_id}` (§2.1) | SYN-001, 002, 005, 006, 008 |
| Conversation reads | `GET /v1/conversations` (current memberships, paginated), `GET /v1/conversations/{id}` (settings, my membership, `visible_ranges`, `last_seq`, pins of visible messages), `GET …/members`, `GET …/messages?before=&limit=` (history page of visible messages), `GET …/links` (holders of the link right only) | ORG-001, GRP-001..003, 007, SYN-008, 009 |
| Conversations | `POST /v1/conversations` (dm/group), `PATCH /v1/conversations/{id}`, `DELETE /v1/conversations/{id}`, `POST/DELETE /v1/conversations/{id}/members/{user}`, `PATCH …/members/{user}` (role, rights, ban, timeout), invite links `POST/DELETE /v1/conversations/{id}/links`, `POST /v1/links/{token}/join`, join requests `POST …/requests/{id}/approve\|decline` | DM-001, GRP-001..007 |
| Messages | `POST /v1/conversations/{id}/messages`, `PATCH …/messages/{mid}` (edit, `expected_revision`), `DELETE …/messages/{mid}?scope=self\|everyone`, `POST …/messages/{mid}/forward`, `PUT/DELETE …/pins/{mid}` | DM-001..006 |
| State | `PUT /v1/conversations/{id}/read` (`seq`), `PUT …/prefs` (mute, archive, pin, notify level), typing over WS `typing` frame | DM-008, 009, ORG-001, 002, GRP-008 |
| Media | `POST /v1/attachments` (create, returns upload target), `POST /v1/attachments/{id}/finalize`, `GET /v1/attachments/{id}/url` | MED-001, 002, 010 |
| Search | `GET /v1/search?q=&scope=` | ORG-004 |
| Admin and ops | `GET /v1/admin/overview`, `POST /v1/admin/support-bundle`, `/healthz`, `/readyz`, `/metrics` (internal listener only) | ENT-010, OPS-004 |

The snapshot reset ([sync.md §4](sync.md#4-catch-up-and-realtime)) rebuilds a conversation from `GET /v1/conversations/{id}` and `…/messages` pages, not from the event log.

### 2.1 Idempotent mutations and operation lookup

- **Scope.** Every mutating command records its idempotency record in the same transaction as its effect: sends, edits, deletes, forwards and pins; create group and open DM; invite and link redemption; attachment create and finalize; read position; prefs; membership and role changes ([sync.md §3](sync.md#3-server-write-path-durable-ack)).
- **Canonical command.** The record is keyed `(actor_user_id, device_id, operation_id)` and stores the command kind, its target (conversation, message) and a hash of the command the server builds after parsing: kind, target, normalized body and entities, attachment ids. Raw request bytes are never hashed, so a client that re-encodes a pending op after an upgrade still matches.
- **Replay and conflict.** The same `operation_id` with the same canonical command returns only the stored original ACK fields plus `duplicate: true`, never new data. The same `operation_id` with a different kind, target or hash returns `operation_conflict`.
- **Open DM.** `POST /v1/conversations` with `kind: "dm"` for a pair that already has a DM returns that conversation with `created: false`. The pair is unique per organization ([architecture.md §4](architecture.md#4-domain-model-sketch-validated-against-invariants-not-a-final-schema)).
- **`GET /v1/operations/{operation_id}`** returns `{operation_id, kind, target, ack}` from the record of the caller's own user and device. It returns `not_found` when this device has no recorded effect under that id (never applied, or past retention, [sync.md §7](sync.md#7-evolution-retention-and-clocks)). The client calls it after `operation_conflict` and to settle a pending op without resending ([sync.md §5](sync.md#5-client-outbox-and-pending-state)).

### 2.2 Visible ranges, event pages and redacted stubs

- **`visible_ranges`** is the reader's list of half-open `[from_seq, to_seq)` pairs, with `to_seq: null` for an open range. The server computes it from membership intervals and `history_visibility` ([sync.md §6](sync.md#6-revocation-and-history-authorization)). It is returned by `GET /v1/conversations/{id}`, every event page and every history page.
- **Event page** (`GET /v1/conversations/{id}/events?after=S&limit=N`):

  ```json
  { "conversation_id": "0192…", "covered_from": 1001, "covered_to": 1100, "last_seq": 1250,
    "visible_ranges": [[1, 900], [1001, null]], "events": [ … ] }
  ```

  `covered_from` is `S + 1` and `covered_to` is the highest seq the page accounts for, so the client stores `covered_to` as its `covered_through` cursor ([sync.md §4](sync.md#4-catch-up-and-realtime)). For a current member, each seq in `[covered_from, covered_to]` that lies inside a visible range appears exactly once, as a full event or a redacted stub. Seqs outside visible ranges are absent and are not gaps, so a page may advance `covered_to` without returning events. More pages remain while `covered_to < last_seq`.
- **Redacted stub:** `{ "seq": 1043, "type": "redacted" }`, with no other field (no actor, time, original type or payload). The server sends one in place of (1) `message.edited`, `message.deleted`, `message.pinned` or `message.unpinned` when the referenced message's creation seq is not visible to the reader, and (2) `link.*` or `join_request.*` events to members without the matching right (§3). Over WebSocket it travels as `{conversation_id, seq, event}` like any other event.
- **Referenced messages:** in `message.created`, `reply_to` and `forwarded_from` become `{ "unavailable": true }` when the referenced message is not visible to the reader. A request naming an invisible message id returns `not_found`.
- **`GET /v1/sync` heads:** `conversation_heads` lists only conversations where the user is currently a member, plus one final head capped at `left_seq` for a conversation the user just left.

## 3. Event catalog (conversation stream unless noted, all `schema_version: 1`)

`message.created`, `message.edited`, `message.deleted` (tombstone), `message.pinned`, `message.unpinned`, `conversation.created`, `conversation.updated`, `conversation.deleted`, `member.added`, `member.removed`, `member.role_changed`, `member.restricted`, `link.created`, `link.revoked`, `join_request.created`, `join_request.resolved`. On the user stream: `user.membership_changed`, `user.read_position`, `user.prefs_changed`, `user.profile_changed`, `user.session_revoked`, `user.message_hidden` (delete-for-self), `user.join_request_resolved`, `receipt.updated`. Ephemeral, never sequenced: `typing`, `presence`.

Envelope (matches the PDF discovery sketch, with `seq` naming):

```json
{ "event_id": "0192…", "conversation_id": "0192…", "seq": 1042, "type": "message.created",
  "schema_version": 1, "actor_id": "0192…", "device_id": "0192…", "operation_id": "6f1c…",
  "server_time": "2026-11-24T08:00:00Z", "payload": { "message_id": "0192…", "body": "…", "entities": [] } }
```

`operation_id` and `device_id` appear only to the actor's own devices. Other recipients get the envelope without them, which hides device metadata.

**Reader-scoped payloads** (rules in [sync.md §6](sync.md#6-revocation-and-history-authorization)):

- `link.created` and `link.revoked` carry `link_id` and metadata (expiry, use limit, use count, approval required), never the token. No event carries an invite or link token. The token is returned only in the `POST …/links` response to its creator and by `GET …/links` to holders of the link right.
- `link.*` payloads reach holders of the link right and `join_request.*` payloads reach holders of the approve right. Other members receive redacted stubs at those seqs (§2.2).
- `user.membership_changed` carries `conversation_id`, `joined_seq`, `left_seq` (`null` while a member) and `history_visibility`, so a client knows where a new visible range starts after a rejoin.
- `receipt.updated` goes to message authors, coalesced and rate-limited (*policy*). In a DM it carries the reader's position `{conversation_id, reader_id, read_seq}`; in a group, `{conversation_id, up_to_seq, read_by_count}` (DM-009).
- `user.join_request_resolved` goes to the requester: `{conversation_id, request_id, outcome: "approved" | "declined"}` (GRP-006).

## 4. Error model

Each error is `{"error": {"code": "<stable_snake_case>", "retryable": bool, "retry_after_ms"?: n, "detail"?: {...}}, "server_time": "…"}` with a matching HTTP status. Stable codes: `unauthenticated`, `session_revoked`, `not_found` (also used for unauthorized object access, XC-1), `forbidden_action` (a member lacking a right), `payload_invalid`, `too_large`, `rate_limited`, `operation_conflict`, `revision_conflict`, `invite_invalid`, `cursor_expired`, `upgrade_required`, `unavailable`. Across the WASM boundary the same codes become a TS discriminated union `{ kind: code, … }`. The binding generator must produce that union, and PT-01 checks it.

- `operation_conflict` means the `operation_id` was already used for a different command, whatever its kind or target (§2.1).
- `unavailable` (retryable) also covers PostgreSQL deadlock (`40P01`) and serialization failure (`40001`) once the server has retried the transaction up to 3 times with jitter. The lock order that keeps these rare is in [sync.md §3](sync.md#3-server-write-path-durable-ack).
- When several checks fail, the write-path order in [sync.md §3](sync.md#3-server-write-path-durable-ack) decides which code is returned (for example `session_revoked` wins over a duplicate).
- How the client outbox treats each code is in [sync.md §5](sync.md#5-client-outbox-and-pending-state). The TS union also carries client-only reasons, such as `dependency_failed`, that never appear on the wire.

## 5. Contract fixtures (P0 acceptance)

For each driving adapter and each P1 use case there is a golden fixture set under `crates/rem-protocol/fixtures/v1/`, created in P1-04. It covers: (1) a valid command and its ACK, (2) a denial (`not_found` for a non-member, `forbidden_action` for a missing right), (3) a retry with the same `operation_id` returning `duplicate: true`, and (4) a version mismatch giving `upgrade_required`. Both server tests and client SDK tests consume the same fixtures, which is how drift is caught. Fixture changes are reviewed like schema changes ([testing-ci.md §3](../engineering/testing-ci.md#3-impact-map-and-selection)).
