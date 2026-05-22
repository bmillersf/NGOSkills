---
name: sf-datacloud-connect
description: >
  Salesforce Data Cloud Connect phase.
  TRIGGER when: user manages Data Cloud connections, connectors, connector
  metadata, tests a connection, browses source objects or databases, or sets
  up a new source system; or says "connect [source] to Data Cloud", "set up
  a Data Cloud connector", "create a new connector in Data Cloud", "test
  connector authentication", "browse source tables for Data Cloud", "wire
  S3 / Snowflake / BigQuery / Azure to Data Cloud", "configure a
  connection from [external system]", "validate the connection metadata",
  or "troubleshoot a connector that can't reach the source".
  DO NOT TRIGGER when: the task is about data streams or DLOs (use sf-datacloud-prepare),
  DMOs or identity resolution (use sf-datacloud-harmonize), retrieval/search (use sf-datacloud-retrieve),
  or STDM telemetry (use sf-ai-agentforce-observability).
license: MIT
compatibility: "Requires an external community sf data360 CLI plugin and a Data Cloud-enabled org"
metadata:
  version: "1.0.0"
  author: "Gnanasekaran Thoppae"
  phase: "Connect"
  scoring: "100 points across 4 categories — newly authored 2026-05-22 (Connector Selection 30 / Auth + Credential Hygiene 30 / Source Discovery 20 / Verification 20)"
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
  dc_connect_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Connector selection. Right connector type for the source (S3 / Snowflake / BigQuery / Azure / Salesforce CRM / etc.); --connector-type flag honored on commands that require it."
      automatic_hard_fail_rules:
        - "connection list run without --connector-type (the flag is required; command fails or returns subset)"
        - "Wrong connector type chosen for the source (e.g., generic JDBC when a native Snowflake connector exists)"
        - "Connection created without confirming the source system's connector is supported in the org's Data Cloud edition"
        - "Connector created when an existing one already targets the same source (duplication)"
    - name: Robustness
      max: 25
      hard_fail_below: 18
      description: "Auth + credential hygiene. Heaviest robustness floor — connector credentials are external-system entry points; weak credential management is a direct cross-system compromise path."
      automatic_hard_fail_rules:
        - "Inline credentials / API keys in connector metadata or scripts (must use Named Credential / secret store)"
        - "Credential rotation policy not documented for the connector"
        - "Long-lived service-account credentials with no expiry / no rotation cadence"
        - "Connection test (authentication probe) skipped before saving the connector"
        - "OAuth-based connector wired without confirming the OAuth scope is minimum-privilege for the documented use case"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Source discovery + downstream handoff. Browse source objects/tables before downstream Prepare phase consumes them; hand off cleanly to sf-datacloud-prepare."
      automatic_hard_fail_rules:
        - "Source object/table list not browsed before designing downstream Data Streams (Prepare phase has no menu of what's available)"
        - "Connect-phase work bleeding into Prepare (creating Data Streams here instead of routing to sf-datacloud-prepare)"
        - "External CRM connector wired here when the source is another Salesforce org (specific Salesforce-to-Salesforce connector pattern needed)"
        - "Source schema captured but not communicated downstream (Prepare phase has to re-discover)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Verification. Connection authenticates, source list returns expected schema, latency is acceptable for ingestion frequency."
      automatic_hard_fail_rules:
        - "Connection test passed but source-list probe never run (auth works, but readability of expected tables/objects unverified)"
        - "Latency / throughput characteristics of the connector not measured for the documented ingestion cadence (large-table refresh exceeds the window)"
        - "Connector regression after upgrade not retested (silent breaking changes between versions)"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.c360_a_data_connectors.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/data/data-cloud-dev/guide/dc-create-data-stream.html
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/data-cloud
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_datacloud_connectors.htm
---

# sf-datacloud-connect: Data Cloud Connect Phase

Use this skill when the user needs **source connection work**: connector discovery, connection metadata, connection testing, browsing source objects, or understanding what connector type to use.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 100-pt rubric across 4 Connect-phase categories, newly authored 2026-05-22. Robustness floor at 18 — connector credentials are external-system entry points; weak credential management is a direct cross-system compromise path. Hard-fail rules block missing --connector-type flag, wrong connector type chosen, inline credentials, missing rotation policy, OAuth scopes broader than minimum-privilege, source-discovery skipped, and downstream Prepare work hijacked here. Disable with `eval_harness.enabled: false`.

## When This Skill Owns the Task

Use `sf-datacloud-connect` when the work involves:
- `sf data360 connection *`
- connector catalog inspection
- connection creation, update, test, or delete
- browsing source objects, fields, databases, or schemas
- identifying connector types already in use

Delegate elsewhere when the user is:
- creating data streams or DLOs → [sf-datacloud-prepare](../sf-datacloud-prepare/SKILL.md)
- creating DMOs, mappings, IR rulesets, or data graphs → [sf-datacloud-harmonize](../sf-datacloud-harmonize/SKILL.md)
- writing Data Cloud SQL or search-index workflows → [sf-datacloud-retrieve](../sf-datacloud-retrieve/SKILL.md)

---

## Required Context to Gather First

Ask for or infer:
- target org alias
- connector type or source system
- whether the user wants inspection only or live mutation
- connection name if one already exists
- whether credentials are already configured outside the CLI

---

## Core Operating Rules

- Verify the plugin runtime first; see [../sf-datacloud/references/plugin-setup.md](../sf-datacloud/references/plugin-setup.md).
- Run the shared readiness classifier before mutating connections: `node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase connect --json`.
- Prefer read-only discovery before connection creation.
- Suppress linked-plugin warning noise with `2>/dev/null` for standard usage.
- Remember that `connection list` requires `--connector-type`.
- Discover existing connector types from streams first when the org is unfamiliar.
- API-based external connector creation is supported, but payloads are connector-specific.
- Do not use query-plane errors from other phases to declare connect work unavailable.

---

## Recommended Workflow

### 1. Classify readiness for connect work
```bash
node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase connect --json
```

### 2. Discover connector types
```bash
sf data360 connection connector-list -o <org> 2>/dev/null
sf data360 data-stream list -o <org> 2>/dev/null
```

### 3. Inspect connections by type
```bash
sf data360 connection list -o <org> --connector-type SalesforceDotCom 2>/dev/null
sf data360 connection list -o <org> --connector-type REDSHIFT 2>/dev/null
```

### 4. Inspect a specific connection
```bash
sf data360 connection get -o <org> --name <connection> 2>/dev/null
sf data360 connection objects -o <org> --name <connection> 2>/dev/null
sf data360 connection fields -o <org> --name <connection> 2>/dev/null
```

### 5. Test or create only after discovery
```bash
sf data360 connection test -o <org> --name <connection> 2>/dev/null
sf data360 connection create -o <org> -f connection.json 2>/dev/null
```

### 6. Start from curated example payloads for external connectors
Use the phase-owned examples before inventing a payload from scratch:
- `examples/connections/heroku-postgres.json`
- `examples/connections/redshift.json`

To discover payload fields for a connector type not covered by those examples, create one in the UI and inspect it:
```bash
sf api request rest "/services/data/v66.0/ssot/connections/<id>" -o <org>
```

---

## High-Signal Gotchas

- `connection list` has no true global "list all" mode; query by connector type.
- The connection catalog name and connection connector type are not always the same label.
- Some external connector credential setup still depends on UI-side configuration.
- Use connection metadata inspection before guessing available source objects or databases.
- An empty connection list usually means "enabled but not configured yet", not "feature disabled".
- Heroku Postgres and Redshift payloads use different credential / parameter names. Reuse the curated examples instead of guessing.

---

## Output Format

```text
Connect task: <inspect / create / test / update>
Connector type: <SalesforceDotCom / REDSHIFT / S3 / ...>
Target org: <alias>
Commands: <key commands run>
Verification: <passed / partial / blocked>
Next step: <prepare phase or connector follow-up>
```

---

## References

- [README.md](README.md)
- [examples/connections/heroku-postgres.json](examples/connections/heroku-postgres.json)
- [examples/connections/redshift.json](examples/connections/redshift.json)
- [../sf-datacloud/references/plugin-setup.md](../sf-datacloud/references/plugin-setup.md)
- [../sf-datacloud/references/feature-readiness.md](../sf-datacloud/references/feature-readiness.md)
- [../sf-datacloud/UPSTREAM.md](../sf-datacloud/UPSTREAM.md)
