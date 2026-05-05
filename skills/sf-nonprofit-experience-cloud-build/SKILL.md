---
name: sf-nonprofit-experience-cloud-build
description: >
  Nonprofit Experience Cloud build methodology: mine a reference organization
  website for design tokens and content architecture, then translate into
  purposeful LWCs with correct routing, guest access, and deployment. TRIGGER
  when: user builds, beautifies, or redesigns a nonprofit Experience Cloud site,
  models a community after an existing organization website, creates donor /
  giving / volunteer / member portals, or wires up public-facing donation,
  signup, or self-service flows inside a community. Also triggers when user
  asks to "build an LWC for a portal / community site", "create a donor giving
  page", "volunteer signup page", "portal component", "portal form", or "wire
  up a portal page". DO NOT TRIGGER when: portal
  strategy and sharing architecture (use sf-nonprofit-experience-cloud), portal
  UX/UI design principles and journeys (use sf-nonprofit-experience-cloud-ux),
  generic LWC unrelated to a portal (use sf-lwc), or generic LWC component
  authoring (use sf-lwc).
license: MIT
metadata:
  version: "1.0.0"
  companion_skills:
    - sf-nonprofit-experience-cloud
    - sf-nonprofit-experience-cloud-ux
    - sf-lwc
    - sf-subagent-orchestration
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://developer.salesforce.com/docs/atlas.en-us.exp_cloud_lwr.meta/exp_cloud_lwr/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.networks_communitybuilder_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/experience-cloud
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_networks.htm
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

## Everything is Metadata API — do NOT automate Experience Builder

Every page composition, branding change, route, guest access toggle, navigation menu item, and theme decision in an Experience Cloud site is expressible as Metadata API files in the ExperienceBundle, Network, Profile, NavigationMenu, and BrandingSet types. Author those JSON/XML files directly, deploy with `sf project deploy start`, and publish with `sf community publish --name "<Site Name>"`.

**Do not reach for Playwright or Experience Builder drag-drop** to wire up components, pages, or branding. The Builder UI is iframe-wrapped and shadow-DOM heavy; selectors are fragile and shift between releases. The same state is authorable in ~10 minutes of JSON editing and deploys reliably across orgs. If you find yourself generating Playwright selectors to drag a component onto a page, stop and re-read [reference.md](reference.md) — the metadata path exists.

The only legitimate UI-only steps are (a) visually previewing a theme and (b) troubleshooting when a metadata-only deploy isn't reflecting — both rare. Even `sf community publish` usually replaces the Builder's Publish button.

## Phase 0 — Detect the site runtime (Aura vs LWR)

Authoring rules diverge sharply between Aura and LWR sites. Get the flavor right before copying any template, or gotchas compound.

1. **Identify the ExperienceBundle name** — it's often NOT the Network name. Run:

   ```bash
   sf data query --query "SELECT Name, UrlPathPrefix FROM Site WHERE UrlPathPrefix LIKE '<prefix>%'"
   ```

   The `Site.Name` (e.g. `CSEA1`) is the `sf project retrieve --metadata "ExperienceBundle:<Name>"` target — NOT the Network name (`CSEA`). A numeric suffix is common for Aura sites.

2. **First publish materializes the bundle.** Until `sf community publish --name "<Network Name>"` runs once, `ExperienceBundle:<Name>` retrieves as "Entity cannot be found." Publish first, wait 30-60s, then retrieve.

3. **Detect Aura vs LWR** by looking at `experiences/<Bundle>/views/home.json` once retrieved:
   - Aura: `componentName` is `siteforce:sldsTwoCol84SidebarFeaturedLayout` / `sldsOneColLayout` / `serviceBody`. Regions include `header` / `featured` / `content` / `sidebar` / `footer` / `sfdcHiddenRegion`.
   - LWR: `componentName` is `siteforce:dynamicLayout`. Components wrapped in `forceCommunity:section`.

4. **Customer Community Plus orgs almost always use Aura** (Customer Service template). Confirm with the `siteforce:serviceBody` check above.

See [reference.md § Aura vs LWR](reference.md#aura-vs-lwr--two-site-runtimes-with-different-authoring-rules) for the side-by-side table of route/view/viewType/devName rules by runtime.

## The five-phase workflow

Copy this checklist at the start of the engagement:

```
Phase Progress:
- [ ] Phase 0: Detect site runtime (Aura vs LWR) + discover ExperienceBundle name
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

**Routing — custom public pages** (rules split by runtime per Phase 0):

LWR:
1. `routes/<page>.json` → `devName: "<Page>__c"` (must end in `__c`), `routeType: "custom-<page>"`, `pageAccess: "Public"`
2. `views/<page>.json` → `componentName: "siteforce:dynamicLayout"`, wrap LWC in a `forceCommunity:section`
3. LWC's `js-meta.xml` → include `lightning__CommunityPage` in `targets`

Aura:
1. `routes/<page>.json` → `devName: "<Page_Name>"` (NO `__c` suffix), `routeType: "custom-<page>"`, `pageAccess: "Public"`, `pageAuthorization: "Public"`
2. `views/<page>.json` → `componentName: "siteforce:sldsOneColLayout"` (or another Aura layout), `viewType` matches the `routeType` exactly, component dropped directly into `regions[].components` (no `forceCommunity:section` wrapper needed)
3. Aura component's `.cmp-meta.xml` or LWC's `js-meta.xml` → must expose to Experience Cloud (`forceCommunity:availableForAllPageTypes` or `lightning__CommunityPage`)

Both runtimes:
- **Critical URL rule**: `@salesforce/community/basePath` **already includes `/s`**. Build URLs as `` `${basePath}/donate` ``, never `` `${basePath}/s/donate` ``
- View's `viewType` MUST equal route's `routeType` (e.g. both `custom-application`). Deploy rejects mismatches.

**Guest access — three toggles that ALL must be set:**

- `experiences/<Site>/config/<siteName>.json` → `"isAvailableToGuests": true`. **Without this, every guest request redirects to `/login` even if individual routes say `pageAccess: Public`.** This is the single most common "my site keeps redirecting to login" cause.
- `profiles/<Guest Profile>.profile-meta.xml` → add `<classAccesses>` for **every Apex class** any public LWC/Aura component imports, even if the component hides content from guests (Aura controllers and `@wire` fire before render). Grant `objectPermissions` (Create + Read together — Create requires Read) for any object a public form submits to. Remove required fields from `fieldPermissions` — required fields inherit access and Salesforce rejects the deploy otherwise.
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
- [ ] `experiences/<Bundle>/config/<siteName>.json` has `isAvailableToGuests: true` (the single most common cause of "my public site redirects to login")
- [ ] Guest profile `<Site Name> Profile` has `classAccesses` for every Apex class any public LWC/Aura component imports
- [ ] Guest profile has `objectPermissions` Create+Read (paired) for any object public forms submit to
- [ ] **Standard-first audit**: list the final standard:custom component ratio and the one-line justification for each custom component. If any custom component's justification reduces to "for branding" or "to look nicer," revert to the standard equivalent and re-theme.

If a route returns "Page not available," 95% of the time it is one of:
- `/s/s/` double-prefix in a navigation URL (see basePath rule above)
- LWR: `devName` missing `__c` suffix. Aura: `devName` has a `__c` suffix it shouldn't have.
- LWR view using `siteforce:sldsOneColLayout` instead of `siteforce:dynamicLayout`
- Aura view's `viewType` doesn't match the route's `routeType`
- `isAvailableToGuests: false` in the ExperienceBundle config
- Community not re-published after ExperienceBundle change

## Anti-patterns

- **Cloning another org's ExperienceBundle as a starting point.** Copied `routes/`, `views/`, and `brandingSets/` files carry stale IDs, dead component references, and layout choices that belong to a different brand. They produce a site that *looks* like the source org no matter how much you restyle. Author every JSON file fresh from the metadata schema; inspect reference bundles only to confirm file shape.
- **Using `sf community create --template-name "Customer Service"` / "Partner Central" / "Customer Account Portal" for a new build.** These are packaged Aura templates with baked-in `siteforce:sldsTwoCol84SidebarFeaturedLayout` / `serviceBody` wrappers and forced sidebar/featured regions that no amount of theme customCSS can override. Default to `"Build Your Own (LWR)"` (or `"Microsite"` for public-only marketing). Aura templates produce noticeably lower UI/UX quality — avoid them for new builds.
- **Picking Aura because the org uses Customer Community Plus.** The license doesn't dictate the runtime. Build Your Own (LWR) supports Customer Community Plus users. Only a *named, irreplaceable* Aura-only capability justifies Aura.
- **Copying Arlington (or any reference repo) LWCs without re-running Phase 1 brand-mining.** The Arlington component list (`donorHeroBanner`, `givingOpportunitiesGrid`, etc.) reflects Arlington's IA. Another org's IA produces a different list. Re-derive every time; use Arlington only for the *shape* of a standard-first LWC.
- **"Inherit the template and theme over it" as a shortcut.** Brand-mined typography, spacing, and color tokens land cleanly in LWR `themes/*.json` customCSS; they fight Aura packaged templates at every level (component-owned styles, template-enforced regions, locked layout). Build on LWR or document the blocker.

## Reference implementation — read for patterns, do NOT clone

This skill was distilled from building the **Arlington Donor Portal** — an LWR donor site modeled after `arlingtondiocese.org`. Use it as a **pattern reference only**, never as a source to copy files from.

**Read the Arlington repo to see:**

- How a brand-mined static resource is organized: `staticresources/arlingtonDioceseAssets/`
- How design tokens flow into theme customCSS: `experiences/Arlington_Donor_Portal1/themes/customerAccountPortal.json` `customCSS`
- The shape of a standard-first homepage decomposition: `lwc/donorPortalHeader`, `donorHeroBanner`, `givingOpportunitiesGrid`, `bishopQuoteBanner`, `upcomingEvents`, `donorDashboard`
- The multi-step form pattern: `lwc/donationForm` + `lwc/donationThankYou`
- The shape of custom route metadata: `experiences/Arlington_Donor_Portal1/routes/donate.json` + `views/donate.json`
- The shape of a guest access profile: `profiles/Arlington Donor Portal Profile.profile-meta.xml`

**Do NOT:**

- Copy Arlington's `routes/*.json`, `views/*.json`, or `brandingSets/*.json` into a new project. Those files carry Arlington-specific IDs, component references, and layout choices that produce a low-quality result when dropped into a different brand.
- Copy any Aura ExperienceBundle (Customer Service, Customer Account Portal, Partner Central) as a starting point. Packaged Aura layouts (`siteforce:sldsTwoCol84SidebarFeaturedLayout`, `serviceBody`, forced sidebar/featured regions) cannot be themed away and will override your brand work.
- Copy LWCs across organizations without first re-deriving the component list from *this* engagement's Phase 1 brand-mine. A component that served Arlington's IA may be wrong for another org.

**Instead:** author every `routes/*.json`, `views/*.json`, `brandingSets/*.json`, and `themes/*.json` file fresh from the metadata schema, using the Arlington files only to confirm the shape of a valid file. LWCs are re-derived from Phase 1 brand-mining and Phase 3 standard-first composition every time.

## Additional resources

- Detailed metadata templates and the full gotcha catalog: [reference.md](reference.md)
- Concrete LWC code patterns (header, hero, grid, form): [examples.md](examples.md)
