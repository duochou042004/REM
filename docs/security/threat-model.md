# REM — Threat model and authorization matrix (P1)

**Owner:** Security · **Status:** Specified (P0 r1, 2026-11-24). An independent review is required before `Reviewed` ([evidence.md](../plan/evidence.md)). **Inputs:** [PROJECT_SPEC §4.2](../../PROJECT_SPEC.md#42-security-architecture), OWASP ASVS as the requirement source (version 5.0 per the PDF discovery notes; chapter mapping is pending, see §7), [sync.md](../architecture/sync.md). This document does not claim compliance or certification.

## 1. Assets

Message bodies and attachments (confidential), membership and conversation metadata (confidential), credentials, session tokens and invite tokens (secret), signing keys and the token pepper (secret), audit log (integrity-critical), backups (confidential, at full scope), local device stores (confidential, held by the user).

## 2. Trust boundaries

| # | Boundary | Crossing | Primary controls |
|---|---|---|---|
| B1 | Internet or LAN → reverse proxy | HTTPS/WSS | TLS (SEC-001), rate limits (SEC-009), request size caps |
| B2 | Proxy → `rem-server` | HTTP, auth headers or cookies | authentication in the driving adapter, CSRF for the cookie session, origin checks on WS |
| B3 | `rem-server` → PostgreSQL | SQL | least-privilege DB role; TLS or a private network; parameterized queries (SQLx) |
| B4 | `rem-server` → object store | S3 API | per-instance bucket and credentials; private bucket; presigned URLs with short TTL |
| B5 | Browser or desktop ↔ local store | OS or browser storage | per-origin isolation; data cleared on logout; no secrets in IndexedDB beyond the session (cookie is HttpOnly) |
| B6 | WASM binding ↔ React UI | JS calls | the UI is untrusted for authorization; all checks are on the server; the binding validates inputs |
| B7 | Operator ↔ host | shell, compose, secrets | operator is outside the app RBAC; secrets come from files or env; support bundles are redacted |
| B8 | Outbound fetch (previews, scanners) | HTTP egress | off by default (DEV-05); SSRF controls when enabled |

## 3. Threats and mitigations (STRIDE, messaging-specific)

| ID | Threat | Mitigation | Verified by |
|---|---|---|---|
| T1 | IDOR/BOLA: read another conversation, message, attachment or session by ID | Membership check in every use case; `not_found` for non-members; UUIDv7 IDs | SEC-003 negative suite |
| T2 | Removed member reads new messages by guessing a cursor | Membership intervals enforced in `EventReader` (I4) | SYN-009 forged-cursor test |
| T3 | Revoked session keeps acting through an open WebSocket | Revocation closes sockets; every command re-checks the session in its transaction | ID-003 test with timing measurement |
| T4 | Replay or duplication of commands | Idempotency records (I2); payload-hash conflict | SYN-002 property test |
| T5 | Event tampering by a client | Clients never write events; the server derives events from validated commands | contract fixtures |
| T6 | Attachment URL leak | Short-TTL presigned URLs; no new URLs after removal; disclosed TTL window | MED-010 tests |
| T7 | Malicious upload (polyglot, XSS via SVG/HTML, zip bomb) | Magic-byte check; deny inline rendering of active types; `Content-Disposition: attachment` and `nosniff`; size caps; no server-side decoding in P1; scanner port | MED-002 fixtures |
| T8 | XSS through message text or entities | Typed entities, no HTML rendering; CSP on the web app; React escaping; fixtures | DM-001 XSS fixtures |
| T9 | SSRF via URL previews | Off by default; allow-list, private-IP blocking, DNS rebinding guard, redirect re-validation, size and time caps when on | SEC-010 tests (when enabled) |
| T10 | Credential stuffing, brute force | Argon2id, per-account and per-IP rate limits, generic errors | ID-002 tests |
| T11 | Invite token brute force or reuse | ≥128-bit tokens, hashed, expiry, use limits, atomic redemption | ID-001 tests |
| T12 | Realtime abuse (socket floods, typing spam) | Connection caps per user and IP, frame size caps, typing rate limits, bounded fanout queues | SEC-009, SYN-011 tests |
| T13 | Privilege escalation in groups | Server-side permission checks; owner invariant; audited role changes; dual approval option | GRP-003/004, ENT-012 tests |
| T14 | Sensitive data in logs or telemetry | Redaction by construction (typed log fields), a log-scan test | OPS-005 test |
| T15 | Secrets in images, repo or support bundles | Secret files and env only; CI secret scanning; redacted bundles | SEC-006, ENT-010 |
| T16 | Backup theft | Encrypted backups; key held separately; restore rehearsal | ENT-007, OPS-006 |
| T17 | Supply chain (crates, npm, actions, images) | Lockfiles with `--locked`; RustSec and npm audit; cargo-deny licenses and bans; actions pinned by SHA; image digests; SBOM | SEC-013, OPS-008 |
| T18 | Cross-org data mix in future multi-tenant use | `organization_id` scoping now; single-tenant deployment | SEC-004 tests |
| T19 | Operator or support overreach | Operator works outside the app; support bundle has no content; privileged admin actions audited | ENT-010 review |
| T20 | Local device compromise or shared browser | Logout clears data; session list and remote revoke; no E2EE claim (ADR-0009) | ID-003, UX copy review |

## 4. Authorization matrix (P1)

Roles: **O** org owner, **A** org admin, **M** org member; inside a group: **GO** group owner, **GA** group admin (with the listed right), **GM** group member (default rights per GRP-003). **Op** is the operator (host access, no in-app role). ✓ allowed, ✗ denied, *r* allowed when the right or policy grants it.

| Action | O | A | M | GO | GA | GM | Op |
|---|---|---|---|---|---|---|---|
| Bootstrap org | — | — | — | — | — | — | ✓ (one-time token) |
| Invite or create users, deactivate, reset password | ✓ | ✓ | ✗ | | | | ✗ |
| Grant org admin | ✓ | *r* (dual approval if on) | ✗ | | | | ✗ |
| Revoke own sessions | ✓ | ✓ | ✓ | | | | |
| Revoke others' sessions | ✓ | ✓ | ✗ | | | | ✗ |
| Create DM or group | ✓ | ✓ | ✓ | | | | |
| Read conversation events | member only | member only | member only | ✓ | ✓ | ✓ | ✗ |
| Send text or media | | | | ✓ | ✓ | *r* | |
| Edit own message (within window) | | | | ✓ | ✓ | ✓ | |
| Delete own message for everyone (within window) | | | | ✓ | ✓ | ✓ | |
| Delete others' messages | | | | ✓ | *r* | ✗ | |
| Pin or unpin | | | | ✓ | *r* | *r* | |
| Change info or settings | | | | ✓ | *r* | *r* | |
| Add members or create invite links | | | | ✓ | *r* | *r* | |
| Remove, ban or timeout members | | | | ✓ | *r* (not GO/GA above them) | ✗ | |
| Promote or demote admins | | | | ✓ | *r* | ✗ | |
| Transfer group ownership | ✓ (break-glass, DEV-07) | ✓ (break-glass) | | ✓ (re-auth) | ✗ | ✗ | |
| Delete group | | | | ✓ | ✗ | ✗ | |
| Approve join requests | | | | ✓ | *r* | ✗ | |
| Download attachment | | | | per MED-010 | per MED-010 | per MED-010 | ✗ |
| Search messages | own memberships only | same | same | | | | ✗ |
| View admin overview or support bundle | ✓ | ✓ | ✗ | | | | ✓ (host logs, redacted) |

Org roles grant **no** implicit read access to conversations they are not members of. An admin content-access or eDiscovery capability is ENT-004/005 (P3), needs an explicit, audited policy, and is a PO product decision.

## 5. Data classification and logging

| Class | Examples | Log or metric rule |
|---|---|---|
| Secret | passwords, tokens, invite tokens, keys | never logged; hashed at rest |
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
