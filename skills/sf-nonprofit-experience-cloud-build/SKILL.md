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

## The five-phase workflow

Copy this checklist at the start of the engagement:

```
Phase Progress:
- [ ] Phase 1: Brand-mine the reference website
- [ ] Phase 2: Translate brand into a design system
- [ ] Phase 3: Decompose the page into purposeful LWCs
- [ ] Phase 4: Wire routing, guest access, and deployment
- [ ] Phase 5: Publish and verify end-to-end
```

### Phase 1 — Brand-mine the reference website

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

### Phase 3 — Decompose the page into purposeful LWCs

**Rule: never build mega-LWCs.** Each story on the homepage = one LWC. Compose the view in the ExperienceBundle's `views/home.json`.

Typical LWC set for a marketing-style community homepage:

| LWC | Purpose |
|-----|---------|
| `<org>Header` | Logo, primary nav, primary CTA (donate / sign up) |
| `<org>HeroBanner` | Full-width hero with eyebrow + headline + 1-2 CTAs |
| `<org>OpportunitiesGrid` | 3-6 tiles linking to deeper actions (often deep-linked with URL params) |
| `<org>QuoteBanner` | Leadership / testimonial pull-quote |
| `<org>UpcomingEvents` | Curated event list with date badges |
| `<org>Dashboard` | Authenticated-user summary (hidden for guests) |

**Dual-audience pattern**: public marketing LWCs render for everyone; authenticated dashboards must use `@salesforce/user/isGuest` to gate rendering *and* to short-circuit any `@wire` Apex calls so guest sessions don't throw errors.

For transactional flows (donate, sign up, register) use a separate route with a dedicated **multi-step form LWC**:

- Stepper with visible progress (e.g. `Amount → Info → Payment → Review`)
- Parse URL params on `connectedCallback` so tiles can deep-link with pre-selected values (`?fund=General%20Fund&amount=50`)
- Confirm to a dedicated thank-you route (`/donate-thank-you`), **not** a modal — supports bookmarking, refresh, and analytics

See [examples.md](examples.md) for concrete component shells you can adapt.

### Phase 4 — Wire routing, guest access, and deployment

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

Before calling the site done, verify:

- [ ] `curl https://<domain>/<site>/s/` returns 200 and the expected LWCs appear in the bootstrap payload
- [ ] `curl https://<domain>/<site>/s/<public-route>` returns 200 for every public route (not the "Page not available" screen)
- [ ] Guest navigation from home → tile → form → thank-you works without login
- [ ] Deep links with query params (`?fund=X&amount=Y`) pre-fill the form correctly
- [ ] Authenticated user sees dashboard LWCs that guests don't
- [ ] Every custom route is listed in NavigationMenu if user-discoverable
- [ ] Community status in `sf data query "SELECT Name, Status FROM Network"` is `Live`

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
