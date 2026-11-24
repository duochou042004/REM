# REM — Risk register

**Owner:** Lead · **Revision:** r1, 2026-11-24. An open risk has an impact, an owner and a resolution criterion (PROJECT_SPEC §6). Status is `OPEN`, `MITIGATING` or `CLOSED` (with evidence).

| ID | Risk | Impact | Owner | Resolution criterion | Status |
|---|---|---|---|---|---|
| R-01 | Browser persistence or the WASM binding cannot meet the durable-outbox needs on all three engines (OPFS, quota, private mode, worker constraints) | CLI-001/004 redesign; P1-07 delayed | Client | PT-01 shows the four scenarios passing on Chromium, Firefox and WebKit, with recorded bundle and load cost; ADR-0003 decided | OPEN (blocked on PO-Q1) |
| R-02 | The per-conversation row lock caps send throughput in hot groups | Group-size limits; possible sequencing redesign | Architecture | PT-02 measures sends per second per conversation on recorded hardware; the GRP-001 member limit is set from it | OPEN (blocked on PO-Q1) |
| R-03 | A device offline longer than `IDEMPOTENCY_TTL` retries and creates duplicates | Duplicate messages | Architecture | The expired state is never auto-retried (SYN-007.c test); the TTL policy is documented | MITIGATING (design) |
| R-04 | Selective CI misses an affected dependency, so a regression escapes | Broken merges | QA | PT-03 cases C1–C5 observed; mainline-full and nightly always run; a missed dependency becomes a lesson and a map update | OPEN |
| R-05 | No remote or CI host: no CI evidence, no remote device handoff | Gate item 9 is partial; continuity relies on bundles | PO | PO-Q2 answered and the remote verified | OPEN |
| R-06 | Required tooling is missing (wasm32 target, wasm-pack or bindgen, Playwright, DB images) | Prototypes cannot run | PO | PO-Q1 approved and the tools verified by version checks | OPEN |
| R-07 | The S3-compatible store bundled for on-premise installs has license or maintenance problems | Packaging and licensing risk | DevOps | ADR-0012 store choice with a dated license and maintenance review before P1-14 | OPEN |
| R-08 | Telegram reference values are unverified (edit and delete windows, pending state) | UX expectations differ | Research | Policy defaults are used; optional OBSERVED evidence (P0-RES-02, PO-Q7) | MITIGATING |
| R-09 | Scope creep from the 207-ID inventory | P1 never ships | Lead | Phase gates; P1 is the 84 IDs only; new behavior becomes a change request | MITIGATING |
| R-10 | Customers expect E2EE | Sales friction | PO | Customer discovery (P0-RES-03); ADR-0009 messaging | OPEN |
| R-11 | No customer validation yet | Building the wrong product | PO | Interviews and pilot criteria before P3 investment | OPEN |
| R-12 | The independent reviewer shares the author's model family, so blind spots are correlated | Missed security or sync flaws | Lead | A human or external security review before any P1 release or pilot (P1-15) | OPEN |
| R-13 | The ASVS 5.0 mapping is not done | Security requirements are incomplete | Security | P0-SEC-01 mapping table | OPEN |
| R-14 | P2–P4 capabilities are not yet researched (the registry asks for P0 research of every capability) | Later re-planning | Research | P0-RES-04 before P2 planning; not gating P1 | OPEN |
| R-15 | Event log and index growth is unknown | Storage cost; retention design | Architecture | PT-02 measures bytes per message and per event; `EVENT_RETENTION` default set from it | OPEN |
