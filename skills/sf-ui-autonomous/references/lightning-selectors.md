# Lightning Selector Patterns

Captured specs must use the resilient-selector hierarchy. The compiler enforces this; this doc explains the rationale and patterns.

## The hierarchy

| Tier | Selector | Why it's preferred |
|---|---|---|
| 1 | `getByRole(role, { name })` | Backed by ARIA tree. Survives DOM restructuring. Mirrors how a screen reader sees the page |
| 2 | `getByLabel(text)` | Couples to the visible label, not the underlying input wiring |
| 3 | `getByTestId(id)` | Salesforce sets `data-testid` on `lightning-base-components` (not all, but a growing fraction) |
| 4 | `getByText(text, { exact })` | Use sparingly; brittle to copy changes |
| 5 | CSS / XPath | **Forbidden** without a TODO comment justifying the exception |

## App Launcher

Always open via the role-named button, never via CSS:

```typescript
await page.getByRole('button', { name: 'App Launcher' }).click();
await page.getByRole('combobox', { name: 'Search apps and items' }).fill('Volunteer Hub');
await page.getByRole('option', { name: 'Acme Volunteer Hub' }).click();
```

## Lookup fields

Lightning lookup combos require typing + selecting the dropdown option. The option role + name pair is reliable:

```typescript
await page.getByRole('combobox', { name: 'Account Name' }).fill('By The Hand Club');
await page.getByRole('option', { name: 'By The Hand Club' }).first().click();
```

`.first()` matters because matching accounts also surface "create new" hints with similar text.

## Save buttons

The footer Save button:

```typescript
await page.getByRole('button', { name: 'Save', exact: true }).click();
```

`exact: true` prevents matching "Save & New" or "Save and Close".

## Toast verification

Success toasts appear in a regional ARIA live region:

```typescript
await expect(
  page.getByRole('region', { name: /toast/i }).getByText(/was created/i)
).toBeVisible({ timeout: 10000 });
```

## Related lists (record page)

The related-list card has an accessible name matching the related object plural label:

```typescript
const relatedList = page.getByRole('region', { name: 'Contacts' });
await expect(relatedList.getByRole('row')).toHaveCount(2);
```

## Shadow DOM (lightning-base-components)

Playwright pierces shadow DOM automatically when using role-based locators. Direct shadow CSS (`>>>`) is **forbidden** — if a role locator can't find an element inside shadow DOM, the underlying component lacks accessibility wiring and should be flagged for `sf-lwc` review.

## Forbidden patterns (compiler rejects these)

```typescript
// ❌ deep CSS chain — brittle to DOM updates
await page.locator('.slds-form-element__control input.slds-input').fill('...');

// ❌ XPath — opaque, hard to maintain
await page.locator('//div[contains(@class, "modal")]//button').click();

// ❌ class-only selector — Lightning class names change between releases
await page.locator('.forceListViewManagerHeader').click();

// ❌ raw record IDs in selectors — not portable across orgs
await page.goto('/lightning/r/Contact/0035g00000XYZabc/view');
```

If any of the above are unavoidable, the compiler emits a TODO and raises `fragility_score`.
