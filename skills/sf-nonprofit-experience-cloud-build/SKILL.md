---
name: sf-nonprofit-experience-cloud-build
description: >
  Nonprofit Experience Cloud build methodology: mine a reference organization
  website for design tokens and content architecture, then translate into
  purposeful LWCs with correct routing, guest access, and deployment. TRIGGER
  when: user builds, beautifies, or redesigns a nonprofit Experience Cloud site,
  models a community after an existing organization website, creates donor /
  giving / volunteer / member portals, or wires up public-facing donation,
  signup, or self-service flows inside a community. DO NOT TRIGGER when: portal
  strategy and sharing architecture (use sf-nonprofit-experience-cloud), portal
  UX/UI design principles and journeys (use sf-nonprofit-experience-cloud-ux),
  or generic LWC component authoring (use sf-lwc).
license: MIT
metadata:
  version: "1.0.0"
  companion_skills:
    - sf-nonprofit-experience-cloud
    - sf-nonprofit-experience-cloud-ux
    - sf-lwc
    - sf-subagent-orchestration
---

# sf-nonprofit-experience-cloud-build: Nonprofit Portal Build Methodology

Build Experience Cloud sites that feel like the organization's real marketing website, not a generic Salesforce template. This skill codifies a methodology that has produced Experience Cloud sites with measurably better UI/UX than default builds.

The core insight: **the reference website already solved the IA and brand problems — mine it, don't reinvent it.**

## When to apply

Apply this skill whenever the user asks to:
- Build or "beautify" a Salesforce Experience Cloud / Community site
- Model a community after an existing organization website
- Create a donor portal, giving site, member portal, or customer community
- Add a public-facing donation / signup / self-service flow inside a community

## Component selection policy: standard-first

**Default to standard Experience Cloud / Lightning components. Write a custom LWC only when standard components cannot meet the requirement.** Brand is delivered at the theme layer (Phase 2) and applies to both standard and custom components, so "it should look branded" is never a reason to go custom.

**Decision rule — use a standard component when any of these is true:**

- A standard component already renders the required data or behavior (restyling via `customCSS` or SLDS utilities is not a reason to replace it).
- The requirement is CRUD on a Salesforce record → Record Detail, Create Record Form, Edit Record Form, Related List — Single.
- The requirement is navigation, search, profile, topics, recommendations, headlines, or tiles → all have first-party equivalents.
- The requirement is a static content block → Rich Content Editor or HTML Editor.
- The requirement is a guided multi-step form → **Screen Flow embedded via the standard Flow component** is the default. Fall back to a custom LWC only when Flow provably cannot express the logic (e.g. payment-gateway integration, multi-object atomic commit beyond Flow's capability, or UI patterns Flow cannot render).

**A custom LWC is justified only when at least one is true — document which in the plan:**

- The UI composes data from multiple objects or external systems in a layout no standard component supports.
- The interaction requires conditional branching / client-side state that Flow cannot express.
- Deep-linking, query-param parsing, or analytics events are required and the standard component does not emit them.
- Guest-aware conditional rendering is required that standard components do not gate.

**Standard → custom mapping (use this as the audit checklist):**

| Need | Prefer (standard) | Go custom only if |
|------|-------------------|-------------------|
| Global nav / menu | Navigation Menu, Profile Header | Mega-menu driven by Apex or non-NavigationMenu data |
| Hero / banner | HTML Editor or Rich Content Editor (themed) | Hero parameterizes over a Custom Metadata / Apex-backed model |
| Tile grid / cards | Tile Menu, Card, Related List — Single | Tiles must deep-link with query params the standard does not emit |
| Pull quote / testimonial | Rich Content Editor + themed `.quote-block` | Rotating from an object with complex sort / personalization |
| Event / list surfaces | List View, Calendar, Related List — Single | Design requires merged badges, filters, or cross-object joins |
| Record view | Record Detail, Record Banner, Related List — Single | Cross-object composed dashboard no standard layout represents |
| Form / submit | Create Record Form; or Screen Flow via the Flow component | Multi-step wizard with payment gateway or multi-object atomicity |
| FAQ / content blocks | Accordion, Tabs, Headline, Rich Content Editor | — |
| Search | Search Bar, Search Results | Faceted search across custom indexes |

**Enforcement in every phase:**

- **Phase 1 brand-mining** — when listing homepage sections, tag each section with the standard component that will render it. Only sections with no standard match advance to the custom-LWC list.
- **Phase 3 decomposition** — must begin with a written standard-component audit (see below). No custom-LWC subagents are spawned until the audit is captured.
- **Phase 5 verification** — the review summary must list the standard:custom ratio and the one-line justification for each custom component.

## The five-phase workflow

Copy this checklist at the start of the engagement:

```
Phase Progress:
- [ ] Phase 1: Brand-mine the reference website
- [ ] Phase 2: Translate brand into a design system
- [ ] Phase 3: Compose standard-first, custom LWCs only where standard falls short
- [ ] Phase 4: Wire routing, guest access, and deployment
- [ ] Phase 5: Publish and verify end-to-end
```

### Phase 1 — Brand-mine the reference website

**Delegation**: spawn an `explore` subagent per `sf-subagent-orchestration` with mission *"Visit <reference-url>, return color palette (hex), font pairing (display + body), homepage IA section list in order, voice/tone samples, and complete asset URL inventory as a structured summary."* The parent never sees raw HTML — only the digested summary.

Before writing any code, extract from the reference site:

1. **Assets** — fetch the homepage and key sub-pages with `WebFetch` or `curl`. Download and save:
   - Logo (prefer SVG or high-res PNG)
   - Hero / above-the-fold photography
   - Section imagery (ministry tiles, feature photos, etc.)
   - Any icon sets already in use

2. **Typography** — identify the display font and body font pairing. Most modern org sites use one serif/display + one humanist sans. Capture the exact Google Fonts URL.

3. **Color palette** — pull the primary brand color, one accent (often gold, blue, or green), neutrals, and a single "action" color for CTAs. Four to six tokens is plenty.

4. **Information architecture** — list the homepage sections *in order*: hero, featured programs, testimonial/quote, events, donate. **This ordering becomes your `home.json` layout.** Don't invent sections; translate theirs.

5. **Voice and content** — grab 2-3 sentences of real copy from the site for the hero, pull quotes, and section intros. Never ship lorem ipsum.

Save assets into `force-app/main/default/staticresources/<orgName>Assets/` and declare the resource in `<orgName>Assets.resource-meta.xml` with `contentType: application/zip` and `cacheControl: Public`.

### Phase 2 — Translate brand into a design system

**Delegation**: keep in **parent**. Design tokens are foundational decisions that every later phase depends on.

Wire the brand into the site in two places so every LWC inherits it:

1. **BrandingSet** (`experiences/<Site>/brandingSets/*.json`):
   - `HeaderFonts` = the display font (e.g. `"Playfair Display"`)
   - `PrimaryFont` = the body font (e.g. `"Open Sans"`)
   - Primary / accent color fields match the palette

2. **Theme customCSS** (`experiences/<Site>/themes/*.json`) — inline one CSS string containing:
   - Google Fonts `@import url(...)` for both fonts
   - `body,html` font-family override to the body font
   - `h1-h4` override to the display font
   - Branded utility classes with a short project prefix (e.g. `.adp-card`, `.adp-cta-donate`, `.adp-quote-block`). LWCs reuse these so brand is defined once.

See [reference.md](reference.md#design-system-wiring) for a complete customCSS template.

### Phase 3 — Compose the page standard-first; build custom LWCs only where needed

**Delegation**:
- The standard-component audit is done in the **parent** (it scopes the whole phase).
- After the audit, fire one `generalPurpose` subagent *per surviving custom LWC* in a single tool-call message (parallel pattern from `sf-subagent-orchestration`). Each subagent receives: the design tokens from Phase 2, the LWC's spec (purpose, props, behavior), the static resource name, and an acceptance criteria checklist. Each returns a summary + file paths. The parent integrates the composed view in Phase 5.

**Phase 3 opens with a mandatory standard-component audit.** Walk the Phase 1 IA section by section. For each section, name the standard component that will render it. Only sections that fail the "Component selection policy" decision rule advance to the custom-LWC list. Record the audit as a short table in the plan so it is reviewable *before* any custom code is written.

**Rule: never build mega-LWCs.** When custom is justified, each story = one LWC. Compose the view in the ExperienceBundle's `views/home.json` by mixing standard and custom components. Do **not** rewrap standard components inside a custom shell just to unify styling — theme them instead.

**Standard-first composition for a marketing-style community homepage** (flip this to custom only with an explicit justification):

| Section | Default choice | Custom only if |
|---------|---------------|----------------|
| Global header | **Standard** Navigation Menu + Profile Header (themed) | Header composes Apex-driven widgets or cross-site auth state |
| Hero | **Standard** HTML Editor (themed) or Rich Content Editor | Hero is parameterized from Custom Metadata / Apex |
| Programs / ministry grid | **Standard** Tile Menu or Card | Tiles must deep-link with query params the standard does not emit → custom `<org>OpportunitiesGrid` |
| Pull quote | **Standard** Rich Content Editor + themed `.quote-block` | Rotating quotes from an object with complex selection rules |
| Upcoming events | **Standard** List View or Related List — Single | Design requires merged date badges / filters not in OOTB list |
| Donate / signup flow | **Standard** Screen Flow via the Flow component | Payment gateway or multi-object atomicity Flow cannot express → custom multi-step form LWC |
| Authenticated dashboard | **Standard** Record Detail + Related Lists | Cross-object composed view no standard layout represents → custom `<org>Dashboard` |
| FAQ / content | **Standard** Accordion, Tabs, Headline | — |

**Dual-audience pattern** (applies to any custom LWC you do ship): public marketing components render for everyone; authenticated dashboards must use `@salesforce/user/isGuest` to gate rendering *and* to short-circuit any `@wire` Apex calls so guest sessions don't throw errors. Standard components already gate themselves — another reason to prefer them.

**If a custom multi-step form survives the Flow-first audit**, use a separate route with a dedicated multi-step form LWC:

- Stepper with visible progress (e.g. `Amount → Info → Payment → Review`)
- Parse URL params on `connectedCallback` so tiles can deep-link with pre-selected values (`?fund=General%20Fund&amount=50`)
- Confirm to a dedicated thank-you route (`/donate-thank-you`), **not** a modal — supports bookmarking, refresh, and analytics

See [examples.md](examples.md) for concrete component shells you can adapt.

### Phase 4 — Wire routing, guest access, and deployment

**Delegation split**:
- Routing/profile/network metadata authoring → **parent** (small, interdependent, decision-laden)
- The actual deploy + publish + verify loop → **`shell` subagent** per `sf-subagent-orchestration`. Verbose `sf project deploy` output and curl verification stay out of the parent's context; the subagent returns a status summary only.

This phase has the most Salesforce-specific gotchas. Get these wrong and nothing renders.

**Routing — custom public pages require all four pieces:**

1. `routes/<page>.json` → `devName: "<Page>__c"` (must end in `__c`), `routeType: "custom-<page>"`, `pageAccess: "Public"`
2. `views/<page>.json` → `componentName: "siteforce:dynamicLayout"`, wrap your LWC in a `forceCommunity:section`
3. LWC's `js-meta.xml` → include `lightning__CommunityPage` in `targets`
4. **Critical URL rule**: `@salesforce/community/basePath` **already includes `/s`**. Build URLs as `` `${basePath}/donate` ``, never `` `${basePath}/s/donate` ``

**Guest access:**

- `experiences/<Site>/config/<site>.json` → `"isAvailableToGuests": true`
- `profiles/<Guest Profile>.profile-meta.xml` → add `<classAccesses>` for **every Apex class** any public LWC imports, even if the LWC hides content from guests — `@wire` still fires before render
- `networks/<Site>.network-meta.xml` → `<status>Live</status>`. Network status **cannot** be changed via Apex DML; it must be set in metadata.

**Deployment order matters:**

```
1. Deploy LWCs + static resources + Apex + profiles
2. Deploy the ExperienceBundle (references from step 1 must already exist)
3. sf community publish --name "<Site Name>"
4. Wait for the publish email / re-verify with curl
```

A single `sf project deploy start` of everything at once often fails because the ExperienceBundle validates component references before LWCs are created. Split into two deploys.

See [reference.md](reference.md) for complete metadata templates and the full gotcha catalog.

### Phase 5 — Publish and verify end-to-end

**Delegation**: `shell` subagent per `sf-subagent-orchestration` runs the full verification checklist below as a single mission and returns pass/fail per item. Parent reviews the summary and reports to the user.

Before calling the site done, verify:

- [ ] `curl https://<domain>/<site>/s/` returns 200 and the expected LWCs appear in the bootstrap payload
- [ ] `curl https://<domain>/<site>/s/<public-route>` returns 200 for every public route (not the "Page not available" screen)
- [ ] Guest navigation from home → tile → form → thank-you works without login
- [ ] Deep links with query params (`?fund=X&amount=Y`) pre-fill the form correctly
- [ ] Authenticated user sees dashboard LWCs that guests don't
- [ ] Every custom route is listed in NavigationMenu if user-discoverable
- [ ] Community status in `sf data query "SELECT Name, Status FROM Network"` is `Live`
- [ ] **Standard-first audit**: list the final standard:custom component ratio and the one-line justification for each custom component. If any custom component's justification reduces to "for branding" or "to look nicer," revert to the standard equivalent and re-theme.

If a route returns "Page not available," 95% of the time it is one of:
- `/s/s/` double-prefix in a navigation URL (see basePath rule above)
- `devName` missing `__c` suffix
- View using `siteforce:sldsOneColLayout` instead of `siteforce:dynamicLayout`
- Community not re-published after ExperienceBundle change

## Reference implementation

This skill was distilled from building the **Arlington Donor Portal** — an Experience Cloud donor site modeled after `arlingtondiocese.org`. That repository is the canonical worked example for every pattern in this skill:

- Brand-mined static resource: `staticresources/arlingtonDioceseAssets/`
- Design system tokens: `experiences/Arlington_Donor_Portal1/themes/customerAccountPortal.json` `customCSS`
- Homepage LWC decomposition: `lwc/donorPortalHeader`, `donorHeroBanner`, `givingOpportunitiesGrid`, `bishopQuoteBanner`, `upcomingEvents`, `donorDashboard`
- Multi-step form: `lwc/donationForm` + `lwc/donationThankYou`
- Custom route metadata: `experiences/Arlington_Donor_Portal1/routes/donate.json` + `views/donate.json`
- Guest access profile: `profiles/Arlington Donor Portal Profile.profile-meta.xml`

When adapting the patterns, treat the Arlington repo files as templates to copy-modify, not as files to reference at runtime.

## Additional resources

- Detailed metadata templates and the full gotcha catalog: [reference.md](reference.md)
- Concrete LWC code patterns (header, hero, grid, form): [examples.md](examples.md)
