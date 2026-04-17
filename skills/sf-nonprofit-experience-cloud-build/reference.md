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
| "Page not available" on custom route | `devName` missing `__c` suffix | Rename to end in `__c`, update route JSON |
| "Page not available" on custom route | View uses `siteforce:sldsOneColLayout` with `routeType: custom-*` | Change to `siteforce:dynamicLayout` + wrap in `forceCommunity:section` |
| Double `/s/s/` in URL, 404 | Built URL as `${basePath}/s/...` | Drop the `/s/` - basePath already includes it |
| Site not accessible to guests | Network `Status: UnderConstruction` | Set `<status>Live</status>` in networks metadata |
| LWC throws on guest load | Apex class not in guest profile `classAccesses` | Add `<classAccesses>` block per class |
| Deploy fails: component reference invalid | ExperienceBundle deployed before its referenced LWCs | Deploy LWCs/SRs first, ExperienceBundle second |
| Changes deployed but not visible on site | Community not republished | Run `sf community publish` after every ExperienceBundle change |
| Static resource 404 after deploy | Asset not inside the `<name>/` subfolder | Images must be under `staticresources/<name>/`, not alongside the `-meta.xml` |
| `Network` DML error from Apex | Can't update Network via DML | Must be done in metadata and deployed |
| Font not applied | BrandingSet and theme customCSS disagree | Set both - BrandingSet fields AND `@import` in customCSS |

## API version notes

Use `apiVersion: "60.0"` (or your org's current) consistently across route, view, LWC `js-meta.xml`, and profile files. Mismatches rarely cause hard errors but can cause subtle rendering differences.
