# REM — Lessons learned

**Owner:** Lead. Only recurring or costly mistakes are recorded here (AGENT_HARNESS §6). Before starting a task, check the rows whose trigger matches it.

```yaml
id: LESSON-20261124-001
symptom: "Reading the 46-page Vietnamese discovery PDF page by page into the lead context used roughly 100K tokens before any planning output."
trigger: "Large non-English provenance document read directly by the lead (P0-INIT-01)."
root_cause: "Per-page text sizes were checked, but the read was not delegated; Vietnamese text tokenizes densely."
evidence: "Context reading 160,147 tokens shortly after the PDF read (evidence E-11)."
wasted_cost: "Estimated at roughly 60-80K tokens beyond what a delegated summary would have cost (estimate, not measured)."
prevention: "For any source over about 20K characters that is needed only for provenance, delegate a bounded read-only subagent that returns page-cited findings; the lead reads only the pages a decision depends on."
verification: "Next session: the lead context stays under 100K before the first planning output on a comparable intake."
owner: "Lead"
status: proposed
review_date: "2026-12-24"
```

```yaml
id: LESSON-20261125-001
symptom: "P0-REV-02 started 76 subagents in two workflows (56 + 20 starts, 48 finished), used about 5.7M subagent tokens over 4.3 h, hit the Pro 5-hour limit once, and still left 11 of 38 rows open with 5 new MAJOR critic findings after round 2."
trigger: "Multi-file documentation rework with adversarial verification (P0-REV-02)."
root_cause: "The verification design scaled with the number of rows, not with risk: 7 clusters x 2 overlapping lenses plus a critic per round. Any MINOR residual re-queued its whole cluster. A fresh open-ended critic each round always found new MAJORs, so no round could converge. Every verifier re-read the same ~250 KB of docs. The ultracode reminder ('token cost is not a constraint') overrode the Pro-plan size guideline, and nothing enforced a budget."
evidence: "Workflow journals wf_62a7dcfb-074 and wf_49afa1cd-1e3; evidence E-12."
wasted_cost: "Estimated at more than half of the subagent tokens: the round-2 re-verification of clusters that were already clean, and the re-reads (estimate, not measured)."
prevention: "LD-39: a declared budget per workflow, enforced by a hook; one verifier per concern; MINOR findings recorded but not re-verified; stop once the acceptance criteria hold; re-verify only what a fix touched."
verification: "The next fan-out declares its budget, stays within 5 agents and 1 round, and the ledger (`python3 scripts/orchestration_guard.py report`) shows no ask or deny that the PO had to override."
owner: "Lead"
status: verified  # 2026-11-25, E-09c: 1 workflow (agents=2 rounds=1) plus 1 targeted re-check, no ask or deny in the ledger
review_date: "2026-12-25"
```
