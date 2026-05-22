---
name: sf-datacloud-segment
description: >
  Salesforce Data Cloud Segment phase.
  TRIGGER when: user creates or publishes segments, manages calculated insights,
  inspects segment counts or membership, or troubleshoots audience SQL in Data Cloud;
  or says "segment for donors / lapsed donors / email campaign", "audience rule for [behavior]",
  "build a segment".
  DO NOT TRIGGER when: the task is DMO/mapping/identity-resolution work (use sf-datacloud-harmonize),
  activation work (use sf-datacloud-act), query/search-index work (use sf-datacloud-retrieve),
  or STDM/session tracing (use sf-ai-agentforce-observability).
license: MIT
compatibility: "Requires an external community sf data360 CLI plugin and a Data Cloud-enabled org"
metadata:
  version: "1.0.0"
  author: "Gnanasekaran Thoppae"
  phase: "Segment"
  scoring: "100 points across 4 categories — newly authored 2026-05-22 (Segment Definition + SQL 30 / Calculated Insight Reuse 25 / Publish + Refresh Cadence 25 / Verification 20)"
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
  dc_segment_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Segment definition + SQL correctness. Right DMO root, filter logic resolves business intent, no CRM-SOQL syntax in Data-Cloud-SQL contexts, calculated insight references resolve."
      automatic_hard_fail_rules:
        - "Segment built on a DLO instead of a DMO (segments operate on harmonized data)"
        - "CRM SOQL syntax used in segment SQL (Data Cloud SQL is different — silent SQL parse error or wrong semantics)"
        - "Filter logic AND/OR placement doesn't reflect business intent (membership semantics off)"
        - "Calculated Insight referenced that doesn't exist or isn't published (segment SQL fails at compile)"
        - "Segment built on Customer DMO when audience requires Account / Subscription DMO root (wrong unit of audience)"
    - name: Robustness
      max: 25
      hard_fail_below: 14
      description: "Consent + suppression + privacy. Segment honors consent, opt-out / unsubscribe records suppressed, PII filters scoped, regulated-data audience use justified."
      automatic_hard_fail_rules:
        - "Marketing segment without consent / opt-out filter (downstream activation can email unsubscribers — compliance incident)"
        - "Data Cloud Contact Point Consent not consulted in the segment definition"
        - "PII / PHI filter not scoped per industry rule (HIPAA / GDPR / state-PII boundary)"
        - "Suppression list (legal hold / DSAR / right-to-be-forgotten) not respected by segment"
        - "Audience that includes minors / sensitive populations without policy reference"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Calculated Insight reuse + downstream handoff. Reuse existing CIs over duplicate inline calculations; hand off to sf-datacloud-act for activation work."
      automatic_hard_fail_rules:
        - "Inline calculation duplicating an existing Calculated Insight (drift + maintenance debt)"
        - "Activation authored here instead of routed to sf-datacloud-act"
        - "Retrieval / search work authored here instead of routed to sf-datacloud-retrieve"
        - "Segment SQL hand-rolled when Calculated Insight + simple segment filter is the documented pattern"
        - "Org-specific segment JSON written when generic template would serve"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Publish + refresh cadence + verification. Refresh cadence aligns with downstream activation cadence; member-count verified before publish; SQL execution time bounded."
      automatic_hard_fail_rules:
        - "Refresh cadence faster than downstream consumer needs (over-cost) OR slower than they need (stale activation)"
        - "Segment published without member-count sanity check"
        - "Member-count drastically different from prior version (>20%) without investigation (silent IR / mapping change broke definition)"
        - "Segment SQL execution time exceeds documented Data Cloud query budget without query-plan tuning"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.c360_a_segmentation.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/data/data-cloud-dev/guide/dc-segments.html
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/data-cloud
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_datacloud_segmentation.htm
---

# sf-datacloud-segment: Data Cloud Segment Phase

Use this skill when the user needs **audience and insight work**: segments, calculated insights, publish workflows, member counts, or troubleshooting Data Cloud segment SQL.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 100-pt rubric across 4 Segment-phase categories, newly authored 2026-05-22. Hard-fail rules block segments built on DLO instead of DMO, CRM-SOQL syntax in Data-Cloud-SQL contexts, missing consent/opt-out filters on marketing segments, missing suppression-list (legal hold / DSAR), inline duplication of existing Calculated Insights, member-count drift >20% without investigation, and downstream Activation work hijacked here. Disable with `eval_harness.enabled: false`.

## When This Skill Owns the Task

Use `sf-datacloud-segment` when the work involves:
- `sf data360 segment *`
- `sf data360 calculated-insight *`
- segment publish workflows
- member counts and segment troubleshooting
- calculated insight execution and verification

Delegate elsewhere when the user is:
- still building DMOs, mappings, or identity resolution → [sf-datacloud-harmonize](../sf-datacloud-harmonize/SKILL.md)
- activating a segment downstream → [sf-datacloud-act](../sf-datacloud-act/SKILL.md)
- writing read-only SQL or search-index queries → [sf-datacloud-retrieve](../sf-datacloud-retrieve/SKILL.md)

---

## Required Context to Gather First

Ask for or infer:
- target org alias
- unified DMO or base entity name
- whether the user wants create, publish, inspect, or troubleshoot
- whether the asset is a segment or calculated insight
- expected success metric: member count, aggregate value, or publish status

---

## Core Operating Rules

- Treat Data Cloud segment SQL as distinct from CRM SOQL.
- Run the shared readiness classifier before mutating audience assets: `node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase segment --json`.
- Prefer reusable JSON definitions for repeatable segment and CI creation.
- Use `--api-version 64.0` when segment creation behavior is unstable on newer defaults.
- Verify with counts or SQL after publish/run steps instead of assuming success.
- Use SQL joins rather than `segment members` when readable member details are needed.

---

## Recommended Workflow

### 1. Classify readiness for segment work
```bash
node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase segment --json
```

### 2. Inspect current state
```bash
sf data360 segment list -o <org> 2>/dev/null
sf data360 calculated-insight list -o <org> 2>/dev/null
```

### 3. Create with reusable JSON definitions
```bash
sf data360 segment create -o <org> -f segment.json --api-version 64.0 2>/dev/null
sf data360 calculated-insight create -o <org> -f ci.json 2>/dev/null
```

### 4. Publish or run explicitly
```bash
sf data360 segment publish -o <org> --name My_Segment 2>/dev/null
sf data360 calculated-insight run -o <org> --name Lifetime_Value 2>/dev/null
```

### 5. Verify with counts or SQL
```bash
sf data360 segment count -o <org> --name My_Segment 2>/dev/null
sf data360 query sql -o <org> --sql 'SELECT COUNT(*) FROM "UnifiedssotIndividualMain__dlm"' 2>/dev/null
```

---

## High-Signal Gotchas

- Segment creation can require `--api-version 64.0`.
- `segment members` returns opaque IDs; use SQL joins when human-readable member details are needed.
- Segment SQL is not SOQL.
- Calculated insight assets and segment SQL have different limitations.
- Publish/run steps may kick off asynchronous work even when the command returns quickly.
- An empty segment or calculated-insight list usually means the module is reachable but unconfigured, not unavailable.

---

## Output Format

```text
Segment task: <segment / calculated-insight>
Action: <create / publish / inspect / troubleshoot>
Target org: <alias>
Artifacts: <definition files / commands>
Verification: <member count / query result / publish state>
Next step: <act / retrieve / follow-up>
```

---

## References

- [README.md](README.md)
- [../sf-datacloud/assets/definitions/calculated-insight.template.json](../sf-datacloud/assets/definitions/calculated-insight.template.json)
- [../sf-datacloud/assets/definitions/segment.template.json](../sf-datacloud/assets/definitions/segment.template.json)
- [../sf-datacloud/references/feature-readiness.md](../sf-datacloud/references/feature-readiness.md)
- [../sf-datacloud/UPSTREAM.md](../sf-datacloud/UPSTREAM.md)
