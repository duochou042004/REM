# REM — Decision log and PO question queue

**Owner:** Lead · **Revision:** r1, 2026-11-24. Architecture decisions are in [adr.md](../architecture/adr.md). This file records **who** decided **what**, with the source. An answer from the PO is persisted here, together with the IDs it affects.

## 1. PO decisions (binding)

| ID | Decision | Source | Affects |
|---|---|---|---|
| PD-01 | Build an independent, Telegram-inspired platform (option B). No MTProto, no Telegram cloud. | PDF p. 11; PROJECT_SPEC §1 | all |
| PD-02 | Broad Telegram feature parity as **inventory**, implemented in phases P0–P4 | PDF p. 25; PROJECT_SPEC §1, §6 | registry, backlog |
| PD-03 | Hexagonal Architecture governs dependency direction | PROJECT_SPEC §4 (v1.1) | ADR-0001 |
| PD-04 | Web: React/TypeScript with the shared Rust SDK compiled to WASM | PROJECT_SPEC §4; registry CLI-001 | ADR-0002 |
| PD-05 | Claude designs the downstream docs, skills and harness, with no pre-built docs tree | PDF p. 42; PROJECT_SPEC §7 | docs layout |
| PD-06 | Context policy for a 1M window: prepare at about 300K, hard cap 400K, no compaction | PDF p. 23; AGENT_HARNESS §5 | handoff |
| PD-07 | No production implementation until P0 passes **and** the PO authorizes it | AGENT_HARNESS §0; PROJECT_SPEC §6 | gate |
| PD-08 | Security default: TLS plus encryption at rest, server-managed access in the MVP; never advertise E2EE before ADR-0009 conditions | PROJECT_SPEC §2 | ADR-0009 |

## 2. Lead decisions (reversible)

| ID | Decision | Rationale | Reverse by |
|---|---|---|---|
| LD-01 | `git init` with `master` (stable, holds the seed baseline), `develop` (integration) and work branches from `develop` | No repository or branch rules existed; this is the AGENT_HARNESS §8 recommendation | rename or re-branch; no remote yet |
| LD-02 | The documentation layout in [docs/README.md](../README.md) | Smallest set covering PROJECT_SPEC §7, one fact in one place | merge or split files; links are checked |
| LD-03 | Keep the discovery PDF out of Git (`.gitignore`); record its hash and page map in [sources.md](sources.md) | It is a private chat export containing a conversation URL; seeds govern | PO-Q3 |
| LD-04 | Lifecycle vocabulary Discovered → Specified → Reviewed → Implemented → Verified → Released, plus flags | PDF p. 29; keeps the four measures apart | edit requirements §3 |
| LD-05 | The four seeds stay at the repository root, unedited, as governing inputs | Their cross-links rely on root paths; derived docs link to them | a PO revision of the seeds |
| LD-06 | Presence and typing in-process for P1 (ADR-0011); Redis deferred to SYN-012 | Single node in P1; one less operated service | adopt the Redis adapter |
| LD-07 | `.claude/settings.json` sets `DISABLE_AUTO_COMPACT=1` | AGENT_HARNESS §5; documented variable (auto and idle compaction off; manual `/compact` still possible, so the policy forbids using it) | delete the key |
| LD-08 | No custom skills or hooks in P0. Compact `CLAUDE.md` routes to CURRENT and the index. Candidates: `impact-based-qa` (after PT-03), `safe-handoff` (after the second handoff), and a SessionStart hook printing CURRENT (if restarts miss it) | AGENT_HARNESS §7: derive skills from real recurring workflows only | add when the trigger is observed |
| LD-09 | `rust-anything` is not installed. Its record → compare → gate method is borrowed for reference tests later (P2), on disposable data only | MIT license per README; it is a migration tool, not a Telegram oracle; installing needs approval | PO approval to install |
| LD-10 | Supported browsers for P1: the latest two stable versions of Chromium, Firefox and WebKit (engines Playwright can drive) | Risk-based matrix | PO product decision |
| LD-11 | JSON v1 wire format with UTF-16 entity offsets (ADR-0006) | Matches the reference entity model and JS strings | ADR revision |
| LD-12 | Dispatch in P0-INIT-01: two read-only research helpers (Telegram reference; official tool docs) plus one independent reviewer | Research was parallel to writing; independent review is needed for critical sync and security claims | — |
| LD-13 | The next ready packet is P0-PT-03, not PT-01/PT-02 | PT-01/PT-02 are blocked on tool approval (PO-Q1); PT-03 needs only installed tools | when PO-Q1 is answered, PT-01 and PT-02 lead |
| LD-14 | Adopt the review resolutions F1–F17 (E-09). F1: visible ranges plus redacted stubs keep seq contiguous inside each visible range, and gap detection uses the next visible seq. F2: admin reset and break-glass rules, with the stance in PO-Q9 and DEV-08. F3: visibility follows the referenced message. F4: push path authorized per event, ordered per-conversation dispatch, ticket re-check. F5: session → lock → idempotency → right. F6: canonical command hash plus a full error-class map. F7: server-time expiry with a margin. F8: idempotency for every mutation, unique DM pair. F9: `user_seq` counter, lock order conversations then users (ascending), bounded retry on 40P01/40001. F10: no tokens in events, scoped events, heads only for current memberships, receipt and request-outcome events. F11: dependent ops. F12: store keyed by user and device, eviction detection. F13: read endpoints. F15: aggregate validated against a lane registry, CODEOWNERS. F16: read-position clamp, stuck-op bound. F17: matrix gaps and `synchronous_commit=on` | Reviewer findings accepted; one decision per finding, so parallel editors stay consistent | the homes are sync.md, contracts.md, threat-model.md, requirements.md, testing-ci.md and operations.md; revise there |
| LD-16 | The next ready packet is P0-REV-02, ahead of P0-PT-03 (this supersedes the ordering in LD-13) | Ten named MAJOR defects sit in the core sync, contract and security docs that PT-01/02 and P1 depend on; PT-03 is independent and follows | — |
| LD-15 | Run the rework as a workflow: 4 file owners on disjoint files, 2 adversarial verifiers per finding, plus 1 critic for new defects | Ultracode on; the lead context was about 300K, so the rework had to happen outside it; one writer per file avoids conflicts | — |

## 3. PO question queue

Each question has options, a recommendation and the consequence of each choice. Work that can continue meanwhile is listed in [CURRENT](../handoff/CURRENT.md).

| ID | Question | Options | Recommendation | Consequence / blocks |
|---|---|---|---|---|
| **PO-Q1** | Approve installing P0 prototype tooling? These are user-level, no `sudo`: `rustup target add wasm32-unknown-unknown`, `cargo install wasm-pack` or `wasm-bindgen-cli` (pinned), npm devDependencies including `@playwright/test` and its browsers in a throwaway directory, and pulling pinned PostgreSQL and S3-compatible images with Podman | A) approve all; B) approve only PT-02 (PostgreSQL); C) defer | **A**. **PO answer 2026-11-24: "Not yet" (deferred). Ask again at the next checkpoint.** | Without it, gate item 8 stays BLOCKED (PT-01, PT-02, PT-04). Playwright browser system libraries may need `sudo apt`, which would be asked separately. |
| **PO-Q2** | Where should the repository and CI live? | A) a new **private** GitHub repository via the authenticated `gh` CLI; B) GitLab (`glab` present); C) stay local and transfer devices with git bundles | **A**, because the CI design (ADR-0014) and the official docs checked are for GitHub Actions | Required for CI evidence (required checks, retention), remote device handoff and P1-00. With C, gate item 9 can be only partly evidenced. |
| PO-Q3 | Track the discovery PDF in Git? | A) keep it outside Git with its hash recorded (current); B) commit it to the private repository | **A** | It is needed only for provenance; B puts a private chat export into history permanently. |
| PO-Q4 | Final product name and brand | — | decide before any pilot | Docs use the working title REM. Not blocking P0 or P1. |
| PO-Q5 | Desktop platforms and code-signing certificates (Windows, macOS, Linux) | A) all three in P1; B) Linux and Windows first | **A**, signing obtained before P1-13 | Blocks signed installers (CLI-002/008), not development. |
| PO-Q6 | Security contact (mailbox) for `SECURITY.md` and vulnerability disclosure | — | a dedicated alias | Needed by P1-15 (SEC-013). |
| PO-Q7 | Provide or approve a test Telegram account and device for OBSERVED reference evidence (P0-RES-02)? | A) yes, a dedicated test account; B) no, keep policy defaults where UNKNOWN | **B** for now | Under B, edit and delete windows stay org *policy* defaults, and the rows stay UNKNOWN. |
| **PO-Q9** | Admin account-recovery power. In a server-managed system, an admin-initiated password reset lets the admin take over an account. How should P1 allow it? | A) reset link only by email to the user (needs SMTP); B) without SMTP, an admin-delivered single-use link with dual approval (when enabled), all sessions revoked, an audit record and a user notification; C) reset only through the operator CLI | **A, with B as fallback** (current interim default, DEV-08) | Decides whether org admins have takeover capability, which bears on ENT-004/005. It does not block P0 docs; it must be answered before P1-03 is accepted. |
| PO-Q8 | **Implementation authorization** for P1 | asked only after the gate passes ([p0-gate.md](p0-gate.md)) | — | Recorded separately from the gate result. |
