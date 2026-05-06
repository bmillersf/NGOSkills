---
name: sf-marketing-account-engagement
description: >
  Marketing Cloud Account Engagement (formerly Pardot): B2B marketing
  automation — Engagement Studio, forms, landing pages, dynamic lists,
  automation rules, scoring & grading, B2BMA, Pardot Einstein.
  TRIGGER when: org has the `pi__` namespace or a Pardot Business Unit; user
  says "Pardot", "MCAE", "Engagement Studio", "Pardot form/landing
  page/email", "score and grade", "tracker domain", "Salesforce-Pardot
  connector"; references Prospect / Pardot Campaign / Engagement Program.
  DO NOT TRIGGER when: org runs MCG and request is DC-backed email/SMS or
  Journey Builder in Core (sf-marketing-cloud-growth); legacy SFMC tenant
  (out of scope); DC segment / DMO (sf-datacloud-segment, -harmonize, -act);
  industry / nonprofit pack owns the campaign data (matching sf-industry-* /
  sf-nonprofit-* skill); Sales stage email without Pardot (sf-sales-cloud);
  Service agent reply (sf-service-cloud); Field Service SMS
  (sf-field-service); code — Apex (sf-apex), LWC (sf-lwc), Flow (sf-flow) —
  not configuring Pardot.
license: MIT
compatibility: "Requires Pardot / Marketing Cloud Account Engagement license (Growth / Plus / Advanced / Premium) and the pi__ managed package installed in a connected Salesforce org"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.pardot_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/marketing/pardot/overview
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/marketing
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_pardot.htm
---

# sf-marketing-account-engagement: Marketing Cloud Account Engagement (formerly Pardot)

Use this skill when the user is designing, building, or troubleshooting B2B marketing automation on **Marketing Cloud Account Engagement** (MCAE) — the product formerly known as Pardot. MCAE is a B2B-centric, account-oriented marketing automation platform with its **own data warehouse** (not backed by Data Cloud), synced to Salesforce CRM via the Salesforce-Pardot Connector, and running under the `pi__` managed-package namespace. It is a fundamentally different product from Marketing Cloud Growth (Data Cloud-native) and from legacy Marketing Cloud Engagement (ExactTarget / SFMC).

This skill owns Engagement Studio programs, email templates, forms, form handlers, landing pages, dynamic lists, automation rules, completion actions, scoring and grading, B2B Marketing Analytics (B2BMA), Pardot Einstein features, and lead assignment on the Pardot side.

---

## 1. When This Skill Owns the Task

This skill owns the task when the user is designing or implementing **B2B nurture programs**, **forms / form handlers / landing pages**, **email templates (Pardot)**, **scoring and grading**, **automation rules / completion actions**, **Engagement Studio programs**, **B2B Marketing Analytics**, or **Pardot Einstein features** — on a Pardot / MCAE deployment specifically.

Delegate to another skill when the task is outside that surface:

| User need | Route to | Why |
|---|---|---|
| The org has Marketing Cloud Growth installed and the user asked about a Data-Cloud-segment-driven email/SMS, Journey Builder in the Core org, or Content Builder in the Core org | [sf-marketing-cloud-growth](../sf-marketing-cloud-growth/SKILL.md) | MCG is a different runtime with Data Cloud as its audience source |
| The org runs legacy Marketing Cloud Engagement (ExactTarget, separate `*.marketingcloudapis.com` tenant, AMPscript, SSJS, Automation Studio) | not owned by this skill family today — flag to the user | MCE is a distinct tenant and tech stack |
| Build a Data Cloud segment that will activate to any marketing surface | [sf-datacloud-segment](../sf-datacloud-segment/SKILL.md) | Data Cloud segments are orthogonal to Pardot's data warehouse |
| DMO harmonization / identity resolution / unified profile work | [sf-datacloud-harmonize](../sf-datacloud-harmonize/SKILL.md) | Data Cloud harmonization, not Pardot |
| Activate a Data Cloud audience to Pardot / MCAE (the activation target exists) | [sf-datacloud-act](../sf-datacloud-act/SKILL.md) | Activation wiring is Data Cloud's concern |
| Nonprofit donor campaigns on Nonprofit Cloud (Gift Transaction, Person Account, Gift Designation) | [sf-nonprofit-fundraising](../sf-nonprofit-fundraising/SKILL.md) | NPC fundraising owns donor-campaign semantics |
| Nonprofit donor campaigns on NPSP (Opportunity-based donations, npsp__CampaignMember) | [sf-nonprofit-npsp](../sf-nonprofit-npsp/SKILL.md) | NPSP's CampaignMember model differs |
| FSC life-event client journeys | [sf-industry-fsc](../sf-industry-fsc/SKILL.md) | FSC owns the life-event triggers |
| Health Cloud patient outreach tied to Care Plan / Care Request | [sf-industry-health](../sf-industry-health/SKILL.md) | Health Cloud owns care-plan-driven communications |
| Education Cloud student communication on Program Enrollment / Term | [sf-industry-education](../sf-industry-education/SKILL.md) | EDU owns academic-cycle sends |
| PSS constituent notifications on Benefit / License / Permit | [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) | PSS owns the benefit/license triggers |
| Manufacturing Cloud account-plan outreach | [sf-industry-manufacturing](../sf-industry-manufacturing/SKILL.md) | Sales Agreement semantics |
| Consumer Goods Cloud retail-execution notifications | [sf-industry-consumer-goods](../sf-industry-consumer-goods/SKILL.md) | Visit / Retail Execution |
| Communications Cloud subscriber notifications | [sf-industry-communications](../sf-industry-communications/SKILL.md) | ESM / Number Management |
| Media Cloud subscriber engagement | [sf-industry-media](../sf-industry-media/SKILL.md) | Subscriber semantics |
| Energy & Utilities premise notifications | [sf-industry-energy](../sf-industry-energy/SKILL.md) | Premise / Service Point |
| Field Service appointment reminder SMS | [sf-field-service](../sf-field-service/SKILL.md) | Appointment reminders live in FS |
| Sales Cloud opportunity-stage email with no Pardot runtime | [sf-sales-cloud](../sf-sales-cloud/SKILL.md) | Not a Pardot send |
| Service Cloud agent-reply email / email-to-case | [sf-service-cloud](../sf-service-cloud/SKILL.md) | Not a Pardot send |
| Generic Apex / LWC / Flow with no Pardot configuration | [sf-apex](../sf-apex/SKILL.md) / [sf-lwc](../sf-lwc/SKILL.md) / [sf-flow](../sf-flow/SKILL.md) | Orthogonal surface |

---

## 2. Phase 0: Industry Pre-Check (MANDATORY)

**Before producing any MCAE / Pardot artifact, run the shared industry pre-check:** [`references/industry-precheck.md`](../../references/industry-precheck.md).

Pardot is a **generic cloud skill**. An industry solution's data model (Household, Care Plan, Program Enrollment, Benefit, Gift Transaction, Sales Agreement, Visit, Subscriber, Premise, etc.) often owns the semantic trigger, the audience definition, and the reporting rollup for a B2B or constituent campaign. **NEVER silently override an industry data model.** If the industry owns the entity driving the campaign, the industry skill owns the design — this skill executes only the Pardot mechanics on instruction from the industry skill.

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

Nonprofit pre-check: if the org has Nonprofit Cloud or NPSP installed AND the campaign is a donor / constituent / volunteer communication, route to [sf-nonprofit-fundraising](../sf-nonprofit-fundraising/SKILL.md) (NPC) or [sf-nonprofit-npsp](../sf-nonprofit-npsp/SKILL.md) (NPSP) before this skill.

**Deferral behaviour.** If industry detection is positive and the user's request overlaps with an industry-owned object/process, print:

```
Detected {industry} is installed. Routing to sf-{industry-skill}
because this request touches {matched object/process}.
The Pardot / MCAE mechanics will be invoked from that skill.
```

Then STOP generic Pardot workflow and return control so the industry skill can run its domain logic and call back into this skill for Pardot-only mechanics.

**Exception.** Generic Pardot still owns the task when the user explicitly says "ignore the industry overlay" OR the campaign has no industry-object binding (e.g., a pure generic B2B newsletter on Leads with no FSC Household / Health Patient / etc. involvement). Document the exception.

**Important nuance.** Pardot is predominantly B2B. Many industry solutions (Health, Education, Public Sector, Nonprofit) are B2C-leaning; when they are installed, it is rare for Pardot to be the correct runtime for industry-specific communications. When both are present, start with the assumption that the industry skill wins, and require explicit justification to route to Pardot.

---

## 3. Marketing Cloud Product Disambiguation (Critical)

Before this skill does anything, confirm the org is actually running Marketing Cloud Account Engagement (Pardot) and not one of the two adjacent products. Salesforce has three Marketing Cloud products in market as of Spring '26 and they are **not interchangeable**:

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
       ROUTE: sf-marketing-account-engagement  (this skill)
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
       ROUTE: sf-marketing-cloud-growth
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

**If both Pardot and MCG are installed** (common in large B2B2C orgs): the skill that owns the **specific channel the user asked about wins**.

- B2B engagement programs, scoring, grading, forms, landing pages, form handlers, completion actions, automation rules, B2BMA → this skill.
- Journeys on the Core org, Content Builder in MCG, Einstein for Marketing features in MCG, Data-Cloud-segment-driven email/SMS → `sf-marketing-cloud-growth`.

If genuinely ambiguous, ask the user which tier (Pardot BU vs MCG) should own the campaign. Do not guess.

**Pardot vs legacy MCE — quick distinguisher.**

| Signal | Pardot / MCAE | Legacy MCE |
|---|---|---|
| Target audience shape | B2B (account-centric) | Any (usually B2C) |
| Data store | Pardot's own warehouse (not Data Cloud, not the CRM directly) | SFMC Data Extensions |
| Runtime location | Pardot Business Unit synced via Connector to Salesforce | Separate tenant (`*.marketingcloudapis.com`) |
| Namespace | `pi__` managed package | None on the Core org |
| Primitives | Prospect, Pardot List, Engagement Program, Form, Landing Page, Automation Rule | Subscriber, List, Data Extension, Journey, Automation |
| Sync to CRM | Salesforce-Pardot Connector (bi-directional, field-by-field) | Sales / Marketing Cloud Connect (optional) |
| Templating | HML (Handlebars Merge Language) + merge fields | AMPscript, SSJS |
| Scoring / grading | Native | Not native |

---

## 4. Required Context to Gather First

Before producing any Pardot / MCAE design, establish:

- **Edition / tier.** Growth, Plus, Advanced, or Premium? Each tier has different caps — Growth has limited automation-rule count and no Einstein; Plus adds Engagement Studio; Advanced adds custom object sync, B2B Marketing Analytics, and Einstein; Premium adds sandbox, extended data retention, and SSL on all vanity domains. Designing for a tier the org does not own will produce a plan that cannot deploy.
- **Business Unit topology.** Single Pardot Business Unit (BU) or multiple (Enterprise / Premium)? If multi-BU, which Prospects live in which BU? What is the data-sharing posture (Marketing Data Sharing rules) between BUs and the Salesforce CRM?
- **Salesforce-Pardot Connector status.** Is the connector verified, synced, and recent? What objects are synced (Lead, Contact, Account, Opportunity, Custom Objects)? Are the Marketing Data Sharing rules configured to control which CRM records sync as Prospects? An unhealthy connector is an upstream blocker for every design below.
- **Tracker domain / CNAME.** What is the tracked vanity domain (`go.example.com` or similar) and is the SSL certificate current? Is it on the new Tracker Domain (per-BU, HTTPS-only) or the legacy tracker domain?
- **Sender authentication.** SPF, DKIM (signing domain or Sender Authentication Package), DMARC alignment. Gmail and Apple Mail enforce DMARC alignment for bulk senders.
- **Prospect sourcing.** Where do Prospects come from — Pardot forms, Pardot form handlers, imported lists, Salesforce lead sync, API? Which path is the primary? What is the de-duplication rule (email-based by default, can be CRM ID-based in newer BUs)?
- **Scoring and grading policy.** Scoring (implicit, behaviour-based) vs Grading (explicit, profile-based). One scoring rule set or scoring categories (Advanced)? One grading profile or multiple?
- **Lead assignment.** Round-robin, territory-based, score-threshold-based, or external tool (LeanData, Distribution Engine)? How are MQLs handed off to Sales — automation rule, completion action, or manual?
- **B2B Marketing Analytics (B2BMA).** Is the B2BMA app installed and refreshing? Which dashboards are in use? Is the Einstein Attribution model (multi-touch vs first-touch vs last-touch) explicit?
- **Compliance.** GDPR / ePrivacy (EU), CAN-SPAM (US), CASL (Canada). Explicit-opt-in Lists vs implicit. Preference Center live? Pardot's built-in Email Preference Center vs a custom one? Suppression list posture?
- **Integration surface.** Third-party webinar tools (ON24, Zoom, Webex), webhooks, Salesforce engagement history, CRM custom objects.

Missing the edition, connector status, or tracker domain status is a design-blocking gap.

---

## 5. Workflow Phases

Run in order. Phase 0 (industry pre-check) has already executed.

### Phase 1 — Connector and Data Model Alignment

1. Verify the Salesforce-Pardot Connector is **Verified** and most recent sync is fresh (< 1 hour).
2. List synced objects: Lead, Contact, Account, Opportunity, Campaign — are all required? Are Custom Objects synced (Advanced / Premium only)?
3. Audit Marketing Data Sharing rules — Prospect-to-Lead, Prospect-to-Contact, Prospect-to-Opportunity — they gate which CRM records appear as Prospects in Pardot. Overly loose rules mean every CRM Lead/Contact becomes a Prospect (billing and deliverability implications); overly tight rules mean segments cannot be built.
4. Confirm field-level sync direction (Pardot-to-Salesforce, Salesforce-to-Pardot, or bi-directional) for every custom field. A bi-directional field with stale data on one side will silently overwrite the fresher side.
5. Document the Prospect-to-Lead-vs-Contact routing rule: when a Prospect is created, does it become a Lead until converted, or is the org on the "Contact-only" or "Lead-only" flow?

### Phase 2 — Tracker Domain, Authentication, and Deliverability

1. Confirm the Pardot tracker domain (e.g., `go.example.com`) is CNAME'd to the correct Pardot-provided target, SSL is issued, and the domain is selected as the default in Pardot Settings.
2. Confirm the sending domain's SPF, DKIM (signing domain or Sender Authentication Package), and DMARC alignment — all passing. DMARC policy of at least `p=none` with RUA reporting; `p=quarantine` / `p=reject` only after RUA analysis.
3. Confirm the legal-text footer (physical mailing address, unsubscribe link, preference-center link) is in every email template via a reusable snippet — never hand-typed per email.
4. Review IP warm-up posture — new Pardot BUs on dedicated IPs require a 4–6 week warm-up plan.

### Phase 3 — Lists, Segmentation, and Dynamic Lists

1. Define the list strategy: **Static Lists** for ad-hoc / imported / campaign-specific audiences; **Dynamic Lists** for rule-driven audiences that refresh continuously (membership rules on Prospect fields, Visitor activity, List membership, CRM fields, scoring, grading).
2. Use **Suppression Lists** on every public send — at minimum: hard-bounces, unsubscribes, competitors, customer-side seed list.
3. Name lists by convention: `[Campaign] - [Persona] - [Stage] - [Date]` or similar. Lists proliferate in Pardot; without convention the BU becomes unnavigable.
4. Prefer Dynamic Lists over Static with automation-rule backfill — Dynamic Lists are self-healing when Prospect fields change; Static + automation is an anti-pattern.
5. For cross-BU or cross-CRM orgs: use Marketing Data Sharing rules to scope lists, not manual exclusion logic.

### Phase 4 — Scoring and Grading

1. **Scoring** (implicit, behaviour-driven). Define the point values for each tracked behaviour: page view, form submission, email open, email click, file download, webinar attendance, custom-object interaction. Tune defaults — Pardot's out-of-the-box values are a starting point, not a finished design.
2. **Scoring Categories** (Advanced / Premium only) — separate scores per product line or buyer persona. If the org sells multiple products, use categories; otherwise the single score becomes a meaningless average.
3. **Grading** (explicit, profile-based). Define the Grading Profile: industry, employee count, revenue, job title, geography. Letter grades (A through F) are applied via a Profile that matches known fields. Do not design scoring without grading — scoring without grading produces high-score-but-wrong-fit leads.
4. **Score decay** (automation rule): prospects lose N points per week of inactivity. Without decay, old prospects who once engaged look indistinguishable from freshly engaging prospects.
5. **MQL threshold** — the combined score + grade that triggers the MQL-to-Sales handoff. Document the threshold explicitly; the Engagement Studio and automation rules both reference it.

### Phase 5 — Forms, Form Handlers, and Landing Pages

1. **Forms** (hosted by Pardot) — use when the form runs on a Pardot landing page or is embedded via iframe on a Pardot-tracked domain. Forms natively write to Prospect fields, fire completion actions, and honor progressive profiling.
2. **Form Handlers** (non-hosted) — use when the form lives on a non-Pardot website (marketing website on a CMS, e-commerce system). Form Handlers accept `POST` payloads, de-dupe by email, and map to Prospect fields. No HTML is served by Pardot.
3. **Progressive Profiling** — configure on Forms so repeat visitors see additional questions in place of already-captured ones. Limit total questions on any single form to the fewest that produce an MQL-worthy Prospect; long forms kill conversion.
4. **Completion Actions** on a form / form handler: add to list, add tag, adjust score, assign to user, register to campaign, notify user, send autoresponder email, create Salesforce task. Chain completion actions in a logical order (score adjust first, then list add, then autoresponder).
5. **Landing Pages** — build in Pardot with a layout template (MJML or hand HTML). One landing page per Form; embed the Form via the Form component. Test on mobile; most B2B landing pages still render poorly on small screens.
6. **reCAPTCHA** (honey-pot or v3) on every public form to block bot submissions — bot form fills inflate scoring and corrupt MQL counts.
7. Validate **honey-pot fields** or **Pardot's reCAPTCHA integration** is enabled. Otherwise, spam floods.

### Phase 6 — Engagement Studio Programs

Engagement Studio is Pardot's multi-step nurture engine.

1. Define the program goal in plain English: "educate net-new leads through awareness-to-consideration over 6 weeks", "re-engage lapsed MQLs in 10 days", "post-demo nurture toward proposal over 4 weeks", etc. One goal per program.
2. Define the **recipient list** (Dynamic List preferred) and the **suppression list**. Set the **Schedule** — usually business hours in the prospect's timezone (requires `Timezone` field populated on Prospect).
3. Author the nodes:
   - **Action** — Send Email (bound to a template), Add to List, Remove from List, Adjust Score, Assign to User, Notify User, Register to Campaign, Create Task in Salesforce
   - **Trigger** — Email Opened, Email Clicked, Email Unopened, Link Clicked, Landing Page Visited, Form Submitted, Prospect Updated, Custom Redirect, Custom Event, Scored Higher Than, Graded Higher Than, Prospect Time Elapsed
   - **Rule** — conditional branch on Prospect field, grade, score, tag, list membership
4. Wait / pause nodes — respect recipient time zone and business hours; avoid "send Sunday 3am" paths.
5. Exit criteria — goal achieved (e.g., demo requested), score threshold crossed, manual removal, program end date. Every program needs an explicit exit; programs without exit accumulate stale Prospects.
6. Test the program with Test Mode on a seed recipient before activating. Pardot's Test Mode is non-destructive — use it.

### Phase 7 — Automation Rules, Completion Actions, and Segmentation Rules

1. **Automation Rules** — run continuously (re-evaluate every ~15 min). Use for ongoing classification: score decay, lifecycle stage update, list membership maintenance. Limit the Automation Rule count per BU (tier-capped — Growth has the lowest cap) and use Dynamic Lists or Segmentation Rules where possible to preserve Automation Rules for truly-ongoing logic.
2. **Segmentation Rules** — run once, then stop. Use for one-time list builds, retroactive tagging, bulk updates.
3. **Completion Actions** — run once per Prospect per trigger event (form submit, email click, etc.). Use for per-submission logic (assign owner, fire autoresponder, register to campaign).
4. Prefer the lightest-weight rule type that does the job. A Completion Action is cheaper than an Automation Rule; a Dynamic List is cheaper than an Automation Rule that maintains a Static List.
5. Document every Automation Rule's purpose in its description field. Orphaned automation rules accumulate across years and silently mis-score Prospects; a description field is the only way to audit them.

### Phase 8 — Lead Assignment to Salesforce

1. Decide the trigger: score threshold crossed, grade threshold crossed, form submission on a high-intent form, manual by BDR. One trigger per assignment rule.
2. Choose the mechanism: Pardot Completion Action → Assign to User; Automation Rule → Assign to User / Group / Queue; external tool (LeanData, Distribution Engine).
3. For round-robin or territory-based assignment, external tools are usually stronger than Pardot's native assignment; Pardot's native is "to user" or "to queue" — it does not do true round-robin natively without an external layer.
4. On assignment, confirm the Prospect is synced to Salesforce as a Lead (or Contact, depending on org model) before the assignment fires — otherwise the Salesforce user is assigned to a record that does not exist yet.

### Phase 9 — B2B Marketing Analytics and Pardot Einstein

1. **B2B Marketing Analytics (B2BMA)** — Advanced / Premium tier. Install the app, refresh the dataset (daily is standard), tailor the out-of-the-box dashboards (Engagement, Marketing Manager, Pipeline). Do not build a custom B2BMA app before the default dashboards are in use; the default surface answers most B2B questions.
2. **Pardot Einstein** — Advanced / Premium tier. Four main features:
   - **Einstein Behavior Scoring** — ML-predicted likelihood to become an Opportunity based on behaviour patterns.
   - **Einstein Lead Scoring** — alternative to the rules-based scoring, using historical conversion patterns.
   - **Einstein Campaign Insights** — pattern analysis across Campaigns.
   - **Einstein Attribution** (within B2BMA) — multi-touch / first-touch / last-touch revenue attribution.
3. Do not run Einstein scoring and rules-based scoring in parallel without an explicit policy — either reconcile them into one MQL threshold, or make it clear which scoring drives assignment.

### Phase 10 — Testing and Validation

1. **Email rendering** — send test emails to at least Gmail, Outlook 365, Apple Mail, and two mobile clients. Pardot's preview is not a substitute.
2. **Deliverability** — send a seed test and verify Gmail Postmaster / Apple Business / Google DMARC RUA report show alignment.
3. **Form / Form Handler** — submit synthetic test submissions, verify Prospect creation, verify completion actions all fire, verify the Prospect is visible in Pardot and synced to Salesforce if applicable.
4. **Engagement Studio** — run in Test Mode with a seed Prospect; verify every branch.
5. **Compliance** — unsubscribe one seed Prospect, verify the opt-out propagates across all lists and suppresses future sends. Test the Email Preference Center.
6. **Regression** — if this campaign is demoable, route to [sf-demo-playwright](../sf-demo-playwright/SKILL.md).

---

## 6. Scoring Rubric — 130 Points

Apply to any Pardot / MCAE design or build deliverable. Minimum passing: **98 / 130**. Sub-threshold categories must be fixed even if the total exceeds 98.

| Category | Max | Passing | What "passing" looks like |
|---|---|---|---|
| **Connector and data model alignment** | 25 | 19 | Salesforce-Pardot Connector verified and fresh; Marketing Data Sharing rules scoped; synced fields documented; Prospect-to-Lead/Contact routing explicit; no stale bi-directional overwrites |
| **Scoring, grading, and lead qualification** | 25 | 19 | Scoring rules defined; Scoring Categories used when multiple product lines exist; Grading Profile defined; score decay configured; MQL threshold documented; no scoring-without-grading |
| **Engagement Studio program design** | 20 | 15 | One program goal; recipient + suppression lists; all branches tested in Test Mode; explicit exit criteria; timezone / business-hours respected |
| **Forms, landing pages, and conversion UX** | 20 | 15 | Progressive profiling configured; minimum-question forms; completion actions chained in the right order; reCAPTCHA / honey-pot live; mobile rendering verified |
| **Compliance and deliverability** | 20 | 15 | Tracker domain with valid SSL; SPF/DKIM/DMARC aligned; legal footer reusable snippet; suppression lists on every public send; Email Preference Center live; GDPR / CASL / CAN-SPAM posture documented for audience geography |
| **Reporting (B2BMA / Einstein) and operational hygiene** | 20 | 15 | B2BMA dashboards in use (if licensed); Einstein features configured and not conflicting with rules-based scoring; every Automation Rule has a description; list-naming convention followed |

---

## 7. Anti-Patterns

- **Treating Pardot and legacy MCE (ExactTarget) as the same product.** They share the "Marketing Cloud" brand and almost nothing else. Pardot is B2B, uses the `pi__` managed package, syncs via Salesforce-Pardot Connector, and uses Engagement Studio + forms + scoring/grading. MCE is a separate tenant, uses AMPscript/SSJS, and uses Data Extensions + Automation Studio + Journey Builder (MCE variant). Mixing terminology leads to non-deployable designs.
- **Treating Pardot and Marketing Cloud Growth as the same product.** MCG is Data-Cloud-backed, runs in the Core org, and uses Data Cloud segments + Journey Builder-in-Core + Content Builder. Pardot has its own warehouse, its own Business Unit, and its own primitives. Route by detection signal, not by naming similarity.
- **Static Lists maintained by Automation Rules.** If the rule is "Prospect has score > 50", a Dynamic List is the correct answer — it's self-healing when the score changes. A Static List + Automation Rule backfill means stale lists, wasted Automation Rule count, and silent correctness drift. Dynamic Lists are free of Automation Rule cap.
- **Scoring without grading.** Scoring measures engagement; grading measures fit. A 1000-point prospect at a 5-person company is not an MQL; a 300-point prospect at a 50,000-person target-fit company probably is. Without grading, Sales receives high-volume, low-fit MQLs and loses confidence in the motion.
- **Long forms at top of funnel.** A 12-field form on a gated whitepaper kills conversion. Use progressive profiling: 3 fields first visit, 3 more on second visit (different fields), and so on. Conversion rate roughly doubles per field removed.
- **No reCAPTCHA / honey-pot on public forms.** Bot submissions flood Pardot with fake Prospects, inflate scoring, and sometimes trigger real sales outreach. Always gate public forms.
- **Sending from an unauthenticated domain or a tracker domain with expired SSL.** Gmail and Apple Mail will silently drop or quarantine. "It sends and I got it in my test inbox" is not deliverability proof.
- **One Engagement Studio program trying to cover awareness + consideration + decision + re-engage.** Each of those has different content, different frequency, different exit criteria. One-program-fits-all collapses into a mediocre compromise for all four.
- **Overly loose Marketing Data Sharing rules.** Syncing every CRM Lead/Contact as a Prospect when the marketing goal only needs a subset inflates Prospect count (billing), inflates email suppression complexity, and wastes sync cycles. Tighten Marketing Data Sharing.
- **Running Einstein scoring and rules-based scoring in parallel with no reconciliation.** Sales sees two numbers and does not know which to trust. Pick one as the MQL trigger and relegate the other to informational.
- **Hand-built legal-footer HTML in every email template.** Reuse a Snippet or a reusable email-footer component. When the company changes its physical mailing address, a hand-built footer requires editing every template. A shared snippet requires editing once.

---

## 8. Common Failure Modes and Remediation

### Failure 1 — "Salesforce-Pardot Connector shows 'Errors' — sync is backed up"
- **Symptom:** The Pardot Connector tile in Pardot Setup shows an error count, or the last sync timestamp is > 1 hour old. Prospects do not appear in Salesforce; CRM updates do not appear on Prospects.
- **Root cause:** Field-level errors (missing required field, picklist value mismatch, validation rule blocking sync), Pardot-side field permission issue, or Connector user (integration user) lost its permission set / profile configuration.
- **Fix:** Open Pardot Setup → Connectors → Salesforce → Errors tab. Review the top error — typically a validation rule on Lead or Contact blocking the sync of a specific field. Either exempt the Connector user from the rule (recommended pattern: check `$User.UserName` or an "Integration User" custom permission) or fix the underlying data. Re-verify the connector after fixing. If the Connector user's permission set was revoked, restore `Pardot Integration User` permission set license and re-verify.

### Failure 2 — "Prospect opts out, but keeps getting Engagement Studio emails"
- **Symptom:** A Prospect clicks unsubscribe in an email, but the next step of the Engagement Studio program still fires an email two days later.
- **Root cause:** Engagement Studio evaluates the `Opted Out` flag at the moment of send, but certain list-based exclusions only re-run on list-refresh; if the program uses a Static List, the Prospect may not be removed between steps. Additionally, list-based opt-out does not always propagate across Business Units.
- **Fix:** Verify the global `Opted Out` flag is honored by every send step (it should be, by default). Switch the recipient list to a Dynamic List with `Opted Out = false` as a membership rule. Audit whether multi-BU sync is copying the Prospect's opt-out across BUs — if not, enable cross-BU opt-out sync. For belt-and-suspenders, add a global suppression list for all opted-out Prospects and apply it to every Engagement Studio program.

### Failure 3 — "Form conversion dropped to zero overnight"
- **Symptom:** A Pardot form that was converting at 15% yesterday is converting at 0% today.
- **Root cause:** Tracker domain SSL expired; reCAPTCHA key rotated and the form is silently failing; Pardot account hit the monthly mailable-Prospect cap and new-Prospect creation is throttled; or the form's landing page was accidentally unpublished.
- **Fix:** Check the tracker domain SSL status in Pardot Settings; renew if expired. Check the reCAPTCHA site key / secret key pair in Pardot Settings → Security — if rotated externally, the form will silently accept and discard. Check the mailable-Prospect count vs account cap. Check the landing page's publish status. Test-submit the form yourself and watch the Network tab for the real error.

### Failure 4 — "Scoring Categories produce wildly different scores for the same Prospect"
- **Symptom:** A Prospect has score 800 in Category A and score 20 in Category B, and it is not obvious which product-line team should engage.
- **Root cause:** This is by design — Scoring Categories separate behaviour toward product lines so the right Sales team is tipped off. Symptom = feature, not a bug. However, if the MQL threshold is set on the unified score (`pardotScore`), it is misleading; the threshold should be evaluated per category, not per unified.
- **Fix:** Create category-specific automation rules: `when Category A score > N, assign to the Category A rep` (and same for B). Do not use the `pardotScore` unified field for MQL gating in a multi-category setup. Document this in the scoring strategy.

### Failure 5 — "B2BMA dashboards show no data / show stale data"
- **Symptom:** The B2BMA dashboards render but all charts are empty, or show last week's data frozen.
- **Root cause:** The B2BMA app's data refresh schedule is paused, the underlying dataflow errored, or the `Pardot API` user the app uses has been deactivated. Alternatively, a recent field-level security change removed access to a field B2BMA depends on.
- **Fix:** In CRM Analytics Studio, open the B2BMA app → Data Manager → Monitor. Check the dataflow status. Reschedule or re-run manually. Verify the integration user has not been deactivated and still has the `CRM Analytics for B2B Marketing` permission set. Review recent field permission changes on Lead, Contact, Opportunity, and Campaign for fields B2BMA depends on.

### Failure 6 — "Form Handler accepts submissions but no Prospect is created"
- **Symptom:** External form posts to the Pardot Form Handler URL; the HTTP response looks fine; no Prospect appears.
- **Root cause:** The Form Handler's required fields are not being mapped from the source form; or the email is malformed and fails validation silently; or the Form Handler is configured with `Disable Visitor Activity Throttling` off and a bot / load-test earlier rate-limited submissions.
- **Fix:** Open the Form Handler in Pardot, verify the field mapping includes every required Prospect field (Email at minimum). Test-submit manually with a known-good email. Check Pardot logs for visitor throttling. If throttled, disable throttling on the Form Handler (only for low-abuse-risk paths).

---

## 9. Pardot / MCAE Object Cheat Sheet

### Core primitives

| Object / concept | Purpose |
|---|---|
| **Prospect** | Pardot's core record — a tracked individual. Synced bidirectionally with Salesforce Lead or Contact via Connector. |
| **Visitor** | An anonymous tracked browser, pre-Prospect. Converts to Prospect on form submission or identified email click. |
| **List** (Static) | A manually-populated collection of Prospects. Survives forever; does not self-heal. |
| **Dynamic List** | A rule-driven list that refreshes continuously as Prospect attributes change. Preferred over Static. |
| **Suppression List** | A list applied to sends to exclude specific Prospects (unsubscribes, competitors, internal). |
| **Campaign** (Pardot) | Pardot's campaign primitive; distinct from Salesforce Campaign (but synced). |
| **Form** (hosted) | A Pardot-hosted form embedded on a Pardot landing page or iframe. |
| **Form Handler** | An endpoint that accepts POSTs from a non-Pardot form. |
| **Landing Page** | A Pardot-hosted page, usually containing one Form. |
| **Engagement Program** (Engagement Studio) | A multi-step nurture with actions, triggers, rules. |
| **Email Template** | A reusable email shell (HTML/HML) used in sends and programs. |
| **List Email** | A one-time email send to a list. |
| **Autoresponder Email** | An email sent as a Completion Action on a form. |
| **Tracker Domain** | The branded vanity domain (e.g., `go.example.com`) used for tracking links and email rendering. |
| **Sender Authentication** | SPF + DKIM + DMARC alignment for the sending domain. |
| **Scoring** | Implicit, behaviour-driven point accumulation per Prospect. |
| **Scoring Category** | (Advanced+) Per-product-line or per-persona score. |
| **Grading** | Explicit, profile-based letter grade (A–F) per Prospect. |
| **Grading Profile** | The definition of which fields contribute to grade. |
| **Automation Rule** | Continuously-evaluated rule (~15 min cycle). Tier-capped count. |
| **Segmentation Rule** | One-time rule, then stops. |
| **Completion Action** | Fires once per Prospect per trigger event (form submit, email click, etc.). |
| **Custom Redirect** | A Pardot-tracked shortlink for attribution on off-site assets. |
| **Business Unit** | (Enterprise / Premium) A tenant within the Pardot account. Prospects live in one BU; cross-BU sharing via Marketing Data Sharing. |
| **Salesforce-Pardot Connector** | Bi-directional sync between a Pardot BU and a Salesforce org. |
| **Marketing Data Sharing rule** | The scoping rule controlling which CRM records sync to which Pardot BU. |
| **B2B Marketing Analytics (B2BMA)** | CRM Analytics-based dashboards for Pardot data. |
| **Pardot Einstein** | ML features: Behavior Scoring, Lead Scoring, Campaign Insights, Attribution. |

### Tier feature matrix (approximate)

| Feature | Growth | Plus | Advanced | Premium |
|---|---|---|---|---|
| Engagement Studio | Limited | Yes | Yes | Yes |
| Automation Rules (count cap) | Low | Medium | High | Highest |
| Scoring Categories | No | No | Yes | Yes |
| Custom Object sync | No | No | Yes | Yes |
| B2B Marketing Analytics | No | No | Yes | Yes |
| Pardot Einstein | No | No | Yes | Yes |
| Sandbox | No | No | No | Yes |
| Dedicated IP | No | Optional | Yes | Yes |

Confirm exact caps and feature matrix against current release notes.

### Cross-skill integration

| Need | Delegate to | Reason |
|---|---|---|
| Data Cloud-backed journeys in the Core org | [sf-marketing-cloud-growth](../sf-marketing-cloud-growth/SKILL.md) | Different runtime |
| Build a Data Cloud segment / calculated insight | [sf-datacloud-segment](../sf-datacloud-segment/SKILL.md) | Data Cloud is orthogonal to Pardot's warehouse |
| Harmonize source data into DMOs / identity resolution | [sf-datacloud-harmonize](../sf-datacloud-harmonize/SKILL.md) | Upstream of any Data Cloud work |
| Activate a Data Cloud audience to Pardot | [sf-datacloud-act](../sf-datacloud-act/SKILL.md) | Activation target wiring |
| Apex, LWC, Flow adjacent to Pardot | [sf-apex](../sf-apex/SKILL.md) / [sf-lwc](../sf-lwc/SKILL.md) / [sf-flow](../sf-flow/SKILL.md) | Generic platform code |
| Generate seed / test data for the demo | [sf-data](../sf-data/SKILL.md) | Data factory |
| Diagram a nurture or architecture | [sf-diagram-mermaid](../sf-diagram-mermaid/SKILL.md) | Mermaid diagrams |
| Validate an end-to-end demo flow | [sf-demo-validate](../sf-demo-validate/SKILL.md) | Pre-flight |

---

## 10. Output Format

When finishing, report in this order:

1. **Task classification** — design / build / troubleshoot / migrate
2. **Product confirmation** — MCAE / Pardot (not MCG, not MCE)
3. **Industry pre-check result** — not-applicable / deferred-to-{industry-skill}
4. **Edition / tier** — Growth / Plus / Advanced / Premium
5. **Business Unit topology** — single or multi-BU + Marketing Data Sharing posture
6. **Connector status** — verified + fresh / errors + remediation
7. **Tracker domain + sender authentication** — SSL status, SPF/DKIM/DMARC alignment
8. **Scoring / grading strategy** — rules-based, Einstein, or hybrid, with MQL threshold
9. **Compliance posture** — preference center, suppression lists, GDPR / CASL / CAN-SPAM coverage
10. **Scoring total** — N / 130, with any sub-threshold category flagged
11. **Next recommended step** — next phase or cross-skill handoff
