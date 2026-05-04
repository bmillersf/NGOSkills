# Reference — Nonprofit Experience Cloud Build

Detailed metadata templates, configuration patterns, and the full gotcha catalog. Read this when SKILL.md points you here or when debugging a specific failure.

## Design system wiring

### Theme customCSS template

Set `customCSS` in `experiences/<Site>/themes/<theme>.json` to a single-line string containing all global styles. Replace `adp-` with a short project prefix.

```css
@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,600;0,700;1,400&family=Open+Sans:wght@300;400;500;600;700&display=swap');

body, html {
  font-family: 'Open Sans', -apple-system, BlinkMacSystemFont, sans-serif;
}

h1, h2, h3, h4, .adp-serif {
  font-family: 'Playfair Display', Georgia, serif;
  letter-spacing: -0.01em;
}

.adp-gold { color: #c79a3a; }

.adp-card {
  background: #ffffff;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(13, 34, 64, 0.08);
  transition: box-shadow .2s ease, transform .2s ease;
}
.adp-card:hover {
  box-shadow: 0 12px 32px rgba(13, 34, 64, 0.14);
  transform: translateY(-2px);
}

.adp-cta-donate {
  background: #bf1e2e !important;
  color: #ffffff !important;
  border: none !important;
  border-radius: 999px !important;
  padding: .65rem 1.6rem !important;
  font-weight: 700 !important;
  text-transform: uppercase !important;
  letter-spacing: .08em !important;
  transition: background .15s ease, transform .1s ease !important;
}
.adp-cta-donate:hover {
  background: #a01825 !important;
  transform: scale(1.03);
}

.adp-quote-block {
  background: linear-gradient(180deg, #faf7f0 0%, #f5f5f0 100%);
  border-left: 4px solid #c79a3a;
  padding: 2rem;
  border-radius: 8px;
}
```

Pack this into the theme JSON as a single escaped string with `\n` stripped. LWCs then just add `class="adp-card"` etc. and inherit the brand.

### Static resource metadata

`staticresources/<org>Assets.resource-meta.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<StaticResource xmlns="http://soap.sforce.com/2006/04/metadata">
    <cacheControl>Public</cacheControl>
    <contentType>application/zip</contentType>
</StaticResource>
```

Place images in the sibling directory `staticresources/<org>Assets/`. SFDX packages the directory as a zip automatically.

Reference from LWC:

```javascript
import ASSETS from '@salesforce/resourceUrl/<org>Assets';
// use: `${ASSETS}/logo.png`
```

## Custom public route metadata

### Route JSON

`experiences/<Site>/routes/<page>.json`:

```json
{
  "label": "Donate",
  "devName": "Donate__c",
  "apiVersion": "60.0",
  "routeType": "custom-donate",
  "pageAccess": "Public",
  "pageAuthorization": "Public",
  "published": true,
  "view": "donate",
  "viewUid": "donate"
}
```

**Required conventions:**
- `devName` must end in `__c`
- `routeType` must be `custom-<something>` (unique per page)
- `pageAccess` and `pageAuthorization` both `Public` for guest-accessible pages
- `view` string matches the filename of the view JSON (without extension)

### View JSON

`experiences/<Site>/views/<page>.json`:

```json
{
  "label": "Donate",
  "devName": "donate",
  "apiVersion": "60.0",
  "componentName": "siteforce:dynamicLayout",
  "componentAttributes": {},
  "regions": [
    {
      "regionName": "content",
      "components": [
        {
          "id": "section_donate",
          "componentName": "forceCommunity:section",
          "componentAttributes": { "layout": "oneColumn" },
          "regions": [
            {
              "regionName": "column1",
              "components": [
                {
                  "id": "lwc_donation_form",
                  "componentName": "c:donationForm",
                  "componentAttributes": {}
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

**Required conventions:**
- `componentName: "siteforce:dynamicLayout"` (NOT `siteforce:sldsOneColLayout` — that works for some but breaks custom `routeType`)
- Wrap the LWC inside a `forceCommunity:section`
- The LWC must declare `lightning__CommunityPage` in its `js-meta.xml` targets

### LWC js-meta.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__CommunityPage</target>
    </targets>
</LightningComponentBundle>
```

## Guest access configuration

### Site config

`experiences/<Site>/config/<site>.json`:

```json
{
  "isAvailableToGuests": true
}
```

### Guest profile classAccesses

`profiles/<Site> Profile.profile-meta.xml` — add one `<classAccesses>` block for **every** Apex class imported by any LWC on any public page. Even LWCs that guard rendering with `isGuest` still compile their `@wire` calls and will error without access.

```xml
<Profile xmlns="http://soap.sforce.com/2006/04/metadata">
    <classAccesses>
        <apexClass>DonorPortalController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>DonationController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <custom>true</custom>
</Profile>
```

### Network status

`networks/<Site>.network-meta.xml`:

```xml
<status>Live</status>
```

**Cannot be changed via Apex DML** — `update new Network(Id=..., Status='Live')` throws "DML operation Update not allowed on Network". Must be set in metadata and deployed.

## Navigation patterns

### basePath rule

`@salesforce/community/basePath` resolves to `/<site-url-prefix>/s`. **It already includes `/s`.** Every URL you build from it must NOT re-append `/s/`.

```javascript
import basePath from '@salesforce/community/basePath';

// Correct
const donateUrl = `${basePath}/donate`;
const homeUrl = `${basePath}/`;

// Wrong — produces /prefix/s/s/donate and results in "Page not available"
const donateUrlBug = `${basePath}/s/donate`;
```

### NavigationMixin pattern

Use `standard__webPage` with the `basePath`-derived URL. This is more reliable for custom routes than `standard__namedPage`.

```javascript
import { NavigationMixin } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';

export default class MyComponent extends NavigationMixin(LightningElement) {
    handleNavigate() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: `${basePath}/donate` }
        });
    }
}
```

### Deep linking with params

```javascript
const params = new URLSearchParams({ fund: 'General Fund', amount: '50' });
this[NavigationMixin.Navigate]({
    type: 'standard__webPage',
    attributes: { url: `${basePath}/donate?${params.toString()}` }
});
```

On the destination LWC, parse in `connectedCallback`:

```javascript
connectedCallback() {
    const params = new URLSearchParams(window.location.search);
    this.fund = params.get('fund') || 'General Fund';
    this.amount = params.get('amount') || '';
}
```

## Guest-aware authenticated LWCs

```javascript
import isGuest from '@salesforce/user/isGuest';
import { wire } from 'lwc';
import getSummary from '@salesforce/apex/DonorPortalController.getDonorSummary';

export default class DonorDashboard extends LightningElement {
    isGuestUser = isGuest;

    @wire(getSummary)
    wiredSummary({ data, error }) {
        if (this.isGuestUser) return;
        // handle data / error
    }

    get showDashboard() {
        return !this.isGuestUser;
    }
}
```

HTML:

```html
<template>
    <template lwc:if={showDashboard}>
        <!-- authenticated content -->
    </template>
</template>
```

## Deployment recipe

```bash
# 1. Deploy components (LWCs, Apex, static resources, profiles, networks)
sf project deploy start \
  --source-dir force-app/main/default/lwc \
  --source-dir force-app/main/default/staticresources \
  --source-dir force-app/main/default/classes \
  --source-dir force-app/main/default/profiles \
  --source-dir force-app/main/default/networks \
  --target-org <alias>

# 2. Deploy the ExperienceBundle (must come after - references components from step 1)
sf project deploy start \
  --source-dir force-app/main/default/experiences \
  --target-org <alias>

# 3. Publish the community
sf community publish --name "<Site Name>" --target-org <alias>

# 4. Verify (give publish ~30-60s to propagate)
curl -sI "https://<domain>/<prefix>/s/<route>"
sf data query --query "SELECT Name, Status FROM Network WHERE Name = '<Site Name>'" --target-org <alias>
```

## The full gotcha catalog

| Symptom | Cause | Fix |
|---------|-------|-----|
| "Page not available" on custom LWR route | `devName` missing `__c` suffix | Rename to end in `__c`, update route JSON (LWR rule — Aura bundles use no suffix) |
| "Page not available" on custom LWR route | View uses `siteforce:sldsOneColLayout` with `routeType: custom-*` | Change to `siteforce:dynamicLayout` + wrap in `forceCommunity:section` |
| Double `/s/s/` in URL, 404 | Built URL as `${basePath}/s/...` | Drop the `/s/` - basePath already includes it |
| Site not accessible to guests | Network `Status: UnderConstruction` | Set `<status>Live</status>` in networks metadata |
| All guest visits redirect to `/login/?ec=302`, even on `pageAccess: Public` routes | `config/<site>.json` has `isAvailableToGuests: false` | Flip to `true`. Without this, guest access is silently off even if individual routes say Public. **(Confirmed May 2026 — Aura site `CSEA`)** |
| `sf project retrieve --metadata "ExperienceBundle:<name>"` returns "Entity cannot be found" | Site has never been Published (bundle not materialized) **or** the bundle name differs from the Network name | (a) Run `sf community publish --name "<Network Name>"`, wait 30-60s, retry. (b) The ExperienceBundle name is the Salesforce `Site.Name` where `UrlPathPrefix='<prefix>/s'` — it often has a numeric suffix. e.g. Network `CSEA` → bundle `CSEA1`. Query: `sf data query --query "SELECT Name, UrlPathPrefix FROM Site WHERE UrlPathPrefix LIKE '<prefix>%'"` |
| ExperienceBundle deploy fails: `viewType value in X and routeType value in X must match` | Custom route's `routeType` and view's `viewType` don't match | Both fields must be the exact same string. Convention: `custom-<page>` in both files. |
| ExperienceBundle deploy fails: `missing a valid entry for region:footer in home.json` | Replaced an Aura view's `regions` array but dropped template-required empty regions | Aura Customer Service home requires all six regions: `header`, `featured`, `content`, `sidebar`, `footer`, `sfdcHiddenRegion`. Keep empty-but-present region entries; only put components in `content`. |
| `actionOverride` deploy fails: `Automation is not a standard action and cannot be overridden` | Retrieved custom object `.object-meta.xml` has override entries Salesforce no longer allows | Remove those `<actionOverrides>` blocks entirely. Safe to delete every `<actionOverrides>` block; they are defaults. |
| NavigationMenu deploy fails: `Target Preferences: bad value for restricted picklist field: CurrentWindow / NewWindow` | `<targetPreference>` values aren't valid in this schema | **Omit the `<targetPreference>` element entirely.** `<type>InternalLink</type>` + `<target>/route</target>` + `<label>` + `<position>` + `<publiclyAvailable>` is enough. |
| NavigationMenu deploy fails: `Element defaultLanguage invalid at this location in type NavigationMenuItem` | Per-item `<defaultLanguage>` element | Remove the `<defaultLanguage>` element from each item. |
| Profile deploy fails: `Permission Create X depends on permission(s): Read X` | ObjectPermissions has `allowCreate: true` but `allowRead: false` | Always set both `allowRead: true` when granting `allowCreate: true`. Read is a prerequisite. |
| Profile deploy fails: `Permission Modify All X depends on permission(s): Delete X` | `modifyAllRecords: true` without `allowDelete: true` | Set `allowDelete: true` when granting `modifyAllRecords`. |
| Permission set deploy fails: `You cannot deploy to a required field: X` | Permission set lists a required custom field under `fieldPermissions` | Required fields inherit access automatically — remove them from the permset entirely. |
| LWC/Apex-controller-backed component throws on guest load | Apex class not in guest profile `classAccesses` | Add `<classAccesses>` block per class. Applies equally to Aura components (`aura/*.cmp` with `controller="Foo"`). |
| `EncryptedText` field deploy fails: `Property 'encrypted' not valid in version 66.0` | Field XML uses `<encrypted>true</encrypted>` | Remove the `<encrypted>` element. `<type>EncryptedText</type>` + valid `<maskType>` (e.g. `ssn`, `creditCard`) is sufficient. |
| Deploy fails: component reference invalid | ExperienceBundle deployed before its referenced LWCs/Aura components | Deploy LWCs, Aura bundles, static resources, and Apex FIRST, then ExperienceBundle second. |
| Changes deployed but not visible on site | Community not republished | Run `sf community publish` after every ExperienceBundle change. Wait 45-60s then curl. |
| Static resource 404 after deploy | Asset not inside the `<name>/` subfolder | Images must be under `staticresources/<name>/`, not alongside the `-meta.xml` |
| `Network` DML error from Apex | Can't update Network via DML | Must be done in metadata and deployed |
| Font not applied | BrandingSet and theme customCSS disagree | Set both — BrandingSet `HeaderFonts`/`PrimaryFont` AND `@import` in theme `customCSS` |

## Aura vs LWR — two site runtimes with different authoring rules

Experience Cloud sites come in two flavors. Authoring rules differ; get the flavor right before copying a template.

| Concern | **Aura** site (Customer Service, Customer Account Portal, Partner Central) | **LWR** site (Build Your Own, Microsite) |
|--------|---------------------------------------------------------------------------|------------------------------------------|
| Route `devName` suffix | **No suffix required** (`"devName": "Become_A_Member"`) | **MUST end in `__c`** (`"devName": "Donate__c"`) |
| View `componentName` | Layout template — `siteforce:sldsTwoCol84SidebarFeaturedLayout`, `siteforce:sldsOneColLayout`, `siteforce:serviceBody`, etc. All template regions must be preserved on home views (header/featured/content/sidebar/footer/sfdcHiddenRegion) | `"siteforce:dynamicLayout"` for every custom view |
| Component placement | LWC or Aura component placed directly in a `regions[].components` entry with `componentAttributes`, `id`, `renderPriority: "NEUTRAL"`, `renditionMap: {}`, `type: "component"` | LWC wrapped in `"componentName": "forceCommunity:section"` whose regions contain the LWC |
| `viewType` value | Must match the route's `routeType` string exactly | Same rule |
| Detection | `sf community create ... --template-name "Customer Service"` (or any non–"Build Your Own"/"Microsite" template) → Aura. | Created as "Build Your Own (LWR)" → LWR. |

**Customer Community Plus orgs most commonly use Aura** (the Customer Service template). If the retrieved bundle has layouts like `siteforce:sldsTwoCol84SidebarFeaturedLayout` or regions like `featured`/`sidebar`, you're on Aura.

### Aura-specific route + view template

`experiences/<Bundle>/routes/becomeAMember.json`:

```json
{
  "activeViewId" : "csea-view-becomeamember",
  "appPageId" : "<same mainAppPageId as other routes>",
  "configurationTags" : [ ],
  "devName" : "Become_A_Member",
  "id" : "csea-route-becomeamember",
  "label" : "Become a Member",
  "pageAccess" : "Public",
  "pageAuthorization" : "Public",
  "routeType" : "custom-becomeamember",
  "type" : "route",
  "urlPrefix" : "become-a-member",
  "published" : true,
  "view" : "becomeAMember",
  "viewUid" : "becomeAMember"
}
```

`experiences/<Bundle>/views/becomeAMember.json`:

```json
{
  "appPageId" : "<same mainAppPageId>",
  "componentName" : "siteforce:sldsOneColLayout",
  "dataProviders" : [ ],
  "id" : "csea-view-becomeamember",
  "label" : "Become a Member",
  "regions" : [ {
    "components" : [ {
      "componentAttributes" : { },
      "componentName" : "c:cseaBecomeAMember",
      "id" : "csea-becomeamember-cmp",
      "renderPriority" : "NEUTRAL",
      "renditionMap" : { },
      "type" : "component"
    } ],
    "id" : "csea-becomeamember-content",
    "regionName" : "content",
    "type" : "region"
  }, {
    "components" : [ {
      "componentAttributes" : {
        "customHeadTags" : "",
        "description" : "Join our union.",
        "title" : "Become a Member"
      },
      "componentName" : "forceCommunity:seoAssistant",
      "id" : "csea-becomeamember-seo",
      "renditionMap" : { },
      "type" : "component"
    } ],
    "id" : "csea-becomeamember-hidden",
    "regionName" : "sfdcHiddenRegion",
    "type" : "region"
  } ],
  "themeLayoutType" : "Inner",
  "type" : "view",
  "viewType" : "custom-becomeamember"
}
```

**Home view on Aura — preserve all six template regions, even empty ones:**

```json
"regions": [
  { "id": "...", "regionName": "header", "type": "region" },
  { "id": "...", "regionName": "featured", "type": "region" },
  { "components": [ { "componentName": "c:cseaHomeHero", ... } ], "regionName": "content", "type": "region" },
  { "id": "...", "regionName": "sidebar", "type": "region" },
  { "id": "...", "regionName": "footer", "type": "region" },
  { "components": [ { "componentName": "forceCommunity:seoAssistant", ... } ], "regionName": "sfdcHiddenRegion", "type": "region" }
]
```

Dropping `header` / `featured` / `footer` even when empty triggers `missing a valid entry for region:footer in home.json` on deploy.

## NavigationMenu template (Aura + LWR)

`navigationMenus/SFDC_Default_Navigation_<SiteName>.navigationMenu-meta.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<NavigationMenu xmlns="http://soap.sforce.com/2006/04/metadata">
    <container><SiteName></container>
    <containerType>Network</containerType>
    <label>Default Navigation</label>
    <navigationMenuItem>
        <label>Home</label>
        <position>0</position>
        <publiclyAvailable>true</publiclyAvailable>
        <target>/</target>
        <type>InternalLink</type>
    </navigationMenuItem>
    <navigationMenuItem>
        <label>Apply</label>
        <position>1</position>
        <publiclyAvailable>true</publiclyAvailable>
        <target>/application</target>
        <type>InternalLink</type>
    </navigationMenuItem>
</NavigationMenu>
```

Do **not** include `<defaultLanguage>` or `<targetPreference>` on items — both cause schema / restricted-picklist errors.

## Authoring workflow — do NOT reach for Experience Builder UI or Playwright

Every page composition, branding change, route, guest profile edit, and navigation menu item in an Experience Cloud site is expressible as Metadata API files in the ExperienceBundle, Network, Profile, NavigationMenu, and BrandingSet types. **Do not automate Experience Builder drag-drop via Playwright** — the Builder is iframe-wrapped, shadow-DOM heavy, and changes across releases; selectors are fragile, and the same state is authorable in 10 minutes of JSON editing.

The only legitimate reason to open Experience Builder is (a) visually reviewing a theme preview during design, or (b) a bug where metadata-only deploys aren't reflecting in the rendered site and you need to republish via the Builder's **Publish** button as a fallback. Even the Publish step is usually reachable via `sf community publish --name "<Site Name>"`.

If Experience Builder drag-drop feels necessary, stop and re-read this skill — the metadata path exists.

## API version notes

Use `apiVersion: "60.0"` (or your org's current) consistently across route, view, LWC `js-meta.xml`, and profile files. Mismatches rarely cause hard errors but can cause subtle rendering differences.
