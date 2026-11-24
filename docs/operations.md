# REM — Operations: deployment, backup, observability, upgrade

**Owner:** DevOps/Release · **Status:** Specified (P0 r1, 2026-11-24) · **Criteria:** OPS-*, ENT-007 and ENT-010 in [requirements.md](product/requirements.md#infrastructure-and-operations-ops). **Decisions:** ADR-0008 and ADR-0012 in [adr.md](architecture/adr.md).

## 1. Deployment shape (single tenant, P1)

| Component | Image / source | State | Notes |
|---|---|---|---|
| reverse proxy | pinned OCI image (product chosen at P1-14; Caddy and nginx are candidates) | certificates | TLS termination, HSTS, WS upgrade, request caps; ACME or customer certificates, works offline (OPS-011) |
| `rem-server` | REM OCI image, digest-pinned, signed | none (stateless) | one replica in P1; runs migrations behind an explicit `migrate` subcommand, not on boot |
| PostgreSQL | pinned major version (ADR-0004) | volume | least-privilege app role, separate migration role; `synchronous_commit=on` pinned for the app role (`ALTER ROLE … SET`), because the durable ACK ([sync.md I1](architecture/sync.md#1-invariants-each-becomes-a-property-or-integration-test)) depends on it |
| object store | S3-compatible (ADR-0012), or the customer's S3 | volume or bucket | private bucket; credentials scoped to it |

Packaging: a compose file valid for both `podman compose`/`podman-compose` and `docker compose`, an `.env.example` holding variable **names** only, and secret files mounted read-only. Host requirements are stated as measured minimums once OPS-009 has run, not guessed.

## 2. Configuration and secrets

Configuration comes from environment variables and secret files only. The server validates it at startup and refuses to start with a missing secret, a default password or an insecure combination (for example, previews enabled without an egress allow-list, or `synchronous_commit` reading anything other than `on` on the app role's connection). There is a rotation procedure for the session pepper, the URL-signing key and database credentials (SEC-006).

## 3. Backup and restore (ENT-007, OPS-003, OPS-006)

- Database: logical backups for P1 (`pg_dump` custom format) on a schedule, plus WAL archiving when the customer needs a lower RPO (customer decision, recorded per deployment). Object store: a bucket sync to backup storage at the same point in time, with the DB backup's ID recorded in a manifest.
- A consistent point means the DB backup completes, then the object sync covers every key referenced at that LSN. Orphan objects are tolerated and garbage-collected.
- Backups are encrypted with a key held outside the instance.
- **Restore rehearsal** (release lane, OPS-006): restore into a scratch instance, run migrations, then check counts, the max `seq` per conversation, a sample of attachment checksums, and that a login and a send work.
- RPO and RTO targets come from customer pilots. P1 publishes the measured restore time for the reference dataset.

## 4. Observability (OPS-004, OPS-005)

- `/healthz` (process alive), `/readyz` (DB and object store reachable, migrations at the expected version), and `/metrics` (Prometheus format) on an internal listener.
- Metrics: ACK latency histogram, sends per second, WS connections, outbox lag (oldest undispatched age), catch-up duration, rate-limit trips, DB pool saturation, storage bytes.
- OpenTelemetry traces with IDs only (threat-model §5). Logs are JSON and structured, and redaction is tested (XC-6).
- The support bundle (ENT-010) holds version, config with secrets removed, the last N hours of redacted logs, and a migration and health snapshot.

## 5. Upgrade and rollback (OPS-002, OPS-007)

- Migrations: forward-only, expand/contract across two releases for breaking changes. Each release note states its **rollback path**: either an image rollback (when the schema is compatible) or a restore point.
- Pre-upgrade: an automatic backup and a migration dry run against a copy.
- Client compatibility: the server accepts the current and previous protocol minor version (SYN-013). The admin overview shows clients below the minimum.
- Upgrade rehearsal from the previous release with data runs in the release lane.

## 6. Runbooks (OPS-013) to write in P1-14

Install, upgrade, backup, restore, rotate secrets, respond to compromised sessions (mass revoke), disk full, DB connection exhaustion, certificate expiry, and the incident template (detect → triage → communicate → mitigate → postmortem, with no message content in incident notes).

## 7. Air-gapped and offline (P3 note)

Nothing in P1 may require internet access at runtime: no license calls, no CDN, no telemetry export by default. Air-gapped install and update packages are OPS-012 (P3), and P1 must keep that path open.
