---
name: sf-datacloud-harmonize
description: >
  Salesforce Data Cloud Harmonize phase.
  TRIGGER when: user works with DMOs, mappings, relationships, identity resolution,
  unified profiles, data graphs, or universal IDs; or says "build a unified profile",
  "set up identity resolution", "map DMO fields".
  DO NOT TRIGGER when: the task is only about streams/DLOs (use sf-datacloud-prepare),
  segments/insights (use sf-datacloud-segment), retrieval/search (use sf-datacloud-retrieve),
  or STDM/session tracing (use sf-ai-agentforce-observability).
license: MIT
compatibility: "Requires an external community sf data360 CLI plugin and a Data Cloud-enabled org"
metadata:
  version: "1.0.0"
  author: "Gnanasekaran Thoppae"
  phase: "Harmonize"
  scoring: "120 points across 4 categories — newly authored 2026-05-22 (DMO + Mapping Design 35 / Identity Resolution Rules 40 / Data Graph + Relationships 25 / Verification 20)"
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric (4 categories) newly authored 2026-05-22 — mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  dc_harmonize_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 16
      description: "DMO + mapping design. Right standard DMO chosen (Customer / Individual / Account / etc.); custom DMO only when standard doesn't fit; field mappings preserve types + semantics."
      automatic_hard_fail_rules:
        - "Custom DMO created when a standard DMO fits (Customer / Individual / Account / Contact / Order / Subscription / etc.)"
        - "DLO field mapped to wrong DMO field (semantic mismatch — Email mapped to Phone, etc.)"
        - "Multiple DLOs mapping to the same DMO field without conflict resolution rule (last-write-wins surprise)"
        - "Mapping skipped on a field downstream segments / activations need (silent null at retrieval)"
    - name: Robustness
      max: 25
      hard_fail_below: 18
      description: "Identity Resolution rule integrity. Heaviest robustness floor — IR is what creates unified profiles; weak match rules either over-merge (privacy disaster) or under-merge (fragmented profiles)."
      automatic_hard_fail_rules:
        - "Match rule too loose (e.g., name + city only — over-merges distinct individuals)"
        - "Match rule too strict (e.g., requires exact email AND phone AND address — most records under-merge)"
        - "Reconciliation rule undefined (when fields conflict across sources, which wins?) — silent precedence default"
        - "Confidence threshold not declared — default merges/separates without explicit policy"
        - "IR run cadence not measured against downstream segment / activation freshness needs"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Data Graph + relationships + downstream handoff. Relationships modeled correctly; data graph definition reflects unified-profile shape; hand off to sf-datacloud-segment for audience work."
      automatic_hard_fail_rules:
        - "Relationship modeled at DLO level when DMO-level relationship is the documented pattern"
        - "Data Graph defined without explicit root entity (Customer-360 / Account-360 / Order-360 — purpose unclear)"
        - "Segment / Calculated Insight authored here instead of routed to sf-datacloud-segment"
        - "Activation work authored here instead of routed to sf-datacloud-act"
        - "Stream / DLO work authored here instead of routed to sf-datacloud-prepare"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Verification + IR run health. Unified record counts measured before/after IR change; match-rate + merge-rate metrics tracked."
      automatic_hard_fail_rules:
        - "IR rule change deployed without before/after unified record count"
        - "Match-rate / merge-rate metrics not captured (no signal on whether the rule shift over- or under-merged)"
        - "IR run failures (rejected records / null-key records / over-threshold rejection) not surfaced + investigated"
        - "Data graph refresh cadence not aligned with downstream consumer needs"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-04
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.c360_a_identity_resolution.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.c360a_api.meta/c360a_api/c360a_api_dmo.htm
    anchor: ""
    sha256: ""
    importance: authoritative
    note: "Previous dc-dmo.html path returned 404 on 2026-05-04; Data Cloud rebranded to Salesforce Data 360 — verify canonical DMO dev-guide URL."
  - url: https://architect.salesforce.com/
    anchor: ""
    sha256: ""
    importance: supplemental
    note: "Previous /design/data-cloud path returned 404 on 2026-05-04 following Data 360 rebrand."
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_datacloud_identity_resolution.htm
---

# sf-datacloud-harmonize: Data Cloud Harmonize Phase

Use this skill when the user needs **schema harmonization and unification work**: DMOs, field mappings, relationships, identity resolution, unified profiles, data graphs, or universal ID lookup.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 120-pt rubric across 4 Harmonize-phase categories, newly authored 2026-05-22. Robustness floor at 18 — Identity Resolution is what creates unified profiles; weak match rules either over-merge (privacy disaster) or under-merge (fragmented profiles). Hard-fail rules block custom DMO when standard fits, semantic mapping mismatches, missing reconciliation rules, match rules too loose / too strict, missing confidence threshold, IR run without before/after unified-record-count measurement, and downstream Segment / Act work hijacked here. Disable with `eval_harness.enabled: false`.

## When This Skill Owns the Task

Use `sf-datacloud-harmonize` when the work involves:
- `sf data360 dmo *`
- `sf data360 identity-resolution *`
- `sf data360 data-graph *`
- `sf data360 profile *`
- `sf data360 universal-id lookup`

Delegate elsewhere when the user is:
- still ingesting streams or building DLOs → [sf-datacloud-prepare](../sf-datacloud-prepare/SKILL.md)
- working on segment logic or calculated insights → [sf-datacloud-segment](../sf-datacloud-segment/SKILL.md)
- running SQL, describe, or search-index workflows → [sf-datacloud-retrieve](../sf-datacloud-retrieve/SKILL.md)

---

## Required Context to Gather First

Ask for or infer:
- source DLO and target DMO names
- whether the task is schema creation, mapping, IR, or graph-related
- target org alias
- whether a ruleset already exists
- the user’s desired unified entity model

---

## Core Operating Rules

- Inspect DMO schema before creating mappings.
- Run the shared readiness classifier before mutating harmonization assets: `node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase harmonize --json`.
- Prefer `dmo list --all` when browsing the catalog, but use first-page `dmo list` for fast readiness checks.
- Use `query describe` or `dmo get --json` instead of inventing unsupported describe flows.
- Treat identity resolution runs as asynchronous and verify results after execution.
- Keep unified-profile work separate from STDM/session tracing work.

---

## Recommended Workflow

### 1. Classify readiness for harmonize work
```bash
node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase harmonize --json
```

### 2. Inspect the catalog
```bash
sf data360 dmo list --all -o <org> 2>/dev/null
sf data360 identity-resolution list -o <org> 2>/dev/null
```

### 3. Inspect schema before mapping
```bash
sf data360 query describe -o <org> --table ssot__Individual__dlm 2>/dev/null
sf data360 dmo get -o <org> --name ssot__Individual__dlm --json 2>/dev/null
```

### 4. Create or review mappings intentionally
```bash
sf data360 dmo mapping-list -o <org> --source Contact_Home__dll --target ssot__Individual__dlm 2>/dev/null
sf data360 dmo map-to-canonical -o <org> --dlo Contact_Home__dll --dmo ssot__Individual__dlm --dry-run 2>/dev/null
```

### 5. Run IR only after mappings are trustworthy
```bash
sf data360 identity-resolution create -o <org> -f ir-ruleset.json 2>/dev/null
sf data360 identity-resolution run -o <org> --name Main 2>/dev/null
```

---

## High-Signal Gotchas

- `dmo list` should usually use `--all`.
- Use `query describe` or `dmo get --json`; there is no `dmo describe` command.
- Mapping and related commands can be sensitive to API-version differences.
- Unified DMO names are ruleset-specific rather than generic.
- Data graph definitions are sensitive to field selection and relationship shape.
- If `dmo list` works but `identity-resolution list` is gated, treat that as a phase-specific gap rather than a full Data Cloud outage.

---

## Output Format

```text
Harmonize task: <dmo / mapping / relationship / ir / data-graph>
Source/target: <dlo → dmo or ruleset/graph names>
Target org: <alias>
Artifacts: <json files / commands>
Verification: <passed / partial / blocked>
Next step: <segment / retrieve / follow-up>
```

---

## References

- [README.md](README.md)
- [../sf-datacloud/assets/definitions/dmo.template.json](../sf-datacloud/assets/definitions/dmo.template.json)
- [../sf-datacloud/assets/definitions/mapping.template.json](../sf-datacloud/assets/definitions/mapping.template.json)
- [../sf-datacloud/assets/definitions/relationship.template.json](../sf-datacloud/assets/definitions/relationship.template.json)
- [../sf-datacloud/assets/definitions/identity-resolution.template.json](../sf-datacloud/assets/definitions/identity-resolution.template.json)
- [../sf-datacloud/assets/definitions/data-graph.template.json](../sf-datacloud/assets/definitions/data-graph.template.json)
- [../sf-datacloud/references/feature-readiness.md](../sf-datacloud/references/feature-readiness.md)
