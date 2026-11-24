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
