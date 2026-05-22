---
name: sf-industry-media
description: >
  Media Cloud architecture stub with industry-first routing precedence. Owns
  `vlocity_cmt__` (or `vlocity_media__` in some installs) namespace claim and
  industry-specific process routing; delegates implementation to OmniStudio common-core skills.
  TRIGGER when: user says "subscription management", "OTT/streaming subscriber",
  "ad sales order", "media campaign response", "audience monetization",
  "content rights management", "entitlement for a subscriber",
  "billing account for a media subscriber", or designs subscriber lifecycle / advertising
  sales workflows on Salesforce Media Cloud.
  DO NOT TRIGGER when: generic Sales Cloud pipeline (use sf-sales-cloud), generic
  Service Cloud case work (use sf-service-cloud), Apex-only work (use sf-apex),
  LWC-only work (use sf-lwc), Flow-only work (use sf-flow), OmniScript build
  (use sf-industry-commoncore-omniscript), Integration Procedure build
  (use sf-industry-commoncore-integration-procedure), Data Mapper build
  (use sf-industry-commoncore-datamapper), FlexCard build
  (use sf-industry-commoncore-flexcard), callable Apex for IPs
  (use sf-industry-commoncore-callable-apex), OmniStudio dependency analysis
  (use sf-industry-commoncore-omnistudio-analyze), or Data Cloud work (use sf-datacloud).
license: MIT
compatibility: "Requires Media Cloud license + `vlocity_cmt__` (shared with Communications) or `vlocity_media__` managed package"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "50 points across 5 categories — Industry detection 10 / Object model 10 / Subscription lifecycle 10 / Routing to common-core 10 / License gating 10"
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "50-pt rubric (5 categories) extracted from existing 'Scoring rubric (50 points)' section in this SKILL.md (line 73). Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  media_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Industry detection + Object model. Maps to Industry detection (10) + Object model (10). Media disambiguated from Comms (shared vlocity_cmt__ namespace); first-class objects (Subscriber / BillingAccount / Entitlement / Subscription)."
      automatic_hard_fail_rules:
        - "vlocity_cmt__ namespace detected but Media not disambiguated from Comms (license + object presence is the discriminator — Subscriber + BillingAccount points to Media)"
        - "Subscribers modeled as plain Contact without Subscriber extension"
        - "Ad sales orders as Opportunity instead of ASM objects (AdInsertionOrder / AdLineItem / AdDelivery)"
        - "Cross-contaminating vlocity_cmt__ metadata between Comms and Media orgs"
        - "Hardcoded content availability instead of ContentRight windows"
    - name: Robustness
      max: 25
      hard_fail_below: 12
      description: "Subscription lifecycle. Maps to Subscription lifecycle (10). Pause/resume/upgrade via SLM (Subscription Lifecycle Management), not custom fields."
      automatic_hard_fail_rules:
        - "Subscription state machine built in Flow instead of SLM"
        - "Custom status fields used to track subscription lifecycle (active / paused / canceled) — SLM owns these states"
        - "Pause/resume/upgrade implemented via custom Apex when SLM provides the lifecycle"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Routing to common-core. Maps to Routing to common-core (10). Media is OmniStudio-first; aggressive delegation."
      automatic_hard_fail_rules:
        - "OmniScript / IP / Data Mapper / FlexCard / Callable Apex authored here instead of delegated"
        - "Generic Sales/Service Cloud routing in Media-detected org (industry override)"
        - "Standard automation work authored here instead of routed to sf-flow / sf-apex"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "License gating. Maps to License gating (10). SLM, ASM (Ad Sales Management), Industries Billing add-ons confirmed."
      automatic_hard_fail_rules:
        - "SLM features recommended without confirming SLM license"
        - "ASM features recommended without confirming ASM license"
        - "Industries Billing recommended without confirming the Industries Billing add-on (vs external billing path)"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.media_cloud_intro.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/industries/media
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_industries_media.htm
---

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 50-pt rubric across 5 router categories, mapped onto the 4-dim shape. Correctness floor at 14 — vlocity_cmt__ is shared with Comms; misattribution corrupts the routing decision. Hard-fail rules block undisambiguated namespace, Subscribers as plain Contact, ad sales orders as Opportunity, hardcoded content availability instead of ContentRight, subscription state machines in Flow instead of SLM, and license-gated features recommended without entitlement check. Disable with `eval_harness.enabled: false`.

## When this skill owns the task

Own the task whenever the org is Media Cloud and work touches `Subscriber`, `BillingAccount`, `Entitlement`, `Subscription`, `CampaignResponse`, `Audience`, `ContentRight`, or media order/subscription constructs. Anchor processes:

- Subscription management (OTT, print, hybrid) — activate/upgrade/pause/cancel
- Advertising sales (IO, line item, placement, delivery recon)
- Audience monetization (segment → activation → delivery)
- Content rights / windowing
- Billing account + entitlement orchestration

Like Comms, Media is **heavily OmniStudio-centric** — route implementation to common-core.

## Industry precedence note

When Media Cloud detected, this skill wins over `sf-sales-cloud`/`sf-service-cloud`. Namespace is typically `vlocity_cmt__` (shared with Comms Cloud after the Salesforce Comms/Media Tech merge), but some installs use `vlocity_media__`. Always disambiguate via license + object presence (`Subscriber`, `BillingAccount`).

## Required context to gather first

1. Media Cloud edition + namespace (`vlocity_cmt__` vs `vlocity_media__`)?
2. SLM enabled?
3. ASM enabled?
4. External billing or Industries Billing?
5. Data Cloud for audience / engagement?

## Workflow phases

1. **Detection** — confirm license + namespace.
2. **Process ID** — subscription, ad sales, audience, content rights.
3. **Route** — subscriber wizard → `sf-industry-commoncore-omniscript`; subscription orchestration → `sf-industry-commoncore-integration-procedure`; billing sync → `sf-industry-commoncore-datamapper`; namespace audit → `sf-industry-commoncore-omnistudio-analyze`.
4. **Testing** — state transitions via `sf-testing`; `sf-demo-validate` end-to-end.

## Scoring rubric (50 points)

| Category | Pts | Criteria |
|---|---|---|
| Industry detection | 10 | Media disambiguated from Comms (shared namespace) |
| Object model | 10 | `Subscriber`/`BillingAccount`/`Entitlement` used properly |
| Subscription lifecycle | 10 | Pause/resume/upgrade via SLM, not custom fields |
| Routing to common-core | 10 | OmniStudio work delegated |
| License gating | 10 | SLM, ASM, Industries Billing add-ons gated |

## Anti-patterns

- Subscribers as plain `Contact` without `Subscriber` extension.
- Subscription state machines in Flow instead of SLM.
- Cross-contaminating `vlocity_cmt__` metadata between Comms and Media orgs.
- Ad sales orders as `Opportunity` instead of ASM objects.
- Hard-coded content availability instead of `ContentRight` windows.

## Industry object cheat sheet

| Object | Purpose |
|---|---|
| `Subscriber` | Media subscriber (extends Contact/PA) |
| `BillingAccount` | Subscriber billing relationship |
| `Entitlement` | Service/content entitlement |
| `Subscription` | Active subscription |
| `SubscriptionLine` | Subscription line |
| `Order__c` (vlocity) | Commercial media order |
| `CampaignResponse` | Marketing campaign response |
| `Audience` | Audience segment |
| `AudienceActivation` | Activation target |
| `ContentRight` | Rights window |
| `AdInsertionOrder` | Ad IO header |
| `AdLineItem` | IO placement line |
| `AdDelivery` | Delivered impressions |
| `MediaOfferBundle` | Offer bundle |

## Delegation table

| Concern | Skill |
|---|---|
| Subscriber onboarding / change wizard | `sf-industry-commoncore-omniscript` |
| Billing sync, provisioning, subscription orchestration | `sf-industry-commoncore-integration-procedure` |
| External billing/CMS mapping | `sf-industry-commoncore-datamapper` |
| Subscriber 360 / entitlement card | `sf-industry-commoncore-flexcard` |
| Callable Apex for IPs | `sf-industry-commoncore-callable-apex` |
| Namespace audit vs Comms | `sf-industry-commoncore-omnistudio-analyze` |
| Custom Apex (rating/billing ext) | `sf-apex` |
| Record-triggered automation | `sf-flow` |
| Audience / engagement signals | `sf-datacloud` |
