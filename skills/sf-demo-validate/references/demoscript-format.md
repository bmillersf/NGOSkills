# Demoscript.md Format Specification

This document defines the standard format for demo scripts used by `sf-demo-validate`. The format is designed to be human-readable for presenters while providing enough structure for automated validation.

---

## File Structure

A demoscript.md file has four sections in order:

1. YAML Frontmatter (required)
2. Prerequisites (recommended)
3. Demo Steps (required)
4. Teardown (optional)

---

## 1. YAML Frontmatter

```yaml
---
title: "Customer 360 Demo"
org_alias: my-demo-org
org_type: scratch          # scratch | sandbox | production | dev
api_version: "62.0"       # optional, defaults to org default

features:                  # Salesforce features that must be enabled
  - Knowledge
  - ServiceCloud
  - ExperienceCloud

packages:                  # Managed/unlocked packages that must be installed
  - name: "Nonprofit Cloud"
    namespace: npsp
    min_version: "3.0"
  - name: "My Unlocked Package"
    id: "04t..."

users:                     # Demo users that must exist
  - alias: demo-admin
    profile: "System Administrator"
    permission_sets:
      - "Demo_Admin_Access"
  - alias: demo-rep
    profile: "Standard User"
    permission_sets:
      - "Sales_Rep_Access"
      - "Knowledge_User"
---
```

### Frontmatter Fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `title` | Yes | string | Demo name, used in reports |
| `org_alias` | Yes | string | sf CLI org alias to validate against |
| `org_type` | Yes | enum | One of: scratch, sandbox, production, dev |
| `api_version` | No | string | Minimum API version required |
| `features` | No | string[] | Org features that must be enabled |
| `packages` | No | object[] | Packages that must be installed |
| `packages[].name` | Yes | string | Display name |
| `packages[].namespace` | No | string | Package namespace prefix |
| `packages[].id` | No | string | Package version ID (04t...) |
| `packages[].min_version` | No | string | Minimum version |
| `users` | No | object[] | Demo users that must exist in the org |
| `users[].alias` | Yes | string | Username or alias identifier |
| `users[].profile` | No | string | Expected profile |
| `users[].permission_sets` | No | string[] | Permission sets that must be assigned |

---

## 2. Prerequisites

Prerequisites are conditions that must be true before the demo begins. They appear under a `## Prerequisites` heading as a bulleted list.

```markdown
## Prerequisites

- Custom object `Invoice__c` exists with fields: `Amount__c`, `Status__c`, `Due_Date__c`
- At least 5 Account records exist with `Type = 'Customer'`
- Flow "Send Invoice Reminder" is active
- Permission set "Invoice Manager" is assigned to the demo user
- Named credential "PaymentGateway" is configured and authenticated
- Lightning app "Invoice Manager" is visible to the demo user profile
```

Each prerequisite should be a single, verifiable statement. The skill parses these and maps them to validation checks. Be specific -- include API names, field values, and counts where possible.

---

## 3. Demo Steps

Demo steps appear under `## Demo Steps` and are numbered sections with a consistent structure.

### Step Structure

Each step has:
- **Title** (in the heading)
- **Type** (optional tag directing the validation strategy)
- **Action** -- what the presenter does
- **Expected** -- what should be visible or happen
- **Check** (optional) -- explicit validation command (SOQL, metadata query, etc.)
- **Visual** (optional) -- description of what the page should look like for screenshot validation
- **Talking Points** (optional) -- presenter notes, not validated

### Syntax

```markdown
## Demo Steps

### Step 1: Open the Invoice Manager App
<!-- type: navigation -->

**Action**: Navigate to the App Launcher and select "Invoice Manager"

**Expected**: The Invoice Manager app opens showing the Invoice list view with recent records

**Talking Points**:
- Point out the custom app navigation
- Mention this was built with Lightning App Builder

### Step 2: View Invoice Records
<!-- type: data -->

**Action**: Click on invoice "INV-001" in the list view

**Expected**: Invoice record page displays with:
- Amount: $5,000.00
- Status: "Sent"
- Due Date: populated
- Related Contact visible in the sidebar

**Check**:
```soql
SELECT Id, Name, Amount__c, Status__c, Due_Date__c, Contact__r.Name
FROM Invoice__c
WHERE Name = 'INV-001'
```

### Step 3: Trigger the Reminder Flow
<!-- type: automation -->

**Action**: Change the Invoice Status to "Overdue" and save

**Expected**: A toast notification confirms the record was saved. Within 30 seconds, an email activity appears in the Activity Timeline showing the reminder was sent.

**Check**:
```soql
SELECT Id, IsActive, ProcessType
FROM FlowDefinitionView
WHERE ApiName = 'Send_Invoice_Reminder' AND IsActive = true
```
```

### Step Type Tag

The `<!-- type: xxx -->` comment is optional. Valid types:

| Type | When to Use |
|------|-------------|
| `navigation` | Steps involving opening apps, tabs, pages, or navigating the UI |
| `data` | Steps that display or verify specific record data |
| `metadata` | Steps that depend on objects, fields, layouts, or record types existing |
| `automation` | Steps where flows, triggers, or automations should fire |
| `permission` | Steps where specific access or visibility must be granted |
| `component` | Steps involving custom LWC or Aura components |
| `integration` | Steps involving external system connections |

A single step can involve multiple types. Use the primary type -- the skill will infer secondary checks from the step description.

If omitted, the skill infers the type from keywords in the Action and Expected text.

### Explicit Checks

The `**Check**` block is optional. When provided, it gives the skill an explicit query or command to run. Supported formats:

**SOQL query** (fenced with `soql` language tag):
```markdown
**Check**:
```soql
SELECT Id, Name FROM Account WHERE Type = 'Customer' LIMIT 5
```
```

**SF CLI command** (fenced with `bash` language tag):
```markdown
**Check**:
```bash
sf project retrieve start --metadata CustomObject:Invoice__c --target-org [alias]
```
```

**Apex anonymous** (fenced with `apex` language tag):
```markdown
**Check**:
```apex
Integer count = [SELECT COUNT() FROM Invoice__c WHERE Status__c = 'Sent'];
System.assert(count > 0, 'Expected at least one Sent invoice');
```
```

When no explicit check is provided, the skill generates its own validation based on the step type and description.

### Visual Validation

Any step can opt into visual screenshot validation. This captures the Salesforce page via a headless browser and lets the agent visually verify the UI matches expectations.

**Option 1: `**Visual**` block** -- describe what the page should look like:

```markdown
### Step 3: View the Case Record Page
<!-- type: navigation -->
<!-- visual_path: /lightning/r/Case/[Id]/view -->

**Action**: Open a High-Priority case from the list view

**Expected**: Case record page displays with all fields populated

**Visual**: The record page should show:
- Case header with Priority badge in red
- Details tab with Status, Priority, and Origin fields visible
- Knowledge sidebar component on the right panel
- Activity Timeline below the details section
```

The `**Visual**` block tells the agent exactly what to look for in the screenshot.

**Option 2: `<!-- visual: true -->` tag** -- use the `**Expected**` block as the visual description:

```markdown
### Step 1: Open the Service Console
<!-- type: navigation -->
<!-- visual: true -->
<!-- visual_path: /lightning/app/ServiceConsole -->

**Action**: Navigate to the Service Console app

**Expected**: The Service Console opens with split-view list showing recent Cases on the left and a case record on the right
```

When `<!-- visual: true -->` is present but no `**Visual**` block exists, the agent uses the `**Expected**` text to assess the screenshot.

### Visual Path Tag

The `<!-- visual_path: /lightning/... -->` comment specifies the Lightning URL path for the screenshot. This is the path portion appended to the org's base URL.

Common patterns:

| Path | Target |
|------|--------|
| `/lightning/app/[AppDevName]` | Lightning app home |
| `/lightning/o/[Object]/list` | Object list view |
| `/lightning/o/[Object]/new` | New record form |
| `/lightning/r/[Object]/[RecordId]/view` | Record detail page |
| `/lightning/setup/SetupOneHome/home` | Setup home |
| `/lightning/page/[PageDevName]` | Custom Lightning page |

If no `visual_path` is provided, the skill constructs the path from the step's Action description.

---

## 4. Teardown (Optional)

Teardown instructions appear under `## Teardown` and describe cleanup steps to reset the org after the demo.

```markdown
## Teardown

- Reset Invoice "INV-001" Status back to "Sent"
- Delete any records created during the demo with Name containing "Demo-"
- Deactivate the "Demo Mode" custom setting
```

Teardown steps are not validated -- they serve as documentation for the presenter.

---

## Complete Annotated Example

```markdown
---
title: "Service Cloud Case Management Demo"
org_alias: service-demo
org_type: scratch
features:
  - ServiceCloud
  - Knowledge
packages: []
users:
  - alias: demo-agent
    profile: "Standard User"
    permission_sets:
      - "Service_Agent_Access"
---

## Prerequisites

- Custom object `SLA_Policy__c` exists with fields: `Response_Time__c` (Number), `Priority__c` (Picklist)
- At least 10 Case records exist with `Status = 'New'` and `Priority = 'High'`
- Entitlement Process "Standard Support" is active
- Knowledge articles exist in the "FAQ" category
- Omni-Channel routing configuration is deployed for Case

## Demo Steps

### Step 1: Open the Service Console
<!-- type: navigation -->
<!-- visual: true -->
<!-- visual_path: /lightning/app/ServiceConsole -->

**Action**: Navigate to the Service Console app from the App Launcher

**Expected**: The Service Console opens with the split-view list showing recent Cases

### Step 2: Show High-Priority Cases
<!-- type: data -->

**Action**: Select the "High Priority Cases" list view

**Expected**: List view shows at least 10 cases, all with Priority = "High" and Status = "New"

**Check**:
```soql
SELECT Id, CaseNumber, Priority, Status
FROM Case
WHERE Priority = 'High' AND Status = 'New'
```

### Step 3: Open a Case and Show Knowledge Sidebar
<!-- type: component -->
<!-- visual_path: /lightning/r/Case/[Id]/view -->

**Action**: Click on any High-Priority case. In the sidebar, locate the Knowledge panel.

**Expected**: The Knowledge sidebar component displays suggested articles related to the case subject

**Visual**: The Case record page should show:
- Case details in the main content area with Status and Priority fields visible
- Knowledge sidebar panel on the right with at least one suggested article
- Activity Timeline component below the record details

**Talking Points**:
- Highlight Einstein-suggested articles
- Mention auto-classification

### Step 4: Verify Agent Has Service Permissions
<!-- type: permission -->

**Action**: (No UI action -- validated automatically)

**Expected**: User "demo-agent" has the Service_Agent_Access permission set assigned and can read/edit Case records

**Check**:
```soql
SELECT Id, PermissionSet.Name, Assignee.Username
FROM PermissionSetAssignment
WHERE PermissionSet.Name = 'Service_Agent_Access'
AND Assignee.Alias = 'demo-agent'
```

### Step 5: Trigger Case Escalation
<!-- type: automation -->

**Action**: Change the Case Priority from "High" to "Critical" and save

**Expected**: The Escalation Flow fires, reassigning the case to the "Tier 2 Support" queue and adding a Case Comment noting the escalation

**Check**:
```soql
SELECT Id, ApiName, IsActive, ProcessType
FROM FlowDefinitionView
WHERE ApiName = 'Case_Escalation_Flow' AND IsActive = true
```

## Teardown

- Reset escalated cases back to original owner and Priority = "High"
- Delete any Case Comments added during the demo
```

---

## Format Flexibility

The skill handles varying levels of structure:

| Level | What's Required | What's Inferred |
|-------|----------------|-----------------|
| **Minimal** | Frontmatter (title + org_alias) and numbered steps with Action/Expected | Step types, validation queries, prerequisites |
| **Standard** | Frontmatter, Prerequisites, steps with type tags and Action/Expected | Validation queries |
| **Full** | Everything including explicit Check blocks | Nothing -- all checks are explicit |

A loosely-written script with just action descriptions and expected outcomes will still be validated -- the skill infers what to check. But more structure yields more precise validation.

---

## Naming Convention

| Convention | Example |
|------------|---------|
| File name | `demoscript.md`, `demo-script.md`, `demoscript-[name].md` |
| Location | Project root or `docs/` folder |
| Multiple scripts | `demoscript-sales.md`, `demoscript-service.md` |
