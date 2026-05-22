---
name: sf-datacloud-prepare
description: >
  Salesforce Data Cloud Prepare phase.
  TRIGGER when: user creates or manages Data Cloud data streams, DLOs, transforms,
  or Document AI configurations, or asks about ingestion into Data Cloud; or says
  "get data into Data Cloud", "upload a CSV to Data Cloud", "create a data stream for [source]".
  DO NOT TRIGGER when: the task is connection setup only (use sf-datacloud-connect),
  DMOs and identity resolution (use sf-datacloud-harmonize), or query/search work (use sf-datacloud-retrieve).
license: MIT
compatibility: "Requires an external community sf data360 CLI plugin and a Data Cloud-enabled org"
metadata:
  version: "1.0.0"
  author: "Gnanasekaran Thoppae"
  phase: "Prepare"
  scoring: "100 points across 4 categories — newly authored 2026-05-22 (Data Stream + DLO Design 30 / Schema + Field Hygiene 25 / Refresh Cadence + Volume 25 / DocAI / Transform 20)"
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
  dc_prepare_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Data Stream + DLO design. Right stream type for the source; DLO schema matches; primary key + record-modified field declared; ingestion mode (full / upsert / append) chosen correctly."
      automatic_hard_fail_rules:
        - "Stream type doesn't match source category (e.g., file-upload stream wired to a streaming source)"
        - "DLO without primary key declared (downstream Identity Resolution / harmonization breaks)"
        - "Record-modified-timestamp field absent on a stream that needs incremental refresh (full refresh on every cadence — over-fetch + cost)"
        - "Ingestion mode chosen wrong (append used for a source where upsert is correct → duplicate records pile up)"
        - "Stream / DLO created without targeting a specific data space when org has multiple spaces"
    - name: Robustness
      max: 25
      hard_fail_below: 14
      description: "Schema + field hygiene. Field types match source, regulated-data fields tagged, PII / PHI fields named per the documented convention."
      automatic_hard_fail_rules:
        - "Field types coerced incorrectly (string used when number/date is the source type — silent precision loss)"
        - "PII / PHI / financial fields not tagged in the DLO definition (downstream activations + segments can't enforce data-classification rules)"
        - "Source nullability not honored (DLO requires non-null where source allows null → ingestion drops records silently)"
        - "Field naming collides with reserved Data Cloud field names (DataSource__c, KQ_*, etc.)"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Generic JSON definition over org-specific payload + downstream handoff. Use assets/definitions/data-stream.template.json; hand off to sf-datacloud-harmonize for DMO / mapping work."
      automatic_hard_fail_rules:
        - "Org-specific stream JSON written when generic template would serve"
        - "DMO / mapping work authored here instead of routed to sf-datacloud-harmonize"
        - "Identity Resolution work authored here instead of routed to sf-datacloud-harmonize"
        - "Document AI configuration authored without confirming DocAI license is active in the org"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Refresh cadence + volume. Cadence matches downstream consumer needs; row volume estimated against Data Cloud ingestion limits; large-source pagination + chunking documented."
      automatic_hard_fail_rules:
        - "Refresh cadence faster than downstream consumers need (over-cost) or slower than they need (stale segments)"
        - "Row volume per refresh exceeds documented Data Cloud ingestion limits without chunking strategy"
        - "Large source-table refresh runs in a single window without slicing (timeout + retry storm)"
        - "Stream cadence not measured at production volume — first scale test is the production cutover"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-04
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.c360_a_data_streams.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/data/data-cloud-dev/guide/dc-dlo.html
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/data-cloud
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_datacloud_streams.htm
---

# sf-datacloud-prepare: Data Cloud Prepare Phase

> **Product rename note (2025-10-14):** Salesforce rebranded **Data Cloud** to **Data 360**. Official Help docs, UI labels, and tab names now read "Data 360" (e.g., "Data Streams in Data 360", "Data 360 Data Streams tab"). The `sf data360 *` CLI namespace already reflects this. Both names still refer to the same product; prefer **Data 360** in new user-facing copy, keep the existing `sf-datacloud-*` skill names and `sf data360` commands unchanged.

Use this skill when the user needs **ingestion and lake preparation work**: data streams, Data Lake Objects, transforms, or DocAI-based extraction.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 100-pt rubric across 4 Prepare-phase categories, newly authored 2026-05-22. Hard-fail rules block stream-type / source mismatch, missing primary key on DLO, wrong ingestion mode (append vs upsert), missing record-modified field on incremental streams, untagged PII/PHI fields, field type coercion mistakes, downstream Harmonize work hijacked here, refresh cadence misaligned with consumer needs, and unmeasured production-volume scale tests. Disable with `eval_harness.enabled: false`.

## When This Skill Owns the Task

Use `sf-datacloud-prepare` when the work involves:
- `sf data360 data-stream *`
- `sf data360 dlo *`
- `sf data360 transform *`
- `sf data360 docai *`
- choosing how data should enter Data Cloud

Delegate elsewhere when the user is:
- still creating/testing source connections → [sf-datacloud-connect](../sf-datacloud-connect/SKILL.md)
- mapping to DMOs or designing IR/data graphs → [sf-datacloud-harmonize](../sf-datacloud-harmonize/SKILL.md)
- querying ingested data → [sf-datacloud-retrieve](../sf-datacloud-retrieve/SKILL.md)

---

## Required Context to Gather First

Ask for or infer:
- target org alias
- source connection name
- source object / dataset
- desired stream type
- DLO naming expectations
- whether the user is creating, updating, running, or deleting a stream

---

## Core Operating Rules

- Verify the external plugin runtime before running Data Cloud commands.
- Run the shared readiness classifier before mutating ingestion assets: `node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase prepare --json`.
- Prefer inspecting existing streams and DLOs before creating new ingestion assets.
- Suppress linked-plugin warning noise with `2>/dev/null` for normal usage.
- Treat DLO naming and field naming as Data Cloud-specific, not CRM-native.
- Confirm whether each dataset should be treated as `Profile`, `Engagement`, or `Other` before creating the stream.
- Hand off to Harmonize only after ingestion assets are clearly healthy.

---

## Recommended Workflow

### 1. Classify readiness for prepare work
```bash
node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase prepare --json
```

### 2. Inspect existing ingestion assets
```bash
sf data360 data-stream list -o <org> 2>/dev/null
sf data360 dlo list -o <org> 2>/dev/null
```

### 3. Confirm the stream category before creation
Use these rules when suggesting categories:

| Category | Use for | Typical requirement |
|---|---|---|
| `Profile` | person/entity records | primary key |
| `Engagement` | time-based events or interactions | primary key + event time field |
| `Other` | reference/configuration/supporting datasets | primary key |

When the source is ambiguous, ask the user explicitly whether the dataset should be treated as `Profile`, `Engagement`, or `Other`.

### 4. Create or inspect streams intentionally
```bash
sf data360 data-stream get -o <org> --name <stream> 2>/dev/null
sf data360 data-stream create-from-object -o <org> --object Contact --connection SalesforceDotCom_Home 2>/dev/null
sf data360 data-stream create -o <org> -f stream.json 2>/dev/null
```

### 5. Check DLO shape
```bash
sf data360 dlo get -o <org> --name Contact_Home__dll 2>/dev/null
```

### 6. Only then move into harmonization
Once the stream and DLO are healthy, hand off to [sf-datacloud-harmonize](../sf-datacloud-harmonize/SKILL.md).

---

## High-Signal Gotchas

- CRM-backed stream behavior is not the same as fully custom connector-framework ingestion.
- Some external database connectors can be created via API while stream creation still requires UI flow or org-specific browser automation. Do not promise a pure CLI stream-creation path for every connector type.
- Stream deletion can also delete the associated DLO unless the delete mode says otherwise.
- DLO field naming differs from CRM field naming.
- Query DLO record counts with Data Cloud SQL instead of assuming list output is sufficient.
- `CdpDataStreams` means the stream module is gated for the current org/user; guide the user to provisioning/permissions review instead of retrying blindly.

---

## Output Format

```text
Prepare task: <stream / dlo / transform / docai>
Source: <connection + object>
Target org: <alias>
Artifacts: <stream names / dlo names / json definitions>
Verification: <passed / partial / blocked>
Next step: <harmonize or retrieve>
```

---

## References

- [README.md](README.md)
- [../sf-datacloud/assets/definitions/data-stream.template.json](../sf-datacloud/assets/definitions/data-stream.template.json)
- [../sf-datacloud/references/plugin-setup.md](../sf-datacloud/references/plugin-setup.md)
- [../sf-datacloud/references/feature-readiness.md](../sf-datacloud/references/feature-readiness.md)
