---
name: sf-service-knowledge
description: >
  Lightning Knowledge architecture — Article Types (record types), Data Categories
  + Category Groups, Article Publication Workflow, Article Versions, Multi-Language
  Articles, Einstein Search Answers, Article Recommendations, Article Feedback,
  Knowledge in Experience Cloud communities, and Article-to-Case linking.
  TRIGGER when: user says "set up Knowledge", "migrate from Classic Knowledge",
  "design article types", "design data categories", "build a category group",
  "configure the article publication workflow", "version an article", "translate
  an article", "enable multi-language knowledge", "surface articles on Case",
  "publish articles to the community", "configure Einstein Search Answers",
  "tune article recommendations", "audit stale articles", "deflect cases with
  knowledge", "link articles to cases"; or works on KnowledgeArticleVersion,
  Knowledge__kav / Knowledge__DataCategorySelection, DataCategory /
  DataCategoryGroup, Knowledge Settings, Article Translation, KnowledgeCaseLink,
  KnowledgeBase (sObject) metadata.
  DO NOT TRIGGER when: Case data model / SLA / Entitlements (use sf-service-case);
  Omni-Channel routing / Presence / Queues (use sf-service-omnichannel); Work
  Order mobile knowledge surfacing for technicians (use sf-field-service — Field
  Service has its own knowledge-in-mobile pattern); multi-phase Service Cloud
  orchestration (use sf-service-cloud); an industry cloud is installed and the
  knowledge scope is industry-owned (e.g., FSC Disclosures, Health Cloud Clinical
  Content, PSS Statutory Knowledge) — defer via Phase 0 to sf-industry-fsc,
  sf-industry-health, sf-industry-education, sf-industry-public-sector,
  sf-field-service, sf-nonprofit-program-case, sf-nonprofit-cloud,
  sf-industry-manufacturing, sf-industry-consumer-goods, sf-industry-communications,
  sf-industry-media, sf-industry-energy; generic Sales / marketing content
  authoring (use sf-sales-cloud, sf-marketing-cloud-growth); Apex that queries
  articles (use sf-apex); LWC that renders articles (use sf-lwc); Flow XML
  triggered by article state change (use sf-flow); Data Cloud ingestion of
  article text (use sf-datacloud); Agentforce topic grounded on Knowledge (use
  sf-ai-agentforce — return here only for the knowledge-base modeling question).
license: MIT
compatibility: "Requires Lightning Knowledge (Classic Knowledge is end-of-life); multi-language requires Knowledge One license + Translation Workbench; Einstein Search Answers is an Einstein for Service add-on"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.knowledge_about.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.knowledge_setup.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.category_manage.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.knowledge_translate_articles.htm
    anchor: ""
    sha256: ""
    importance: authoritative
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_service_knowledge.htm
---

# sf-service-knowledge: Lightning Knowledge

Owns the knowledge base: article types, category hierarchy, publication workflow, versions, languages, search surfaces, feedback, and article-to-case linking. Classic Knowledge is end-of-life; this skill is Lightning Knowledge only.

Comes after [sf-service-cloud](../sf-service-cloud/SKILL.md) has decided that Knowledge is in scope, or engages directly when the scope is solely knowledge base work.

---

## When This Skill Owns the Task

Use `sf-service-knowledge` when the work involves:

- Enabling Lightning Knowledge in an org (one-way door; cannot be disabled once enabled)
- Designing Article Types via Case record types on `Knowledge__kav` (FAQ, Procedure, Release Note, Troubleshooting, Policy, etc.)
- Data Categories + Category Groups — the hierarchical taxonomy that gates article visibility per profile, role, and community
- Article fields + Rich Text vs File fields; attachments vs embedded images; version-safe field design
- Article Publication Workflow — Draft → In Review → Approved → Published → Archived, with approvers + assignment
- Article Versions — creating a new version without breaking existing URLs; version comparison
- Multi-Language Articles — Translation Workbench, master language, translated versions, sync strategy
- Einstein Search Answers — indexing, retrieval, the "answer" vs "article link" trade-off
- Article Recommendations on Case — Einstein-trained vs keyword-matching, model health
- Article Feedback — thumbs-up/down, comments, feedback-driven retirement
- Knowledge in Experience Cloud — public-article visibility, guest access, surfaced fields, Topics
- Article-to-Case linking (KnowledgeCaseLink) — suggested articles, linked articles, attached-as-PDF
- Knowledge SEO (URL slugs, meta fields, indexability for public sites)
- Article lifecycle metrics — view count, attach-on-case count, deflection rate, stale-article audit

### Delegate outside this skill when

| Need | Route to | Boundary |
|---|---|---|
| Case data model / SLA / Entitlements | [sf-service-case](../sf-service-case/SKILL.md) | Data model only |
| Omni-Channel routing of Case with KB context | [sf-service-omnichannel](../sf-service-omnichannel/SKILL.md) | Routing only |
| Multi-phase Service Cloud design | [sf-service-cloud](../sf-service-cloud/SKILL.md) | Orchestrator |
| Work Order mobile knowledge | [sf-field-service](../sf-field-service/SKILL.md) | Field Service has its own pattern |
| Apex querying Knowledge | [sf-apex](../sf-apex/SKILL.md) | Code authoring |
| Flow triggered by article state | [sf-flow](../sf-flow/SKILL.md) | Flow mechanics |
| LWC rendering articles | [sf-lwc](../sf-lwc/SKILL.md) | Component authoring |
| Experience Cloud site design consuming Knowledge | [sf-nonprofit-experience-cloud](../sf-nonprofit-experience-cloud/SKILL.md) | Community design (nonprofit); generic Experience Cloud skills if present |
| Data Cloud ingestion of article text | [sf-datacloud](../sf-datacloud/SKILL.md) | DMO mapping |
| Agentforce topic grounded on Knowledge | [sf-ai-agentforce](../sf-ai-agentforce/SKILL.md) | Agent grounding |
| Permission set audit on Knowledge | [sf-permissions](../sf-permissions/SKILL.md) | Access audit |
| Metadata XML for Knowledge record types + fields | [sf-metadata](../sf-metadata/SKILL.md) | After article-type design is locked |

---

## Phase 0: Industry Pre-Check (MANDATORY)

Before any knowledge-base work, run the shared [industry pre-check](../../references/industry-precheck.md). Industry clouds often ship their own knowledge models (FSC Disclosures, Health Cloud Clinical Content, PSS Statutory Knowledge, Comms regulatory docs, Education syllabi) — do not redesign those from scratch.

**NEVER silently override an industry data model.** If an industry cloud is installed AND the request touches industry-owned knowledge content or objects, halt and forward.

### Deferral map for knowledge-adjacent industry ownership

| Detected industry | Knowledge-adjacent scope owned by the industry | Route to |
|---|---|---|
| Financial Services Cloud (`FinServ__`) | Required-disclosure articles, KYC/AML guidance, advisor compliance content | [sf-industry-fsc](../sf-industry-fsc/SKILL.md) |
| Health Cloud (`HealthCloudGA__`) | Clinical knowledge / care-plan guidance / patient-education content, HIPAA-tagged articles | [sf-industry-health](../sf-industry-health/SKILL.md) |
| Education Cloud / EDA (`hed__`) | Syllabi, course catalogs, advising guidance tied to Program Enrollment | [sf-industry-education](../sf-industry-education/SKILL.md) |
| Public Sector Solutions (`OutfundsPS__`) | Statutory knowledge, regulatory citations, eligibility guidance linked to Benefit / BusinessLicense | [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) |
| Field Service (`FieldServiceStandard`) | Mobile knowledge on WorkOrder for technicians (Field Service uses its own pattern) | [sf-field-service](../sf-field-service/SKILL.md) |
| Nonprofit Cloud program/case (`NonprofitCloudCaseManagement`) | Benefit-eligibility and program-policy knowledge linked to ProgramEnrollment | [sf-nonprofit-program-case](../sf-nonprofit-program-case/SKILL.md) |
| Nonprofit Cloud generic | Donor / grantee / constituent knowledge tied to nonprofit objects | [sf-nonprofit-cloud](../sf-nonprofit-cloud/SKILL.md) |
| Manufacturing Cloud (`Mfg`) | Product specification docs, warranty terms, dealer-policy articles | [sf-industry-manufacturing](../sf-industry-manufacturing/SKILL.md) |
| Consumer Goods Cloud (`CG`) | Retail Execution playbooks, Visit checklists, merchandising guidance | [sf-industry-consumer-goods](../sf-industry-consumer-goods/SKILL.md) |
| Communications Cloud (`vlocity_cmt__`) | Product-catalog and offer-policy articles, ESM runbooks | [sf-industry-communications](../sf-industry-communications/SKILL.md) |
| Media Cloud (`vlocity_media__`) | Subscription-policy articles, entitlement rules, billing-policy articles | [sf-industry-media](../sf-industry-media/SKILL.md) |
| Energy & Utilities (`vlocity_ins__` + `EnergyAndUtilities`) | Meter-policy, tariff, outage-comms articles | [sf-industry-energy](../sf-industry-energy/SKILL.md) |

### Deferral procedure

1. Run detection per `references/industry-precheck.md`.
2. If positive AND the knowledge scope overlaps any row above, print: `Detected {industry} is installed. Routing to sf-{industry-skill} because this request touches {matched object/process}.`
3. Halt and return control.
4. Only proceed if detection is negative, OR the user explicitly requests "generic Knowledge, ignore the industry overlay" (document the exception).

---

## Required Context to Gather First

1. **Knowledge state** — Lightning Knowledge already enabled (irreversible) or greenfield. If already on, capture existing article-type count, category-group count, language count.
2. **Audience segmentation** — internal agents, partners, external customers (community), public (SEO). Each surface has distinct visibility and field-exposure rules.
3. **Article-type inventory** — FAQ, Procedure, Troubleshooting, Release Note, Policy, Known Issue, Product Guide, How-To, Announcement. Target 3–7 article types — more fragments authoring.
4. **Category hierarchy** — how deep (max 5 levels supported), how wide, which dimensions are used for filtering (product, region, audience, language, severity).
5. **Publication workflow** — single approver vs stage-gated; approver group; expected time-to-publish; SLA for updates.
6. **Languages in scope** — master language, translated languages, translation source (in-house team, LSP, machine translation).
7. **Einstein feature availability** — Search Answers licensed, Article Recommendations licensed, training data volume (number of published articles; minimum 50 per article type for recommendations to train usefully).
8. **Community / public** — is Knowledge surfaced in an Experience Cloud site? Guest user access rules? SEO requirements?
9. **Article-to-Case linking model** — suggested (Einstein), manual search, attach-as-PDF for email reply.
10. **Lifecycle governance** — stale-article threshold (days since last updated), retirement workflow, archival vs delete, feedback-to-retirement loop.
11. **Metrics surface** — view count, attach count, thumbs-up/down, deflection dashboard, feedback-to-retirement loop.
12. **Compliance constraints** — HIPAA (PHI in articles), regulated-content retention, legal-hold behavior, export controls (ITAR, EAR).

---

## Workflow Phases

### Phase 1 — Pre-Check & Scope Lock

1. Run **Phase 0 industry pre-check**. Halt and forward if positive.
2. Confirm Lightning Knowledge state and audience segmentation.
3. If Classic Knowledge is still on, plan migration before greenfield work — Classic → Lightning is a data-migration project (Migration Tool + manual re-tagging).

### Phase 2 — Article Type Design

1. Define 3–7 article types aligned to *content patterns*, not subject domains. Common set: FAQ, Procedure, Troubleshooting, Policy, Release Note.
2. For each article type: required fields, rich-text regions, attachment fields (File fields), validation rules, layout per publication stage.
3. Keep fields *aligned* across article types where possible — consistent core fields (Summary, Audience, Product, Last Reviewed Date) ease cross-type search and reporting.

### Phase 3 — Data Categories + Category Groups

1. Enumerate Category Groups — at most 5 active per org. Typical set: Product, Region, Audience, Content Type, Regulatory.
2. Design the hierarchy within each Category Group — max 5 levels; aim for 3.
3. Assign default categories + category visibility per profile / permission set.
4. Plan translation of category labels if multi-language.

### Phase 4 — Publication Workflow

1. Design Draft → Review → Approved → Published states. Prefer Approval Process over Flow for audit trail, but Flow if routing by category / author.
2. Configure Approval Process approvers (queue-based for load-balancing, role-hierarchy for default).
3. Define "Publish As" action: Publish New, Publish As New Version, Publish Translation.
4. Archive policy: articles archived after N months with no views or with a thumbs-down ratio > X%.

### Phase 5 — Versioning

1. Train authors on `Publish as New Version` — preserves article URL + ID across versions.
2. Decide version retention: keep all versions (audit) vs prune archived versions after N.
3. For major content rewrites, consider a new article with cross-link rather than a new version (keeps search clean).

### Phase 6 — Multi-Language

1. Enable Translation Workbench; add supported languages to Knowledge Settings.
2. Set a master language (typically en_US); all translations derive from it.
3. Define translation workflow: source publish → queue translation → translator completes → publish translation.
4. Decide sync strategy: auto-expire translated articles when source changes, or leave translated as-is with a "master updated" flag.
5. For machine-translation integration, wire via Named Credential (delegate wiring to [sf-integration](../sf-integration/SKILL.md)).

### Phase 7 — Search & Einstein

1. Configure Search Layouts per article type — which fields are searchable + returned in results.
2. Enable Einstein Search Answers if licensed — confirm article text length + structure (H2/H3 anchoring) meets the requirement.
3. Enable Article Recommendations on Case if licensed; train on last 6–12 months of Case + attached articles; monitor model health monthly.
4. Decide whether to enable Knowledge search in global search and in the Service Console sidebar.

### Phase 8 — Article-to-Case Linking

1. Add the Knowledge component to the Case Lightning page (record page or utility).
2. Configure "Insert Article" email composer action for email replies.
3. Enable "Attach as PDF" if customers need the article in an email.
4. Wire Article Feedback — capture thumbs-up/down per article-case link for downstream retirement loop.

### Phase 9 — Experience Cloud / Public Surface (if in scope)

1. Expose selected article types + categories to the community via Topics mapping.
2. Configure guest-user profile access (read-only on Knowledge__kav + data-category visibility).
3. If SEO-public, configure URL slug fields, meta description, schema.org `Article` markup via LWC (delegate LWC work to [sf-lwc](../sf-lwc/SKILL.md)).
4. Decide whether to expose the article author, last-updated date, and feedback widget to public viewers.

### Phase 10 — Lifecycle Governance

1. Build a stale-article report: last-updated > N days, view count = 0 in last 90 days, thumbs-down ratio > X%.
2. Configure a monthly author-review cadence.
3. Define retirement workflow: archive → review → delete or restore.
4. Set up a feedback-driven workflow: 5+ thumbs-down in 30 days → owner review.

### Phase 11 — Verify & Hand Off

1. Smoke-test: publish one article per article type, verify visibility on intended surfaces (console, community, public).
2. Smoke-test translation workflow end-to-end.
3. Verify Einstein recommendations (if licensed) surface relevant articles on sample cases.
4. Emit structured summary.

---

## Scoring Rubric (120 points total — 95 is passing)

| Category | Max | Pass threshold | What earns points |
|---|---|---|---|
| Industry pre-check executed and documented | 15 | 12 | Detection ran; deferral decision explicit |
| Audience + article-type design | 15 | 11 | 3–7 types, content-pattern aligned, consistent core fields |
| Category hierarchy design | 15 | 11 | ≤ 5 groups, depth ≤ 3 in most, visibility gated per profile |
| Publication workflow | 15 | 11 | Approval vs Flow decision justified; approvers + archive policy defined |
| Multi-language (if in scope) | 10 | 7 | Master language + supported languages + sync strategy defined |
| Einstein Search Answers + Recommendations | 10 | 7 | Feature fit justified; article-volume threshold met or flagged |
| Article-to-Case linking | 10 | 7 | Knowledge component on Case layout; email insert / PDF attach enabled |
| Experience Cloud / public surface (if in scope) | 10 | 7 | Topics mapping + guest access + SEO fields configured |
| Lifecycle governance | 10 | 7 | Stale-article report + retirement workflow + feedback loop |
| Delegation + output | 10 | 7 | Correct hand-offs (community, LWC, flow, agentforce) + structured summary |

Fail gates: Phase 0 skipped = automatic fail. Silent override of an industry knowledge model = automatic fail.

---

## Anti-Patterns

1. **Skipping Phase 0.** Designing a knowledge base on an FSC / Health / PSS / Nonprofit / Education / Mfg / CG / Comms / Media / Energy org without verifying the industry's own knowledge model isn't already in play.
2. **Too many article types.** More than 7 fragments authoring, search, and analytics. Consolidate along content pattern, not subject area.
3. **Deep category hierarchies.** Depth > 3 in most branches slows authoring and breaks guest-user access audits; rely on Topics + tags for fine-grained slicing.
4. **Enabling Lightning Knowledge "just to see what it does".** Enablement is a one-way door; do it only when the article-type and category design is locked.
5. **Version-as-rewrite.** Publishing a new version when the content is a near-complete rewrite confuses search and destroys the feedback history. Prefer a new article + redirect.
6. **Translated articles with no sync strategy.** When the master changes, translated versions become silently wrong. Either auto-expire or flag the translation as "master updated — review required".
7. **Einstein Search Answers with thin article volume.** Under ~200 published articles per locale, the model under-fits and returns wrong answers with high confidence. Pilot with top-50 articles and measure hit rate before scaling.
8. **No stale-article audit.** KBs rot. Without a monthly stale report, thumbs-down ratio, and owner-review cadence, the KB becomes untrusted within two release cycles.
9. **Exposing Knowledge to guest users without category-visibility hardening.** Public articles inherit any category the guest profile can see; a single over-broad grant exposes internal-only content.
10. **Building a custom LWC for article rendering when the stock component will do.** Stock gets accessibility + SEO updates for free; custom rebuilds fall behind.

---

## Common Failure Modes + Remediation

### Symptom: "Articles published but don't appear in the Case sidebar"

- **Root cause:** Knowledge component missing from the Case Lightning page; data-category visibility not granted to the agent's profile; article is Draft, not Published.
- **Fix:** Add Knowledge component to Case FlexiPage; grant category visibility on profile / permission set; confirm article state via `SELECT PublishStatus FROM KnowledgeArticleVersion WHERE Id = :id`.

### Symptom: "Translation published but search returns only master language"

- **Root cause:** User's locale not set, or the translated version is in Draft, or the search layout doesn't include the locale field.
- **Fix:** Confirm user Locale and Language; verify translated version is Published (`KnowledgeArticleVersion.Language = 'fr'` + `PublishStatus = 'Online'`); ensure the search layout supports the locale.

### Symptom: "Einstein Article Recommendations suggest irrelevant articles"

- **Root cause:** Model trained on too little labeled data, or training data is skewed (one article attached to many cases), or the training window is too old.
- **Fix:** Increase labeled training data; re-balance (cap per-article attachment count in training); re-train; monitor relevance metric monthly.

### Symptom: "Community guest user sees articles they shouldn't"

- **Root cause:** Guest user profile has broad data-category visibility, or a "Default Parent" category is granted implicitly.
- **Fix:** Audit guest profile data-category visibility; remove parent categories that leak descendants; verify with the View as Guest preview.

### Symptom: "Article URL changed after publish, breaking external links"

- **Root cause:** Article was re-created instead of published as new version; URL slug field changed between versions.
- **Fix:** Train authors on Publish as New Version (preserves URL); lock slug field to read-only after first publish; configure redirect for previously-changed URLs.

---

## CLI / Metadata Cheat Sheet

```bash
# Article inventory
sf data query -q "SELECT Id, Title, ArticleType, Language, PublishStatus, IsLatestVersion, LastPublishedDate FROM KnowledgeArticleVersion WHERE PublishStatus='Online' LIMIT 50" -o <alias>

# Article types (record types on Knowledge__kav)
sf data query -q "SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType='Knowledge__kav'" -o <alias>

# Data categories
sf data query -q "SELECT DeveloperName, MasterLabel FROM DataCategoryGroup" -o <alias>

# Article-to-case link
sf data query -q "SELECT Id, CaseId, KnowledgeArticleId, IsPrimary FROM CaseArticle LIMIT 50" -o <alias>

# Article feedback
sf data query -q "SELECT Id, KnowledgeArticleVersionId, Rating, Comment FROM KnowledgeArticleVoteStat ORDER BY LastReferencedDate DESC LIMIT 50" -o <alias>

# Stale article report (pseudocode — adapt to your LastReviewedDate field)
sf data query -q "SELECT Id, Title, LastPublishedDate FROM KnowledgeArticleVersion WHERE PublishStatus='Online' AND LastPublishedDate < LAST_N_DAYS:180" -o <alias>

# Metadata retrieval for review
sf project retrieve start -m "KnowledgeSettings,CustomObject:Knowledge__kav,RecordType:Knowledge__kav.*,DataCategoryGroup:*,ApprovalProcess:Knowledge__kav.*" -o <alias>
```

Key metadata file families:

- `settings/Knowledge.settings-meta.xml`
- `objects/Knowledge__kav/recordTypes/*.recordType-meta.xml`
- `objects/Knowledge__kav/fields/*.field-meta.xml`
- `dataCategoryGroups/*.dataCategoryGroup-meta.xml`
- `approvalProcesses/Knowledge__kav.*.approvalProcess-meta.xml`
- `flexipages/KnowledgeRecordPage.flexipage-meta.xml`
- `searchLayouts/Knowledge__kav.searchLayouts-meta.xml`
- `translations/*.translation-meta.xml` (for picklist + label translation)

---

## Output Format

```text
Knowledge task: <enable / article-types / categories / workflow / multi-language / einstein / community / governance>
Industry pre-check: <negative / positive → deferred to sf-{industry-skill}>
Lightning Knowledge state: <enabled / greenfield>
Article types: <count + list>
Category groups: <count + list>
Languages: <master + translations>
Publication workflow: <approval-process / flow / hybrid>
Einstein features: <search-answers / recommendations / none>
Article-to-Case linking: <configured / deferred>
Experience Cloud surface: <none / internal-community / public-SEO>
Lifecycle governance: <stale-report + retirement + feedback-loop>
Open risks / assumptions: <list>
Next step: <hand-off to sf-service-case / sf-service-omnichannel / sf-lwc / sf-integration / sf-ai-agentforce>
```
