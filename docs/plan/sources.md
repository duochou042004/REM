# REM — Sources, provenance, conflicts and unknowns

**Owner:** Lead · **Revision:** r1, 2026-11-24. **Authority order:** current PO decisions, then the four seeds, then this planning set, then the discovery PDF (provenance only). Telegram evidence is in [reference-behavior.md](../product/reference-behavior.md).

## 1. Planning inputs

| Input | Version / date | sha256 (first 16) | In Git | Role |
|---|---|---|---|---|
| [START_PROMPT.md](../../START_PROMPT.md) | 2026-11-24; 3,179 characters | `833673b9a6ba9ad3` | yes (`master` bd3312d) | goal command |
| [PROJECT_SPEC.md](../../PROJECT_SPEC.md) | v1.1 baseline, 2026-11-24 | `02a0ac8ec7812e31` | yes | product intent |
| [FEATURE_REGISTRY.md](../../FEATURE_REGISTRY.md) | v1.1 seed; 207 IDs across 19 domains (verified, no duplicates); 84 P1 / 46 P2 / 50 P3 / 27 P4 | `932783b53f296371` | yes | stable IDs |
| [AGENT_HARNESS.md](../../AGENT_HARNESS.md) | v1.2 | `8924a2007c2621e1` | yes | engineering harness |
| `Xây dựng nền tảng chat Rust.pdf` | 46 pages, exported 2026-11-22 (a ChatGPT discussion) | `97caf2ba30873b7f` | **no** (LD-03) | discovery history |

PDF page map (as read): pp. 1–11 option analysis leading to PO choice B; pp. 11–17 architecture blueprint v0.1 (workspace, sync flow, invariants); pp. 18–20 early registry v0.1 (IDs differ); pp. 20–21 security; pp. 22–24 docs tree, agent workflow, context policy; pp. 25–26 PO choice "broad parity"; pp. 26–37 blueprint v1.0 (phases, ADR list, P0 checklist); pp. 37–42 PO request for Markdown export plus QA concerns, where the PO says Claude should decide the docs structure itself (p. 42); pp. 43–46 description of the four-file package. Pages 38–41 were not read in full, because the registry notes they hold a teaching-app writing example.

## 2. Conflicts and resolutions

| ID | Conflict | Resolution |
|---|---|---|
| C-01 | The PDF's early IDs (pp. 18–20: `ID-001` = login, `MSG-*`, `PLT-*`) differ from the registry (`ID-001` = registration) | The registry governs; match by behavior (registry §Reconciling) |
| C-02 | PDF phase plan pp. 9–10 (P2 enterprise readiness, P3 commercial) vs seeds (P2 core UX, P3 enterprise) | Seeds govern (later PO revision, also PDF pp. 29–30) |
| C-03 | PDF p. 27 says "18 domains · 116 capabilities"; the registry says 207 across 19 | The registry governs; the count was verified ([evidence E-03](evidence.md#e-03-registry-integrity)) |
| C-04 | PDF p. 43 says START_PROMPT is 3,648 characters; the current file has 3,179 | The current file governs (a later revision) |
| C-05 | PDF pp. 16–17 propose 13 crates; the spec says a port does not need a crate | 9 crates and 2 apps ([architecture §2](../architecture/architecture.md#2-workspace-layout-created-by-packet-p1-00-not-before)) |
| C-06 | PDF pp. 22 and 30–32 propose a large docs tree; PDF p. 42 and spec §7 say Claude decides and keeps it minimal | Minimal layout (LD-02) |
| C-07 | PDF p. 23: a 100K window hands off at 60–75K; the harness says 1M policy and 100K informational only | The harness governs (PD-06) |
| C-08 | The spec §4 adapter table names Redis for presence | ADR-0011 / LD-06: in-process for P1, reversible and flagged |
| C-09 | The harness wants a 7-day artifact default "where policy permits"; GitHub's default is 90 days | Set the repository setting and an explicit `retention-days` on every upload ([testing-ci §4](../engineering/testing-ci.md#4-ci-design)) |
| C-10 | DM-006 (P1) includes "saved/bookmarks", which overlaps ORG-006 (P2) | DM-006 delivers the Saved Messages self-conversation in P1; bookmarks and tags stay in ORG-006 |
| C-11 | The registry says every capability is researched in P0; the P0 exit list does not require it | P1 IDs researched (P0-RES-01); P2–P4 queued (P0-RES-04, R-14) and not gating P1 |
| C-12 | The spec §4 lists Redis among the defaults to validate | Covered by C-08 |

No conflict was found between the two PO-confirmed decisions (PD-03, PD-04) and any other input.

## 3. Unknowns (kept UNKNOWN until evidence)

The Telegram edit and delete windows, the pending-state glyph and several more rows ([reference §a](../product/reference-behavior.md#a-behaviors-we-could-not-verify)); customer workload and hardware, so every SLO stays *TBD-measure*; browser persistence viability (R-01); hot-conversation throughput (R-02); the CI host (PO-Q2); the brand (PO-Q4); the license of the bundled S3 store (R-07); the ASVS 5.0 control mapping (R-13); whether `DISABLE_AUTO_COMPACT` from a project settings file is honored (no official page says so; checked at restart, E-07).

## 4. External references used

Official tool documentation checked on 2026-11-24 ([evidence E-05](evidence.md#e-05-official-documentation-checks)): code.claude.com (settings, env-vars, statusline, goal), docs.github.com (artifacts, workflow syntax, protected branches), github.com/actions/upload-artifact, doc.rust-lang.org (cargo metadata), playwright.dev (test-cli, ci), github.com/erkamyaman/rust-anything. Telegram sources: [reference-behavior.md source index](../product/reference-behavior.md#source-index).
