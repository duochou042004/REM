# REM — Test strategy, impact selection and CI design

**Owner:** QA + DevOps · **Status:** Specified (P0 r1, 2026-11-24). Cases C1–C5 are observed against a local fixture with emulated GitHub job semantics ([E-14](../plan/evidence.md#e-14-p0-pt-03-ci-selection-spike)). Host verification is PENDING on a CI host (PO-Q2). **Implements:** [AGENT_HARNESS §4](../../AGENT_HARNESS.md#4-intelligent-risk-proportionate-test-selection-mandatory). Nothing here is claimed to run until [evidence.md](../plan/evidence.md) records an observed execution.

## 1. Principles

Select tests from the change-impact graph and the consequence of failure. Selective passes never stand in for full regression at merge, nightly or release gates. A skipped or unrun job is never labelled green.

## 2. Test ladder applied to REM

| Tier | REM content | Typical trigger |
|---|---|---|
| T0 | `cargo fmt --check`, `cargo clippy -p <affected>`, `cargo check`, `tsc --noEmit` for the affected app, eslint, docs check (`scripts/check_docs.py`), secret scan | every change |
| T1 | unit and property tests in `rem-domain`, `rem-client-core` (native target), and React component tests | every code change |
| T2 | `rem-server-adapters` against real PostgreSQL and S3 (containers), contract fixtures, migration up from the previous release, reducer tests on `wasm32` (`wasm-bindgen-test` in a headless browser), dependency-direction check | API, DB, sync, auth, protocol, SDK |
| T3 | Playwright: the affected P1 journeys (J1–J8) on the engines the change touches; visual and a11y checks for the touched screens | user-journey or UI integration risk |
| T4 | full workspace tests plus the lean smoke matrix (one journey per engine, desktop smoke) | integration to `develop` |
| T5 | full engine × OS matrix, fault injection and soak (SYN-014, OPS-009), fuzzing of protocol decoders, backup/restore and upgrade rehearsal, security scans, packaging | nightly and release |

Sync invariants I1–I8 ([sync.md §1](../architecture/sync.md#1-invariants-each-becomes-a-property-or-integration-test)) are proven with model-based and property tests at T1/T2 and fault injection at T5, never with UI click-throughs. E2E tests start from API- or fixture-seeded state (seeded users, conversations and storageState), with one explicit login E2E test.

## 3. Impact map and selection

The initial map is manual (below). P1-00 replaces it with a generated map: `cargo metadata` reverse dependencies, plus a path → lane table in `ci/lanes.toml`, plus feature-ID tags on tests.

| Path or change | Contract | Consumers | Lanes selected |
|---|---|---|---|
| `docs/**`, `*.md` (prose only) | doc links, IDs, prompt length | — | `docs` |
| `crates/rem-domain/**` | domain invariants | server-app, adapters, server | `rust-affected` (reverse deps), `db-integration` |
| `crates/rem-protocol/**` incl. fixtures | wire v1 | server, client-core, wasm, web | `rust-affected`, `compat` (both protocol versions), `wasm-web`, `db-integration` |
| `crates/rem-server-app/**`, `rem-server-adapters/**` | ports, SQL | server | `rust-affected`, `db-integration`; plus `security-neg` if the path is auth or ACL |
| `migrations/**` | DB schema | server | `db-integration`, `migration` (previous release → head) |
| `crates/rem-client-core/**` | reducer, outbox | native, wasm, web | `rust-affected` (native), `wasm-web` (build wasm, typecheck web, browser sync scenario) |
| `crates/rem-client-wasm/**` | TS binding | web | `wasm-web` |
| `apps/web/**` (UI only, no binding change) | components | — | `web-ui` (tsc, lint, component, visual and a11y for touched screens) |
| `apps/desktop/**` | shell | — | `desktop-smoke` |
| `Cargo.lock`, `rust-toolchain.toml`, `.cargo/**`, root `Cargo.toml`, `package-lock`/`pnpm-lock`, `.github/**`, `ci/**` (including the lane registry `ci/lanes.toml`), `scripts/**`, `CODEOWNERS` (at the root, in `.github/` or in `docs/`) | build inputs | all | **widen**: workspace-wide `rust-all` plus every platform lane that the input feeds |
| anything unmatched, or a missing merge-base | unknown | — | **widen**: `rust-all` plus every other registry lane; `rust-affected` unselected (§4) |

Rules: (1) compute changed workspace members from the merge-base diff **and** from base- and head-side `cargo metadata --locked --format-version 1`, so deleted or renamed crates are caught. If either metadata call fails, widen. (2) Reverse dependencies come from `resolve.nodes` (the documented `cargo metadata` field). (3) A workflow, manifest, lane-registry, `CODEOWNERS` or embedded executable change always takes the engineering path, even if the file looks like prose or sits under `docs/`. (4) After a missed dependency is found, update the map and add a lesson ([lessons.md](../plan/lessons.md)).

## 4. CI design

Host: GitHub Actions (ADR-0014; the host itself is PO-Q2). Workflows are written in P1-00, and the docs lane may activate as soon as a remote exists.

**PR entry, `.github/workflows/pr.yml`**: triggers are `pull_request` (and `merge_group` if a merge queue is enabled). There are **no workflow-level `paths` filters**: GitHub leaves path-filtered required checks *Pending*, which blocks merging. `concurrency: { group: pr-${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}, cancel-in-progress: true }`.

```text
classify ──► docs | rust-affected | rust-all | wasm-web | web-ui | db-integration | migration | compat | security-neg | desktop-smoke
   │                (each lane: if: needs.classify.outputs.<lane> == 'true')
   └──────────────────────────────────────────────► required (if: always())
```

- `classify` writes a JSON plan with `{lane: selected, reason}` for every lane in `ci/lanes.toml` and the affected package list (`-p` flags), and uploads nothing on success.
- **Lane registry `ci/lanes.toml`**: the fixed list of lane IDs (each with its job ID and the path → lane rows of §3). It is the only source of valid plan keys. Every registry lane is a job in `pr.yml` and appears in the aggregate's `needs`.
- **`rust-all`** is a real job, not a label for "everything": on one runner and one target directory it runs `cargo fmt --all -- --check`, `cargo clippy --workspace --all-targets --locked -- -D warnings` and `cargo test --workspace --locked`. The classifier selects it whenever §3 widens (build inputs, a removed or renamed crate, failed metadata, unknown impact), and then leaves `rust-affected` unselected because `rust-all` covers every package.
- **`required` aggregate** (the only required status check): it runs with `if: always()` after `needs: [classify, <every lane in ci/lanes.toml>]`, checks out the same commit and validates the plan against the registry. It **fails** when `classify` did not succeed; when the plan names a lane that is not in the registry, or omits a registry lane; when a selected lane is absent from the aggregate's own `needs` list or has no result in the `needs` context; or when a selected lane's result is anything other than `success` (`failure`, `cancelled` or `skipped`). Lanes the plan explicitly left unselected may be `skipped`. This matters because GitHub branch protection treats `skipped` as satisfying a required check, so lanes must never be required individually and the aggregate must check results itself.
- Commands are grouped per runner to reuse compilation: one job runs `fmt` → `clippy -p …` → `test -p …` on the same target directory. Release builds only for benchmarks and packaging.
- Pins: `rust-toolchain.toml`, `--locked` everywhere, `packageManager` in `package.json`, actions pinned by commit SHA, container images by digest.

**Mainline-full** (`push` to `develop`): workspace-wide tests (the `rust-all` job), all T2, lean smoke matrix (T4). Concurrency group `main-${{ github.ref }}` with `cancel-in-progress: false`. **Nightly** (`schedule`): T5 matrix, fault injection, soak (time-boxed), fuzz, audit, backup/restore. **Release** (tag on `master`): rebuild from the candidate SHA, full gate, packaging, SBOM, signing, upgrade and restore rehearsal. Group `release-${{ github.ref }}`, never cancelled.

**Caches:** the Cargo registry and git caches, plus the `node_modules` store and Playwright browsers, are keyed by OS, architecture, toolchain and lockfile hash. An optional compiled `target/` cache is keyed additionally by target, profile, features and RUSTFLAGS, and is **written only from trusted `push` contexts** (`develop`, `master`). PR runs restore only. A test verdict is never cached. Restore time, hit rate and size are recorded at checkpoints before compiler caching (for example sccache) or sharding is added. Stale entries are pruned when total size passes the host's cap.

**Artifacts and retention:** the repository default is 7 days where policy allows. Every upload sets `retention-days` explicitly. The `actions/upload-artifact` README documents a range of 1–90 days unless repository settings change it, and an organization or enterprise cap can lower it further.

| Evidence | `retention-days` | Upload condition |
|---|---:|---|
| PR diagnostic excerpt, failed test report, selected Playwright trace (`retain-on-failure`) | 3 | the job failed and needs diagnosis |
| Mainline or nightly report, sanitized trace | 5 | the run failed, or a trend report is selected |
| Release-candidate package, checksum, SBOM for validation | 7 | candidate verification needs the file |

Never uploaded: `target/`, `node_modules`, dependency trees, databases, unsanitized logs, credentials. Bytes per class and upload failures are tracked. Tested SHA, command, result and reproduction steps are written into Git Markdown ([evidence.md](../plan/evidence.md)) before the artifacts expire. Approved releases and attestations go to the release store, not to workflow artifacts.

### 4.1 Protecting the CI definitions

A `pull_request` run executes the workflow, classifier and lane registry from the PR's own head, so a PR can rewrite them to report success. The aggregate cannot defend against that; repository settings must.

- **Code owners:** `.github/CODEOWNERS` assigns `.github/**`, `ci/**` and `scripts/**` to the QA/DevOps owners named at P1-00. The file sits under `.github/**`, so it protects itself.
- **Protected branches** (`develop`, `master`): pull request required, *Require review from Code Owners* on, stale approvals dismissed when new commits are pushed (so an approved PR cannot later swap in a workflow edit), and the required status check `required` restricted to the GitHub Actions app as its expected source, so a commit status with the same name posted by another integration or token does not satisfy it.
- **Verify on the chosen host (PO-Q2)** before gate item 9 counts any of this: the `CODEOWNERS` path syntax and location are honored; a PR touching a protected path cannot merge without a code-owner approval; the required check's source is pinned to GitHub Actions; and who can bypass the rules. A PR author's own approval does not count, so a single-maintainer repository needs a second code owner or an explicit PO-accepted gap. Case C6 (§6) is the observed proof.

## 5. P1 journey set

J1–J8 from [requirements §2](../product/requirements.md#2-personas-and-critical-journeys), each tagged `@J<n>` and with its feature IDs. Engines: Chromium, Firefox and WebKit. Viewports: 360, 1024 and 1440. Traces `retain-on-failure`. Flake policy: quarantine only with an owner, an issue and an expiry, never for auth, ACL or sync tests.

## 6. P0 acceptance cases for CI selection (synthetic walkthrough — NOT an observed execution)

These come from [AGENT_HARNESS §4.4](../../AGENT_HARNESS.md#rust-workspace-and-github-actions-execution-policy). The *expected* column is the design contract. PT-03 must turn each row into an observed run against a fixture workspace (classifier plus aggregate logic), and the artifact-expiry column needs a real CI host. C6 exercises branch protection rather than the classifier ([§4.1](#41-protecting-the-ci-definitions)), so only a real CI host can observe it.

| Case | Input | Expected lanes | Expected aggregate | Expected artifact | Status |
|---|---|---|---|---|---|
| C1 docs PR | change `docs/plan/backlog.md` | `docs` only | pass when docs passes | none on success | observed locally ([E-14](../plan/evidence.md#e-14-p0-pt-03-ci-selection-spike)); host semantics PENDING (PO-Q2) |
| C2 shared SDK change | change `crates/rem-client-core/src/outbox.rs` | `rust-affected` (client-core, client-native, client-wasm), `wasm-web` | fail if `wasm-web` is skipped | 3-day report only on failure | observed locally ([E-14](../plan/evidence.md#e-14-p0-pt-03-ci-selection-spike)); host semantics PENDING (PO-Q2) |
| C3 removed crate | delete `crates/rem-client-native` (base metadata has it, head does not) | widen: `rust-all` plus every other registry lane; `rust-affected` unselected (§4) | pass only if all widened lanes pass | — | observed locally ([E-14](../plan/evidence.md#e-14-p0-pt-03-ci-selection-spike)); host semantics PENDING (PO-Q2) |
| C4 unclassified change | add `tools/new-thing/x.bin` | widen: `rust-all` plus every other registry lane; `rust-affected` unselected (as C3) | as C3 | — | observed locally ([E-14](../plan/evidence.md#e-14-p0-pt-03-ci-selection-spike)); host semantics PENDING (PO-Q2) |
| C5 failed selected job | C2 with `wasm-web` exiting non-zero | as C2 | **fail** | 3-day failure excerpt; expiry visible in run UI | verdict observed locally ([E-14](../plan/evidence.md#e-14-p0-pt-03-ci-selection-spike)); artifact and expiry PENDING (CI host, PO-Q2) |
| C6 CI-definition tampering | a PR edits `.github/workflows/pr.yml` so `required` always succeeds, with no code-owner approval | widen (`.github/**` is a build input), though the edited workflow may ignore the plan | may report success; the merge is still **blocked** by the missing code-owner review | — | PENDING (CI host, PO-Q2) |

The heading keeps its anchor. The *expected* columns stay the design contract, and the Status column records observations. "Observed locally" means that the classifier and aggregate ran against the fixture with the GitHub `if:` and `needs` semantics emulated, and that every lane apart from the two Rust lanes was a stand-in ([E-14](../plan/evidence.md#e-14-p0-pt-03-ci-selection-spike) omissions 1–2).

Runtime targets stay provisional until measured: queue time, cold and warm compile time, test duration and cache hit size at the first CI checkpoints.
