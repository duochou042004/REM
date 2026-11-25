# REM — Claude Code instructions

Start here: read [docs/handoff/CURRENT.md](docs/handoff/CURRENT.md), then only the sections it lists. The planning index is [docs/README.md](docs/README.md). The seeds (`PROJECT_SPEC.md`, `FEATURE_REGISTRY.md`, `AGENT_HARNESS.md`, `START_PROMPT.md`) govern and are never edited.

## Hard guards

- **Phase P0. No production implementation** until [docs/plan/p0-gate.md](docs/plan/p0-gate.md) passes **and** the PO authorizes P1 (recorded separately). Throwaway prototypes only run on `spike/*` branches under a packet in `docs/plan/backlog.md`.
- Never install tools, pull images, use `sudo`, add plugins or MCP servers, or create remotes without PO approval ([decisions §3](docs/plan/decisions.md#3-po-question-queue)). Inspect tools before using them.
- Never commit or print secrets. No Telegram trademarks or assets. Never claim E2EE, parity or production readiness without evidence.
- Capability IDs are stable and never reused. Each fact lives in one file; link to it rather than copying it.
- No `/compact` and no chat summaries as continuity. Follow the context policy in AGENT_HARNESS §5: prepare at about 300K tokens, hand off before 400K, and record usage readings in `docs/plan/evidence.md`.
- Choose tests by impact ([docs/engineering/testing-ci.md](docs/engineering/testing-ci.md)). Never call a selective pass a full pass.

## Orchestration budget (LD-39; enforced in part by `scripts/orchestration_guard.py`)

- Do the work inline by default. Delegate only for a large read that would cost the lead more than it returns, or for an independent judgment that the authors cannot give (review, adversarial check).
- Routine fan-out is at most 5 agents and 1 verification round. Anything larger needs the PO's approval: the hook asks. Every Workflow script declares `// orchestration-budget: agents=N rounds=R`, and the hook denies scripts that do not.
- Give each agent a coarse, outcome-sized task: one writer per file set, and one verifier per concern, not per row or lens. Batch related checks.
- Verify once against the acceptance criteria, then stop. MINOR findings are recorded, not re-verified. Re-verify only the rows or sections that a fix touched, unless the fix is cross-cutting. A fresh critic per round is not a stop condition: open-ended critics always find something.
- Reuse verification evidence that is still valid. Never restart a completed phase without a recorded reason.
- Check plan usage (`get_usage`) before any fan-out. Turn ultracode off for this project; it conflicts with this budget.

## Workflow

- Branches: `master` holds stable releases (currently the seed baseline), `develop` is integration, and work happens on `p0/*`, `spike/*` or `feat/*` branches from `develop`. Merge with `--no-ff` after the packet is accepted. Never force-push `master` or `develop`.
- Before committing docs, `python3 scripts/check_docs.py` must print `OK`.
- At each checkpoint, update `docs/plan/backlog.md`, `docs/plan/evidence.md` (tested SHA, command, result, omissions) and `docs/handoff/CURRENT.md`. Before starting a task, check `docs/plan/lessons.md` for lessons that apply.
