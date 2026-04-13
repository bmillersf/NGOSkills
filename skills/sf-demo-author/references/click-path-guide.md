# Click Path Writing Guide

A click path is only useful if it's **unambiguous**. Someone who has never seen the org before should be able to follow it exactly and get the same result every time.

---

## The Verbatim Standard

Every action must specify:
1. **What to click/interact with** -- the exact UI element name
2. **Where it is** -- location on screen or navigation path
3. **What value to enter** (if applicable) -- exact text, not a description
4. **What happens next** -- the immediate result of the action

### Bad (ambiguous):
> Open the volunteer app and find the applicant

### Good (verbatim):
> Click the App Launcher (the grid of dots, top left of the nav bar). In the search field, type "Volunteer Hub". Click "BTH Volunteer Hub" in the results. The app opens showing the Applicant list view with recent submissions.

---

## Action Verb Reference

Use these specific verbs -- they map directly to Playwright selectors:

| Verb | When to Use |
|---|---|
| **Click** | Buttons, links, tabs, picklist options, checkboxes |
| **Type** | Free text fields, search boxes |
| **Select** | Dropdown/picklist fields (triggers onChange) |
| **Navigate to** | URL-based navigation, app launcher |
| **Hover over** | Tooltips, action menus that appear on hover |
| **Scroll to** | Elements below the fold |
| **Open** | Expanding sections, accordion panels |
| **Save** | Save button (always specify "Click Save" not "save the record") |

---

## Naming UI Elements

Always use the **label as it appears in the UI**, not the API name:

| Instead of... | Write... |
|---|---|
| Click npe01__Membership_Origin__c | Click the "Membership Origin" field |
| Open the npc__Gift_Transaction__c object | Open the Gift Transactions tab |
| Navigate to /lightning/o/Account/list | Click the App Launcher, type "Accounts", click the Accounts app |

Exception: In `**Check**` blocks, use API names for SOQL accuracy.

---

## Expected Outcome Standards

The `**Expected**` block should describe what the presenter **sees**, including:

- **Page title or app name**
- **Key field values** (use exact values from the seeded data -- persona names, specific amounts, dates)
- **List view counts** ("at least 3 records", "the top result is 'James Okafor'")
- **Component visibility** ("the Volunteer History component shows 2 previous assignments")
- **Status indicators** ("a green 'Approved' badge appears in the Status field")

### Bad:
> Expected: The record opens and shows the volunteer information

### Good:
> Expected: James Okafor's applicant record opens. The Status field shows "Pending Review". The application date is within the last 7 days. The "Background Check" field is empty (not yet submitted).

---

## Step Type Selection

Pick the **primary** type for each step:

| Step involves... | Use type |
|---|---|
| Opening an app, tab, page, or navigating | `navigation` |
| Displaying specific record data or field values | `data` |
| Custom objects, fields, layouts, record types existing | `metadata` |
| A flow, trigger, or automation firing | `automation` |
| User access or permission set assignment | `permission` |
| An LWC or Aura component rendering | `component` |
| A named credential or external connection | `integration` |
| An Experience Cloud page (guest or member) | `experience` |
| Running through a form submission end-to-end | `e2e_simulation` or `intake_simulation` |

---

## Visual Step Rules

Add `<!-- visual: true -->` to a step when:
- It's the **wow moment** (the single most impressive visual in the demo)
- It's an **Experience Cloud page** (external-facing UX is always worth capturing)
- It shows **data that tells the story** (a dashboard, a 360 view, a completed intake)
- The audience will **want to see it on their own screen** later

Limit to 3–4 visual steps per demo. Too many screenshots dilutes the impact.

Always add `<!-- visual_path: /lightning/... -->` when the page URL is known. For record pages, use `[Id]` as a placeholder -- `sf-demo-validate` will substitute the actual record ID.

---

## Talking Points Format

Talking points are **not** a description of what's on screen. They are the **business value translation**:

### Bad:
> This screen shows the volunteer record with all the fields filled in.

### Good:
> Maria just found James's application in under 5 seconds. Before Salesforce, this was buried in an email thread. Notice the skills match -- James listed "tutoring" and there are two open tutoring shifts this week.

**Formula**: [What just happened] + [What it replaces] + [Why it matters for mission]

---

## Check Block Standards

### When to include a Check block:
- **Data steps**: Always include SOQL to verify the record exists with expected values
- **Automation steps**: Always include SOQL to verify the flow is active
- **Permission steps**: Always include SOQL to verify the permission set assignment

### SOQL check pattern:
```soql
SELECT Id, [key fields]
FROM [Object]
WHERE [identifying condition]
LIMIT 1
```

Keep checks focused -- query only the fields the step depends on. Don't SELECT *.

### Apex check pattern (for E2E simulation):
```apex
// Verify intake form created expected records
Integer appCount = [SELECT COUNT() FROM Application__c WHERE LastName = 'Okafor' AND CreatedDate = TODAY];
System.assert(appCount > 0, 'Expected intake form submission to create an Application record');
```

---

## Common Salesforce UI Patterns

Reference these for consistent step writing:

**App Launcher**:
> Click the App Launcher (9-dot grid icon, top left of the navigation bar). Type "[App Name]" in the search field. Click "[App Name]" in the results.

**List View**:
> In the [Object] tab, click the list view selector (dropdown next to "Recently Viewed"). Select "[List View Name]". The list refreshes showing [N] records.

**Related List**:
> Scroll down to the "[Related List Name]" section on the record page. Click "View All" to see the full list.

**Quick Action / Button**:
> Click the "[Button Label]" button in the record action bar (top right of the record page, next to "Edit").

**Flow Screen**:
> Click "[Next / Continue / Submit]" to advance to the next screen of the guided form.

**Global Search**:
> Click the search bar at the top of the page (magnifying glass icon). Type "[search term]". Press Enter. Click the first result: "[Record Name]".
