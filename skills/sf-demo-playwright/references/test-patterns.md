# Playwright Selector Patterns for Salesforce

Salesforce Lightning uses complex, generated class names. These patterns are reliable across orgs and API versions.

---

## Authentication

Inject the sf CLI session into Playwright rather than re-authenticating via the login page:

```javascript
async function getSalesforceSession(orgAlias) {
  const { execSync } = require('child_process');
  const raw = execSync(`sf org display --target-org ${orgAlias} --json`).toString();
  const info = JSON.parse(raw).result;
  return { instanceUrl: info.instanceUrl, accessToken: info.accessToken };
}

// In test setup:
test.beforeEach(async ({ page }) => {
  const { instanceUrl, accessToken } = await getSalesforceSession('my-demo-org');
  // Inject session cookie
  await page.context().addCookies([{
    name: 'sid',
    value: accessToken,
    domain: new URL(instanceUrl).hostname,
    path: '/',
    httpOnly: true,
    secure: true
  }]);
});
```

---

## Navigation Patterns

**App Launcher**:
```javascript
await page.click('.slds-icon-waffle, [title="App Launcher"]');
await page.fill('.slds-global-search__input, input[placeholder="Search apps and items..."]', 'Volunteer Hub');
await page.click('.slds-lookup__item-action:has-text("BTH Volunteer Hub")');
```

**Direct URL navigation** (fastest, most reliable):
```javascript
await page.goto(`${instanceUrl}/lightning/app/BTH_Volunteer_Hub`);
await page.waitForSelector('.oneAppLayoutHost, .slds-template__container', { timeout: 15000 });
```

**Tab navigation**:
```javascript
await page.click('a.tabHeader:has-text("Applications"), .navItem:has-text("Applications")');
await page.waitForLoadState('networkidle');
```

---

## Record Field Assertions

**Standard field value** (record detail page):
```javascript
// Field label + value
await expect(page.locator('.slds-form-element:has(.slds-form-element__label:has-text("Status")) .slds-form-element__control'))
  .toContainText('Submitted');

// Shorter pattern using data-field attribute (where available)
await expect(page.locator('[data-field="Status__c"] .slds-form-element__static'))
  .toContainText('Submitted');
```

**Record header / title**:
```javascript
await expect(page.locator('.slds-page-header__title, .slds-breadcrumb__item:last-child'))
  .toContainText('James Okafor');
```

**Related list count**:
```javascript
const relatedList = page.locator('.slds-card:has(.slds-card__header-title:has-text("Volunteer Shifts"))');
await expect(relatedList.locator('.slds-badge, .countSortedByFilteredBy')).toBeVisible();
```

---

## List View Patterns

**List view record count**:
```javascript
await page.waitForSelector('.slds-table tbody tr, .uiVirtualDataTable tr');
const rows = await page.locator('.slds-table tbody tr').count();
expect(rows).toBeGreaterThanOrEqual(3);
```

**Find a specific record in list view**:
```javascript
await expect(page.locator('.slds-table tbody').locator('td:has-text("James Okafor")')).toBeVisible();
```

**Click a record from list view**:
```javascript
await page.click('.slds-table tbody tr:has-text("James Okafor") a');
```

---

## Form / Flow Patterns

**LWC input field**:
```javascript
await page.fill('input[name="firstName"], lightning-input[data-id="firstName"] input', 'James');
await page.fill('input[name="lastName"]', 'Okafor');
await page.fill('input[type="email"]', 'james.okafor@demo.volunteer');
```

**Picklist / Select**:
```javascript
await page.click('[name="volunteerType"], lightning-combobox[name="volunteerType"] button');
await page.click('.slds-dropdown__list .slds-media__body:has-text("Tutor")');
```

**Submit button**:
```javascript
await page.click('button[type="submit"]:visible, .slds-button:has-text("Submit"):visible');
await page.waitForSelector('.slds-theme--success, .success-message, [class*="confirmation"]', { timeout: 10000 });
```

**Flow Next button**:
```javascript
await page.click('button:has-text("Next"), button:has-text("Continue")');
await page.waitForLoadState('networkidle');
```

---

## Experience Cloud Patterns

**Guest portal page load**:
```javascript
await page.goto(portalUrl);
// Wait for LWR or Aura to finish rendering
await page.waitForSelector('.siteforceContentArea, .experienceSite, main', { timeout: 20000 });
await expect(page).not.toHaveTitle(/Error|404|Unavailable/);
```

**Check a specific component is visible**:
```javascript
await expect(page.locator('c-bth-volunteer-explore, [data-component-id*="bthVolunteer"]')).toBeVisible();
```

**Member portal login**:
```javascript
await page.goto(`${portalUrl}/login`);
await page.fill('input[name="username"]', 'james.okafor@demo.volunteer');
await page.fill('input[name="password"]', 'DemoPass123!');
await page.click('button[type="submit"]');
await page.waitForURL(`${portalUrl}/**`);
```

---

## Toast / Confirmation Assertions

```javascript
// Success toast
await expect(page.locator('.slds-notify--toast.slds-theme--success, .toastMessage')).toBeVisible({ timeout: 8000 });

// Specific toast message
await expect(page.locator('.slds-notify--toast')).toContainText('was saved');
```

---

## Screenshot Best Practices

```javascript
// Full page (for Experience Cloud, dashboards)
await page.screenshot({ path: 'screenshots/step-07-portal.png', fullPage: true });

// Viewport only (for record pages -- cleaner, faster)
await page.screenshot({ path: 'screenshots/step-03-record.png', fullPage: false });

// Clip to a specific element (for detail panels, related lists)
const element = await page.locator('.slds-card:has-text("Volunteer History")').boundingBox();
await page.screenshot({ path: 'screenshots/step-05-history.png', clip: element });
```

**Screenshot naming convention**:
```
step-[NN]-[kebab-case-description].png
step-01-volunteer-hub-home.png
step-03-james-okafor-application.png
step-07-guest-intake-portal.png
```

---

## Timing and Reliability

**Wait for Salesforce to finish loading** (after navigation):
```javascript
await Promise.all([
  page.waitForLoadState('networkidle'),
  page.waitForSelector('.slds-template__container, .oneAppLayoutHost', { timeout: 20000 })
]);
```

**Wait after a save/submit** (allow triggers and flows to fire):
```javascript
await page.click('.slds-button:has-text("Save")');
await page.waitForSelector('.slds-notify--toast', { timeout: 10000 });
await page.waitForTimeout(2000); // buffer for async triggers
```

**Retry flaky assertions**:
```javascript
await expect(async () => {
  const count = await page.locator('.slds-table tbody tr').count();
  expect(count).toBeGreaterThan(0);
}).toPass({ timeout: 15000 });
```
