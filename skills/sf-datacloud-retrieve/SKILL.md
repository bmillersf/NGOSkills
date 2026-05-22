---
name: sf-datacloud-retrieve
description: >
  Salesforce Data Cloud Retrieve phase.
  TRIGGER when: user runs Data Cloud SQL, describe, async queries, vector search,
  search-index workflows, or metadata introspection for Data Cloud objects; or says
  "query Data Cloud", "Data Cloud SQL", "search Data Cloud vectors", "run a DC async query".
  DO NOT TRIGGER when: the task is standard CRM SOQL (use sf-soql), segment creation
  or calculated insight design (use sf-datacloud-segment), or STDM/session tracing/parquet
  analysis (use sf-ai-agentforce-observability).
license: MIT
compatibility: "Requires an external community sf data360 CLI plugin and a Data Cloud-enabled org"
metadata:
  version: "1.0.0"
  author: "Gnanasekaran Thoppae"
  phase: "Retrieve"
  scoring: "100 points across 4 categories — newly authored 2026-05-22 (Query Plane Choice 25 / SQL Correctness + DC vs CRM 25 / Vector / Hybrid Search 25 / Performance 25)"
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "100-pt rubric (4 categories) newly authored 2026-05-22 — mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  dc_retrieve_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Query plane choice + Data Cloud SQL correctness. Right plane (sync SQL / paginated / async) for the workload; Data Cloud SQL syntax (not CRM SOQL); table reference correct (DLO vs DMO suffix conventions)."
      automatic_hard_fail_rules:
        - "CRM SOQL syntax used in Data Cloud SQL context (different planes — silent parse error or wrong semantics)"
        - "DLO suffix __dll referenced when DMO suffix __dlm was needed (or vice versa)"
        - "Sync SQL used for a query that needs >1 minute to run (timeout — should use async query workflow)"
        - "describe used on a table that doesn't exist without first checking via list (silent error)"
        - "Multi-data-space org queried without targeting a specific data space"
    - name: Robustness
      max: 25
      hard_fail_below: 12
      description: "Query result handling + auth + governance. Result-set size bounded; auth refreshed on long async runs; governance (audit / row-level security) honored."
      automatic_hard_fail_rules:
        - "Async query started without polling / status-check loop (results never collected)"
        - "Result-set size unbounded — large query streams full result without pagination"
        - "Long-running async query without auth-refresh strategy (token expires mid-run)"
        - "Row-level security / sharing enforcement not honored when running on behalf of a restricted user"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Vector / hybrid search + downstream handoff. Right search type for the use case; search index up-to-date; segment work to sf-datacloud-segment."
      automatic_hard_fail_rules:
        - "Vector search used when keyword + structured filter is the right pattern (no semantic value)"
        - "Hybrid search misconfigured (vector weight + keyword weight imbalanced)"
        - "Search index not refreshed before query (stale results)"
        - "Segment authored here instead of routed to sf-datacloud-segment"
        - "STDM / session-trace queries authored here instead of routed to sf-ai-agentforce-observability"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Query performance + pagination + caching. Query plan reasonable for table volumes; pagination on large result sets; caching where idempotent."
      automatic_hard_fail_rules:
        - "Query without LIMIT on large DLO/DMO (governor / cost surprise)"
        - "Repeat-query pattern without caching strategy (cost amplifier)"
        - "Pagination not applied to results >10k rows"
        - "Query plan not measured at production volume — first scale check is the production cutover"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://developer.salesforce.com/docs/data/data-cloud-query/guide/overview.html
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.c360_a_query_editor.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/data-cloud
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_datacloud_query.htm
---

# sf-datacloud-retrieve: Data Cloud Retrieve Phase

Use this skill when the user needs **query, search, and metadata introspection** for Data Cloud: sync SQL, paginated SQL, async query workflows, table describe, vector search, hybrid search, or search index operations.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 100-pt rubric across 4 Retrieve-phase categories, newly authored 2026-05-22. Hard-fail rules block CRM SOQL syntax in Data Cloud SQL contexts, DLO/DMO suffix mistakes (__dll vs __dlm), sync SQL for >1min queries (should be async), async query without polling loop, vector search misuse, search index not refreshed before query, queries without LIMIT on large tables, and segment / STDM work hijacked here. Disable with `eval_harness.enabled: false`.

## When This Skill Owns the Task

Use `sf-datacloud-retrieve` when the work involves:
- `sf data360 query *`
- `sf data360 search-index *`
- `sf data360 metadata *`
- `sf data360 profile *` or `sf data360 insight *` inspection
- understanding Data Cloud SQL results or query shape

Delegate elsewhere when the user is:
- writing standard CRM SOQL only → [sf-soql](../sf-soql/SKILL.md)
- designing segment or calculated insight assets → [sf-datacloud-segment](../sf-datacloud-segment/SKILL.md)
- analyzing STDM/session tracing/parquet telemetry → [sf-ai-agentforce-observability](../sf-ai-agentforce-observability/SKILL.md)

---

## Required Context to Gather First

Ask for or infer:
- target org alias
- whether the user needs quick count, medium result set, large export, schema inspection, or semantic search
- table/index name if known
- whether the task is read-only SQL or search-index lifecycle management

---

## Core Operating Rules

- Treat Data Cloud SQL as its own query language, not SOQL.
- Run the shared readiness classifier before relying on query/search surfaces: `node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase retrieve --json`.
- Use describe before guessing columns.
- Prefer `sqlv2` or async query flows for larger result sets.
- Use vector search or hybrid search only when the search index lifecycle is healthy.
- Keep STDM/parquet/session-tracing workflows out of this skill family.

---

## Recommended Workflow

### 1. Classify readiness for retrieve work
```bash
node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase retrieve --json
# optional query-plane probe, only with a real table name
node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase retrieve --describe-table MyDMO__dlm --json
```

### 2. Choose the smallest correct query shape
```bash
sf data360 query sql -o <org> --sql 'SELECT COUNT(*) FROM "ssot__Individual__dlm"' 2>/dev/null
sf data360 query sqlv2 -o <org> --sql 'SELECT * FROM "ssot__Individual__dlm"' 2>/dev/null
sf data360 query async-create -o <org> --sql 'SELECT * FROM "ssot__Individual__dlm"' 2>/dev/null
```

### 3. Use describe before guessing fields
```bash
sf data360 query describe -o <org> --table ssot__Individual__dlm 2>/dev/null
```

### 4. Use vector or hybrid search only when an index exists
```bash
sf data360 search-index list -o <org> 2>/dev/null
sf data360 query vector -o <org> --index Knowledge_Index --query "reset password" --limit 5 2>/dev/null
sf data360 query hybrid -o <org> --index Knowledge_Index --query "reset password" --limit 5 2>/dev/null
sf data360 query hybrid -o <org> --index Insurance_Index --query "weather damage coverage" --prefilter "Type_of_Insurance__c='Home'" --limit 10 2>/dev/null
```

### 5. Reuse curated search-index examples when creating indexes
Use the phase-owned examples instead of inventing JSON from scratch:
- `examples/search-indexes/vector-knowledge.json`
- `examples/search-indexes/hybrid-structured.json`

---

## High-Signal Gotchas

- Data Cloud SQL is not SOQL.
- Table names should be double-quoted in SQL.
- `sqlv2` is better than ad hoc OFFSET paging for medium result sets.
- async query is preferable for large results.
- search-index operations and vector/hybrid queries depend on the index lifecycle being healthy.
- Hybrid search can use `--prefilter`, but only on fields configured as prefilter-capable when the search index was created.
- HNSW index parameters are typically read-only on create; leave `userValues: []` unless the platform explicitly documents otherwise.
- `query describe` is not a universal tenant probe; only run it with a known DMO or DLO table after broader readiness has been confirmed.

---

## Output Format

```text
Retrieve task: <sql / sqlv2 / async / describe / vector / search-index>
Target org: <alias>
Target object: <table or index>
Commands: <key commands run>
Verification: <query rows / schema / status>
Next step: <segment / harmonize / follow-up>
```

---

## References

- [README.md](README.md)
- [examples/search-indexes/vector-knowledge.json](examples/search-indexes/vector-knowledge.json)
- [examples/search-indexes/hybrid-structured.json](examples/search-indexes/hybrid-structured.json)
- [../sf-datacloud/assets/definitions/search-index.template.json](../sf-datacloud/assets/definitions/search-index.template.json)
- [../sf-datacloud/references/plugin-setup.md](../sf-datacloud/references/plugin-setup.md)
- [../sf-datacloud/references/feature-readiness.md](../sf-datacloud/references/feature-readiness.md)
