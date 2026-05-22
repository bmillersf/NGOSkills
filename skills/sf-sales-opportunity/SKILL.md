---
name: sf-sales-opportunity
description: >
  Sales Cloud Opportunity: deal modeling, pipeline, Teams and Splits, Contact
  Roles, stage history, Pipeline Inspection, Deal Insights. Industry-first.
  TRIGGER when: user designs Opportunity work — stage model, record types,
  Splits, Teams, Contact Roles, stage history / velocity, Pipeline Inspection,
  Deal Insights, territory assignment, Opp→Quote hand-off, probability
  tuning, or duplicate detection.
  DO NOT TRIGGER when: scope is multi-capability Sales (sf-sales-cloud),
  Forecasts (sf-sales-forecasting), Cadences (sf-sales-engagement); industry
  / nonprofit pack owns the deal — Manufacturing Sales Agreement, NPC Gift
  Transaction, NPSP donation, FSC mortgage/wealth (matching sf-industry-* /
  sf-nonprofit-* skill); Quote-to-Cash / CPQ (sf-revenue-cloud); Service
  (sf-service-cloud); Field Service (sf-field-service); Marketing campaign
  (sf-marketing-cloud-growth, sf-marketing-account-engagement); code — Apex
  (sf-apex), LWC (sf-lwc), Flow (sf-flow), Data Cloud (sf-datacloud).
license: MIT
compatibility: "Requires Sales Cloud edition; industry-first routing applies"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "120 points across 10 categories — Phase 0 20 / Stage model 20 / Record types 10 / OLI+Quote 10 / OCR automation 10 / Teams 10 / Splits 10 / Pipeline Inspection 10 / Territory 10 / Anti-patterns 10 (96 is passing)"
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric (10 categories) extracted from existing 'Scoring rubric (120 pts)' section in this SKILL.md (line 178). Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  sales_opportunity_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 16
      description: "Industry pre-check + Stage model + Record types. Maps to Phase 0 (20) + Stage model (20) + Record types (10). The stage model is the heart of the deal lifecycle and the link between pipeline + forecasting; missing the industry pre-check or stage→forecast-category mapping breaks both."
      automatic_hard_fail_rules:
        - "Phase 0 industry pre-check skipped on an FSC / Nonprofit / Manufacturing / Revenue Cloud org"
        - "Industry-owned Opportunity-equivalent (Manufacturing Sales Agreement / NPC Gift Transaction / NPSP donation / FSC mortgage) silently overridden"
        - "Stage count >8 (stage explosion — stages are a funnel, not a project plan)"
        - "Forecast Category silence — any OpportunityStage without a Forecast Category mapping (Pipeline / Best Case / Commit / Closed / Omitted)"
        - "'Pipeline' catch-all forecast category used on closed stages (forecast math broken)"
        - "Single record type covering New + Renewal + Upsell when motions diverge (different stage gates / probability / sales motion)"
    - name: Robustness
      max: 25
      hard_fail_below: 14
      description: "Splits + Teams + OCR automation. Maps to Splits (10) + Teams (10) + OCR automation (10). Revenue + Overlay split correctness, OWD-aware Team access, Primary OCR enforcement — three places where silent breakage causes compensation + reporting drift."
      automatic_hard_fail_rules:
        - "Opportunity Revenue Splits not summing to 100% (or summing >100% silently)"
        - "Overlay Splits not independent of Revenue Splits (allocation collision)"
        - "Opportunity Team access matrix doesn't match OWD (Read/Write granted while Account Team access blocks the team member)"
        - "Primary Opportunity Contact Role not enforced (compensation + reporting joins on Primary OCR; null OCR breaks both)"
        - "Lead conversion not auto-populating OCR (manual OCR creation post-conversion is a known forgotten step)"
        - "Opportunity Team templates undefined for the documented motion (every deal hand-rolled)"
    - name: Fit
      max: 25
      hard_fail_below: 14
      description: "Pipeline Inspection + Deal Insights + Territory + OLI/Quote hand-off. Maps to Pipeline Inspection (10) + Territory (10) + Line item+quote hand-off (10). Right tooling for the use case; deal hand-offs to sf-revenue-cloud / sf-sales-forecasting / sf-sales-engagement clean."
      automatic_hard_fail_rules:
        - "Pipeline Inspection treated as a tabular report / dashboard (it's an inline-editing + metric-change surface)"
        - "Pipeline Inspection filters not aligned with Forecast hierarchy (managers can't reconcile views)"
        - "Territory Management chosen but not enabled on Opportunity (assignment doesn't propagate)"
        - "Enterprise Territory Management vs legacy Territory Management not declared (different behavior)"
        - "RunAssignmentRules invocation missing on Opportunity create when ETM is in scope"
        - "Line items + Quote hand-off ambiguous — CPQ / RCA path not routed to sf-revenue-cloud, standard Quote path not declared"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Anti-patterns avoided + Deal Insights data maturity. Maps to Anti-patterns (10) + Deal Insights subset of (10). Einstein activated only with sufficient data maturity; anti-patterns audit explicit; revise pass on score below 96."
      automatic_hard_fail_rules:
        - "Einstein Opportunity Scoring activated without ≥12 months closed-won + closed-lost history"
        - "Einstein Forecasting activated without segment-volume confirmation (model has no signal per segment)"
        - "Anti-patterns audit not done explicitly (stage explosion, forecast silence, industry override) — review summary skips the explicit avoidance call-out"
        - "Score below 96 / 120 returned to user without revise pass"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.sales_core.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.opportunities.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/sales
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_sales.htm
---

# sf-sales-opportunity: Opportunity, Pipeline, Deal Insights

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 120-pt rubric across 10 Opportunity categories, extracted from this skill's existing Scoring rubric section (line 178) and mapped onto the 4-dim shape. Correctness floor at 16 — the stage model is the heart of the deal lifecycle and the link between pipeline + forecasting; missing the industry pre-check or stage→forecast-category mapping breaks both. Hard-fail rules block stage explosion (>8 stages), forecast-category silence, single record type covering distinct motions, Revenue Splits not summing to 100%, missing Primary OCR enforcement, Pipeline Inspection treated as tabular report, and Einstein activated without data maturity. Disable with `eval_harness.enabled: false`.

Owns everything centered on the standard `Opportunity` object and its closest neighbors: Opportunity Line Item, Opportunity Contact Role, Opportunity Team, Opportunity Split, Opportunity Stage History, Pipeline Inspection, Deal Insights, Opportunity-based Quote hand-off, and territory assignment for opportunities. Forecasts, cadences, and Revenue Cloud are explicitly out of scope — this skill hands off cleanly to `sf-sales-forecasting`, `sf-sales-engagement`, and `sf-revenue-cloud`.

---

## When this skill owns the task

Use `sf-sales-opportunity` when the work involves:

- `Opportunity` record types, stages, probability, forecast category, and close date hygiene
- `OpportunityLineItem` (OLI) and price book entry selection on the deal
- `OpportunityContactRole` — influence, primary flag, automatic population
- `OpportunityTeam` — team selling, default access, team templates
- `OpportunitySplit` — revenue splits and overlay credit
- `OpportunityFieldHistory` and `OpportunityStageHistory` — pipeline velocity and age-in-stage
- Pipeline Inspection configuration (metric filters, inline edits, deal momentum)
- Deal Insights signals (engagement, relationship, deal change)
- Opportunity → Quote hand-off on the standard Quote object (CPQ/RCA route to `sf-revenue-cloud`)
- Opportunity territory assignment (ETM / legacy TM)
- Opportunity-level automation that does NOT cross into forecasting, cadences, or CPQ

Delegate elsewhere when:

| Scope | Route to |
|---|---|
| Forecast types, categories, hierarchy, adjustments, quotas | [sf-sales-forecasting](../sf-sales-forecasting/SKILL.md) |
| Cadences, Sales Dialer, EAC, prioritized work | [sf-sales-engagement](../sf-sales-engagement/SKILL.md) |
| CPQ, RCA, Subscription Management, Billing Schedules | [sf-revenue-cloud](../sf-revenue-cloud/SKILL.md) |
| Multi-capability Sales Cloud design | [sf-sales-cloud](../sf-sales-cloud/SKILL.md) |
| Apex trigger / handler / batch for Opportunity | [sf-apex](../sf-apex/SKILL.md) |
| LWC rendering opportunity fields | [sf-lwc](../sf-lwc/SKILL.md) |
| Flow XML mechanics on Opportunity | [sf-flow](../sf-flow/SKILL.md) |

---

## Phase 0: Industry Pre-Check (MANDATORY)

**Before any opportunity modeling, run the shared industry pre-check.** See [references/industry-precheck.md](../../references/industry-precheck.md) for the full detection + deferral protocol.

Procedure:

1. **Detect.** Run license / namespace / object scans per the reference.
2. **Cross-reference.** If the user's "Opportunity" request is actually a packaged industry artifact in disguise, halt and forward:

   | Detected | "Opportunity" is really | Route to |
   |---|---|---|
   | FSC (`FinServ__`) | Mortgage / lending pipeline, wealth pursuit with Financial Goal / Life Event ties | `sf-industry-fsc` |
   | Health Cloud (`HealthCloudGA__`) | Payer contracting, provider network deal | `sf-industry-health` |
   | Education Cloud / EDA (`hed__`) | Advancement / gift cultivation on EDA | `sf-industry-education` |
   | Public Sector (`OutfundsPS__`) | Funding pursuit tied to Benefit / Application | `sf-industry-public-sector` |
   | Field Service | Work Order / Service Appointment (not an Opportunity at all) | `sf-field-service` |
   | Nonprofit Cloud | Gift Transaction / Funding Award | `sf-nonprofit-cloud` + children |
   | NPSP (`npsp`) | Opportunity-as-donation, Recurring Donation | `sf-nonprofit-npsp` |
   | Manufacturing Cloud | Sales Agreement, Account Forecast | `sf-industry-manufacturing` |
   | Consumer Goods Cloud | Visit / Retail Execution outcome | `sf-industry-consumer-goods` |
   | Communications Cloud (`vlocity_cmt__`) | Cart / Offer / Order Decomposition | `sf-industry-communications` |
   | Media Cloud (`vlocity_media__`) | Subscription / Entitlement | `sf-industry-media` |
   | Energy & Utilities (`vlocity_ins__` + E&U) | Premise / Service Point / Work Request | `sf-industry-energy` |
   | Revenue Cloud Advanced / CPQ (`SBQQ__`) | Quote line item / Subscription / Asset | `sf-revenue-cloud` |

3. **Defer.** Emit the standard handoff line and stop generic work.
4. **Proceed only when clean**, or when the user has explicitly opted out, or when the work is pure generic Opportunity configuration with no industry extension.

**NEVER silently override an industry data model.** A packaged industry Opportunity has upgrade-protected picklists, triggers, and sharing; layering generic stage changes on top of it corrupts the next package release.

---

## Required context to gather first

- **Org edition** — Enterprise+ for Opportunity Splits and ETM.
- **Revenue Cloud state** — no CPQ, CPQ classic (`SBQQ__`), or Revenue Cloud Advanced. Drives whether OLI lives here or routes to `sf-revenue-cloud`.
- **Sales motion** — new / upsell / renewal / partner-sourced. Informs record types.
- **Deal complexity** — direct vs team-sold vs overlay. Drives Team + Split requirements.
- **Probability policy** — per-stage fixed probability vs per-deal override allowed.
- **Close-date hygiene** — back-dating allowed? future-pushing tracked?
- **Territory model** — ETM, legacy TM, or rule-based.
- **Forecast alignment** — who owns stage → forecast category mapping (delegate to `sf-sales-forecasting` for the mapping itself, but gather the intent here).
- **Industry overlay** — confirmed clean from Phase 0.

---

## Workflow phases

### Phase 1 — Stage + record type design

1. Limit to ~5–8 stages. Funnel, not project plan.
2. Decide record types: at minimum New Business vs Renewal (and Upsell if the motion warrants). Each record type gets its own stage picklist values via Record Type Picklist Values.
3. Map every stage to a Forecast Category (`Pipeline` / `Best Case` / `Commit` / `Closed Won` / `Closed Lost` / `Omitted`). Missing mappings break forecasts silently.
4. Set default probability per stage. Allow per-deal override only if Sales Ops explicitly owns the policy.
5. Decide on close-date behavior: auto-push on stage advance vs manual, back-dating lockout, stale-deal policy.

### Phase 2 — Line items + quote hand-off

1. Confirm price book strategy with `sf-sales-cloud` orchestrator if unclear; OLI must reference a Price Book Entry.
2. Decide whether Quotes live here (standard Quote) or route to `sf-revenue-cloud` (CPQ/RCA).
3. If standard Quote: confirm Quote → Order → Contract flow and who owns each hop.
4. If CPQ/RCA: stop, hand off to `sf-revenue-cloud`.

### Phase 3 — Teams, contact roles, splits

1. **Opportunity Contact Role** — auto-populate on conversion from Lead; require a Primary contact; drive influence reporting.
2. **Opportunity Team** — decide default access (Read / Read-Write), team roles, default team template per user, auto-add triggers.
3. **Opportunity Splits** — only if the comp plan needs them. Revenue splits must total 100%; overlay splits are independent and can exceed 100%.
4. Verify Opportunity OWD + Account Team sharing is consistent with team role access. Private OWD + team role Read will not unlock the team to edit.

### Phase 4 — Pipeline Inspection + Deal Insights

1. Enable Pipeline Inspection; configure the metric set (Amount change, close-date change, stage change) and the time window filter.
2. Enable Deal Insights; review the engagement, relationship, and deal-change signals.
3. Train reps + managers on inline editing from Pipeline Inspection (it is an editing surface, not a report).
4. Confirm Pipeline Inspection filters match the forecast hierarchy view used by `sf-sales-forecasting` — mismatched filters drive "my forecast doesn't match my pipeline" complaints.

### Phase 5 — Territory + assignment

1. Confirm ETM vs legacy TM vs rule-based from Phase 0 context.
2. Enable Opportunity territory assignment if ETM; run `RunAssignmentRules` on insert / update as appropriate.
3. Document manual override path for reps to reassign a deal with reason code.

### Phase 6 — Velocity + history

1. Use `OpportunityStageHistory` + `OpportunityFieldHistory` for age-in-stage, stage skip, and amount-change velocity.
2. Decide audit-field policy: which fields track history, which drive reports, which feed Einstein Opportunity Scoring.
3. Confirm deal-momentum fields feed Deal Insights, not custom aggregation Apex.

### Phase 7 — Verification + report

1. Confirm Phase 0 ran cleanly.
2. Confirm every stage maps to a forecast category.
3. Confirm team + split + contact-role rules are consistent with OWD.
4. Confirm Pipeline Inspection + Deal Insights are enabled with aligned filters.
5. Confirm hand-offs to `sf-sales-forecasting` (stage → forecast category), `sf-revenue-cloud` (CPQ/RCA), and `sf-sales-engagement` (cadence on opportunities) are explicit.

---

## Scoring rubric (120 pts)

| Category | Points | Pass threshold |
|---|---|---|
| Phase 0 industry pre-check executed + documented | 20 | Industry detection run; deferral emitted if positive |
| Stage model quality (≤ 8 stages, forecast-category complete) | 20 | Every stage mapped, no "Pipeline" catch-all for closed deals |
| Record type strategy (New / Renewal / Upsell separated) | 10 | Separate stages where motions differ |
| Line item + quote hand-off clarity | 10 | OLI or Quote routed correctly; CPQ/RCA → sf-revenue-cloud |
| Opportunity Contact Role automation | 10 | Primary enforced, auto-populate on conversion |
| Opportunity Teams + default access | 10 | Access matrix matches OWD; team templates defined |
| Opportunity Splits correctness | 10 | Revenue = 100%; overlay independent |
| Pipeline Inspection + Deal Insights enabled + aligned | 10 | Filters match forecast hierarchy |
| Territory assignment (ETM / legacy / rules) correct | 10 | Assignment fires on insert/update |
| Anti-patterns explicitly avoided | 10 | No stage-explosion, no forecast silence, no industry override |

Pass = 96 / 120. Below 96, revise.

---

## Anti-patterns

1. **Skipping Phase 0.** Recommending an Opportunity stage model in an FSC / Nonprofit / Manufacturing / Revenue Cloud org without running the industry pre-check.
2. **Silently overriding an industry data model.** NEVER silently override an industry data model. Editing stage picklists, record types, or adding fields to an industry-managed Opportunity will break the next package upgrade.
3. **Stage explosion.** More than ~8 stages. Stages are a funnel; per-deal state lives in status, record type, or line-item level.
4. **Forecast-category silence.** Leaving stages unmapped to a forecast category, or mapping closed-won stages to `Pipeline`. Forecasts break silently.
5. **Per-deal probability override without governance.** Turning on free-form probability editing with no Sales Ops policy produces forecast noise and AE gaming.
6. **Mis-specified Opportunity Splits.** Letting revenue splits sum to less than or more than 100%, or confusing revenue splits with overlay splits. Compensation reports will be wrong.
7. **OWD / team role mismatch.** Keeping Opportunity OWD Private and granting Opportunity Team members Read without also confirming Account Team sharing. Reps will complain they can see but can't edit.
8. **Treating Pipeline Inspection as a report.** It is an editing + metric-change surface with inline update capability, not a tabular dashboard. Using it as a reporting substitute misreads the feature.
9. **Einstein Opportunity Scoring without 12 months of history.** The model has nothing to learn from and will output noise.

---

## Common failure modes + remediation

### Symptom: "Forecasts don't match my pipeline report."
- **Root cause:** Stage → Forecast Category mapping has a gap, or a closed-won stage is mapped to `Pipeline`.
- **Fix:** Re-verify every stage's forecast category. Route hierarchy-level mismatches to `sf-sales-forecasting`.

### Symptom: "Sales Operations says splits total 120%."
- **Root cause:** Revenue splits (must total 100%) and overlay splits (can exceed) are being edited as one pool.
- **Fix:** Separate the two split types; enforce 100% on revenue splits via validation; overlay stays free.

### Symptom: "AE is on the Opportunity Team but can't edit."
- **Root cause:** Opportunity OWD Private + team role Read-only, or Account Team access blocks the chain.
- **Fix:** Promote the team role to Read-Write, and confirm Account Team access if the Account is also Private.

### Symptom: "Opportunity territory isn't assigned on insert."
- **Root cause:** ETM opportunity assignment not enabled, or the trigger flow doesn't run assignment rules.
- **Fix:** Enable opportunity territory assignment in ETM settings; ensure `Opportunity.RunAssignmentRules` fires on insert and update.

### Symptom: "Pipeline Inspection filters don't match the forecast view."
- **Root cause:** Pipeline Inspection default filter (e.g., "My Team's Opportunities") doesn't align with the forecast hierarchy role.
- **Fix:** Align filters with the forecast role; confirm with `sf-sales-forecasting` owner.

---

## CLI / metadata cheat sheet

```bash
# Stage → forecast category audit
sf data query --target-org <alias> --query "SELECT MasterLabel, ForecastCategory, DefaultProbability, IsClosed, IsWon, SortOrder FROM OpportunityStage ORDER BY SortOrder"

# Record type inventory
sf data query --target-org <alias> --query "SELECT DeveloperName, IsActive FROM RecordType WHERE SobjectType = 'Opportunity'"

# Opportunity Contact Role coverage
sf data query --target-org <alias> --query "SELECT COUNT(Id), IsPrimary FROM OpportunityContactRole GROUP BY IsPrimary"

# Opportunity Team default access
sf data query --target-org <alias> --query "SELECT UserId, TeamMemberRole, OpportunityAccessLevel FROM OpportunityTeamMember LIMIT 50"

# Opportunity Splits audit
sf data query --target-org <alias> --query "SELECT OpportunityId, SplitPercentage, SplitType.MasterLabel FROM OpportunitySplit LIMIT 50"

# Stage history velocity
sf data query --target-org <alias> --query "SELECT OpportunityId, StageName, CreatedDate FROM OpportunityStageHistory ORDER BY OpportunityId, CreatedDate DESC LIMIT 200"

# Territory assignment state
sf data query --target-org <alias> --query "SELECT Id, Territory2Id, Name FROM Opportunity WHERE Territory2Id != NULL LIMIT 50"
```

Metadata surfaces owned here:

- `OpportunityStage` (picklist + forecast category + probability)
- `Opportunity` custom fields + record types
- `OpportunityTeamRole` templates
- `OpportunitySplitType` configuration
- `AppMenuItem` / Pipeline Inspection + Deal Insights permission sets

---

## Output format

```text
Opportunity task: <stage model / team / split / contact role / pipeline inspection / territory>
Phase 0 industry pre-check: <clean / deferred to sf-industry-X (reason)>
Edition gates: <Enterprise+ confirmed for Splits / ETM>
Stage model: <count + forecast category coverage>
Record types: <New / Renewal / Upsell / other>
Teams + splits: <default access; revenue vs overlay>
Pipeline Inspection + Deal Insights: <enabled / configured / aligned with forecast>
Territory: <ETM / legacy / rules>
Hand-offs: <sf-sales-forecasting / sf-revenue-cloud / sf-sales-engagement>
Verification: <stage mapping complete / splits sum correctly / team access matches OWD>
Next step: <open phase skill or sales-ops decision>
```

---

## References

- [Industry pre-check reference](../../references/industry-precheck.md) — MANDATORY Phase 0
- [sf-sales-cloud orchestrator](../sf-sales-cloud/SKILL.md)
- [sf-sales-forecasting](../sf-sales-forecasting/SKILL.md)
- [sf-sales-engagement](../sf-sales-engagement/SKILL.md)
- [sf-revenue-cloud](../sf-revenue-cloud/SKILL.md)
