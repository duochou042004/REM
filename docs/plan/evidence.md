# REM — Evidence index (commands and results)

**Owner:** Lead. Each row records its tested revision, environment, exact command, result, coverage and omissions. Outputs are redacted and kept only as long as needed to reproduce. Rows are appended and never rewritten. A correction is a new row.

Environment for all rows unless stated: Debian 13 x86_64, the local checkout at `/home/deb/App_sources/REM` (no remote), and Claude Code 2.1.329 (Opus 5.5, 1M context).

## E-01 Seed integrity

- **Revision:** `master` bd3312d (seed baseline commit). **Command:** `sha256sum START_PROMPT.md PROJECT_SPEC.md FEATURE_REGISTRY.md AGENT_HARNESS.md "Xây dựng nền tảng chat Rust.pdf"`.
- **Result:** the hashes are recorded in [sources §1](sources.md#1-planning-inputs). The PDF has 46 pages, per `pdfinfo`.

## E-02 Environment inventory

- **Command:** `command -v` for git gh glab docker podman rustup cargo rustc node npm pnpm yarn npx python3 pdftotext wasm-pack wasm-bindgen sqlx psql redis-server playwright claude jq shellcheck. Version calls: `git --version; gh --version; rustc --version; cargo --version; rustup show active-toolchain; rustup target list --installed; node --version; npm --version; python3 --version; podman --version; claude --version`. Auth was checked with `gh auth status`, account redacted.
- **Result:** summarized in [bootstrap §1](../engineering/bootstrap.md#1-observed-environment-2026-11-24). Missing: docker CLI, wasm-pack, wasm-bindgen, psql, redis-server, Playwright, the wasm32 target. Nothing was installed.

## E-03 Registry integrity

- **Command:** `grep -oE '^\| \`[A-Z]+-[0-9]{3}\`' FEATURE_REGISTRY.md | wc -l` (and `| sort | uniq -d`), plus a phase count with `grep -oE '\| P[0-4] \|$' | sort | uniq -c`.
- **Result:** 207 IDs, 0 duplicates, 19 product domain headings. P1 84, P2 46, P3 50, P4 27.

## E-04 Discovery PDF provenance

- **Command:** `pdftotext -f N -l N` per page. The full page-level read covered pp. 1–37 and 42–46. Pages 38–41 were skipped (a writing example, per the registry note).
- **Result:** page map and conflicts C-01..C-11 in [sources.md](sources.md#2-conflicts-and-resolutions). The PDF contains a private conversation URL, which is not copied into any tracked file.

## E-05 Official documentation checks

- **Method:** one read-only web-fetch helper (LD-12), 2026-11-24. It cited these official pages: code.claude.com settings, env-vars, statusline and goal; docs.github.com store-and-share-data, workflow-artifacts, workflow-syntax (read in part) and about-protected-branches; github.com/actions/upload-artifact; doc.rust-lang.org cargo-metadata; playwright.dev test-cli and ci; github.com/erkamyaman/rust-anything.
- **Findings used:** `DISABLE_AUTO_COMPACT` turns off auto and idle compaction while manual `/compact` stays available (`DISABLE_COMPACT` turns off both). Project `.claude/settings.json` `env` applies after the folder is trusted. Statusline `context_window.current_usage` holds input, cache-creation and cache-read tokens and can be null. `/goal` conditions are limited to 4,000 characters. The `upload-artifact` README gives `retention-days` 1–90 unless repository settings change it, and the latest major in that README is v7. A required status check accepts success, **skipped** or neutral. A path-filtered skipped workflow leaves required checks pending. `cargo metadata` exposes `workspace_members` and `resolve.nodes`, and `--locked` fails on lockfile drift. Playwright warns that `--only-changed` is heuristic and that a full suite is still needed. rust-anything is MIT, and its record and replay stages run cases with real side effects.
- **Omissions:** the workflow-syntax page was read in part (the `needs` and `if: always()` behavior came from a summary), and the Playwright trace-mode semantics page was not fetched. PT-03 must confirm both on a real run.

## E-06 Telegram P1 reference research

- **Method:** one read-only research helper (packet P0-RES-01), 26 fetches of official telegram.org and core.telegram.org pages, 2026-11-24.
- **Result:** 33 rows: 13 OFFICIAL, 19 OFFICIAL with gaps marked, 1 UNKNOWN (ID-005, which has no Telegram analogue), 0 OBSERVED. Recorded in [reference-behavior.md](../product/reference-behavior.md). The lead reviewed it and adopted DEV-04 and DEV-07.

## E-07 Restart path and receiver cases

*Pending: filled in after the fresh-context receiver run.*

## E-08 Docs check

*Pending: filled in after the commit is checked.*

## E-09 Independent review

*Pending.*

## E-10 Device-transfer bundle

*Pending.*

## E-11 Context readings

| Time (UTC) | Reading | Source | Remaining-work estimate |
|---|---|---|---|
| 2026-11-24 ~05:04 | 160,147 / 1,000,000 tokens | `get_usage` (app context meter) | docs about +80K, review and restart about +30K: below 300K, continue |
