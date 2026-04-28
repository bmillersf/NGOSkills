---
title: "My Demo"
org_alias: my-demo-org
org_type: scratch
# api_version: "62.0"

# features:
#   - ServiceCloud
#   - Knowledge

# packages:
#   - name: "Package Name"
#     namespace: pkg_ns
#     min_version: "1.0"

# users:
#   - alias: demo-user
#     profile: "Standard User"
#     permission_sets:
#       - "Demo_Access"
---

## Prerequisites

- (Describe objects, fields, or metadata that must exist before the demo)
- (Describe data records that must be present, with counts and field values)
- (Describe automations that must be active)
- (Describe permissions or access requirements)
- (Describe integrations or external connections needed)

## Demo Steps

### Step 1: (Title)
<!-- type: navigation -->
<!-- visual: true -->
<!-- visual_path: /lightning/app/MyApp -->

**Action**: (What the presenter does -- e.g., Navigate to App Launcher and select "My App")

**Expected**: (What should be visible -- e.g., The app opens showing the record list view)

### Step 2: (Title)
<!-- type: data -->

**Action**: (What the presenter does)

**Expected**: (What should be visible, including specific field values)

**Check**:
```soql
SELECT Id, Name FROM Account WHERE Type = 'Customer' LIMIT 5
```

### Step 3: (Title)
<!-- type: automation -->

**Action**: (What the presenter does to trigger an automation)

**Expected**: (What should happen automatically -- e.g., A flow fires and creates a Task)

**Check**:
```soql
SELECT Id, ApiName, IsActive FROM FlowDefinitionView WHERE ApiName = 'My_Flow' AND IsActive = true
```

### Step 4: (Title)
<!-- type: permission -->

**Action**: (What the presenter does -- or "validated automatically" for access checks)

**Expected**: (What access should be granted)

### Step 5: (Title)
<!-- type: component -->
<!-- visual_path: /lightning/r/MyObject__c/[Id]/view -->

**Action**: (What the presenter does)

**Expected**: (What custom component should be visible and how it should behave)

**Visual**: (Describe what the page should look like for screenshot validation)
- (e.g., Custom component visible in the right sidebar)
- (e.g., Record header shows the expected fields)
- (e.g., No error messages or broken components)

<!--
  Add more steps as needed. Supported types:
  navigation, data, metadata, automation, permission, component, integration

  The type comment is optional -- the skill will infer types from your descriptions.

  The Check block is optional -- include SOQL, bash, or apex for explicit validation.

  Visual validation options:
  - Add <!-- visual: true --> to screenshot the page and verify against **Expected**
  - Add a **Visual** block to describe exactly what the page should look like
  - Add <!-- visual_path: /lightning/... --> to specify the page URL to screenshot
  - Visual checks require Playwright: npm install playwright && npx playwright install chromium
-->

## Teardown

- (Reset any records modified during the demo)
- (Delete any records created during the demo)
- (Restore original configuration if changed)
