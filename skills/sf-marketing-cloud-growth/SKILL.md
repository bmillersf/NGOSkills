---
name: sf-marketing-cloud-growth
description: >
  Marketing Cloud Growth (the Data Cloud-native Marketing Cloud, Starter / Growth / Advanced tiers)
  architecture with 130-point scoring.
  TRIGGER when: user designs or implements email, SMS, or journey marketing on a Core-org Marketing
  Cloud Growth (MCG) deployment — Data Cloud is enabled AND the MarketingCloudGrowth feature /
  MarketingCloudGrowthEdition license is present; user says "Marketing Cloud Growth", "MC Growth",
  "send an email from MC Growth", "build a journey in Marketing Cloud Growth", "SMS campaign in MCG",
  "activate a Data Cloud segment to Marketing Cloud", "Einstein for Marketing send-time optimization",
  "Content Builder asset in Core", "campaign in MC Growth", "Journey Builder inside the CRM",
  "Starter / Growth / Advanced tier Marketing Cloud", or references a Core-org Campaign / Journey /
  MessageDefinitionSendDefinition bound to Data Cloud segments.
  DO NOT TRIGGER when: the org has the `pi__` Pardot namespace or the Pardot Business Unit setup
  (use sf-marketing-account-engagement); when both MC Growth and Pardot are installed, route based
  on the specific channel the user asked about — if user asked about B2B engagement programs,
  scoring, forms, landing pages, or lead grading, Account Engagement wins (use
  sf-marketing-account-engagement); the task is pure Data Cloud segment building with no MC Growth
  send in scope (use sf-datacloud-segment); the task is the activation wiring from Data Cloud to
  MC Growth but no send design (use sf-datacloud-act); the task is DMO harmonization / identity
  resolution (use sf-datacloud-harmonize); industry solutions own the request — FSC households
  getting a life-event journey (use sf-industry-fsc), Health Cloud patient outreach on Care Plan
  (use sf-industry-health), Education Cloud student communication on Program Enrollment
  (use sf-industry-education), Public Sector Solutions constituent notifications on Benefit /
  License (use sf-industry-public-sector), Manufacturing Cloud account-plan outreach
  (use sf-industry-manufacturing), Consumer Goods Cloud retail-execution notifications
  (use sf-industry-consumer-goods), Communications Cloud subscriber notifications
  (use sf-industry-communications), Media Cloud subscriber engagement
  (use sf-industry-media), Energy & Utilities Cloud premise notifications
  (use sf-industry-energy), Field Service appointment-reminder SMS tied to ServiceAppointment
  (use sf-field-service); nonprofit campaigns on Nonprofit Cloud Gift Transaction / Person Account
  fundraising (use sf-nonprofit-fundraising), nonprofit campaigns on NPSP Opportunity-based
  donations or CampaignMember appeals (use sf-nonprofit-npsp); the task is Sales Cloud
  opportunity-stage email on Lead/Contact without Marketing Cloud involvement (use sf-sales-cloud);
  the task is Service Cloud case-routing email-to-case or agent-reply email (use sf-service-cloud);
  writing Apex (use sf-apex), LWCs (use sf-lwc), or Flows (use sf-flow) that happen to fire an email
  alert and have no Marketing Cloud runtime involvement.
license: MIT
compatibility: "Requires Data Cloud enabled + Marketing Cloud Growth (Starter / Growth / Advanced) license. Runs inside the Core org, not on a separate MC tenant."
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.mcg_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/marketing/marketing-cloud-growth/guide/overview.html
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/marketing
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_marketing_cloud_growth.htm
---

# sf-marketing-cloud-growth: Marketing Cloud Growth (Data Cloud-Native)

Use this skill when the user is designing, building, or troubleshooting marketing on **Marketing Cloud Growth** (MCG) — the Core-org, Data-Cloud-backed Marketing Cloud introduced in 2024 and sold as the Starter, Growth, and Advanced tiers. MCG is a fundamentally different product from legacy Marketing Cloud Engagement (ExactTarget / SFMC) and from Marketing Cloud Account Engagement (Pardot). It runs **inside the Core org**, it uses **Data Cloud as its system of record** for audiences, and it uses the Core-org Campaign object as the campaign primitive.

This skill owns the send-side design: journeys, email templates, SMS templates, Content Builder assets, campaigns, and Einstein for Marketing features. It defers to the Data Cloud skill family for anything upstream of the send (DMOs, identity resolution, segmentation, activation wiring).

---

## 1. When This Skill Owns the Task

This skill owns the task when the user is designing or implementing the **message**, the **journey that sends the message**, the **campaign that reports on the message**, or **Einstein features that optimize the send** — on Marketing Cloud Growth specifically.

Delegate to another skill when the task is outside that surface:

| User need | Route to | Why |
|---|---|---|
| Build or edit a Data Cloud segment that feeds an MCG send | [sf-datacloud-segment](../sf-datacloud-segment/SKILL.md) | Segment authorship lives in Data Cloud, not MCG |
| Map source fields into DMOs, resolve unified profiles, configure identity resolution | [sf-datacloud-harmonize](../sf-datacloud-harmonize/SKILL.md) | Harmonization is upstream of any send |
| Wire an activation from Data Cloud → Marketing Cloud Growth activation target | [sf-datacloud-act](../sf-datacloud-act/SKILL.md) | Activation target plumbing is Data Cloud's concern |
| Ingest source data (CRM objects, files, webhooks) into Data Cloud | [sf-datacloud-prepare](../sf-datacloud-prepare/SKILL.md) | Prepare phase owns DLOs and streams |
| The org is running legacy Marketing Cloud Engagement (ExactTarget, separate `*.marketingcloudapis.com` tenant, Automation Studio, SSJS, AMPscript) | not owned by this skill family today — flag to the user; legacy MCE is a different product | MCE is a distinct tenant and tech stack |
| B2B email / engagement programs on Pardot (`pi__` namespace, Pardot Business Unit) | [sf-marketing-account-engagement](../sf-marketing-account-engagement/SKILL.md) | Pardot is a different runtime with its own warehouse |
| Donor / fundraising campaigns on NPC (Gift Transaction, Person Account, Gift Designation) | [sf-nonprofit-fundraising](../sf-nonprofit-fundraising/SKILL.md) | NPC fundraising owns the donor-campaign semantics |
| Donor campaigns on NPSP (Opportunity-based donations, npsp__CampaignMember) | [sf-nonprofit-npsp](../sf-nonprofit-npsp/SKILL.md) | NPSP's CampaignMember model is distinct |
| FSC life-event-driven journeys (Household, Life Event Moment, Financial Account) | [sf-industry-fsc](../sf-industry-fsc/SKILL.md) | FSC owns the life-event triggers |
| Health Cloud patient outreach tied to Care Plan / Care Request | [sf-industry-health](../sf-industry-health/SKILL.md) | Health Cloud owns care-plan-driven communications |
| Education Cloud student communication on Program Enrollment / Term | [sf-industry-education](../sf-industry-education/SKILL.md) | EDU owns academic-cycle sends |
| PSS constituent notifications on Benefit / License / Permit lifecycle | [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) | PSS owns the benefit/license triggers |
| Manufacturing Cloud account-plan outreach | [sf-industry-manufacturing](../sf-industry-manufacturing/SKILL.md) | Sales Agreement semantics |
| Consumer Goods Cloud retail-execution notifications | [sf-industry-consumer-goods](../sf-industry-consumer-goods/SKILL.md) | Visit / Retail Execution semantics |
| Communications Cloud subscriber notifications | [sf-industry-communications](../sf-industry-communications/SKILL.md) | ESM / Number Management semantics |
| Media Cloud subscriber engagement | [sf-industry-media](../sf-industry-media/SKILL.md) | Media-subscriber semantics |
| Energy & Utilities premise notifications | [sf-industry-energy](../sf-industry-energy/SKILL.md) | Premise / Service Point semantics |
| Field Service appointment-reminder SMS tied to ServiceAppointment | [sf-field-service](../sf-field-service/SKILL.md) | Appointment reminders live in FS |
| Sales Cloud opportunity-stage email (no MC runtime) | [sf-sales-cloud](../sf-sales-cloud/SKILL.md) | Not an MC send |
| Service Cloud agent-reply email / email-to-case | [sf-service-cloud](../sf-service-cloud/SKILL.md) | Not an MC send |
| Apex that fires an Email Alert with no MC runtime | [sf-apex](../sf-apex/SKILL.md) | Platform email, not MC |
| LWC or Flow work that happens alongside marketing but is not MC config | [sf-lwc](../sf-lwc/SKILL.md) / [sf-flow](../sf-flow/SKILL.md) | Orthogonal surface |

---

## 2. Phase 0: Industry Pre-Check (MANDATORY)

**Before producing any MCG artifact, run the shared industry pre-check:** [`references/industry-precheck.md`](../../references/industry-precheck.md).

Marketing Cloud Growth is a **generic cloud skill**. An industry solution's data model (Household, Care Plan, Program Enrollment, Benefit, Gift Transaction, Sales Agreement, Visit, etc.) often owns the semantic trigger, the audience definition, and the reporting rollup for a marketing send. **NEVER silently override an industry data model.** If the industry owns the entity driving the send, the industry skill owns the design — this skill executes only the message / journey / Einstein mechanics on instruction from the industry skill.

Run the pre-check's detection steps (license/feature flag, namespace scan, object existence) and if **any** of the following industry skills is positive AND the user's request touches that industry's owned objects or processes, **halt and forward**:

1. [sf-industry-fsc](../sf-industry-fsc/SKILL.md) — Financial Services Cloud (Household, Life Event Moment, Financial Account, Financial Goal)
2. [sf-industry-health](../sf-industry-health/SKILL.md) — Health Cloud (Patient, Care Plan, Care Request, EHR)
3. [sf-industry-education](../sf-industry-education/SKILL.md) — Education Cloud / EDA (Student, Program Enrollment, Term, Affiliation)
4. [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) — Public Sector Solutions (Benefit, License, Permit, Inspection)
5. [sf-industry-manufacturing](../sf-industry-manufacturing/SKILL.md) — Manufacturing Cloud (Sales Agreement, Account Forecast, Rebate Program)
6. [sf-industry-consumer-goods](../sf-industry-consumer-goods/SKILL.md) — Consumer Goods Cloud (Retail Store, Visit, Retail Execution)
7. [sf-industry-communications](../sf-industry-communications/SKILL.md) — Communications Cloud (Subscriber, ESM, Offer)
8. [sf-industry-media](../sf-industry-media/SKILL.md) — Media Cloud (Subscriber, Billing Account)
9. [sf-industry-energy](../sf-industry-energy/SKILL.md) — Energy & Utilities Cloud (Premise, Service Point, Meter)
10. [sf-field-service](../sf-field-service/SKILL.md) — Field Service (Work Order, Service Appointment, Service Resource)

Nonprofit pre-check: if the org has Nonprofit Cloud or NPSP installed AND the send is a donor / constituent / volunteer communication, route to [sf-nonprofit-fundraising](../sf-nonprofit-fundraising/SKILL.md) (NPC) or [sf-nonprofit-npsp](../sf-nonprofit-npsp/SKILL.md) (NPSP) before this skill.

**Deferral behaviour.** If industry detection is positive and the user's request overlaps with an industry-owned object/process, print:

```
Detected {industry} is installed. Routing to sf-{industry-skill}
because this request touches {matched object/process}.
The MC Growth mechanics will be invoked from that skill.
```

Then STOP generic MCG workflow and return control so the industry skill can run its domain logic and call back into this skill for send-only mechanics.

**Exception.** Generic MCG still owns the task when the user explicitly says "ignore the industry overlay" OR the send has no industry-object binding (e.g., a newsletter to Leads with no FSC Household / Health Patient / etc. involvement). Document the exception.

---

## 3. Marketing Cloud Product Disambiguation (Critical)

Before this skill does anything, confirm the org is actually running Marketing Cloud Growth and not one of the two adjacent products. Salesforce has three Marketing Cloud products in market as of Spring '26 and they are **not interchangeable**:

```
User asks: "Marketing Cloud"
               │
               ▼
   ┌─────────────────────────────┐
   │ 1. pi__ namespace present?  │
   │    OR dedicated Pardot      │
   │    Business Unit visible?   │
   └──────────────┬──────────────┘
                  │ yes
                  ▼
       ROUTE: sf-marketing-account-engagement
       (Pardot / MC Account Engagement)
                  │ no
                  ▼
   ┌─────────────────────────────────┐
   │ 2. Data Cloud enabled           │
   │    AND MarketingCloudGrowth /   │
   │    MarketingCloudGrowthEdition  │
   │    feature OR license present?  │
   └──────────────┬──────────────────┘
                  │ yes
                  ▼
       ROUTE: sf-marketing-cloud-growth  (this skill)
                  │ no
                  ▼
   ┌─────────────────────────────────────────────┐
   │ 3. Separate MC Engagement tenant?           │
   │    *.marketingcloudapis.com domain,         │
   │    MID/Business Unit, Automation Studio,    │
   │    AMPscript, SSJS, Journey Builder (MCE)?  │
   └──────────────┬──────────────────────────────┘
                  │ yes
                  ▼
       NOT OWNED by this skill family (legacy MCE).
       Flag to user: "This org is running legacy
       Marketing Cloud Engagement; we do not have
       an authoritative skill for that product today.
       Proceed manually or use Salesforce docs directly."
                  │ no
                  ▼
       No Marketing Cloud product detected.
       Ask the user to confirm licensing before design.
```

**If both Pardot and MCG are installed** (common in large B2B2C orgs): the skill that owns the **specific channel the user asked about wins**. B2B engagement programs, scoring, grading, forms, landing pages, completion actions → `sf-marketing-account-engagement`. Journeys, Content Builder, Einstein for Marketing, Data-Cloud-segment-driven email/SMS → this skill. If genuinely ambiguous, ask the user which tier (Pardot BU vs MCG) should own the send.

**MCG vs legacy MCE (ExactTarget / SFMC) — quick distinguisher.**

| Signal | MC Growth | Legacy MCE |
|---|---|---|
| Runtime location | Core org (same URL as the CRM) | Separate tenant (`*.marketingcloudapis.com`) |
| Audience source | Data Cloud segments | SFMC Data Extensions |
| Journey authoring | Core-org Journey Builder (Flow Builder variant) | Journey Builder (MCE, canvas-based) |
| Templating language | Handlebars-style merge fields + Flow | AMPscript, SSJS |
| Campaign object | Core Campaign / CampaignMember | Not applicable — MCE Campaigns are separate |
| Provisioning | Automatic once license is assigned | Separate MID, separate auth, Connected App |
| Tier names | Starter / Growth / Advanced | Corporate / Enterprise / Enterprise 2.0 |

---

## 4. Required Context to Gather First

Before producing any MCG design, establish:

- **Tier.** Starter, Growth, or Advanced? Each tier has different feature caps — Starter has no SMS, limited journeys; Growth adds SMS and most Einstein features; Advanced adds advanced Einstein (generative), multi-language, and higher send limits. Designing for a tier the org does not own will produce a plan that cannot be deployed.
- **Data Cloud readiness.** Is Data Cloud enabled? Are DMOs mapped? Is identity resolution running? Are there segments already published and activating to MCG? MCG cannot send without a Data Cloud segment as the audience source.
- **Channels in scope.** Email only, or email + SMS? If SMS, which country codes, what short-code / long-code / toll-free provisioning, what carrier opt-in / STOP compliance posture.
- **Send domains and deliverability.** Which authenticated sending domain(s) — SPF / DKIM / DMARC status? Dedicated IP (Advanced tier) or shared? BrandKit / brand assets configured?
- **Compliance.** CAN-SPAM (US), CASL (Canada), GDPR / ePrivacy (EU), explicit opt-in lists, suppression lists, preference center URLs. Who owns consent capture — the Core CRM (Individual / Contact Point Consent) or an external CMP?
- **Segment-to-campaign-to-journey mapping.** Which Data Cloud segments feed which Campaigns? Which Campaigns are entry points to which Journeys? This mapping is the skeleton of the design.
- **Reporting source of truth.** Campaign-level rollups in the Core org, Marketing App dashboards, or a Data Cloud calculated insight? Mixing three answers is a common failure.
- **Einstein features licensed.** Send Time Optimization, Subject Line Insights, Engagement Frequency, Copy Insights (generative, Advanced tier). Only design for features the tier owns.
- **Multi-language / multi-brand.** If the send targets multiple locales or brands, is the design planning per-locale Content Builder assets + translated journey branches, or dynamic content within a single asset?

Missing the tier, Data Cloud readiness, or channel scope is a design-blocking gap. Do not guess.

---

## 5. Workflow Phases

Run in order. Phase 0 (industry pre-check) has already executed before this list begins.

### Phase 1 — Audience Design (Hand-off to Data Cloud)

1. Confirm the audience definition with the user in plain English ("lapsed monthly donors who opened at least one email in 90 days", "households with a life event in the last 30 days", etc.).
2. **Do not build the segment here.** Delegate to [sf-datacloud-segment](../sf-datacloud-segment/SKILL.md). Return to this skill only after the segment is published and the Data Cloud → MCG activation is wired (via [sf-datacloud-act](../sf-datacloud-act/SKILL.md)).
3. Verify the activation has completed at least one successful run and the segment membership is visible to MCG. An empty or stale activation will silently produce zero sends.
4. Document which DMO attributes are available for personalization in the send. You can only merge fields that are exposed on the segment's attribute set.

### Phase 2 — Campaign Setup (Core Org Campaign Object)

1. Create a Core-org **Campaign** for the marketing effort. MCG uses the standard Campaign object as the campaign primitive; do not confuse with legacy MCE Campaigns.
2. Set Campaign Type, Status, Start / End dates, Budgeted / Expected values per org convention.
3. Decide the CampaignMember strategy: in MCG, membership is driven by the Data Cloud segment and the activation, not by manual add. Record this in the Campaign description.
4. If multiple journeys roll up to one business outcome, use a parent/child Campaign hierarchy so cost and response rollups are meaningful.

### Phase 3 — Content Builder Assets

1. Author **Email** assets in Content Builder. Use the drag-and-drop editor for most work; drop to HTML only when a template is not expressive enough. BrandKit tokens (colors, logo, fonts) must be referenced, not hard-coded, so rebranding does not require a rebuild.
2. Author **SMS** assets (Growth / Advanced only). Keep body length under the single-segment limit (160 GSM-7, 70 UCS-2) unless multi-part is explicitly acceptable. Include opt-out language per country (STOP, HELP) where required.
3. Use **Personalization** merge fields from the Data Cloud segment attribute set. Do not hard-code default values for fields that are not guaranteed; use the Content Builder default-value syntax so missing data does not leak raw placeholders.
4. For multi-locale: prefer one email asset with dynamic content blocks over N duplicated assets, unless the locales diverge in layout.
5. Accessibility: alt text on every image, sufficient contrast, minimum font size, single-column responsive fallback, plain-text version.
6. Preview and test-send to a seed list before tying the asset into a journey.

### Phase 4 — Journey Builder (MCG Variant)

MCG's Journey Builder runs on Flow. It is **not** the legacy MCE canvas.

1. Define the journey's **entry criteria** — typically a Data Cloud segment activation or a Flow-triggered event. One entry source per journey; do not combine segment entry and ad-hoc entry without an entry-dedupe strategy.
2. Define the journey **exit criteria** — goal met (conversion event), unsubscribe, bounce, hard exit time window, or segment removal.
3. Model the journey nodes:
   - **Send Email** / **Send SMS** steps with a bound Content Builder asset and sender profile
   - **Wait** steps with either a duration or a wait-until-time
   - **Decision** / branch steps on segment attributes, engagement events (opened, clicked), or Flow variables
   - **Flow** action steps for CRM side effects (task creation, record update)
4. Frequency guardrails: respect the org's Engagement Frequency limits (if licensed). Do not send > N messages per recipient per period, even if the journey logic allows it.
5. Quiet hours per recipient timezone where required by locale or compliance.
6. Test the journey end-to-end with a seed audience before activation. Verify every branch path with a synthetic recipient.

### Phase 5 — Einstein for Marketing (If Licensed)

Enable only what the tier supports:

- **Send Time Optimization (STO)** — per-recipient optimal send time from engagement history. Available Growth and above. Activate on the Send step, not globally.
- **Subject Line Insights** — ML scoring of candidate subject lines. Available Growth and above.
- **Engagement Frequency** — per-recipient frequency cap recommendations. Governance feature; respect the output.
- **Copy Insights (generative)** — Advanced tier only. Generative drafting of subject lines and body copy. Always human-reviewed before activation.
- **Einstein Segmentation / Lookalike** — if present, these live in Data Cloud, not here; delegate to [sf-datacloud-segment](../sf-datacloud-segment/SKILL.md).

Always log which Einstein feature was used in the Journey / Send notes so later optimization attribution is auditable.

### Phase 6 — Compliance, Deliverability, and Preferences

1. Confirm sending domain(s) have SPF + DKIM + DMARC all passing. A missing DMARC alignment will silently drop inbox placement.
2. Configure the **Preference Center** (unsubscribe page, preference groups, language selection). One-click unsubscribe must be honored at the Core-org level and propagate to Data Cloud (Individual / Contact Point Consent).
3. Configure **Suppression Lists** — global suppression, per-publication suppression, hard-bounce suppression. A send that ignores suppression is a compliance incident.
4. Confirm the **Consent Model**: are consents stored on Individual, Contact Point Email, Contact Point Phone, or Contact Point Consent? MCG queries Data Cloud for current consent at send time; stale consent in Data Cloud means non-compliant sends.
5. Document the data retention policy — how long do send logs, engagement events, and unsubscribe records live in Data Cloud DLOs?

### Phase 7 — Testing and Validation

1. **Seed send** — send to an internal seed list on at least 3 inbox providers (Gmail, Outlook 365, Apple Mail) + 2 mobile clients. Verify rendering, image loading, link clicks, tracking pixel, and unsubscribe.
2. **Journey dry run** — activate the journey against a small test segment (e.g., 10 recipients). Verify each branch fires, each Content Builder merge renders, and the journey exits cleanly.
3. **Compliance test** — send to a suppression-listed address and verify it is suppressed. Click unsubscribe and verify the opt-out propagates to Data Cloud Contact Point Consent.
4. **Einstein test (if used)** — verify Send Time Optimization produces a reasonable distribution; verify Subject Line Insights returns scores; verify Copy Insights generates on-brand draft output.
5. **Reporting validation** — verify the Campaign rollup counts match the Journey send counts match the Data Cloud activation counts. A mismatch > ~1% is a reporting-wiring bug, not statistical noise.
6. **Regression** — if this send is demoable, route to [sf-demo-playwright](../sf-demo-playwright/SKILL.md) for a pre-flight script.

---

## 6. Scoring Rubric — 130 Points

Apply to any MCG design or build deliverable. Minimum passing: **98 / 130**. Sub-threshold categories must be fixed even if the total exceeds 98.

| Category | Max | Passing | What "passing" looks like |
|---|---|---|---|
| **Audience / Data Cloud integration** | 25 | 19 | Data Cloud segment exists and is activated to MCG; attribute set matches personalization needs; identity resolution is verified; no manual CampaignMember adds as a workaround for a missing segment |
| **Journey design correctness** | 25 | 19 | Entry, exit, branch logic, wait steps, and frequency caps all declarative; branches tested with synthetic recipients; no custom Apex replacing native Journey Builder functionality |
| **Content / Content Builder quality** | 20 | 15 | Brand tokens used (no hard-coded colors/logos); merge fields have safe defaults; accessibility checks pass; plain-text version present; SMS within single-segment length or explicitly acknowledged multi-part |
| **Compliance and deliverability** | 25 | 19 | SPF/DKIM/DMARC all passing on the sending domain; preference center live; suppression lists respected; consent model documented; unsubscribe propagates to Data Cloud Contact Point Consent; CAN-SPAM / CASL / GDPR requirements for the audience geography met |
| **Einstein / optimization usage** | 15 | 11 | Only licensed Einstein features enabled; STO activated on the Send step (not globally) when used; Subject Line Insights output reviewed; generative Copy Insights output human-edited before activation; feature usage logged for attribution |
| **Reporting and validation** | 20 | 15 | Campaign rollup, journey send count, and Data Cloud activation count reconcile within ~1%; seed send tested on 3 inbox providers + 2 mobile; branch paths individually tested; regression / pre-flight defined |

---

## 7. Anti-Patterns

- **Treating MCG and legacy MCE (ExactTarget) as the same product.** They share the name "Marketing Cloud" and almost nothing else. AMPscript, SSJS, Automation Studio, Data Extensions, and separate-tenant auth all belong to MCE. MCG uses Flow, Handlebars-style merge, Data Cloud segments, and the Core org. Designing for one on the other produces a plan that cannot deploy.
- **Manually adding CampaignMembers to feed a journey.** MCG's audience source is a Data Cloud segment activation. Hand-populating CampaignMember records because "the segment isn't ready yet" creates a divergence between Campaign rollups and actual send counts, and the manual-add workflow never gets unwound.
- **Hard-coding brand colors, fonts, or logo URLs in Content Builder assets.** Use BrandKit tokens. Rebrands happen. An email template with hard-coded hex codes and an `<img src>` pinned to a deleted CDN is a guaranteed incident.
- **Ignoring SPF / DKIM / DMARC alignment on the sending domain.** Gmail and Apple Mail will silently downgrade inbox placement for unaligned DMARC sends starting in 2024. "It sends and I got it in my inbox" is not deliverability proof.
- **Sending SMS without the country-required STOP / HELP language and without consent capture on file.** The US TCPA, Canadian CASL, UK PECR, and EU ePrivacy all have strict SMS consent and opt-out requirements. A single non-compliant SMS blast can be a five-to-seven-figure settlement.
- **Designing for Advanced-tier Einstein features when the org is on Starter or Growth.** Copy Insights (generative), advanced frequency optimization, and multi-language generative features are Advanced-only. Design before confirming license tier, and the implementation stalls at deployment.
- **Using one Journey for multiple unrelated business scenarios.** Emergency / transactional / promotional / nurture journeys have different entry criteria, frequency caps, and compliance requirements. Collapsing them produces a journey that is a mediocre compromise for all four.
- **Skipping the test-send to external inboxes.** The Preview button renders in a webview. Gmail, Outlook 365, Apple Mail, Yahoo, and mobile clients all render emails differently (especially background images, CSS fallbacks, and dark mode). Always test on real inbox providers before activation.
- **Overriding Data Cloud consent in the send step.** If Data Cloud Contact Point Consent says "unsubscribed" and the MCG send proceeds anyway because of a bypass flag, that is a compliance incident. Consent is the source of truth; the send must honor it.

---

## 8. Common Failure Modes and Remediation

### Failure 1 — "Journey activates but sends zero messages"
- **Symptom:** Journey is marked Active in MCG, entry source is set to a Data Cloud segment, but the send count is 0 after activation.
- **Root cause:** The Data Cloud segment is published but the activation to MCG either has not run, has errored, or is filtering to zero recipients (empty segment or consent-excluded). Alternatively, the segment's attribute set does not expose an Email / Phone contact point, so MCG has no deliverable address.
- **Fix:** In Data Cloud, verify the segment's most recent run produced > 0 members. Verify the activation target is MCG and the last activation status is Success. Confirm the segment includes Email Contact Point (or Phone for SMS) in its attribute set and that identity resolution is producing a unified profile with those contact points. Rerun the activation. If still zero, inspect Data Cloud Contact Point Consent for blanket opt-out.

### Failure 2 — "Personalization merge fields render as raw `{{Contact.FirstName}}` in the email"
- **Symptom:** Recipients see literal merge-tag placeholders in the delivered email instead of resolved values.
- **Root cause:** The merge field is referencing a Data Cloud DMO attribute that is not exposed on the segment's activation attribute set, OR the attribute name has a typo / wrong namespace, OR the segment attribute is not populated for the recipient.
- **Fix:** Open the segment's activation configuration and confirm the attribute is in the included attribute list. Confirm the exact attribute API name (these are case- and namespace-sensitive). Use Content Builder's default-value syntax (`{{Contact.FirstName | default: "there"}}`-style) so missing data degrades gracefully. Rebuild the asset and test-send.

### Failure 3 — "Einstein Send Time Optimization produces nonsensical send times (3am)"
- **Symptom:** STO schedules sends for times that make no business sense (middle of the night, weekend for a B2B audience).
- **Root cause:** STO is trained per-recipient on engagement history. For brand-new recipients with no history, STO falls back to a global model; for small segments, the per-recipient signal is noisy. Also, STO honors the recipient's timezone only if that timezone is known — a missing timezone defaults to UTC.
- **Fix:** For brand-new recipients, disable STO for the first 2–3 sends and let engagement accrue. Verify every recipient has a populated timezone on their Data Cloud unified profile. For small segments (< 1000), consider a fixed send time instead of STO until volume grows.

### Failure 4 — "Unsubscribe from email did not stop the follow-up SMS"
- **Symptom:** Recipient clicks unsubscribe in an email, but receives an SMS from the same journey the next day.
- **Root cause:** Consent in Data Cloud is stored per Contact Point (Email vs Phone), not per Individual. Unsubscribing the Email contact point does not automatically opt out the Phone contact point.
- **Fix:** This is often the correct behaviour (email and SMS opt-outs are legally distinct in most jurisdictions). If the business wants a blanket opt-out, add logic at the preference center level that, on "unsubscribe from all", writes opt-out to every Contact Point on the Individual — and build a Flow or Data Cloud calculated insight that enforces it. Do not paper over with a journey-side filter; consent belongs in Data Cloud.

### Failure 5 — "Campaign rollup count does not match journey send count"
- **Symptom:** The Core-org Campaign shows 10,000 members; the Journey dashboard shows 9,200 sends; Data Cloud activation shows 9,850 activated. All three numbers differ.
- **Root cause:** Three different timestamps and three different exclusion sets. Campaign membership is a cumulative snapshot; activation count is per-run; journey send count excludes recipients filtered by frequency caps, suppression, and in-flight consent changes.
- **Fix:** Document the expected reconciliation rules up front: `journey_send = activation_count - suppression - frequency_capped - consent_changed_midflight`. If the deltas exceed ~1–2% of the activation, audit: new suppressions since activation, frequency cap hits, mid-flight consent revocations. If the Campaign count diverges more than 5%, the CampaignMember-sync rule is misconfigured.

### Failure 6 — "SMS sends bounce with 'STOP keyword received' but recipient says they never texted STOP"
- **Symptom:** An SMS recipient is marked opted-out after a prior STOP, but the recipient denies ever sending STOP.
- **Root cause:** Carriers apply keyword opt-out at the short-code level, not per-brand. If the same short code serves multiple brands / campaigns, a STOP to any of them opts out the phone number from all. Alternatively, a previous test send received STOP and the opt-out persisted.
- **Fix:** Review short-code sharing — most compliance-aware orgs use dedicated short codes or toll-free numbers per brand. Audit the Data Cloud Contact Point Consent history for the phone number. For test-triggered opt-outs, import a consent-reset only with documented recipient re-opt-in.

---

## 9. Marketing Cloud Growth Cheat Sheet

### Runtime surface

| Area | Where it lives | Notes |
|---|---|---|
| Marketing App | Core org, Marketing tab | Unified entry point for MCG |
| Journey Builder | Core org, Journeys | Flow-based; not the MCE canvas |
| Content Builder | Core org, Content | Email + SMS assets, BrandKit tokens |
| Campaign | Core org, standard Campaign object | Primitive for send-level rollup |
| Audience source | Data Cloud segment | Activation wiring via Data Cloud Act |
| Sender profiles | Core org, Marketing Setup | Sending domain, BU, reply-to |
| Preference Center | Core org, hosted by MCG | Per-BU per-publication preferences |
| Einstein features | Core org, per Send / Journey step | Tier-gated |

### Tier feature matrix (approximate)

| Feature | Starter | Growth | Advanced |
|---|---|---|---|
| Email sends | Yes (cap) | Yes (higher cap) | Yes (highest cap) |
| SMS | No | Yes | Yes |
| Journeys | Limited | Full | Full |
| Send Time Optimization | No | Yes | Yes |
| Subject Line Insights | No | Yes | Yes |
| Engagement Frequency | No | Yes | Yes |
| Copy Insights (generative) | No | No | Yes |
| Multi-language dynamic content | Limited | Yes | Yes |
| Dedicated IP | No | Optional | Yes |
| Advanced deliverability reporting | No | Partial | Full |

Confirm exact caps and feature matrix against the current release notes — tier contents shift.

### Key objects and metadata

| Object / metadata | Purpose |
|---|---|
| `Campaign` (standard) | Core-org campaign primitive |
| `CampaignMember` (standard) | Membership; populated by Data Cloud activation in MCG, not manual |
| `MessageDefinitionSendDefinition` | A defined send (email / SMS) with template + sender profile |
| `EmailTemplate` / Content Builder asset | Templated content |
| Journey (Flow metadata) | The Journey Builder artifact, serialized as a Flow |
| Data Cloud segment | Audience source |
| Data Cloud activation | Wiring from segment → MCG |
| `Individual`, `ContactPointEmail`, `ContactPointPhone`, `ContactPointConsent` | Consent / preference surface in Data Cloud |
| BrandKit | Color / logo / font tokens used in Content Builder |

### Cross-skill integration

| Need | Delegate to | Reason |
|---|---|---|
| Build / publish a Data Cloud segment | [sf-datacloud-segment](../sf-datacloud-segment/SKILL.md) | Segment authorship is Data Cloud's |
| Wire the activation Data Cloud → MCG | [sf-datacloud-act](../sf-datacloud-act/SKILL.md) | Activation target is Data Cloud's |
| Harmonize source data into DMOs / identity resolution | [sf-datacloud-harmonize](../sf-datacloud-harmonize/SKILL.md) | DMOs are upstream |
| Ingest source data into Data Cloud | [sf-datacloud-prepare](../sf-datacloud-prepare/SKILL.md) | Prepare owns streams and DLOs |
| Generate seed / test data for the demo | [sf-nonprofit-demo-data](../sf-nonprofit-demo-data/SKILL.md) (nonprofit) / [sf-data](../sf-data/SKILL.md) (generic) | Data factory |
| Diagram a journey or architecture | [sf-diagram-mermaid](../sf-diagram-mermaid/SKILL.md) | Mermaid sequence / flow diagrams |
| Validate an end-to-end demo flow | [sf-demo-validate](../sf-demo-validate/SKILL.md) | Pre-flight check |

---

## 10. Output Format

When finishing, report in this order:

1. **Task classification** — design / build / troubleshoot / migrate
2. **Product confirmation** — MC Growth (not MCE, not Pardot)
3. **Industry pre-check result** — not-applicable / deferred-to-{industry-skill}
4. **Tier** — Starter / Growth / Advanced
5. **Audience source** — Data Cloud segment name + activation status
6. **Channels in scope** — email / SMS / both
7. **Einstein features** — listed, with license-tier confirmation
8. **Compliance posture** — SPF/DKIM/DMARC status, preference center, suppression, consent model
9. **Scoring total** — N / 130, with any sub-threshold category flagged
10. **Next recommended step** — next phase or cross-skill handoff
