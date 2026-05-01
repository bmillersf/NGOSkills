---
name: sf-tableau
description: >
  Tableau + Tableau Next + CRM Analytics architecture with 140-point scoring
  and industry-first routing precedence.
  TRIGGER when: user builds Tableau workbooks (Desktop/Server/Cloud), Tableau
  Next semantic models or Pulse metrics (Tableau Next is GA as of 2026),
  CRM Analytics dashboards, dataflows, recipes, lenses, SAQL queries,
  Einstein Discovery stories, or Tableau Semantic Layer views; or says
  "build a Tableau dashboard", "connect Tableau to Data Cloud", "CRM
  Analytics recipe", "publish to Tableau Cloud", "Einstein Discovery
  prediction", "Tableau Pulse digest", "Tableau Next semantic model",
  "migrate CRM Analytics to Tableau Next", "embed analytics in Lightning".
  DO NOT TRIGGER when: user wants native Salesforce reports + dashboards
  (use sf-reports-dashboards when GA'd — native report builder is Phase 2);
  raw Data Cloud SQL or vector search (use sf-datacloud-retrieve); Data
  Cloud insights / segments / calculated insights (use sf-datacloud-segment);
  Agentforce observability parquet analysis (use sf-ai-agentforce-observability);
  generic Apex or LWC work with no analytics surface (use sf-apex / sf-lwc);
  industry-specific dashboards where the data model is industry-owned
  (see Phase 0: route to sf-industry-fsc for FSC Financial Account
  dashboards, sf-industry-health for clinical dashboards, etc.).
license: MIT
compatibility: "Requires Tableau Cloud / Tableau Server / CRM Analytics license; Tableau Next license for Tableau Next Semantic Layer + Pulse"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "140 points across 7 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.tableau.com
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.bi.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.analytics_tableau_next.htm
    anchor: ""
    sha256: ""
    importance: authoritative
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_analytics.htm
---

# sf-tableau: Tableau + Tableau Next + CRM Analytics

Owns the Salesforce analytics stack outside of native Reports & Dashboards: **Tableau** (Desktop / Server / Cloud / Public), **Tableau Next** (GA 2026 — the Data Cloud-native successor to CRM Analytics), and **CRM Analytics** (formerly Einstein Analytics / Wave). Includes Tableau Pulse (AI-surfaced insights), Tableau Semantic Layer, Einstein Discovery, and the Tableau ↔ Data Cloud connector.

---

## When This Skill Owns the Task

Use `sf-tableau` when the work involves:

- **Tableau**: Desktop authoring, Server/Cloud publishing, data source design, calculated fields, LOD expressions, actions, parameters, extensions, embedded analytics in Lightning
- **Tableau Next** (2026 GA): Semantic Layer models, metrics, Pulse digests, Tableau Next Data Cloud connector, AI-assisted authoring
- **CRM Analytics** (legacy, still in market): dataflows (`.wdf`), recipes, dataset design, lenses, dashboards (`.wdash`), SAQL/SOQL-to-SAQL, bindings, global filters, embedded dashboards
- **Einstein Discovery**: story creation, predictive model publication, deployment to Lightning / Flow / Apex
- **Tableau Semantic Layer**: published data sources, metrics, certified fields, governed calculations
- **Data Cloud → Analytics pipeline**: Tableau Next native connector, CRM Analytics Data Cloud input connector
- Deciding between **Tableau vs Tableau Next vs CRM Analytics vs native Reports** for a given use case

Delegate outside this skill when:

| Scope | Route to | Reason |
|---|---|---|
| Native Salesforce Reports & Dashboards (`Report.cls`) | `sf-reports-dashboards` (Phase 2) | Native report builder is a separate product surface |
| Data Cloud SQL / async query / vector search | `sf-datacloud-retrieve` | Query plane, not presentation layer |
| Data Cloud segment or calculated insight | `sf-datacloud-segment` | Data Cloud audience engine owns CI |
| Data Cloud DMO / identity resolution | `sf-datacloud-harmonize` | Harmonize phase, not analytics |
| Agentforce session / STDM / parquet analysis | `sf-ai-agentforce-observability` | Different telemetry surface |
| Industry-owned dashboards (FSC AUM, Health census) | `sf-industry-fsc` / `sf-industry-health` / etc. | Industry data model wins |
| Apex or LWC custom code | `sf-apex` / `sf-lwc` | Code-only implementation |
| Named Credential to external BI tool | `sf-integration` | Integration layer |

---

## Phase 0: Industry Pre-Check (MANDATORY)

Before producing any artifact, run the shared industry pre-check at [`references/industry-precheck.md`](../../references/industry-precheck.md).

Analytics workloads sit on top of industry data models constantly — FSC households + financial accounts, Health Cloud clinical encounters, Education Cloud enrolment metrics, Nonprofit gift transactions. The pre-check ensures we don't build a generic Tableau dashboard that misrepresents an industry's governed data model.

1. Detect installed industry clouds via license/feature scan + namespace scan (see pre-check reference).
2. If an industry cloud is installed AND the user's dashboard touches industry-owned objects, **halt and forward**:
   - FSC AUM / Household roll-up / Investor segmentation → `sf-industry-fsc` for data-model guidance, then return here for the Tableau build
   - Health Cloud patient / encounter / care plan analytics → `sf-industry-health` (HIPAA boundary check is load-bearing)
   - Education Cloud enrolment / retention analytics → `sf-industry-education`
   - Nonprofit donor analytics → `sf-nonprofit-fundraising` (for Gift Transaction semantics) or `sf-nonprofit-npsp` (for Opportunity-based donor analytics)
   - Public Sector / Manufacturing / Comms / Media / Energy dashboards → corresponding `sf-industry-*`
3. **Return path**: industry skill confirms semantic model and governed calculations, then this skill assembles the Tableau / Tableau Next / CRM Analytics artifact on top. This two-step handoff is expected and correct.
4. If the user explicitly says "use raw Salesforce data / bypass the industry overlay", document the exception and proceed.

Print handoff on deferral, e.g.:

```
Detected Health Cloud + request mentions patient panel analytics. Routing to
sf-industry-health to confirm HIPAA-governed fields and Protected Health
Information (PHI) masking rules before Tableau workbook build.
```

---

## Tableau vs Tableau Next vs CRM Analytics vs Native Reports

Pick the right surface once. Retrofitting later is expensive.

| Need | Use | Why |
|---|---|---|
| Ad-hoc operational reports on CRM records with row-level security | **Native Reports & Dashboards** | Runs on Salesforce sharing model automatically; lowest latency; no extract |
| Dashboards on Data Cloud with AI insights, governed semantic model, natural-language authoring, Pulse digests | **Tableau Next** | 2026 GA; Data Cloud-native; replaces CRM Analytics for new greenfield |
| Rich visual analytics across Salesforce + non-Salesforce data, deep viz interactions, publishing to large org | **Tableau** (Desktop + Cloud/Server) | Best-in-class viz layer; mature |
| Existing CRM Analytics investment (dataflows, dashboards, Einstein Discovery) | **CRM Analytics** until migration | Still supported; migrate to Tableau Next for new capability |
| Predictive scoring + writeback to Salesforce records | **Einstein Discovery** (inside CRMA or Tableau) | Model deployment to Flow/Apex |

**Rule of thumb (2026):**

- **Greenfield analytics on Data Cloud** → Tableau Next.
- **Greenfield analytics on non-Data-Cloud sources or complex viz** → Tableau.
- **Maintain, don't grow** CRM Analytics until migration is scheduled.
- **Never** build a Tableau workbook to replace a Report that is naturally covered by the native report builder — you'll fight sharing and re-invent filters.

---

## Required Context to Gather First

Ask for or infer:

- Target org alias + edition
- License flags: `CRMAnalyticsUser`, `Wave`, `Tableau`, `TableauNext`, `EinsteinDiscoveryUser`
- Which surface: Tableau, Tableau Next, CRM Analytics, or Einstein Discovery
- Data source: Salesforce CRM, Data Cloud, external DB, file upload
- Consumption model: live connection, extract, Data Cloud zero-copy, CRM Analytics dataset
- Deployment target: Tableau Cloud, Tableau Server, embedded in Lightning, embedded in Experience Cloud, Slack via Tableau Pulse
- Users: internal only, external (community/partner), row-level security required?
- Industry cloud installed? (see Phase 0)
- Refresh cadence: live, hourly, daily, on-demand
- Governance: certified data source required? semantic layer in use?

---

## Workflow Phases

### Phase 1: Source Selection + Governance

1. Confirm source system (CRM / Data Cloud / external).
2. For Data Cloud: prefer **zero-copy** (Tableau Next connector or CRM Analytics Direct Data via Data Cloud) — no duplicate storage.
3. For CRM: prefer live connection unless performance requires extract.
4. Register certified / governed data source (Tableau Published Data Source, CRMA dataset with Security Predicate, or Tableau Next Semantic Layer metric).
5. Apply row-level security early (Security Predicate on CRMA; Row-Level Security on Tableau; sharing inheritance on Data Cloud zero-copy).

### Phase 2: Semantic + Data Modeling

1. **Tableau**: published data source with folders, hierarchies, calculated fields, LODs, and measure formatting.
2. **Tableau Next**: build Semantic Layer model — facts, dimensions, metrics, certified calculations. Metrics become reusable across Pulse, Lightning embeds, and Slack.
3. **CRM Analytics**: dataflow or recipe producing a dataset. Recipes preferred for new work (GUI, lineage, profiling); dataflows retained for complex `sfdcDigest` patterns on legacy orgs.
4. **Einstein Discovery**: story on a dataset with labeled outcome variable, feature engineering, model registration.

### Phase 3: Visualization + Dashboard

1. **Tableau**: author in Desktop, publish to Cloud/Server. Use container layouts + dashboard actions + set actions. Ensure mobile-responsive layout for Tableau Mobile.
2. **Tableau Next**: author in browser with AI assist (Einstein). Metrics drive Pulse + dashboards simultaneously.
3. **CRM Analytics**: dashboard JSON (`.wdash`) with widgets bound via SAQL or SOQL-to-SAQL. Use bindings for cross-widget interactivity; prefer Compact Form where possible.
4. Always: keep widget count < 15 per dashboard view, avoid unnecessary interactivity, respect colour-blind palettes.

### Phase 4: AI + Insights Layer

1. **Tableau Pulse** (Tableau Next): subscribe users to metric digests. Configure anomaly detection, outliers, breakdowns.
2. **Einstein Discovery**: publish prediction → surface via CRMA dashboard, Lightning card, Flow element, or Apex `ConnectApi.SmartDataDiscovery`.
3. **Tableau Ask Data / Explain Data / Einstein Copilot for Tableau**: enable for natural-language querying of certified sources.
4. Never enable AI on uncertified / unmasked datasets containing PII/PHI.

### Phase 5: Embed + Distribute

1. **Lightning embed**: `lightning-tableau-viz` component (Tableau) or Analytics dashboard component (CRMA) or Tableau Next component (2026).
2. **Experience Cloud embed**: ensure guest-user permissions + row-level security hold for unauthenticated traffic.
3. **Slack**: Tableau Pulse → Slack Connect for scheduled metric digests.
4. **Email subscriptions / alerts**: Tableau subscriptions, CRMA notification on threshold.
5. **Agentforce**: Tableau Next metrics can be exposed as agent tools (2026). Confirm per license.

### Phase 6: Governance, Refresh, Monitoring

1. Schedule refresh (CRMA dataflow/recipe, Tableau extract, Data Cloud zero-copy auto-refresh).
2. Monitor run times, failed refreshes, and adoption (Tableau Cloud Admin Insights, CRMA Usage App).
3. Audit certified sources and metric definitions quarterly.
4. Archive unused workbooks/dashboards — analytics clutter kills adoption.

### Phase 7: Migration (if CRM Analytics → Tableau Next)

1. Inventory: list CRMA datasets, dashboards, Einstein Discovery stories.
2. Score each asset: actively used? governed? easy to rebuild in Tableau Next?
3. Migrate datasets → Data Cloud DMOs (use `sf-datacloud-harmonize`).
4. Rebuild dashboards as Tableau Next metrics + dashboards.
5. Reconnect Einstein Discovery stories to Data Cloud-based features.
6. Run parallel period (both surfaces live), then deprecate CRMA assets.

---

## Scoring Rubric

Total: **140 points across 7 categories.** Any category below its pass threshold fails the whole review.

```
Score: XX/140
├─ Surface Selection: XX/15           (pass >= 10) Right product (Tableau / Next / CRMA / Native) with documented justification
├─ Data Source + Governance: XX/25    (pass >= 18) Certified/published source, zero-copy where possible, RLS applied, refresh cadence correct
├─ Semantic Modeling: XX/20           (pass >= 14) Metrics/calculations reusable, LODs correct, hierarchies + formatting set, no duplicated math
├─ Visualization Quality: XX/25       (pass >= 18) Viz type matches intent, no chart-junk, colour-blind palette, mobile-responsive, < 15 widgets/view
├─ AI + Insights Layer: XX/20         (pass >= 14) Pulse / Einstein Discovery / Ask Data applied where useful; never on unmasked PII/PHI
├─ Embed + Distribution: XX/20        (pass >= 14) Lightning / Experience Cloud / Slack / email embed chosen correctly; guest + RLS validated
└─ Migration + Lifecycle: XX/15       (pass >= 10) CRMA→Tableau Next plan (if applicable); decommission plan; adoption tracked
```

Passing score: **100/140 with every category at pass threshold.** Data Source + Governance and Visualization Quality are the two most-failed categories in analytics reviews — do not let them slip.

---

## Anti-Patterns

- **Building a Tableau workbook to replace a native Salesforce Report.** You will re-invent sharing, re-invent filters, and lose Lightning record context. If native Reports covers it, use native.
- **Greenfielding CRM Analytics in 2026.** Tableau Next is the successor. New investment in CRMA just creates migration debt.
- **Dual-stacking CRMA and Tableau Next on the same metric.** Two sources of truth, two refresh schedules, two sets of permissions. Pick one authoritative metric per KPI.
- **Extracting Data Cloud to a CRMA dataset when zero-copy is available.** Duplicates storage, adds refresh latency, breaks governance lineage. Use the Data Cloud zero-copy connector.
- **Embedding Tableau in Experience Cloud without validating guest-user permissions + RLS.** The #1 way PII leaks from an analytics embed. Always test as the guest user.
- **Enabling Einstein Discovery / Ask Data / Einstein Copilot on an unmasked PHI/PII dataset.** AI surfaces will quote sensitive values verbatim. Certify + mask first.
- **Dashboards with 30+ widgets.** Cognitive overload, slow render, and unused. Cap at ~15 widgets per view; if you need more, make it a second dashboard.
- **Letting CRMA dataflows replace what a recipe can do.** Recipes have lineage, profiling, and GUI; dataflows are harder to maintain. New work → recipes unless there's a `sfdcDigest` pattern that recipes can't express.
- **Letting a generic Tableau designer build an FSC / Health / Education dashboard without the industry skill confirming the governed model.** Phase 0 exists for this reason.
- **Publishing uncertified "everyone's playground" Tableau data sources as the default.** Governance decays within a quarter. Certify the authoritative source, lock schema, and document ownership.
- **No row-level security on a Tableau Cloud site with external users.** A single weekend mistake and internal revenue numbers become public. Security Predicate / RLS is non-negotiable.

---

## Common Failure Modes + Remediation

| Symptom | Root Cause | Fix |
|---|---|---|
| Tableau dashboard fast in Desktop, slow in Cloud | Live connection to a high-latency source; extract never published | Publish an extract; schedule refresh; or switch to Data Cloud zero-copy |
| CRMA dashboard shows wrong totals | Security Predicate not applied, or applied after aggregation | Apply predicate at dataset load time; re-run dataflow/recipe |
| Tableau Next metric differs from Tableau Desktop number | Semantic Layer calculation differs from workbook calc | Consolidate to semantic metric; deprecate workbook-local calc |
| Einstein Discovery prediction drift | Model not retrained since source schema changed | Retrain on refreshed dataset; version story; redeploy |
| Pulse digest empty | Metric has no new data, or subscription anchored to wrong timezone | Verify source refresh; confirm metric grain; reset subscription window |
| Embedded dashboard shows "No data" to guest user | RLS / Security Predicate excludes guest context | Add guest user to predicate exception; test as guest before publishing |

---

## Cheat Sheet — Surface Comparison

| Concern | Tableau | Tableau Next | CRM Analytics | Native Reports |
|---|---|---|---|---|
| Authoring | Desktop / Web | Browser (AI-assisted) | Web (dashboard JSON) | Lightning Report Builder |
| Data source | Live / extract / Data Cloud | Data Cloud native (zero-copy) | Dataset (dataflow/recipe) | Salesforce records (SOQL) |
| Semantic layer | Published data source | Metrics + Semantic Model | Dataset + Security Predicate | Report Type + folders |
| AI insights | Ask Data / Explain / Copilot | Pulse + Einstein | Einstein Discovery + Explainer | Einstein for Reports (limited) |
| Mobile | Tableau Mobile | Tableau Mobile | CRMA Mobile | Salesforce Mobile |
| Embed | `lightning-tableau-viz` | Tableau Next component | CRMA dashboard component | Dashboard component |
| Row-level security | RLS via entitlement table | Inherits Data Cloud sharing | Security Predicate | Native sharing model |
| Best for | Rich viz + non-SF data | Data Cloud-first, AI-native | Legacy investments | Operational CRM reporting |

---

## Cross-Skill Integration

| To Skill | When to Use |
|---|---|
| `sf-datacloud-harmonize` | Build DMO + identity resolution before Tableau Next semantic model |
| `sf-datacloud-retrieve` | Data Cloud SQL for ad-hoc exploration before dashboard build |
| `sf-datacloud-segment` | Segment-driven audience metrics (different from analytics metrics) |
| `sf-ai-agentforce-observability` | Agent telemetry analysis — not a Tableau use case |
| `sf-integration` | Named Credential for external DB source |
| `sf-lwc` | Custom Lightning component wrapping embedded viz |
| `sf-nonprofit-*` / `sf-industry-*` | Governed industry data model before dashboard |
| `sf-deploy` | Promote Tableau/CRMA assets via metadata API (CRMA dashboards are metadata; Tableau is managed via Tableau APIs) |

---

## Additional Resources

- [Tableau Help](https://help.tableau.com)
- [CRM Analytics overview](https://help.salesforce.com/s/articleView?id=sf.bi.htm)
- [Tableau Next overview](https://help.salesforce.com/s/articleView?id=sf.analytics_tableau_next.htm)
- [Industry pre-check reference](../../references/industry-precheck.md)
