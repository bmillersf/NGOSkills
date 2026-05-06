---
name: sf-experience-cloud
description: >
  General (non-nonprofit) Experience Cloud: LWR/Aura sites, Experience Builder,
  Audiences, Branding, Navigation, CMS, external user licenses, Sharing Sets,
  Share Groups, Account Relationships, guest access. Industry-first.
  TRIGGER when: user builds / brands / troubleshoots a customer community,
  partner community, self-service portal, help center, or public microsite on
  LWR or Aura; touches `.site-meta.xml`, `.experienceBundle`, or
  `.networks-meta.xml`; configures Audiences, Branding, Navigation, CMS,
  Topics, Guest user profile, Customer/Partner Community licenses, Sharing
  Sets, Share Groups, or Account Relationships.
  DO NOT TRIGGER when: nonprofit donors/volunteers/grantees/clients
  (sf-nonprofit-experience-cloud, -ux, -build); industry-pack-owned site
  (matching sf-industry-* skill); component authoring on the site — LWC
  (sf-lwc), Apex (sf-apex), Flow (sf-flow), metadata (sf-metadata), permissions
  (sf-permissions); Slack Connect (sf-slack); Marketing landing pages
  (sf-marketing-cloud-growth).
license: MIT
compatibility: "Experience Cloud licenses required for external users (Customer Community, Customer Community Plus, Partner Community, External Apps). Available in Lightning Experience with Experience Cloud enabled."
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.networks_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.exp_cloud_lwr_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/decision-guides/experience-cloud
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_experience_cloud.htm
---

# sf-experience-cloud: General (Non-Nonprofit) Experience Cloud

Use this skill when the user is building, branding, or troubleshooting a **general-purpose Experience Cloud site** — a customer community, partner community, self-service portal, help center, or public-facing microsite — for a **non-nonprofit** org. Nonprofit Experience Cloud has its own dedicated trio of skills (architecture, UX, build methodology) that handle donor / volunteer / client / grantee / program-participant portals; industry clouds (FSC / Health / EDU / PSS / Field Service / Manufacturing / CG / Comms / Media / Energy) own their industry-specific portal patterns.

This skill owns: LWR site architecture, Aura site legacy patterns, Experience Builder, Audiences (rule-based targeting), Branding Sets, Theme editor, Site Navigation, CMS channels and content, Topics / Navigational Topics, Guest user access patterns, External user licenses (Customer Community / Customer Community Plus / Partner Community / External Apps), Sharing Sets, Share Groups, Account Relationships, external account hierarchies, external user permission sets, and deployment of Experience Bundles.

---

## 1. When This Skill Owns the Task

This skill owns the task when the user is building a general (non-nonprofit, non-industry-packaged) Experience Cloud site for a typical customer / partner / help-center use case and the work is at the **site architecture / branding / external-sharing / template-composition** layer.

Delegate when the ask is nonprofit-specific, industry-specific, or is a different layer (component code, Apex, Flow, metadata, etc.):

| User need | Route to | Why |
|---|---|---|
| Nonprofit site — donors, volunteers, clients, grantees, program participants on NPC / NPSP | [sf-nonprofit-experience-cloud](../sf-nonprofit-experience-cloud/SKILL.md) (architecture), [sf-nonprofit-experience-cloud-ux](../sf-nonprofit-experience-cloud-ux/SKILL.md) (UX), [sf-nonprofit-experience-cloud-build](../sf-nonprofit-experience-cloud-build/SKILL.md) (brand-mining + build) | Nonprofit domain trio owns the semantics |
| FSC advisor portal, client portal on Households / Financial Accounts | [sf-industry-fsc](../sf-industry-fsc/SKILL.md) | FSC-specific data model and sharing |
| Health Cloud patient portal, provider portal on Care Plan / Care Request | [sf-industry-health](../sf-industry-health/SKILL.md) | HC owns the patient sharing model |
| Education student portal on Program Enrollment / Course Connection | [sf-industry-education](../sf-industry-education/SKILL.md) | EDU model and term-based access |
| Public Sector constituent portal on Benefit / License / Permit / Application | [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) | PSS intake and eligibility patterns |
| Field Service customer scheduling portal on ServiceAppointment / WorkOrder | [sf-field-service](../sf-field-service/SKILL.md) | FS appointment booking patterns |
| Manufacturing partner portal on Sales Agreement / Account Forecast | [sf-industry-manufacturing](../sf-industry-manufacturing/SKILL.md) | Manufacturing-specific partner model |
| Consumer Goods distributor portal on Retail Store / Visit / Trade Promotion | [sf-industry-consumer-goods](../sf-industry-consumer-goods/SKILL.md) | CG-specific portal patterns |
| Communications self-service / partner portal on Offer / Cart / Order | [sf-industry-communications](../sf-industry-communications/SKILL.md) | Comms-specific |
| Media subscriber portal on Subscriber / Billing Account | [sf-industry-media](../sf-industry-media/SKILL.md) | Media-subscriber model |
| Energy & Utilities customer portal on Premise / Service Point | [sf-industry-energy](../sf-industry-energy/SKILL.md) | E&U-specific |
| LWC components placed on the site | [sf-lwc](../sf-lwc/SKILL.md) | Component authoring |
| Apex called by the site | [sf-apex](../sf-apex/SKILL.md) | Code |
| Flows on the site | [sf-flow](../sf-flow/SKILL.md) | Flow authoring |
| Custom object / field / validation for underlying data | [sf-metadata](../sf-metadata/SKILL.md) | Metadata XML |
| Deep permission set / sharing analysis | [sf-permissions](../sf-permissions/SKILL.md) | Access audit |
| Mobile Publisher app shell | out of scope | Different product |
| Slack Connect for external collaboration | [sf-slack](../sf-slack/SKILL.md) | Slack surface |
| Marketing Cloud Growth landing pages | [sf-marketing-cloud-growth](../sf-marketing-cloud-growth/SKILL.md) | MC surface, not ExpC |

---

## 2. Phase 0: Industry Pre-Check (MANDATORY)

**Before producing any Experience Cloud artifact, run the shared industry pre-check:** [`references/industry-precheck.md`](../../references/industry-precheck.md).

Experience Cloud is a **generic cloud skill**. Industry clouds and Nonprofit Cloud / NPSP ship opinionated portal patterns, pre-sharing models, packaged site templates, and external-user license mappings for their domains. A generic "build a portal" request in an org running FSC / Health / EDU / PSS / Field Service / Manufacturing / CG / Comms / Media / Energy / NPC / NPSP almost always means the user wants the industry / nonprofit patterns, not a ground-up generic build. **NEVER silently override an industry or nonprofit data model with a generic site config.**

Run the pre-check's detection steps (license / feature flag, namespace scan, object existence). Deferral table specific to Experience Cloud:

| Detected | User request touches | Route to |
|---|---|---|
| Nonprofit Cloud (NPC) | Donor portal, volunteer portal, program participant portal, grantee portal, any external user with Gift Transaction / Program Enrollment / Funding Award context | [sf-nonprofit-experience-cloud](../sf-nonprofit-experience-cloud/SKILL.md) first, then [sf-nonprofit-experience-cloud-ux](../sf-nonprofit-experience-cloud-ux/SKILL.md) and [sf-nonprofit-experience-cloud-build](../sf-nonprofit-experience-cloud-build/SKILL.md) |
| NPSP | Donor portal on Opportunity-as-donation / Recurring Donation / Household Account | [sf-nonprofit-experience-cloud](../sf-nonprofit-experience-cloud/SKILL.md) + nonprofit trio |
| FSC | Client portal, advisor self-service on Households / Financial Accounts / Life Events | [sf-industry-fsc](../sf-industry-fsc/SKILL.md) |
| Health Cloud | Patient portal, provider portal, member engagement | [sf-industry-health](../sf-industry-health/SKILL.md) |
| Education Cloud / EDA | Student portal, faculty portal, alumni portal | [sf-industry-education](../sf-industry-education/SKILL.md) |
| Public Sector Solutions | Constituent portal, applicant portal, licensee portal, inspector portal | [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) |
| Field Service | Customer scheduling / self-service appointment portal | [sf-field-service](../sf-field-service/SKILL.md) |
| Manufacturing Cloud | Partner / distributor portal on Sales Agreement | [sf-industry-manufacturing](../sf-industry-manufacturing/SKILL.md) |
| Consumer Goods | Distributor portal on Retail / Trade Promotion | [sf-industry-consumer-goods](../sf-industry-consumer-goods/SKILL.md) |
| Communications | Self-service or partner portal on Offer / Cart | [sf-industry-communications](../sf-industry-communications/SKILL.md) |
| Media | Subscriber / advertiser portal | [sf-industry-media](../sf-industry-media/SKILL.md) |
| Energy & Utilities | Customer portal on Premise / Service Point | [sf-industry-energy](../sf-industry-energy/SKILL.md) |

**Deferral behaviour.** If industry / nonprofit detection is positive and the user's request overlaps with the owner, print:

```
Detected {industry-or-nonprofit} is installed. Routing to sf-{owner-skill}
because this request touches {matched object/process/persona}.
The Experience Cloud mechanics will be invoked from that skill.
```

Then STOP generic Experience Cloud workflow and return control. The industry or nonprofit skill will run domain logic and call back for any generic mechanics (audiences, branding mechanics, CMS plumbing) still owned here.

**Exception.** This skill still owns the task when the user explicitly says "ignore the industry / nonprofit overlay", OR the site has no industry / nonprofit-object binding (pure marketing microsite, public help center with no case-linked articles, etc.), OR the industry / nonprofit skill has explicitly delegated back. Document the exception.

---

## 3. Required Context to Gather First

Before producing any site design, establish:

- **Site runtime.** Aura with **Build Your Own (Aura)** is the default scaffold for new builds — composed with custom LWCs dropped into Aura regions, this combination has consistently produced more visually appealing sites than LWR Build Your Own in practice. LWR is permitted only with a named, irreplaceable blocker (e.g., a customer specifically requires an LWR-only feature). Packaged Aura templates (Customer Service, Partner Central, Customer Account Portal) are never used as scaffolding — their baked-in layouts and forced regions can't be themed away.
- **Audience personas.** Who are the external users? Customers (B2C self-service), customers with account hierarchy (B2B self-service), partners (resellers, brokers, dealers), public / unauthenticated visitors, or a mix.
- **External user license types.** Customer Community (simple read-mostly), Customer Community Plus (delegated admin, Roles, full sharing rules), Partner Community (full partner enablement, opportunity sharing, multi-role), External Apps Starter / Plus (flexible, consumption-based). License choice drives cost and capabilities.
- **Data scope per persona.** Which objects does each persona need to see / edit? Which fields? What level of account hierarchy is relevant (parent / child accounts, account relationships)?
- **Sharing model.** External users have narrower default access than internal. Expect to configure: Sharing Sets (owner-less sharing based on account), Share Groups (pool access with internal users), Account Relationships (external account hierarchies), manual sharing as fallback. Public groups for external users differ from internal.
- **Guest user scope.** Does the site have unauthenticated pages? If yes, Guest User profile permissions, guest CRUD restrictions (very limited since Winter '21), Sharing for Guest User, and careful field-level security are critical — guest access misconfiguration is the #1 source of data leaks in Experience Cloud.
- **Branding requirements.** Brand colors, logo, typography, custom CSS, per-Audience branding variants (Branding Sets), light / dark mode, WCAG compliance target (AA typically).
- **Content strategy.** Help articles (Knowledge), discussion (Chatter), custom objects, CMS channels, Topics for navigation, file library strategy, localization.
- **Domain and SEO.** Custom domain (my.example.com vs default `*.force.com` subdomain), SSL certificate management, SEO meta tags, sitemap, indexing policy, redirects from legacy site.
- **Authentication model.** Self-registration enabled? Single Sign-On (SAML, OIDC, social sign-on)? MFA requirement? Passwordless? Login branding?
- **Integration surface.** What does the site call into — Salesforce internal records (via Apex / LWC wire), external APIs (via Named Credentials), Data Cloud (for personalization)? Delegate code layers to the right skills.
- **Compliance posture.** GDPR / CCPA / CASL / accessibility (WCAG 2.1 AA minimum typically), cookie consent, data residency.
- **Performance target.** Time-to-Interactive < 3s on public pages. Aura is heavier than LWR on raw runtime metrics, so lazy-load images, defer non-critical LWCs, audit unused packaged Aura components, and keep the home page composition lean.

Missing the runtime, license type, or audience persona is a design-blocking gap. Do not guess.

---

## 4. Workflow Phases

Run in order. Phase 0 (industry pre-check) has already executed.

### Phase 1 — Runtime Choice

**Build Your Own (Aura) is the default for new builds**, composed entirely from custom LWCs. Packaged templates are never the starting point. LWR is permitted only with a named, irreplaceable blocker.

1. **Aura — Build Your Own (default).** Create with `sf community create --template-name "Build Your Own"` (the Aura BYO template). All new customer / partner / help-center / self-service sites start here. The page surface is Aura; every meaningful UI element is a custom LWC dropped into Aura regions. This combination has produced visually stronger sites than LWR BYO in practice — Aura's region model gives more layout control while LWCs deliver the modern component layer.
2. **Never clone a packaged Aura template** — "Customer Service", "Partner Central", "Customer Account Portal", or any other pre-built template. Their baked-in layouts, forced sidebar/featured/hidden regions, `siteforce:serviceBody` wrappers, and opinionated CSS fight the theme layer at every level and cannot be themed away. Build Your Own (Aura) is the only Aura starting point.
3. **Never clone another org's ExperienceBundle as scaffolding.** Copied `routes/`, `views/`, and `brandingSets/` files carry stale IDs and layout choices that belong elsewhere. Author fresh from the metadata schema.
4. **LWR is permitted only when a named blocker exists** — and the blocker must be written into the plan:
   - The customer specifically requires an LWR-only feature with no Aura+LWC equivalent.
   - The engagement is extending (not rebuilding) an existing LWR site.
   - A regulatory or contractual constraint mandates LWR.
5. If LWR is forced by a named blocker, halt and confirm with the user: *"LWR is required because <blocker>. Default methodology is Aura BYO + custom LWCs. Proceed with LWR?"* Wait for explicit confirmation before authoring LWR metadata.

### Phase 2 — Network Creation and License Strategy

1. In Setup → Digital Experiences → Create a Site. Pick the template. Provide site name and URL suffix.
2. Define **external user licenses** in scope:
   - **Customer Community** — cheapest; read-heavy; no Roles for externals; limited object access
   - **Customer Community Plus** — adds Roles, delegated admin, full sharing rules; priced higher
   - **Partner Community** — for partners / resellers; Opportunity sharing, multi-role account teams
   - **External Apps Starter / Plus** — flexible, consumption-priced; covers custom B2B scenarios
3. For each license: define **profile** and **permission sets** to assign. Never clone an internal profile for external users — external profiles should start from the External Identity / Customer Community / etc. base and add only what is needed.
4. Decide **self-registration**: if enabled, choose verification (email, SMS), CAPTCHA provider, and self-registration Apex handler if default flow needs customization.

### Phase 3 — Sharing and Access

1. Configure **Organization-Wide Defaults (OWD)** per external object: Private / Public Read / Public Read-Write, with the External setting explicit.
2. Create **Sharing Sets** for each external license type:
   - Link an external user profile to a field-level criterion (e.g., `ContactId = User.Contact.Id` grants access to their own Contact's related records)
   - Sharing Sets are the primary mechanism for giving a Customer Community user access to "their" data
3. For cross-user sharing, create **Share Groups**:
   - Pool of internal users who share their records with external users per the Sharing Set
4. Configure **Account Relationships** for partner / customer-customer B2B scenarios:
   - An external account has a relationship to another account (e.g., a distributor's end customer)
   - Relationships grant sharing based on role and relationship type
5. For guest pages, configure **Guest User Sharing**:
   - Guest profile has very narrow default access
   - Grant read on specific records via guest-user sharing rule or published-to-guest Knowledge
   - Never use broad "View All" for guest — audit field-level security field by field
6. Audit **field-level security (FLS)** for every external-accessible object. Fields exposed by mistake (compensation, SSN, internal notes) leak to externals.

### Phase 4 — Experience Builder: Pages, Navigation, CMS

1. **Pages** — Home, Login, Error, 404, Search, Topic, Article, Object (record) pages. Compose every page from custom LWCs in Aura regions; do not adopt packaged-template page layouts as scaffolding.
2. **Navigation** — Site Navigation menu: hierarchical items, external URLs, Topics, Data Categories, internal pages. Per-audience navigation variants for members-only vs guest.
3. **CMS Channels** — connect the site to a CMS Workspace (News, Articles, Image Gallery). Channels control which workspaces publish to this site.
4. **Topics** — Chatter Topics promoted as Navigational Topics; surface articles, discussions, and files under a named topic.
5. **Content collections** — CMS content collections for curated feeds (e.g., "Featured Articles", "Latest News").
6. **Search** — configure object scope (which objects appear in search), Knowledge / article boost, and autocomplete.

### Phase 5 — Audiences and Branding Sets

1. **Audiences** — rule-based user segments (profile, permission, record criteria, login status). Example: `Partner users in NA region`. Audiences drive:
   - Per-Audience page visibility (show different Home to customers vs partners)
   - Per-Audience component visibility
   - Per-Audience branding (different colors / logo for partners)
   - Per-Audience navigation
2. **Branding Sets** — full theme definitions (colors, fonts, images, spacing). Link a Branding Set to an Audience for persona-specific branding without a separate site.
3. Test Audiences end-to-end: create a test user in each audience, log in, confirm correct branding / pages / navigation applies.

### Phase 6 — Guest User Hardening

Guest user misconfiguration is the #1 security incident in Experience Cloud. Harden explicitly:

1. Set Guest User OWD to **Private** for every custom object. Grant access only via specific Sharing For Guest User rules or published-to-guest content.
2. Guest profile permissions: deny **View All / Modify All / API Enabled** on every object. Deny any object not strictly needed.
3. **Field-level security** audit: for every field on every object the guest could conceivably see, confirm FLS. Run a pre-deploy audit script.
4. Guest access to Apex: Apex classes called from guest-accessible pages must not leak other users' data. Run pre-deploy analysis — enabled classes that `SELECT` without `WITH SECURITY_ENFORCED` or user-specific filters are dangerous.
5. Guest LWCs: `@AuraEnabled` methods must likewise enforce security. No `WITH SYSTEM_MODE` without a review.
6. Deny guest user creation/update on standard sensitive objects (User, UserLogin, etc.).
7. Monitor: Security Center + Setup Audit Trail for guest-config changes.

### Phase 7 — Performance, SEO, Compliance

1. **Performance** — Aura BYO has heavier baseline runtime than LWR; offset with aggressive optimization. Target < 3s TTI on public pages: lazy-load images, defer non-critical LWCs, audit and remove unused packaged Aura components, optimize CSS, avoid heavy LWCs on first render, prefer @wire over imperative SOQL where caching helps.
2. **SEO** — sitemap.xml auto-generated; robots.txt; meta tags per page; structured data (Schema.org) for Articles; canonical URLs; hreflang for localization.
3. **Analytics** — Google Analytics / Adobe Analytics / first-party analytics LWC; cookie consent banner for jurisdictions requiring it.
4. **Accessibility** — WCAG 2.1 AA: contrast, keyboard navigation, screen reader labels, ARIA landmarks, focus management. Audit with axe / WAVE.
5. **Cookie consent** — CMP integration (OneTrust, Cookiebot, custom LWC).
6. **Localization** — Translation Workbench for custom labels; CMS content per locale; right-to-left support where relevant.

### Phase 8 — Deployment and Activation

1. Experience Bundles (`.experienceBundle`) are the deploy unit. Deploy via `sf project deploy start -x manifest.xml`.
2. Include in deploy: `Network`, `Site`, `ExperienceBundle`, referenced `CustomApplication`, LWCs, Apex, permission sets, profiles, sharing rules, CMS metadata (if packaged).
3. **Activate** the site in the target env — deployment alone does not make the site live.
4. **Custom domain** — deploy the domain config, install the SSL certificate, update DNS, confirm propagation.
5. Run a **staging smoke test**: login as each persona, navigate every primary page, confirm sharing returns expected data, confirm guest pages render correctly, confirm redirects from legacy URLs.

### Phase 9 — Testing and Validation

1. **Persona × page matrix** — every persona navigates every page. Document expected vs actual data.
2. **Sharing test** — each persona sees only "their" data (and nothing more).
3. **Guest audit** — before production, run an automated guest-access scan: every guest-accessible page, every guest Apex method, every publicly-reachable URL. Document findings.
4. **Authentication test** — self-registration, SSO, MFA, password reset, login throttling.
5. **Performance test** — Lighthouse / WebPageTest on home and 2–3 deep pages; TTI, FCP, CLS thresholds met.
6. **Accessibility test** — axe / WAVE; screen reader walk-through of primary flows.
7. **SEO audit** — sitemap present, meta tags populated, canonical URLs correct.
8. **Regression** — if demoable, route to [sf-demo-playwright](../sf-demo-playwright/SKILL.md) for pre-flight script.

---

## 5. Scoring Rubric — 140 Points

Apply to any Experience Cloud site design or build deliverable. Minimum passing: **105 / 140**. Sub-threshold categories must be fixed.

| Category | Max | Passing | What "passing" looks like |
|---|---|---|---|
| **Runtime and license choice** | 15 | 11 | Aura "Build Your Own" for every new build (composed with custom LWCs in Aura regions), or LWR with a named blocker documented in the plan and user-confirmed; no packaged Aura template cloned as scaffolding; no cross-org bundle copying; external license type matches persona (not over-licensed with Partner Community when Customer Community suffices) |
| **Sharing architecture** | 25 | 19 | OWD explicit per object; Sharing Sets map each external profile to its data scope; Share Groups pool internal-external as needed; Account Relationships used for B2B hierarchies; no reliance on manual sharing as primary strategy |
| **Guest user hardening** | 25 | 19 | Guest OWD Private by default; FLS audited per field; guest Apex reviewed for `WITH SECURITY_ENFORCED`; guest LWCs audited; no guest `View All` on any object; pre-deploy guest scan run |
| **Experience Builder composition** | 20 | 15 | Pages, Navigation, CMS Channels, Topics, Search scope all configured; standard templates used; LWC customization where justified, not gratuitous |
| **Audiences and Branding Sets** | 15 | 11 | Audiences defined per persona; Branding Sets per audience if multi-brand; per-audience navigation where appropriate; end-to-end tested |
| **Performance, SEO, accessibility** | 20 | 15 | TTI < 3s on public pages (Aura BYO needs aggressive optimization to hit this — lazy-load, defer non-critical LWCs); sitemap / meta tags / Schema.org present; WCAG 2.1 AA verified; cookie consent where jurisdiction requires |
| **Deployment and activation** | 10 | 7 | Experience Bundle deployed with dependencies; site activated; custom domain live with SSL; staging smoke test passed |
| **Testing and audit** | 10 | 7 | Persona × page matrix executed; guest audit run pre-production; authentication paths tested; accessibility and performance benchmarks logged |

---

## 6. Anti-Patterns

- **Defaulting to LWR for new sites.** Aura "Build Your Own" + custom LWCs in Aura regions is the methodology default — it has consistently produced more visually appealing sites in practice. LWR is permitted only with a named, irreplaceable blocker (a customer-required LWR-only feature, an existing LWR site being extended). Defaulting to LWR without that blocker means shipping a visibly weaker UI baseline.
- **Cloning a packaged Aura template as the starting point** (Customer Service, Partner Central, Customer Account Portal). These templates ship with baked-in layouts (`siteforce:sldsTwoCol84SidebarFeaturedLayout`, `serviceBody`), forced sidebar/featured/hidden regions, and opinionated CSS that fight the theme layer at every level. Theme customCSS cannot override template-enforced structure. Always create with `"Build Your Own"` (Aura) and compose from custom LWCs.
- **Copying another org's ExperienceBundle as scaffolding.** Copied `routes/`, `views/`, and `brandingSets/` files carry stale IDs, dead component references, and layout choices that belong to a different brand. The result looks like the source org no matter how much restyling happens downstream. Author every JSON file fresh from the metadata schema; inspect reference bundles only to confirm file shape.
- **Filling Aura regions with packaged Aura components instead of custom LWCs.** The methodology is *Aura runtime + custom LWC component layer*. Dropping `forceCommunity:` and `siteforce:` packaged components into regions reintroduces the stock-Salesforce look the runtime choice was meant to escape. Use packaged Aura components only when no LWC equivalent is feasible.
- **Over-licensing external users.** Assigning Partner Community to users who only need Customer Community is a recurring cost that adds up fast. License match personas precisely.
- **Cloning an internal profile for external users.** Internal profiles have dozens of permissions irrelevant or dangerous for externals (Setup access, data export, impersonation). Always start from an External base profile and add only what is needed.
- **Relying on manual sharing as the primary access mechanism for external users.** Manual sharing doesn't scale, isn't auditable, and breaks when records are re-owned. Use Sharing Sets + Account Relationships as the architecture; manual sharing is only for rare exceptions.
- **Exposing guest pages without a field-level security audit.** The #1 Experience Cloud incident class. A field exposed by mistake (email, SSN, internal notes) leaks to every anonymous visitor. Run a pre-deploy audit per field.
- **Guest Apex without `WITH SECURITY_ENFORCED`.** Apex called from guest pages runs in guest context but, if it bypasses FLS / sharing, can return data the guest should never see. Treat every guest Apex endpoint as a security surface.
- **Building brand variations as separate sites.** Audiences + Branding Sets give per-persona branding within one site. Spinning up a second site per brand triples deploy and maintenance cost. Only separate when domains genuinely differ (example.com vs partner.example.com with regulatory separation).
- **Navigation menu hard-coded instead of per-Audience.** One giant navigation with everything-visible means partners see customer links, guests see member-only links, etc. Per-Audience nav cleanly separates intent.
- **Skipping the custom domain + SSL setup.** A site hosted at `whatever.force.com` looks unprofessional and is flagged as "not first-party" by browsers. Always provision a custom domain before go-live.
- **Ignoring the industry / nonprofit pre-check.** The #1 routing mistake. Building a generic customer portal in an org running FSC / Health / EDU / PSS / NPC means you are reinventing a data model the industry already ships. Route first.
- **Reaching for packaged Chatter components by default.** Chatter is Aura-native, so the runtime is fine — but packaged Chatter UI fights the brand layer the same way packaged templates do. For new builds, evaluate a custom LWC discussion component first; only drop in packaged Chatter when a custom build isn't budget-feasible.
- **Deploying without activating.** Deploying the Experience Bundle puts the metadata in place; it does not make the site live. Activation is a separate step, and the #1 post-deploy "my site isn't up" cause.

---

## 7. Common Failure Modes and Remediation

### Failure 1 — "External user logs in but sees no records they should see"
- **Symptom:** Customer Community user logs in, navigates to "My Cases" or "My Orders", and the list is empty — even though records exist owned by / related to their Contact.
- **Root cause:** Sharing Set missing or wrong-criteria; OWD too restrictive; the field linking user to data is not populated (e.g., `ContactId` on User doesn't match the Contact that owns the Case).
- **Fix:** Setup → Sharing Settings → find the relevant Sharing Set for the external profile. Confirm the criterion (e.g., `User.Contact.Id = Case.ContactId`). Confirm the test user has their `ContactId` field populated and matches a Contact that has child records. Check OWD for the object — if `Private`, sharing must be granted via Sharing Set or Share Group.

### Failure 2 — "Site loads slowly (> 8s) on a public marketing page"
- **Symptom:** Public LWR page takes 8+ seconds to render for anonymous visitors.
- **Root cause:** Too many heavy LWCs on initial render; large unoptimized images; no CDN on custom static resources; guest user Apex making synchronous callouts.
- **Fix:** Run Lighthouse on the page; identify the bottleneck (JS, network, image). Lazy-load LWCs not above the fold. Move images to CMS (CDN-backed) or compressed static resources. Replace synchronous Apex callouts with async patterns or cached data. If on Aura, consider LWR migration for a 2–3x baseline improvement.

### Failure 3 — "Guest user can somehow see records they shouldn't"
- **Symptom:** Security review discovers that anonymous visitors to the site can view records meant for authenticated users only.
- **Root cause:** Guest profile has unintended object or FLS access; Sharing For Guest User rule grants broader access than intended; guest Apex without `WITH SECURITY_ENFORCED` returns extra data; a `@AuraEnabled(cacheable=true)` method is reachable from a guest context and leaks data.
- **Fix:** Immediate — mark site as restricted, audit logs. Systemic — run comprehensive guest audit: every object's guest FLS, every guest-callable Apex (search for `@AuraEnabled` in classes referenced from guest-accessible LWCs), every guest sharing rule. Remove broad access. Patch Apex. Re-enable. Consider engaging [sf-permissions](../sf-permissions/SKILL.md) for deep analysis.

### Failure 4 — "Custom domain shows SSL certificate warnings"
- **Symptom:** Browsers warn that the custom domain's certificate is invalid / mismatched.
- **Root cause:** Certificate chain is incomplete; certificate's CN / SAN doesn't include the domain; DNS CNAME not propagated; SF-provisioned certificate not activated.
- **Fix:** Setup → Domains → confirm the domain's certificate status. If Salesforce-provisioned, ensure it has been activated. If customer-provided, confirm the full chain (intermediate + root) is present. Verify DNS CNAME or ALIAS record is in place and propagated (`dig`). Reissue if required.

### Failure 5 — "Audience-based branding doesn't apply for some users"
- **Symptom:** Users in a specific Audience see the default branding instead of the audience-targeted Branding Set.
- **Root cause:** Audience criteria don't match the user (profile, permission, criteria evaluates false); Branding Set not linked to the Audience; user's browser cached the prior branding.
- **Fix:** Audit the Audience criteria — load a test user that *should* match and verify each criterion. Confirm the Branding Set is linked correctly in Experience Builder. Clear cache / hard refresh. If using criteria based on custom fields, confirm the user object / related records have values set.

### Failure 6 — "Self-registration creates users but they can't log in"
- **Symptom:** User self-registers, receives welcome email, but login fails.
- **Root cause:** Self-registration Apex handler misconfigured (creates the User but fails to link to Contact / Account); profile / permission set not assigned on registration; user is created inactive; password policy prevents set on first login.
- **Fix:** Debug the self-registration Apex handler with logs. Confirm new user has: `ContactId` populated, `IsActive = true`, correct `ProfileId`, required permission sets assigned, and either a generated password or a valid "set password" flow. Test the email link and reset flow end-to-end.

### Failure 7 — "Deployment succeeded but the site is not accessible"
- **Symptom:** `sf project deploy` completed with success, but the public site URL returns 404 or "site is disabled".
- **Root cause:** Site was deployed but not **activated** in the target environment. Site activation is a separate setting; in sandboxes and production it may need a manual flip.
- **Fix:** Setup → Digital Experiences → All Sites → find the site → click Activate. For automated deploy pipelines, include a post-deploy activation step (Apex callable from CI, or `sf data` update on the Network record).

---

## 8. Experience Cloud Cheat Sheet

### Metadata files

| File suffix | Purpose |
|---|---|
| `.site-meta.xml` | The Site definition |
| `.network-meta.xml` | Network / community configuration (licenses, self-reg, settings) |
| `.experienceBundle` | Experience Builder page composition (LWR + Aura templates) |
| `.customApplication-meta.xml` | Lightning App backing the site |
| `.profile-meta.xml` | External user profile |
| `.permissionset-meta.xml` | External user permission set |
| `.sharingRules-meta.xml` | Sharing rules (internal + external) |

### Runtime chooser

Aura "Build Your Own" + custom LWCs is the default for new builds. LWR is permitted only with a named, irreplaceable blocker (see Phase 1).

| Use case | Scaffold | Notes |
|---|---|---|
| Public marketing / help center | Build Your Own (Aura) + custom LWCs | Default |
| B2C self-service | Build Your Own (Aura) + custom LWCs | Compose with custom LWCs in Aura regions; embed Screen Flow for guided forms |
| Partner portal | Build Your Own (Aura) + custom LWCs | License: Partner Community; do NOT start from "Partner Central" packaged template |
| Help / Knowledge-heavy | Build Your Own (Aura) + custom LWCs + Knowledge components | Custom LWCs handle article surfaces; package only when no LWC alternative |
| Customer-required LWR-only feature | Build Your Own (LWR) | Document the named blocker; user-confirm before scaffolding |
| Extending existing LWR site | Stay on LWR (scope-limited) | Do NOT clone another bundle; inspect and author fresh |
| Extending existing Aura site | Stay on Aura (scope-limited) | Do NOT clone another bundle; inspect and author fresh |

### License chooser

| Use case | License |
|---|---|
| B2C read-mostly self-service | Customer Community |
| B2C with delegated admin + Roles | Customer Community Plus |
| B2B partner / reseller / broker | Partner Community |
| Flexible B2B, consumption-priced | External Apps Starter / Plus |

### Guest user hardening checklist

- [ ] Guest OWD = Private on every custom object
- [ ] Guest profile FLS audited per field
- [ ] Guest Apex methods use `WITH SECURITY_ENFORCED`
- [ ] Guest LWCs use properly-scoped `@AuraEnabled`
- [ ] No `View All` / `Modify All` in guest profile
- [ ] Guest sharing rules reviewed
- [ ] Pre-deploy guest-audit scan run

### Sharing primitives

| Primitive | Use |
|---|---|
| OWD | Baseline access per object (Private / Public Read / Public Read-Write) |
| Sharing Set | External user profile → record access via criterion (primary) |
| Share Group | Pool internal users who share with external users |
| Account Relationship | B2B account hierarchies, partner-to-partner, customer-of-customer |
| Manual Sharing | Rare; exceptions only |
| Sharing Rule | Standard criteria-based sharing (works for internal + some external) |

### Performance targets (LWR)

| Metric | Target |
|---|---|
| Time-to-Interactive (TTI) | < 3s on public pages |
| First Contentful Paint (FCP) | < 1.5s |
| Cumulative Layout Shift (CLS) | < 0.1 |
| Image optimization | > 80 Lighthouse Perf |

### Cross-skill integration

| Need | Delegate to | Reason |
|---|---|---|
| Nonprofit site (donors / volunteers / clients / grantees / program participants) | [sf-nonprofit-experience-cloud](../sf-nonprofit-experience-cloud/SKILL.md) family | Nonprofit domain |
| Industry portal (FSC / Health / EDU / PSS / FS / Manufacturing / CG / Comms / Media / Energy) | corresponding industry skill | Industry data model |
| LWC components on the site | [sf-lwc](../sf-lwc/SKILL.md) | Component authoring |
| Apex (guest + authenticated) | [sf-apex](../sf-apex/SKILL.md) | Code |
| Flow / screen flow on the site | [sf-flow](../sf-flow/SKILL.md) | Flow authoring |
| Metadata XML for custom objects / fields | [sf-metadata](../sf-metadata/SKILL.md) | Object / field definition |
| Deep permission / sharing audit | [sf-permissions](../sf-permissions/SKILL.md) | Access analysis |
| Connected App / OAuth for external integrations | [sf-connected-apps](../sf-connected-apps/SKILL.md) | Auth surface |
| Named Credentials for external API calls from the site | [sf-integration](../sf-integration/SKILL.md) | Callouts |
| Site on a Lightning record page via FlexiPage | [sf-lightning-app-builder](../sf-lightning-app-builder/SKILL.md) | Internal record page composition |
| Reports / dashboards embedded on site pages | [sf-reports-dashboards](../sf-reports-dashboards/SKILL.md) | Report engine |
| Marketing Cloud Growth landing pages | [sf-marketing-cloud-growth](../sf-marketing-cloud-growth/SKILL.md) | Marketing surface |
| Slack for external collaboration | [sf-slack](../sf-slack/SKILL.md) | Slack Connect |
| Deployment + activation | [sf-deploy](../sf-deploy/SKILL.md) | DevOps |
| Pre-flight regression + demo test | [sf-demo-playwright](../sf-demo-playwright/SKILL.md) / [sf-demo-validate](../sf-demo-validate/SKILL.md) | Validation |

---

## 9. Output Format

When finishing, report in this order:

1. **Task classification** — design / build / troubleshoot / migrate
2. **Industry / nonprofit pre-check result** — not-applicable / deferred-to-{skill}
3. **Template** — LWR / Aura + reason
4. **Licenses** — Customer Community / Customer Community Plus / Partner Community / External Apps
5. **Sharing architecture** — OWD + Sharing Sets + Share Groups + Account Relationships summary
6. **Guest scope** — enabled / disabled; if enabled, audit posture
7. **Audiences and branding** — personas and branding sets
8. **Performance / SEO / accessibility targets** — met / pending
9. **Deployment and activation** — packaged / activated / domain live
10. **Scoring total** — N / 140, with any sub-threshold category flagged
11. **Next recommended step** — next phase or cross-skill handoff
