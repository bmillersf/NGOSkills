---
name: sf-datacloud-act
description: >
  Salesforce Data Cloud Act phase.
  TRIGGER when: user manages activations, activation targets, data actions,
  or downstream delivery of Data Cloud audiences and data; or says
  "activate this segment", "push audience to [destination]",
  "send segment to Marketing Cloud / Slack / etc.".
  DO NOT TRIGGER when: the task is segment creation (use sf-datacloud-segment),
  data retrieval/search work (use sf-datacloud-retrieve), or STDM/session tracing
  (use sf-ai-agentforce-observability).
license: MIT
compatibility: "Requires an external community sf data360 CLI plugin and a Data Cloud-enabled org"
metadata:
  version: "1.0.0"
  author: "Gnanasekaran Thoppae"
  phase: "Act"
  scoring: "100 points across 4 categories — newly authored 2026-05-22 (Activation Target + Schema 30 / Consent + Compliance 30 / Refresh + Delivery Cadence 20 / Verification 20)"
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
  dc_act_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Activation target + schema. Right activation target type for the destination (Marketing Cloud / Slack / Ad platforms / data action target); schema attributes match destination needs."
      automatic_hard_fail_rules:
        - "Activation target type doesn't match destination (e.g., generic file target wired to a system that has a native target)"
        - "Activation attributes mapped without confirming destination supports the field (silent drop)"
        - "Activation built on a segment that hasn't been published"
        - "Data Action wired without confirming the destination consumer can handle the cadence + payload shape"
    - name: Robustness
      max: 25
      hard_fail_below: 18
      description: "Consent + compliance. Heaviest robustness floor — activation is the egress point; compliance failures (TCPA / GDPR / CCPA / PECR) all manifest at this layer."
      automatic_hard_fail_rules:
        - "Activation runs without consulting Data Cloud Contact Point Consent (egress to channels the user opted out of)"
        - "Suppression list / DSAR / right-to-be-forgotten not respected"
        - "Cross-border data transfer activation (e.g., EU → US) without documented Standard Contractual Clauses / Adequacy Decision"
        - "PII / PHI activated to a destination the destination provider has no BAA / DPA in place to receive"
        - "Consent expiry not respected — activations include records whose consent has lapsed"
        - "Activation logs not retained per regulatory requirement (audit gap)"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Generic templates + downstream handoff. Use generic activation templates; segment work belongs to sf-datacloud-segment; STDM / observability to sf-ai-agentforce-observability."
      automatic_hard_fail_rules:
        - "Org-specific activation JSON written when generic activation-target.template.json / activation.template.json would serve"
        - "Segment creation authored here instead of routed to sf-datacloud-segment"
        - "Observability / STDM telemetry handled here instead of routed to sf-ai-agentforce-observability"
        - "Custom Apex authored here for activation logic when Data Cloud activation handles it natively"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Refresh + delivery cadence + verification. Cadence aligns with destination consumer needs; first-publish smoke verified; failure-mode handling (retry, dead-letter) defined."
      automatic_hard_fail_rules:
        - "Activation cadence faster than destination ingestion limits (rate-limit storm)"
        - "First-publish smoke not run (full audience pushed before single-record validation)"
        - "Activation failure mode undefined (no retry / dead-letter / alerting on partial delivery)"
        - "Audience size on first publish not measured against destination capacity (e.g., pushing 5M records to a destination with 100k/day cap)"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.c360_a_activation.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/data/data-cloud-dev/guide/dc-activation.html
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/data-cloud
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_datacloud_activation.htm
---

# sf-datacloud-act: Data Cloud Act Phase

Use this skill when the user needs **downstream delivery work**: activations, activation targets, data actions, or pushing Data Cloud outputs into other systems.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 100-pt rubric across 4 Act-phase categories, newly authored 2026-05-22. Robustness floor at 18 — activation is the egress point; compliance failures (TCPA / GDPR / CCPA / PECR) manifest here. Hard-fail rules block activation without consulting Contact Point Consent, ignored suppression / DSAR / right-to-be-forgotten, cross-border transfers without SCCs, PII/PHI activated to destinations without BAA/DPA, missing first-publish smoke test, undefined failure mode (no retry / dead-letter), and audience size mismatched with destination capacity. Disable with `eval_harness.enabled: false`.

## When This Skill Owns the Task

Use `sf-datacloud-act` when the work involves:
- `sf data360 activation *`
- `sf data360 activation-target *`
- `sf data360 data-action *`
- `sf data360 data-action-target *`
- verifying downstream delivery setup

Delegate elsewhere when the user is:
- still building the audience or insight → [sf-datacloud-segment](../sf-datacloud-segment/SKILL.md)
- exploring query/search or search indexes → [sf-datacloud-retrieve](../sf-datacloud-retrieve/SKILL.md)
- setting up base connections or ingestion → [sf-datacloud-connect](../sf-datacloud-connect/SKILL.md), [sf-datacloud-prepare](../sf-datacloud-prepare/SKILL.md)

---

## Required Context to Gather First

Ask for or infer:
- target org alias
- destination platform or downstream system
- whether the segment already exists and is published
- whether the user needs create, inspect, update, or delete
- whether the task is activation-focused or data-action-focused

---

## Core Operating Rules

- Verify the upstream segment or insight is healthy before creating downstream delivery assets.
- Run the shared readiness classifier before mutating activation assets: `node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase act --json`.
- Inspect available platforms and targets before mutating activation setup.
- Keep destination definitions deterministic and reusable where possible.
- Treat downstream credential and platform constraints as separate validation concerns.
- Prefer read-only inspection first when the destination state is unclear.

---

## Recommended Workflow

### 1. Classify readiness for act work
```bash
node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org> --phase act --json
```

### 2. Inspect destinations first
```bash
sf data360 activation platforms -o <org> 2>/dev/null
sf data360 activation-target list -o <org> 2>/dev/null
sf data360 data-action-target list -o <org> 2>/dev/null
```

### 3. Create the destination before the activation
```bash
sf data360 activation-target create -o <org> -f target.json 2>/dev/null
sf data360 data-action-target create -o <org> -f target.json 2>/dev/null
```

### 4. Create the activation or data action
```bash
sf data360 activation create -o <org> -f activation.json 2>/dev/null
sf data360 data-action create -o <org> -f action.json 2>/dev/null
```

### 5. Verify downstream readiness
```bash
sf data360 activation list -o <org> 2>/dev/null
sf data360 activation data -o <org> --name <activation> 2>/dev/null
```

---

## High-Signal Gotchas

- Activation design depends on a healthy published upstream segment.
- Destination configuration usually comes before activation creation.
- Downstream credential and platform constraints may live outside the Data Cloud CLI alone.
- Read-only inspection is the safest first move when the destination setup is unclear.
- `CdpActivationTarget` or `CdpActivationExternalPlatform` means the activation surface is gated for the current org/user; guide the user toward activation setup, permissions, and destination configuration instead of retrying blindly.

---

## Output Format

```text
Act task: <activation / activation-target / data-action / data-action-target>
Destination: <platform or target>
Target org: <alias>
Artifacts: <definition files / commands>
Verification: <listed / created / blocked>
Next step: <destination validation or downstream testing>
```

---

## References

- [README.md](README.md)
- [../sf-datacloud/assets/definitions/activation-target.template.json](../sf-datacloud/assets/definitions/activation-target.template.json)
- [../sf-datacloud/assets/definitions/activation.template.json](../sf-datacloud/assets/definitions/activation.template.json)
- [../sf-datacloud/assets/definitions/data-action-target.template.json](../sf-datacloud/assets/definitions/data-action-target.template.json)
- [../sf-datacloud/assets/definitions/data-action.template.json](../sf-datacloud/assets/definitions/data-action.template.json)
- [../sf-datacloud/UPSTREAM.md](../sf-datacloud/UPSTREAM.md)
- [../sf-datacloud/references/plugin-setup.md](../sf-datacloud/references/plugin-setup.md)
- [../sf-datacloud/references/feature-readiness.md](../sf-datacloud/references/feature-readiness.md)
