---
name: sf-reports-dashboards
description: >
  Native Salesforce Reports, Report Types, Dashboards, and Analytics Tab architecture with
  120-point scoring and industry-first routing precedence.
  TRIGGER when: user builds or troubleshoots native Salesforce reports (Tabular, Summary, Matrix,
  Joined formats), configures Report Types (standard or custom), authors Report Filters / Logic /
  Cross-Filters / Bucket Fields, manages Report Folders and sharing, schedules Report Subscriptions,
  builds Dashboards with Chart / Table / Metric / Gauge / Lightning Table components, configures
  Dynamic Dashboards, sets Dashboard Subscriptions, touches `.report-meta.xml`,
  `.dashboard-meta.xml`, or `.reportType-meta.xml`, or asks to "build a report for X",
  "pipeline by stage by owner", "donors who gave last year but not this year report", "matrix
  report of cases by priority by queue", "joined report comparing Q3 vs Q4", "dashboard for the
  VP", "donut chart of funding sources", "dynamic dashboard that shows each manager their team",
  "subscribe me to this report weekly", "add a bucket for age ranges", "cross-filter accounts
  without opportunities", "historical trending on forecast", "my custom object isn't showing
  up — need a report type", "funnel chart of opportunity stage", "gauge showing how close we
  are to goal".
  DO NOT TRIGGER when: the analytics are in Tableau, Tableau Next, CRM Analytics (formerly
  Einstein Analytics / Tableau CRM), Einstein Discovery, SAQL, lenses, dashboards in the
  Analytics Studio app, Pulse metrics, or Tableau Semantic Layer views (use sf-tableau for all
  Tableau / CRMA / Tableau Next work); the query is Data Cloud SQL, async query, calculated
  insight, or a segment count via DC (use sf-datacloud-retrieve or sf-datacloud-segment); the
  ask is raw CRM SOQL with no visualization (use sf-soql); the report is a Power BI / Looker /
  third-party BI artifact (out of scope — not a Salesforce-native skill); Industry Cloud ships
  packaged reports and dashboards on industry-owned objects and the user is asking for those —
  FSC reports on Household / Financial Account / Life Event Moment (use sf-industry-fsc);
  Health Cloud reports on Patient / Care Plan / Care Request (use sf-industry-health);
  Education Cloud / EDA reports on Student / Program Enrollment / Course Connection
  (use sf-industry-education); Public Sector Solutions reports on Benefit / License / Permit /
  Inspection (use sf-industry-public-sector); Field Service reports on Work Order / Service
  Appointment / Dispatcher metrics (use sf-field-service); Manufacturing Cloud reports on
  Sales Agreement / Account Forecast / Rebate Program (use sf-industry-manufacturing); Consumer
  Goods Cloud reports on Visit / Retail Execution / Trade Promotion (use sf-industry-consumer-goods);
  Communications Cloud reports on Product Catalog / Order Decomposition (use sf-industry-communications);
  Media Cloud reports on Subscriber / Billing Account (use sf-industry-media); Energy & Utilities
  reports on Premise / Service Point / Meter (use sf-industry-energy); Nonprofit Cloud reports
  on Gift Transaction / Program Enrollment / Funding Award (use sf-nonprofit-cloud family);
  NPSP reports on Opportunity-as-donation / Recurring Donation / Household Account
  (use sf-nonprofit-npsp); Revenue Cloud / CPQ reports on Quote / Order / Subscription
  (use sf-revenue-cloud); Service Cloud Omni-Channel supervisor dashboards — those are
  Omni-Channel's own real-time dashboards, not native Reports (use sf-service-omnichannel);
  embedded LWC dataviz (use sf-lwc); SOQL-in-Apex for a visualization (use sf-apex / sf-soql).
license: MIT
compatibility: "Available in all editions with Reports & Dashboards enabled. Dynamic Dashboards and Historical Trending require Enterprise edition or above."
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.reports_dashboards_intro.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.reports_report_types_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/decision-guides/analytics
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_analytics_reports.htm
---

# sf-reports-dashboards: Native Salesforce Reports + Dashboards

Use this skill when the user needs **native Salesforce Reports and Dashboards** — the reporting surface that ships with every edition, exposed through the Analytics / Reports tab, built on Report Types, authored in the Lightning Report Builder, and visualized with the standard Dashboard components. This is **not Tableau**, **not CRM Analytics**, and **not Data Cloud SQL**. Those three are owned by [sf-tableau](../sf-tableau/SKILL.md), [sf-datacloud-retrieve](../sf-datacloud-retrieve/SKILL.md), and [sf-datacloud-segment](../sf-datacloud-segment/SKILL.md) respectively.

This skill owns: standard Report Types, custom Report Types (`.reportType-meta.xml`), Tabular / Summary / Matrix / Joined report formats, Report Filters / Filter Logic / Cross-Filters / Bucket Fields / Row-Level Formulas / Summary Formulas, Report Folders and sharing, Report Subscriptions, the Analytics tab, Dashboards, all standard Dashboard components (Chart, Table, Metric, Gauge, Funnel, Lightning Table), Dynamic Dashboards, Dashboard Filters, and Dashboard Subscriptions.

---

## 1. When This Skill Owns the Task

This skill owns the task when the user wants **native** Salesforce reports or dashboards — authored in the Report / Dashboard Builder, stored as `.report-meta.xml` / `.dashboard-meta.xml` / `.reportType-meta.xml`, and rendered inside the Salesforce org's Reports tab or on a Lightning page.

Delegate when the task is a different analytics product or an industry-owned report pattern:

| User need | Route to | Why |
|---|---|---|
| Tableau, Tableau Next, or CRM Analytics (Einstein Analytics / Tableau CRM) workbooks, dashboards, dataflows, recipes, lenses, SAQL, Pulse metrics, Einstein Discovery stories | [sf-tableau](../sf-tableau/SKILL.md) | Different product, different runtime, different query language |
| Data Cloud SQL, async query, vector search, search indexes | [sf-datacloud-retrieve](../sf-datacloud-retrieve/SKILL.md) | DC is a separate query plane |
| Data Cloud calculated insights, segment counts | [sf-datacloud-segment](../sf-datacloud-segment/SKILL.md) | Segment metrics, not CRM reports |
| Raw SOQL without visualization | [sf-soql](../sf-soql/SKILL.md) | Query, not report |
| Reports / dashboards on industry-owned objects (see Phase 0) | Industry skills | Industry owns the object and ships packaged analytics |
| Embedded LWC data visualization | [sf-lwc](../sf-lwc/SKILL.md) | Component code |
| Service Cloud Omni-Channel supervisor real-time dashboards | [sf-service-omnichannel](../sf-service-omnichannel/SKILL.md) | Real-time, not Report-engine-backed |
| Power BI / Looker / third-party BI | out of scope | Not a Salesforce-native skill |

---

## 2. Phase 0: Industry Pre-Check (MANDATORY)

**Before producing any report or dashboard, run the shared industry pre-check:** [`references/industry-precheck.md`](../../references/industry-precheck.md).

Industry Clouds own the **data model** for their domain — and nearly always ship **packaged reports and dashboards** against that model. A generic "build me a report" request in an FSC / Health / EDU / PSS / Field Service / Manufacturing / CG / Comms / Media / Energy / NPC / NPSP / RCA org is usually asking for a report on an industry-owned object. Shipping a hand-rolled report that bypasses the packaged report type is almost always the wrong answer — it ignores formatting conventions, misses rollup fields, and diverges from the industry's dashboard library.

Run the pre-check's detection steps (license / feature flag, namespace scan, object existence) and if **any** of the following is positive AND the user's request touches that industry's owned objects, **halt and forward**:

1. [sf-industry-fsc](../sf-industry-fsc/SKILL.md) — Households, Financial Accounts, Financial Goals, Life Event Moments, Relationship Maps
2. [sf-industry-health](../sf-industry-health/SKILL.md) — Patient, Care Plan, Care Request, Clinical Encounter, EHR, Assessment, Care Team
3. [sf-industry-education](../sf-industry-education/SKILL.md) — Student, Program Enrollment (edu), Course Connection, Affiliation, Term
4. [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) — Benefit, License, Permit, Inspection, Application, Regulatory Code Violation
5. [sf-field-service](../sf-field-service/SKILL.md) — Work Order, Service Appointment, Service Resource, Territory
6. [sf-industry-manufacturing](../sf-industry-manufacturing/SKILL.md) — Sales Agreement, Account Forecast, Rebate Program
7. [sf-industry-consumer-goods](../sf-industry-consumer-goods/SKILL.md) — Retail Store, Visit, Retail Execution, Trade Promotion
8. [sf-industry-communications](../sf-industry-communications/SKILL.md) — Product Catalog, Offer, Order Decomposition, ESM
9. [sf-industry-media](../sf-industry-media/SKILL.md) — Subscriber, Billing Account, Campaign Response
10. [sf-industry-energy](../sf-industry-energy/SKILL.md) — Premise, Service Point, Meter, Interval Data
11. [sf-nonprofit-cloud](../sf-nonprofit-cloud/SKILL.md) family — Gift Transaction, Gift Designation, Funding Award, Program Enrollment (NPC), Benefit (NPC)
12. [sf-nonprofit-npsp](../sf-nonprofit-npsp/SKILL.md) — Opportunity-as-donation, Recurring Donation, Household Account, Allocation
13. [sf-revenue-cloud](../sf-revenue-cloud/SKILL.md) — Quote, Order, Subscription, Contract-as-revenue, Billing Schedule

**Deferral behaviour.** If industry detection is positive and the user's request overlaps with an industry-owned object/process, print:

```
Detected {industry} is installed. Routing to sf-{industry-skill}
because this request touches {matched object/process}.
Report / dashboard mechanics will be invoked from that skill.
```

Then STOP generic report workflow and return control so the industry skill can decide whether to use a packaged report type, customize one, or call back into this skill for generic mechanics.

**Exception.** This skill still owns the task when the user explicitly says "standard Salesforce report — ignore the industry overlay", OR the report targets only generic standard objects that the industry does not extend (e.g., a User login report, a Task activity report where Task is not industry-customized), OR the industry skill has explicitly delegated back for generic mechanics.

---

## 3. Required Context to Gather First

Before producing any report or dashboard, establish:

- **Subject.** What is being measured? Identify the primary object (and secondary if joined) before anything else. "Pipeline by stage" → Opportunity. "Donors who haven't given in a year" → Account/Contact + Gift Transaction or Opportunity.
- **Report Type.** Does a standard Report Type exist for the object combination? If not, does a custom Report Type need to be created? If a custom Report Type is needed, confirm with the user — CRTs are metadata and deploy across environments.
- **Format.** Tabular (flat list), Summary (grouped rows, one group dimension), Matrix (rows × columns grouping), or Joined (multiple report blocks side-by-side on a shared key).
- **Time grain.** Daily / weekly / monthly / quarterly / fiscal-period / rolling-window? Does the user need historical trending (point-in-time snapshots) — that requires Historical Trending enabled and is only on certain objects (Opportunity, Case, a few more).
- **Audience and access.** Who sees this report? Report Folder and folder-sharing rules determine access. Shared with a role, role-and-subordinates, public group, or a specific person?
- **Filters.** Standard filters (date range, record type, owner), Filter Logic (AND/OR combinations, NOT), Cross-Filters ("accounts WITH opportunities", "accounts WITHOUT cases"), Bucket Fields (categorize a field into named buckets), Row-Level Formulas, Summary Formulas.
- **Chart requirements.** Bar / column / line / donut / funnel / scatter / gauge / metric / table — driven by what question the chart answers. Charts on reports are optional; charts on dashboards are required.
- **Dashboard scope.** Is this a standalone report or a component of a dashboard? If dashboard, how many components, what running user (static vs. dynamic), what filters, what subscriber audience?
- **Dynamic Dashboards.** Does the dashboard need to show each viewer their own data (dynamic, "view as logged-in user") or a fixed running user's data (static)? Dynamic Dashboards are Enterprise+, cost a license slot, and have a per-org cap.
- **Subscription needs.** Who gets the report / dashboard by email on what schedule? Report Subscriptions vs Dashboard Subscriptions behave differently — Dashboard Subscriptions send PNG snapshots; Report Subscriptions send conditional alerts and attachment options.
- **Localization / formatting.** Currency (single vs multi-currency), timezone, locale-specific date formats, decimal precision.
- **Performance budget.** How many rows is the report expected to return? Reports > 2,000 rows paginate; > 2,000,000 rows may require async export or a different analytics product (Tableau / CRMA / Data Cloud).

Missing the subject, Report Type, or audience is a design-blocking gap. Do not guess.

---

## 4. Workflow Phases

Run in order. Phase 0 (industry pre-check) has already executed.

### Phase 1 — Report Type Selection

1. Determine if a standard Report Type covers the object combination. Example: "Opportunities with Products" is standard; "Accounts with Volunteer Hours" is not.
2. If no standard Report Type exists:
   - Create a custom Report Type (`.reportType-meta.xml`).
   - Choose **Primary Object** (must be the record the report groups on).
   - Add **Related Objects** (up to 4 levels deep), each with its relationship type (A records may or may not have related B).
   - Select **Fields Available for Reporting** — not all fields from related objects are exposed by default; you pick.
   - Deploy the Report Type metadata; verify it appears in Report Builder's Report Type picker.
3. For heavy reporting loads, keep custom Report Types narrow — a Report Type with 300 fields exposed is slow and unmanageable.

### Phase 2 — Format and Grouping

1. Pick the **Report Format** by question shape:
   - "Give me a flat list of records" → Tabular
   - "Group by one dimension (owner / stage / month)" → Summary
   - "Pivot on two dimensions (owner × stage, month × region)" → Matrix
   - "Compare disjoint slices side-by-side (Q3 pipeline vs Q4 pipeline as two blocks)" → Joined
2. Add **Groupings**:
   - Summary: one group level (up to 3 nested).
   - Matrix: up to 2 row groups and 2 column groups.
   - Joined: each block can group independently.
3. For time groupings, use **Date Grouping** (by day / week / month / quarter / fiscal quarter / year). Use calendar or fiscal calendar per org's fiscal settings.

### Phase 3 — Filters and Logic

1. Add **Standard Filters** (date range, record type, scope like "My Opportunities" / "All Opportunities").
2. Add **Field Filters** — specific criteria like `Stage = 'Closed Won'`, `Amount > 10000`.
3. Use **Filter Logic** to combine filters with AND/OR/NOT. Example: `(1 AND 2) OR (3 AND 4)`.
4. Use **Cross-Filters** for membership / non-membership across related objects:
   - "Accounts WITH Opportunities" → keep accounts that have at least one related opportunity
   - "Accounts WITHOUT Opportunities (in the last 12 months)" → exclude accounts that do
5. Add **Bucket Fields** when the user wants to categorize a field into named ranges that don't exist as a field value (e.g., bucket `Amount` into `< 10k`, `10k-50k`, `50k-100k`, `> 100k`).
6. Add **Row-Level Formulas** for per-row calculations (limit: 1 per report).
7. Add **Summary Formulas** for aggregate calculations at grouping levels (e.g., % change between two groups).
8. Respect **sharing rules** — a report does not bypass FLS or record sharing. If a user can't see the record in the UI, they won't see it in the report.

### Phase 4 — Charts on the Report

1. Add a chart to the report for visual summary (optional but recommended for reports surfaced on dashboards or record pages).
2. Pick chart type matching the question:
   - Count of records / compare categories → Bar / Column
   - Trend over time → Line
   - Proportion of whole → Donut / Pie (prefer Donut)
   - Conversion progression → Funnel (Opportunity Stage classic)
   - Single-metric vs goal → Gauge
3. Configure axis labels, chart title, legend position. Accessibility: do not rely on color alone to convey meaning.

### Phase 5 — Report Folder and Sharing

1. Save the report in a **Report Folder** (not My Personal Custom Reports, unless truly personal).
2. Configure folder sharing:
   - Viewer / Editor / Manager access
   - Shared with Users / Roles / Roles and Subordinates / Public Groups
3. For cross-org or external user access, confirm folder sharing aligns with the external user's license. Experience Cloud users cannot access most folders by default.

### Phase 6 — Subscriptions

1. **Report Subscription** — a user can subscribe themselves (or be subscribed by admin, up to a limit per org). On the schedule, the report runs and emails conditions OR attaches results (formatted / CSV). Subscription honors the running user's sharing.
2. **Dashboard Subscription** — admin can subscribe up to N recipients. On the schedule, the dashboard renders as a PNG snapshot and emails. Subscription honors the running user of the dashboard (static) or each recipient individually (dynamic).
3. Confirm subscription limits per edition — they are capped.

### Phase 7 — Dashboard Composition

1. Create the **Dashboard** in a Dashboard Folder with appropriate sharing.
2. Add **Components** — each component is backed by a **source report**:
   - Chart (line / bar / donut / column / funnel / scatter)
   - Metric (single number with optional conditional formatting)
   - Gauge (progress toward goal)
   - Table (grouped or ungrouped tabular list)
   - Lightning Table (richer formatting, conditional cell highlighting, more columns)
3. Configure **Dashboard Filters** (up to 3 filters that cascade across all components; each filter exposes selected values to each component's source report).
4. Set the **Running User**:
   - **Static**: one running user's access determines what every viewer sees (use for exec dashboards where all viewers should see the same data)
   - **"Let dashboard viewers choose"** / **Dynamic Dashboard**: each viewer sees data per their own access (use for manager dashboards where each manager sees their team)
5. Save, add to Home Page / App Page / record page as needed.

### Phase 8 — Testing and Validation

1. **Row accuracy** — spot-check the report against the raw data (SOQL query, record search). Numbers that don't match the source mean a filter, join, or Report Type is wrong.
2. **Sharing test** — impersonate (or have a test user log in as) a user in each relevant role. Confirm they see the report, the right rows, and the right numbers.
3. **Subscription test** — run the subscription once on demand; verify the email renders, the PNG is legible, the conditional alert fires only on condition.
4. **Dashboard filter test** — apply each dashboard filter, verify each component filters correctly; check that filter values scope sub-reports appropriately.
5. **Dynamic dashboard test** — as User A, confirm their data; as User B, confirm different data; as an exec who sees both, confirm full data.
6. **Performance test** — run the largest-expected query; confirm the report returns < 2,000 rows in-UI or paginates cleanly; if > 2M rows expected, recommend a different analytics product (Tableau / CRMA / DC).

---

## 5. Scoring Rubric — 120 Points

Apply to any report / dashboard deliverable. Minimum passing: **90 / 120**. Sub-threshold categories must be fixed.

| Category | Max | Passing | What "passing" looks like |
|---|---|---|---|
| **Report Type correctness** | 20 | 15 | Primary object matches question; relationships correct; fields exposed without bloat; custom RT only if needed and deployed as metadata |
| **Format and grouping match** | 20 | 15 | Format (Tabular / Summary / Matrix / Joined) reflects the question shape; grouping levels are meaningful; no Matrix where Summary suffices, no Joined where Matrix suffices |
| **Filter correctness** | 20 | 15 | Standard filters scoped correctly; Filter Logic resolves business intent; Cross-Filters applied for membership semantics; Bucket / Row-Level / Summary Formulas used where field math alone falls short |
| **Chart and dashboard design** | 20 | 15 | Chart type matches the question; dashboard filters scoped meaningfully; Lightning Table used over classic where formatting matters; running user explicit (static or dynamic, not defaulted) |
| **Folder, sharing, and access** | 15 | 11 | Saved to a properly-shared folder; folder sharing matches audience; external user access considered if applicable; no reports orphaned in personal folders |
| **Subscription and delivery** | 10 | 7 | Subscription configured where audience doesn't visit the Reports tab daily; conditional alerts where appropriate; schedule tested; recipients within edition limits |
| **Testing and performance** | 15 | 11 | Row-level spot-check against source; impersonation test for sharing; row volume within Reports engine limits or routed to Tableau / CRMA / DC if over |

---

## 6. Anti-Patterns

- **Building the report in the wrong analytics product.** Reports & Dashboards is for **operational CRM analytics** on Salesforce objects with standard sharing semantics. For > 2M rows, for cross-object joins that CRT can't express, for predictive models, or for data that lives primarily outside the org, Tableau / CRM Analytics / Data Cloud are the right answer. Don't force-fit a huge historical analysis into native Reports.
- **Creating a custom Report Type when a standard one already works.** Custom Report Types are metadata that must be maintained. If the standard "Opportunities with Products" Report Type covers the need, use it.
- **Using Matrix format when Summary would suffice.** Matrix is powerful but confusing when only one dimension is needed. Pick the simplest format that answers the question.
- **Putting every field on the custom Report Type "just in case".** 300 fields on a CRT make it slow, hard to skim in the builder, and surface confusing namesakes. Expose only fields with reporting value; more can be added later.
- **Saving reports in personal folders.** "My Personal Custom Reports" means only the author can access the report. Dashboards that source from personal reports break for every other viewer.
- **Ignoring sharing rules in the mental model.** Users see only what their sharing allows. A report that "looks right" to an admin may return zero rows for a field rep. Always test with a representative user role.
- **Building a Dynamic Dashboard when a static one would do.** Dynamic Dashboards cost a license slot and are capped per org. Only use Dynamic when each viewer should see a different filtered slice (e.g., manager sees their team); for execs who should see the whole org, a static dashboard with one running user is cheaper and simpler.
- **Subscribing an entire company to a dashboard.** Dashboard Subscriptions are capped per edition. Subscribing 500 people to a daily dashboard hits limits and floods inboxes. Put the dashboard on Home or a Lightning App page instead, or use a Chatter / Slack post with a link.
- **Reporting on a DC segment count by exporting it to the Core org.** That is not how Data Cloud integrates. Segment counts live in Data Cloud; surface them via CRMA dashboards, DC calculated insights, or Activation-driven CampaignMember populations. Don't fake it with a Salesforce report.
- **Ignoring Historical Trending on forecast / pipeline discussions.** If the user wants "how has our pipeline changed week over week", they need Historical Trending (point-in-time snapshots) — not a regular Opportunity report. Historical Trending is only enabled on specific objects and is edition-gated.

---

## 7. Common Failure Modes and Remediation

### Failure 1 — "Report returns zero rows, but the records clearly exist"
- **Symptom:** The user knows 500 records match the criteria, but the report returns 0.
- **Root cause:** Running user's sharing excludes the records; or the Report Type has an INNER join where records lack the related record; or a filter is excluding everything unintentionally.
- **Fix:** Run the report as an admin / System Administrator. If rows appear, the issue is sharing — log in as the intended user to confirm. If zero even as admin, inspect the Report Type (does it require the related object to exist?) and the Filter Logic. Simplify filters one at a time until rows appear.

### Failure 2 — "Report returns duplicate-looking rows"
- **Symptom:** Accounts show up multiple times in what should be a flat list.
- **Root cause:** The Report Type includes a related object with a 1:many relationship (Account → Contact). Each contact duplicates the account row. Or the report format is Tabular when it should be Summary.
- **Fix:** Either switch to a Summary format grouping by Account (and the related objects surface as grouped detail), or use a Report Type that doesn't traverse the 1:many, or add a filter that limits to one related record per parent.

### Failure 3 — "Dashboard component shows different number than the source report"
- **Symptom:** The source report shows `$1.2M pipeline`. The dashboard metric shows `$900K`.
- **Root cause:** The dashboard filter is applied to the component (narrowing the report), or the dashboard's running user differs from the user who opened the report, or the dashboard is cached and stale.
- **Fix:** Click the component's "View Report" to see the filtered source. Compare to unfiltered report. Check dashboard filter values. Click "Refresh" to bust cache. Confirm running user matches expected scope.

### Failure 4 — "Dynamic dashboard shows wrong data for viewer"
- **Symptom:** Manager A opens the dashboard and sees Manager B's team numbers.
- **Root cause:** Running user is set to "Specific User" instead of "Logged-in User" (dynamic), OR the sharing model doesn't give Manager A access to their own team's records (role hierarchy misconfigured).
- **Fix:** Open dashboard properties → Running User → set to "The dashboard viewer" (dynamic). Verify Enterprise+ and a Dynamic Dashboard license slot available. Verify role hierarchy so Manager A actually has access to their team in sharing model.

### Failure 5 — "Subscription email arrives but the attachment is empty or truncated"
- **Symptom:** The subscribed recipient gets the email but the report attachment is 0 rows or cut off.
- **Root cause:** Subscription runs as the subscriber's own access (for self-subscriptions) or the admin's running user (for admin-configured subscriptions). If that user's sharing is narrower than expected, results are narrower. Attachment size limits also apply (Reports attachments are capped; > cap = truncated).
- **Fix:** Confirm running user access. If the report is large, switch to "Email me the formatted report" (link-only) rather than attached CSV, or switch to a Dashboard Subscription (PNG snapshot) if visual is sufficient.

### Failure 6 — "Custom Report Type doesn't show up in Report Builder"
- **Symptom:** CRT metadata is deployed but users building a new report can't find the type.
- **Root cause:** The Report Type is in Development status, not Deployed; OR the user's profile doesn't have access to the RT's primary/related objects; OR the RT was deployed to production but a profile was not updated to grant report builder access.
- **Fix:** Setup → Report Types → find the RT → change status from In Development to Deployed. Confirm all involved objects are accessible by the user. Confirm "Reports" tab is visible to the profile.

### Failure 7 — "Historical Trending report is blank for dates before last month"
- **Symptom:** The trending report returns rows for recent dates but nothing for older dates.
- **Root cause:** Historical Trending captures snapshots going forward from the date the feature was enabled on the object. There is no retroactive backfill.
- **Fix:** Explain the limitation. For retroactive analysis, look at CRM Analytics (which can ingest historical via dataflow) or Data Cloud. Going forward, set baseline expectations: snapshots accumulate from enablement date.

---

## 8. Reports & Dashboards Cheat Sheet

### Metadata files

| File suffix | Purpose |
|---|---|
| `.report-meta.xml` | The report definition (format, filters, groupings, columns) |
| `.dashboard-meta.xml` | The dashboard definition (components, filters, running user) |
| `.reportType-meta.xml` | Custom Report Type (primary + related objects + available fields) |
| `.reportFolder-meta.xml` / `.dashboardFolder-meta.xml` | Folders (with sharing config elsewhere) |

### Report format chooser

| Question shape | Format |
|---|---|
| "List of records matching criteria" | Tabular |
| "Counts / sums grouped by one dimension" | Summary |
| "Counts / sums pivoted on rows × columns" | Matrix |
| "Two or more disjoint views side-by-side with shared filter" | Joined |

### Chart type chooser

| Intent | Chart |
|---|---|
| Compare categories | Column / Bar |
| Trend over time | Line |
| Proportion of whole | Donut (prefer over Pie) |
| Conversion steps | Funnel |
| Single metric vs goal | Gauge |
| Compare two metrics | Combo Chart |
| Correlation of two metrics | Scatter |
| Tabular with conditional formatting | Lightning Table |

### Formulas at a glance

| Type | Scope | Limit |
|---|---|---|
| Bucket Field | Categorize a field into named ranges | Multiple per report |
| Row-Level Formula | Calculation per row | 1 per report |
| Summary Formula | Calculation at grouping level | Several per report (edition-gated) |

### Running user modes on Dashboards

| Mode | Who sees what | Edition |
|---|---|---|
| Static (specific user) | Everyone sees that user's data | All |
| Dynamic (logged-in user) | Each viewer sees their own data | Enterprise+ |
| "Let viewers choose" | Choose at runtime from allowed list | Enterprise+ |

### Subscription caps (approximate — verify per release)

| Object | Per-org cap | Per-user cap |
|---|---|---|
| Report Subscriptions | (per release notes) | typically 5 active |
| Dashboard Subscriptions | (per release notes) | typically 7 recipients per subscription, N per user |

### Cross-skill integration

| Need | Delegate to | Reason |
|---|---|---|
| Richer analytics, > 2M rows, predictive, blended | [sf-tableau](../sf-tableau/SKILL.md) | Tableau / CRMA / Tableau Next |
| Data Cloud segment counts / calculated insights | [sf-datacloud-segment](../sf-datacloud-segment/SKILL.md) | DC segment metrics |
| Data Cloud SQL / async query / vector | [sf-datacloud-retrieve](../sf-datacloud-retrieve/SKILL.md) | DC query plane |
| Raw SOQL without viz | [sf-soql](../sf-soql/SKILL.md) | Query only |
| Embedded dataviz in LWC | [sf-lwc](../sf-lwc/SKILL.md) | Component code |
| Report surfaced on a Lightning record page via FlexiPage | [sf-lightning-app-builder](../sf-lightning-app-builder/SKILL.md) | Page composition |
| Report-triggered automation | [sf-flow](../sf-flow/SKILL.md) | Report subscription doesn't fire automation; Flow does |
| Deployment / packaging | [sf-deploy](../sf-deploy/SKILL.md) | DevOps |

---

## 9. Output Format

When finishing, report in this order:

1. **Task classification** — design / build / troubleshoot / migrate
2. **Industry pre-check result** — not-applicable / deferred-to-{industry-skill}
3. **Subject and Report Type** — object(s) + standard or custom
4. **Format** — Tabular / Summary / Matrix / Joined
5. **Filters summary** — standard + field + cross-filter + bucket + row-level + summary formula
6. **Chart / dashboard plan** — chart type(s), dashboard components, running user mode
7. **Folder and sharing** — folder name + share target
8. **Subscription plan** — scope, schedule, recipients
9. **Scoring total** — N / 120, with any sub-threshold category flagged
10. **Next recommended step** — next phase or cross-skill handoff
