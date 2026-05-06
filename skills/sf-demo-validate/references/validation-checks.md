# Validation Checks by Step Type

This document defines the specific validation strategy, SOQL queries, and sf CLI commands used for each demo step type. The skill selects the appropriate checks during Phase 3 (Validate).

---

## General Approach

1. If the step has an explicit `**Check**` block, run that first
2. Then run the type-specific checks below to cover anything the explicit check missed
3. Record results as PASS (check succeeded) or FAIL (with diagnostic detail)

All queries use `--json` for parseable output. Replace `[alias]` with the org alias from the demoscript frontmatter.

---

## Platform Prerequisites

**Goal**: Verify org-level features and configurations the demo depends on before checking individual steps. These are blocking prerequisites — if any fail, downstream validations will also fail.

### Person Accounts Enabled

```bash
sf data query --query "SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account' AND IsPersonType = true LIMIT 1" --target-org [alias] --json
```

Pass: Returns 1 row. Fail: 0 rows — Person Accounts are not enabled. This is a **BLOCKING** failure; the entire intake form, trigger chain, and shift sign-up depend on Person Accounts.

### NPC Objects Exist

Verify that Nonprofit Cloud objects required by the demo exist in the org schema:

```bash
sf data query --query "SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName IN ('ApplicationForm','Applicant','JobPosition','JobPositionShift','JobPositionAssignment','Program','Location')" --target-org [alias] --json --use-tooling-api
```

Pass: Returns 7 rows (all objects present). Fail: Any missing object means the NPC package is not installed or incomplete.

### ApplicationForm Record Type (Programs)

```bash
sf data query --query "SELECT Id, DeveloperName, IsActive FROM RecordType WHERE SobjectType = 'ApplicationForm' AND DeveloperName IN ('Programs','Program','NPC_Programs') AND IsActive = true" --target-org [alias] --json
```

Pass: Returns at least 1 active row. Fail: 0 rows — `VolunteerIntakeService` will throw `AuraHandledException` on intake form submission.

### Custom Fields on NPC Objects

Verify custom fields the demo code depends on:

```bash
sf data query --query "SELECT QualifiedApiName, EntityDefinition.QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'ApplicationForm' AND QualifiedApiName = 'Description__c'" --target-org [alias] --json --use-tooling-api
```

Pass: Returns 1 row. Fail: `VolunteerIntakeService` will fail when setting `Description__c`.

### Volunteer_Review Queue

```bash
sf data query --query "SELECT Id, DeveloperName, Name FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Volunteer_Review'" --target-org [alias] --json
```

Pass: Returns 1 row. Fail: The applicant trigger creates Tasks owned by this queue; without it, Tasks fall back to the running user (which may confuse the demo).

### Provisioner Script Exists

Check that the local project contains the provisioner script referenced by the demo script:

```
Glob: **/scripts/apex/provision-demo-member.apex
```

Pass: File exists. Fail: Presenter cannot provision the demo member user Jamie.

---

## Data Quality & Freshness

**Goal**: Verify that demo data is not just present but is *demo-quality* — complete field population, future-dated, and free of stale test artifacts.

### Location Data Completeness

```bash
sf data query --query "SELECT Id, Name, Description, DrivingDirections, TimeZone, Latitude, Longitude FROM Location WHERE IsActive = true" --target-org [alias] --json
```

For each location, check:
- `Description` is not null/blank (shown in shift detail modal)
- `DrivingDirections` is not null/blank (shown in shift detail modal)
- `TimeZone` is not null/blank (used by controller for time display)
- `Latitude` and `Longitude` are populated (enables Google Maps link)

Pass: At least 4 of 6 locations have all fields populated. Warn: Some locations missing fields (modal will show incomplete info). Fail: Majority of locations have empty fields.

### Shift Date Freshness Window

```bash
sf data query --query "SELECT COUNT() FROM JobPositionShift WHERE StartDate >= TODAY AND Status = 'Published'" --target-org [alias] --json
```

Then check the distribution:

```bash
sf data query --query "SELECT MIN(StartDate) minStart, MAX(StartDate) maxStart FROM JobPositionShift WHERE StartDate >= TODAY AND Status = 'Published'" --target-org [alias] --json
```

Pass: At least 10 future shifts exist, with `maxStart` >= TODAY + 30. Warn: All shifts within 7 days (demo may be scheduled later). Fail: 0 future shifts.

For demos scheduled ahead, verify adequate coverage:

```bash
sf data query --query "SELECT COUNT() FROM JobPositionShift WHERE StartDate >= TODAY + 14 AND Status = 'Published'" --target-org [alias] --json
```

Pass: At least 5 shifts ≥ 14 days out. Warn: Fewer than 5 shifts with comfortable lead time.

### RemainingCapacity Check

```bash
sf data query --query "SELECT COUNT() FROM JobPositionShift WHERE StartDate >= TODAY AND Status = 'Published' AND (RemainingCapacity > 0 OR RemainingCapacity = null)" --target-org [alias] --json
```

Pass: At least some shifts have available capacity (or null = unlimited). Fail: All future shifts show `RemainingCapacity = 0` — the sign-up button will not appear.

### Stale Demo Data

Check for test artifacts from previous runs that would clutter the demo:

```bash
sf data query --query "SELECT Id, Title, CreatedDate FROM ApplicationForm WHERE Title LIKE '%E2E%' OR Title LIKE '%test%' OR Title LIKE '%Test%' ORDER BY CreatedDate DESC LIMIT 10" --target-org [alias] --json
```

```bash
sf data query --query "SELECT Id, Name, ScheduledStartTime FROM JobPositionAssignment WHERE ScheduledStartTime < TODAY ORDER BY ScheduledStartTime DESC LIMIT 10" --target-org [alias] --json
```

Pass: No stale test data found. Warn: Stale records found — report count and recommend cleanup.

### Duplicate Assignment Check (Jamie)

```bash
sf data query --query "SELECT Id, AssignedContactId, AssignedPositionShiftId, ScheduledStartTime FROM JobPositionAssignment WHERE AssignedContactId IN (SELECT PersonContactId FROM Account WHERE PersonEmail = 'acme.volunteerdemo@example.com')" --target-org [alias] --json
```

Pass: 0 existing assignments (clean slate for demo). Warn: Existing assignments found — may block duplicate sign-up prevention or confuse the presenter.

---

## Navigation

**Goal**: Verify that the app, tab, page, or record page the presenter needs to navigate to actually exists in the org.

### Custom App Existence

```bash
sf data query --query "SELECT Id, DeveloperName, Label FROM AppDefinition WHERE DeveloperName = '[AppDevName]'" --target-org [alias] --json --use-tooling-api
```

Pass: Query returns 1 row. Fail: 0 rows.

### Tab Existence

```bash
sf data query --query "SELECT Id, Name, SobjectName FROM TabDefinition WHERE Name = '[TabName]'" --target-org [alias] --json --use-tooling-api
```

### Lightning Page (FlexiPage) Existence

```bash
sf data query --query "SELECT Id, DeveloperName, MasterLabel, Type FROM FlexiPage WHERE DeveloperName = '[PageDevName]'" --target-org [alias] --json --use-tooling-api
```

### List View Existence

```bash
sf data query --query "SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = '[ListViewDevName]' AND SobjectType = '[ObjectName]'" --target-org [alias] --json
```

### App Tab Configuration

When the demoscript specifies which tabs an app should contain, retrieve the app metadata and verify:

```bash
sf project retrieve start --metadata CustomApplication:[AppDevName] --target-org [alias] --output-dir temp-retrieve --json
```

Then inspect the retrieved XML for `<tab>` or `<actionOverrides>` entries. For example, if the script says "Acme Volunteer Demo has tabs: Application Form, Applicant, Account, Job Position", verify these tabs appear in the app XML.

Pass: All expected tabs are present. Fail: Tabs missing — the presenter won't see the expected navigation.

### Fallback (Retrieve Check)

If the specific API name isn't known, attempt a retrieve:

```bash
sf project retrieve start --metadata CustomApplication:[AppName] --target-org [alias] --json
```

Pass: Retrieve succeeds. Fail: "No source backed components" or error.

---

## Data

**Goal**: Verify that demo records exist with the expected field values and relationships.

### Record Existence

```bash
sf data query --query "SELECT Id, [FieldList] FROM [Object] WHERE [Conditions]" --target-org [alias] --json
```

Pass: Query returns expected number of rows with correct field values. Fail: 0 rows or wrong values.

### Record Count

```bash
sf data query --query "SELECT COUNT() FROM [Object] WHERE [Conditions]" --target-org [alias] --json
```

Pass: Count >= expected minimum.

### Related Records

```bash
sf data query --query "SELECT Id, Name, (SELECT Id, Name FROM [ChildRelationship]) FROM [ParentObject] WHERE [Conditions]" --target-org [alias] --json
```

Pass: Parent exists AND has child records.

### Field Value Verification

When a step says "field shows X", build a WHERE clause:

```bash
sf data query --query "SELECT Id, [Field] FROM [Object] WHERE Name = '[RecordName]' AND [Field] = '[ExpectedValue]'" --target-org [alias] --json
```

Pass: Query returns 1+ rows.

### Parsing Data Results

Parse the JSON response:
- `result.records` contains the rows
- `result.totalSize` is the count
- Check each field value against the expected value from the demo step

---

## Metadata

**Goal**: Verify that objects, fields, record types, page layouts, and other schema elements exist.

### Object Existence

```bash
sf data query --query "SELECT QualifiedApiName, Label, IsCustomSetting FROM EntityDefinition WHERE QualifiedApiName = '[ObjectApiName]'" --target-org [alias] --json --use-tooling-api
```

### Field Existence

```bash
sf data query --query "SELECT QualifiedApiName, Label, DataType, EntityDefinition.QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = '[ObjectApiName]' AND QualifiedApiName = '[FieldApiName]'" --target-org [alias] --json --use-tooling-api
```

### Multiple Fields on One Object

```bash
sf data query --query "SELECT QualifiedApiName, DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = '[ObjectApiName]' AND QualifiedApiName IN ('[Field1]','[Field2]','[Field3]')" --target-org [alias] --json --use-tooling-api
```

Pass: Row count matches the number of fields queried.

### Record Type Existence

```bash
sf data query --query "SELECT Id, DeveloperName, Name, IsActive FROM RecordType WHERE SobjectType = '[ObjectApiName]' AND DeveloperName = '[RTDevName]'" --target-org [alias] --json
```

Pass: Returns 1 row with `IsActive = true`.

### Page Layout Existence

```bash
sf data query --query "SELECT Id, Name, TableEnumOrId FROM Layout WHERE Name = '[LayoutName]'" --target-org [alias] --json --use-tooling-api
```

### Validation Rule Existence

```bash
sf data query --query "SELECT Id, ValidationName, Active, EntityDefinition.QualifiedApiName FROM ValidationRule WHERE ValidationName = '[RuleName]' AND Active = true" --target-org [alias] --json --use-tooling-api
```

### Retrieve Check (Fallback)

```bash
sf project retrieve start --metadata CustomObject:[ObjectApiName] --target-org [alias] --json
```

---

## Automation

**Goal**: Verify that flows, triggers, and process builders are deployed and active.

### Flow Existence and Active Status

```bash
sf data query --query "SELECT Id, ApiName, Label, ProcessType, IsActive, Description FROM FlowDefinitionView WHERE ApiName = '[FlowApiName]' AND IsActive = true" --target-org [alias] --json --use-tooling-api
```

Pass: Returns 1 row with `IsActive = true`. Fail: 0 rows (missing) or `IsActive = false` (inactive).

### Flow by Process Type

```bash
sf data query --query "SELECT ApiName, ProcessType, IsActive FROM FlowDefinitionView WHERE ProcessType = '[Type]' AND IsActive = true" --target-org [alias] --json --use-tooling-api
```

ProcessType values: `AutoLaunchedFlow`, `Flow` (screen flow), `Workflow`, `CustomEvent`, `InvocableProcess`, `RecordAfterSave`, `RecordBeforeSave`.

### Apex Trigger Existence

```bash
sf data query --query "SELECT Id, Name, TableEnumOrId, Status FROM ApexTrigger WHERE Name = '[TriggerName]' AND Status = 'Active'" --target-org [alias] --json --use-tooling-api
```

### Scheduled Job Existence

```bash
sf data query --query "SELECT Id, CronJobDetail.Name, State, NextFireTime FROM CronTrigger WHERE CronJobDetail.Name = '[JobName]'" --target-org [alias] --json
```

### Apex Compilation Health

Verify that all project Apex classes compile successfully. A class can exist but have compilation errors after a dependency change:

```bash
sf data query --query "SELECT Id, Name, IsValid FROM ApexClass WHERE Name IN ('[Class1]','[Class2]','[Class3]') AND NamespacePrefix = null" --target-org [alias] --json --use-tooling-api
```

Pass: All classes have `IsValid = true`. Fail: Any class has `IsValid = false` — it will throw at runtime.

For a broader check of all custom classes:

```bash
sf data query --query "SELECT Name, IsValid FROM ApexClass WHERE NamespacePrefix = null AND IsValid = false" --target-org [alias] --json --use-tooling-api
```

Pass: 0 rows returned (no invalid classes). Fail: Invalid classes found — report names and investigate.

### Flow Test Execution (Preferred — Run Before Side-Effect Simulation)

If the demo step claims a flow fires (e.g. "approving the application sends a welcome email"), **run an authored FlowTest first** rather than insert-record-and-check-side-effects. FlowTests don't commit DML (no cleanup), support `--code-coverage`, and let you assert on intermediate elements (`WasVisited`, `HasError`) that side-effect inspection can't see.

```bash
# Unified runner (preferred, CLI v2.107+)
sf logic run test --tests "FlowTesting.<flow-test-name>" --target-org [alias] --synchronous --code-coverage --json

# Legacy runner (older CLIs)
sf flow run test --tests <FlowTestName> --target-org [alias] --json
```

If **no** FlowTest covers the demo's behavior, author one before validation: see [sf-flow/references/flow-test-authoring.md](../../sf-flow/references/flow-test-authoring.md) for schema + verified examples (file lives in `force-app/main/default/flowtests/<Flow>_<Test>.flowtest-meta.xml`). Fastest authoring path is Setup → Flow → Debug → Convert to Test → `sf project retrieve start --metadata FlowTest:<Flow>.<Test>` → commit. Fall back to the record-insert-and-verify-side-effects pattern only when:
- The flow is a screen flow taking input variables (FlowTest's `InputVariable` type is still reserved).
- The validation pass explicitly excludes authoring new test metadata.

---

## Permission

**Goal**: Verify that users, profiles, and permission sets grant the access required by the demo step.

### Permission Set Existence

```bash
sf data query --query "SELECT Id, Name, Label, IsCustom FROM PermissionSet WHERE Name = '[PermSetApiName]'" --target-org [alias] --json
```

### Permission Set Assignment

```bash
sf data query --query "SELECT Id, PermissionSet.Name, Assignee.Username, Assignee.Alias FROM PermissionSetAssignment WHERE PermissionSet.Name = '[PermSetApiName]' AND Assignee.Alias = '[UserAlias]'" --target-org [alias] --json
```

### Object-Level Permissions

```bash
sf data query --query "SELECT Id, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete FROM ObjectPermissions WHERE Parent.Name = '[PermSetApiName]' AND SobjectType = '[ObjectApiName]'" --target-org [alias] --json
```

### Field-Level Security

```bash
sf data query --query "SELECT Id, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE Parent.Name = '[PermSetApiName]' AND SobjectType = '[ObjectApiName]' AND Field = '[ObjectApiName].[FieldApiName]'" --target-org [alias] --json
```

### Tab Visibility

```bash
sf data query --query "SELECT Id, Name, Visibility FROM PermissionSetTabSetting WHERE Parent.Name = '[PermSetApiName]' AND Name = '[TabName]'" --target-org [alias] --json --use-tooling-api
```

### Permission Set Content — Apex Class Access

The demo relies on specific Apex classes being accessible through permission sets. Verify the permission set grants access to the required controllers:

```bash
sf data query --query "SELECT Id, SetupEntityId, SetupEntityType FROM SetupEntityAccess WHERE ParentId IN (SELECT Id FROM PermissionSet WHERE Name = '[PermSetApiName]') AND SetupEntityType = 'ApexClass'" --target-org [alias] --json
```

Cross-reference the returned `SetupEntityId` values against the Apex classes listed in the demoscript. For the Acme demo:

| Permission Set | Required Apex Classes |
|---|---|
| `Acme_Volunteer_Guest_Run_Intake_Flow` | `VolunteerExploreGuestController`, `VolunteerIntakeGuestController`, `VolunteerIntakeSubmitInvocable` |
| `Acme_Volunteer_Member_Demo` | `VolunteerExploreGuestController`, `VolunteerIntakeGuestController`, `VolunteerIntakeSubmitInvocable`, `VolunteerShiftSignupController` |

To resolve class names from IDs:

```bash
sf data query --query "SELECT Id, Name FROM ApexClass WHERE Id IN ('[Id1]','[Id2]','[Id3]')" --target-org [alias] --json --use-tooling-api
```

Pass: All required classes are listed. Fail: Missing class access — the corresponding LWC will throw "Insufficient access" at runtime.

### Network Member Groups (Experience Site Membership)

Verify the Experience site allows the correct user license type as a member:

```bash
sf project retrieve start --metadata Network:[NetworkName] --target-org [alias] --output-dir temp-retrieve --json
```

Inspect the retrieved XML for `<networkMemberGroups>` entries. Verify that `Customer Community Plus Login User` (or the license specified in the demoscript) appears.

Alternatively, check via SOQL:

```bash
sf data query --query "SELECT Id, NetworkId, ParentId FROM NetworkMemberGroup WHERE NetworkId IN (SELECT Id FROM Network WHERE Name = '[SiteName]')" --target-org [alias] --json
```

Pass: The expected license/profile is included. Fail: Demo users won't be able to log in to the Experience site.

### Profile-Based Checks

When checking profile access (less preferred than perm sets):

```bash
sf data query --query "SELECT Id, Name, UserLicense.Name FROM Profile WHERE Name = '[ProfileName]'" --target-org [alias] --json
```

---

## Component

**Goal**: Verify that LWC or Aura components are deployed to the org.

### LWC Bundle Existence (Retrieve)

```bash
sf project retrieve start --metadata LightningComponentBundle:[ComponentName] --target-org [alias] --json
```

Pass: Retrieve succeeds and returns component files. Fail: "No source backed components" error.

### LWC Tooling API Check

```bash
sf data query --query "SELECT Id, DeveloperName, MasterLabel FROM LightningComponentBundle WHERE DeveloperName = '[ComponentName]'" --target-org [alias] --json --use-tooling-api
```

### Aura Component Check

```bash
sf data query --query "SELECT Id, DeveloperName, MasterLabel FROM AuraDefinitionBundle WHERE DeveloperName = '[ComponentName]'" --target-org [alias] --json --use-tooling-api
```

### Component on FlexiPage

To verify a component is actually placed on a page:

```bash
sf project retrieve start --metadata FlexiPage:[PageName] --target-org [alias] --output-dir temp-retrieve --json
```

Then inspect the retrieved XML for `<componentInstance>` entries matching the component name.

---

## Integration

**Goal**: Verify that external system connections, credentials, and services are configured.

### Named Credential

```bash
sf data query --query "SELECT Id, DeveloperName, MasterLabel, Endpoint FROM NamedCredential WHERE DeveloperName = '[CredentialDevName]'" --target-org [alias] --json
```

Pass: Returns 1 row with a non-empty Endpoint.

### External Credential

```bash
sf data query --query "SELECT Id, DeveloperName, MasterLabel FROM ExternalCredential WHERE DeveloperName = '[CredentialDevName]'" --target-org [alias] --json --use-tooling-api
```

### External Service Registration

```bash
sf data query --query "SELECT Id, DeveloperName, MasterLabel, Description FROM ExternalServiceRegistration WHERE DeveloperName = '[ServiceDevName]'" --target-org [alias] --json --use-tooling-api
```

### Connected App

```bash
sf data query --query "SELECT Id, Name, ContactEmail FROM ConnectedApplication WHERE Name = '[AppName]'" --target-org [alias] --json --use-tooling-api
```

### Remote Site Setting

```bash
sf data query --query "SELECT Id, SiteName, EndpointUrl, IsActive FROM RemoteProxy WHERE SiteName = '[SiteName]' AND IsActive = true" --target-org [alias] --json --use-tooling-api
```

### Custom Setting / Custom Metadata for Integration Config

```bash
sf data query --query "SELECT Id, [Fields] FROM [CustomSettingOrMDT] WHERE [Conditions]" --target-org [alias] --json
```

---

## Experience Cloud

**Goal**: Verify that the Experience Cloud site renders correctly for both guest (unauthenticated) and member (authenticated) users, with live org data visible.

### Resolve Experience Site URL

```bash
sf data query --query "SELECT Id, Name, UrlPathPrefix, Status FROM Network WHERE Name = '[SiteName]'" --target-org [alias] --json
```

Or query the Site object:
```bash
sf data query --query "SELECT Id, Name, SiteType, Status, Subdomain, UrlPathPrefix FROM Site WHERE Name LIKE '%[SiteName]%' AND Status = 'Active'" --target-org [alias] --json
```

The public URL is typically: `https://[subdomain].my.site.com/[UrlPathPrefix]`

If the demoscript provides a custom domain, use that instead.

### Guest (Unauthenticated) Validation

Use Playwright to load the public site URL **without** any auth cookies:

```bash
node [skill-path]/scripts/screenshot.js "[public-site-url]" "screenshots/experience-guest.png" --no-auth
```

Validate:
1. Page loads without error (no "Authorization Required" or 500 page)
2. Expected LWC components render (catalog cards, program list, shift schedule)
3. Live data is visible (query the org for expected data, then verify it appears on the page)
4. Navigation elements are present (header, footer, menus)
5. Call-to-action elements render (sign-up buttons, intake forms if applicable)

### Member (Authenticated) Validation

1. Get a frontdoor.jsp URL for the demo user:
```bash
sf data query --query "SELECT Id, Username FROM User WHERE Alias = '[UserAlias]'" --target-org [alias] --json
```

2. Get a login-as URL via Setup or use the admin session with site redirect:
```bash
sf org open --url-only --target-org [alias] --json
```

3. Navigate Playwright to the Experience site using auth cookies from the frontdoor session, then redirect to the Experience site URL:
```bash
node [skill-path]/scripts/screenshot.js "[frontdoor-url]&retURL=[experience-url]" "screenshots/experience-member.png"
```

Validate:
1. Logged-in header shows the demo user's name
2. Member-specific features are visible (My Shifts, Sign Up buttons, profile area)
3. Member can navigate to all pages referenced in the demoscript
4. No "Insufficient Privileges" or access errors

### Experience Site URL Reachability

After resolving the public site URL, verify it actually responds with HTTP 200:

```bash
curl -s -o /dev/null -w "%{http_code}" "[public-site-url]"
```

| HTTP Code | Result | Action |
|-----------|--------|--------|
| 200 | **PASS** | Site is reachable |
| 403 | **FAIL** | Site exists but access denied — check guest user profile |
| 404 | **FAIL** | URL not found — site may not be published or URL is wrong |
| 500 | **FAIL** | Server error — check site configuration |
| 0 / timeout | **FAIL** | DNS or network issue — verify the org's Digital Experiences domain |

### Experience Data Cross-Check

After visual validation, cross-check the data visible on the site against the org:

```bash
# Verify the controller returns data matching what the page should display
sf apex run --file scripts/apex/validate-experience-data.apex --target-org [alias]
```

The Apex script should call the same controller methods that the LWC components call and verify the return data matches expectations (e.g., `VolunteerExploreGuestController.getActivePrograms()` returns rows, `getUpcomingShifts()` returns future-dated shifts with locations).

---

## E2E User Simulation

**Goal**: Execute the demo flow as specific demo users to prove end-to-end paths work without manual testing. Supports multi-user scenarios with different permission contexts.

### CRITICAL: System.runAs() Limitation

`System.runAs()` does **NOT** work in Anonymous Apex. It only works inside `@IsTest` classes. The skill provides three approaches to work around this:

| Approach | Tests Data Path | Tests Permissions | Tests Controller UserInfo | How |
|----------|:-:|:-:|:-:|-----|
| **A: Admin-Context Apex** | Yes | No | No | Anonymous Apex manually walks controller logic |
| **B: Deployed Test Class** | Yes | Yes | Yes | Deploy `@IsTest` class with `System.runAs()`, run via `sf apex run test` |
| **C: REST API with User Session** | Yes | Yes | Yes | Obtain user session, call `@AuraEnabled` via Aura REST |

**Default**: Use Approach A for data path validation. Elevate to Approach B or C when the demoscript requires permission verification or when the controller uses `UserInfo.getUserId()` (which returns the admin, not the demo user, in Approach A).

### When to Use

E2E simulation validates **transactional demo steps** -- steps where the presenter performs an action (sign up, submit form, create record) and expects a specific outcome. It does NOT replace visual validation; it validates the underlying logic.

### Resolve Demo User

```bash
sf data query --query "SELECT Id, Username, Alias, Name, Profile.Name, IsActive, TimeZoneSidKey, ContactId FROM User WHERE Alias = '[UserAlias]' AND IsActive = true" --target-org [alias] --json
```

Pass: User exists and is active. Fail: User not found or inactive.

### Demo User TimeZoneSidKey

For the Acme demo, Jamie's timezone should match the club region (Chicago):

```bash
sf data query --query "SELECT Id, Username, TimeZoneSidKey FROM User WHERE Alias = 'JVolunte' AND IsActive = true" --target-org [alias] --json
```

Pass: `TimeZoneSidKey = 'America/Chicago'`. Warn: Different timezone — `ScheduledStartTime` / `ScheduledEndTime` on assignments will display in the wrong zone during the demo, confusing the presenter.

---

### Approach A: Admin-Context Data Simulation (Anonymous Apex)

Manually replicate the controller's logic in Anonymous Apex running as the admin user. This tests the data path (record resolution, DML, relationships, side effects) but does NOT test the demo user's permissions or `UserInfo` context.

**When to use**: Default approach. Sufficient when the controller uses `without sharing` and the goal is to verify data integrity and automation chains.

**Pattern — Shift Sign-Up (walks VolunteerShiftSignupController logic)**:

```apex
System.debug('=== E2E SIMULATION START ===');
User demoUser = [SELECT Id, Username, ContactId, Email FROM User WHERE Alias = '[UserAlias]' LIMIT 1];
System.assert(demoUser.ContactId != null, 'E2E FAIL: Demo user has no ContactId');

// Manually resolve Person Contact (same logic as controller.resolvePersonContactForShiftAssignment)
Contact primary = [SELECT Id, Account.IsPersonAccount, AccountId FROM Contact WHERE Id = :demoUser.ContactId];
Id personContactId = primary.Account.IsPersonAccount ? primary.Id : null;
if (personContactId == null) {
    List<Account> pa = [SELECT PersonContactId FROM Account WHERE IsPersonAccount = true AND PersonEmail = :demoUser.Email LIMIT 1];
    personContactId = !pa.isEmpty() ? pa[0].PersonContactId : null;
}
System.assert(personContactId != null, 'E2E FAIL: Cannot resolve Person Contact');

// Find available shift, create assignment, verify, cleanup...
// (full pattern in scripts/apex/e2e-jamie-signup-simulation.apex)
```

---

### Approach B: Deployed Test Class with System.runAs() (Permission Testing)

Deploy a temporary `@IsTest` class that calls the actual controller methods inside `System.runAs(demoUser)`. This tests the real permission/sharing context.

**When to use**: When the demo step depends on the user's permission set granting access, or the controller uses `UserInfo.getUserId()` to resolve the running user (e.g., `VolunteerShiftSignupController` uses it to find `User.ContactId`).

**Step 1: Generate and deploy the test class**

```apex
@IsTest
private class E2E_DemoValidation_Temp {
    @IsTest
    static void testShiftSignupAsJamie() {
        User jamie = [SELECT Id FROM User WHERE Alias = 'JVolunte' AND IsActive = true LIMIT 1];

        // Find a shift to sign up for
        JobPositionShift shift = [
            SELECT Id FROM JobPositionShift
            WHERE StartDate >= TODAY AND Status = 'Published'
            ORDER BY StartDate ASC LIMIT 1
        ];

        Test.startTest();
        System.runAs(jamie) {
            // Call the ACTUAL controller method — runs with Jamie's permissions and UserInfo
            VolunteerShiftSignupController.SignupResult result =
                VolunteerShiftSignupController.registerForShift(shift.Id);
            System.assert(result.assignmentId != null, 'E2E FAIL: registerForShift returned null');

            // Verify assignment
            JobPositionAssignment assign = [
                SELECT AssignedContactId, Status, ScheduledStartTime
                FROM JobPositionAssignment WHERE Id = :result.assignmentId
            ];
            System.assertEquals('Upcoming', assign.Status);
            System.assert(assign.ScheduledStartTime != null);
            System.debug('E2E PASS: Shift sign-up as Jamie succeeded');
        }
        Test.stopTest();
        // Test framework auto-rolls back DML — no manual cleanup needed
    }

    @IsTest
    static void testIntakeAsGuest() {
        // Simulate guest intake (controller is "without sharing" so no user context needed)
        Map<String, String> result = VolunteerIntakeGuestController.submitVolunteer(
            'E2E_Test', 'Validation', 'e2e.test@example.com', '555-0199', 'Tutor', 'Altgeld-Murray'
        );
        System.assertEquals('SUCCESS', result.get('status'));
        System.debug('E2E PASS: Intake form submission succeeded');
        // Test framework auto-rolls back — Person Account + ApplicationForm + Applicant + Task cleaned up
    }

    @IsTest
    static void testCoordinatorViewsApplication() {
        User coordinator = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(coordinator) {
            // Verify coordinator can see ApplicationForm records
            List<ApplicationForm> forms = [SELECT Id, Title, ApplicationStatus FROM ApplicationForm LIMIT 5];
            System.assert(!forms.isEmpty(), 'E2E FAIL: Coordinator cannot see ApplicationForm records');
            System.debug('E2E PASS: Coordinator can view ' + forms.size() + ' application forms');
        }
    }
}
```

**Step 2: Deploy the test class**

```bash
sf project deploy start --source-dir [temp-test-dir] --target-org [alias]
```

**Step 3: Run the test class**

```bash
sf apex run test --class-names E2E_DemoValidation_Temp --result-format json --target-org [alias] --wait 5
```

Parse results for PASS/FAIL per method. The test framework **automatically rolls back all DML** — no manual cleanup needed.

**Step 4: Clean up the test class**

```bash
sf project deploy start --metadata ApexClass:E2E_DemoValidation_Temp --destructive-changes [destructive-xml] --target-org [alias]
```

Or leave it deployed (it's harmless and can be re-run for re-validation).

---

### Approach C: REST API with User Session (Controller + Permission Testing)

Obtain a session token for a specific demo user, then call `@AuraEnabled` controller methods via the Aura REST endpoint. This tests the EXACT call path the LWC uses, with the user's full permission and `UserInfo` context.

**When to use**: When you need to verify the full stack (LWC → controller → DML) with the demo user's actual session, or when Approach B is not feasible (e.g., no test class deployment allowed).

**Step 1: Get a session for the demo user**

Use the admin's session to "login as" the demo user:

```bash
sf org open --url-only --target-org [alias] --json
```

Then use Anonymous Apex to get a frontdoor URL for the demo user:

```apex
User demoUser = [SELECT Id, Username FROM User WHERE Alias = '[UserAlias]' LIMIT 1];
String loginAsUrl = URL.getOrgDomainURL().toExternalForm()
    + '/servlet/servlet.su?oid=' + UserInfo.getOrganizationId()
    + '&suorgadminid=' + UserInfo.getUserId()
    + '&targetURL=%2F&retURL=%2F'
    + '&sid=' + UserInfo.getSessionId();
System.debug('LOGIN_AS_URL: ' + loginAsUrl);
```

**Step 2: Call @AuraEnabled methods via Aura REST**

With the demo user's session, call the controller:

```bash
curl -X POST "[orgUrl]/aura?r=1" \
  -H "Authorization: Bearer [userSessionId]" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data "message={...}&aura.context={...}&aura.token=[token]"
```

Or use Playwright to navigate and interact with the LWC directly in the browser.

**Step 3: Verify outcomes via the same user session or admin SOQL**

---

### Multi-User Orchestration

For demos that require **multiple user contexts** (e.g., guest applies → coordinator reviews → member signs up), orchestrate simulations across users:

```
1. Simulate as GUEST (Approach A): Submit intake form
   → Verify: ApplicationForm + Applicant + Person Account + Task created
   → DO NOT clean up yet (coordinator needs to see it)

2. Simulate as COORDINATOR (Approach B or A): Review the application
   → Verify: Coordinator can see ApplicationForm in list view
   → Update ApplicationStatus to "Approved"
   → Verify: Record-triggered flow fires (Task reassigned, email sent)

3. Simulate as JAMIE (Approach B): Sign up for a shift
   → Verify: registerForShift succeeds with Jamie's permissions
   → Verify: JobPositionAssignment created with correct Person Account

4. CLEANUP: Delete all test records in reverse dependency order
   → Assignment → ApplicationForm → Applicant → Task → Person Account
```

This mirrors the demo's actual presenter flow across Acts 2–4.

### Cleanup Strategy

E2E simulations must ALWAYS clean up after themselves:

1. **Approach B (test class)**: Cleanup is automatic — the test framework rolls back all DML
2. **Approach A/C**: Delete created records in reverse order (children before parents)
3. **Use a test prefix** if creating named records (e.g., `e2e.test@` email prefix) so cleanup can catch stragglers
4. **Wrap in try/finally** to ensure cleanup runs even on failure:
```apex
Id createdId;
try {
    createdId = SomeController.createRecord(...);
    // ... assertions ...
} finally {
    if (createdId != null) {
        Database.delete(createdId, false);
    }
}
```
5. **Multi-user sequences**: When simulations chain across users (guest → coordinator → member), cleanup must wait until ALL steps complete. Track all created IDs in a list and delete in bulk at the end.

### Result Interpretation

| Result | Condition | Action |
|--------|-----------|--------|
| **E2E PASS** | Controller method succeeded, outcomes verified, cleanup done | Mark step as passing |
| **E2E FAIL - Permission** | User lacks access to controller, object, or field | Check permission sets via Approach B to pinpoint the missing permission |
| **E2E FAIL - Data** | No records available for the action (e.g., no shifts) | Run data fix first, then re-simulate |
| **E2E FAIL - Logic** | Controller threw an exception or returned unexpected result | Check controller code, fix via sf-apex |
| **E2E FAIL - UserInfo** | Controller couldn't resolve the user's ContactId or Account | Check User.ContactId, Person Account provisioning |
| **E2E FAIL - Cleanup** | Simulation succeeded but cleanup failed | Report but mark simulation as passing |

---

## Intake Simulation (Guest Apply)

**Goal**: Execute the guest intake form submission end-to-end via Anonymous Apex, verifying the full trigger chain (ApplicationForm → Applicant → Person Account → Task) that the presenter demonstrates in Acts 2–3.

### When to Use

Intake simulation validates the **guest apply path** — the demo's first transactional moment. It proves that when a guest submits the intake form, the entire automation chain fires correctly: records are created, Person Account is matched/created, and a Task lands in the coordinator's queue.

### Build Intake Simulation Apex

```apex
System.debug('=== INTAKE SIMULATION START ===');

// Step 1: Submit via the guest controller (same as the LWC would call)
String testEmail = 'e2e.intake.test.' + DateTime.now().getTime() + '@example.com';
Map<String, String> result = VolunteerIntakeGuestController.submitVolunteer(
    'E2E_Test',
    'IntakeValidation',
    testEmail,
    '555-0199',
    'Tutor',
    'Altgeld-Murray'
);
System.assert(result.get('status') == 'SUCCESS', 'INTAKE FAIL: submitVolunteer returned ' + result.get('status'));
Id formId = Id.valueOf(result.get('applicationFormId'));
Id applicantId = Id.valueOf(result.get('applicantId'));
System.debug('INTAKE STEP 1 PASS: ApplicationForm=' + formId + ', Applicant=' + applicantId);

// Step 2: Verify ApplicationForm fields
ApplicationForm form = [SELECT Id, RecordType.DeveloperName, UsageType, ApplicationStatus, AccountId
                        FROM ApplicationForm WHERE Id = :formId];
System.assertEquals('Volunteer', form.UsageType, 'INTAKE FAIL: Wrong UsageType');
System.assertEquals('Submitted', form.ApplicationStatus, 'INTAKE FAIL: Wrong status');
System.debug('INTAKE STEP 2 PASS: RT=' + form.RecordType.DeveloperName + ', UsageType=' + form.UsageType);

// Step 3: Verify Applicant linked to Person Account
Applicant app = [SELECT Id, AccountId, ContactId, Email FROM Applicant WHERE Id = :applicantId];
System.assert(app.AccountId != null, 'INTAKE FAIL: Applicant not linked to Account');
System.assert(app.ContactId != null, 'INTAKE FAIL: Applicant not linked to Contact');
System.debug('INTAKE STEP 3 PASS: AccountId=' + app.AccountId + ', ContactId=' + app.ContactId);

// Step 4: Verify ApplicationForm also linked to same Account
ApplicationForm formRefresh = [SELECT AccountId FROM ApplicationForm WHERE Id = :formId];
System.assertEquals(app.AccountId, formRefresh.AccountId, 'INTAKE FAIL: Form AccountId mismatch');
System.debug('INTAKE STEP 4 PASS: ApplicationForm.AccountId matches Applicant.AccountId');

// Step 5: Verify Person Account created
Account pa = [SELECT Id, IsPersonAccount, PersonEmail FROM Account WHERE Id = :app.AccountId];
System.assert(pa.IsPersonAccount, 'INTAKE FAIL: Account is not a Person Account');
System.debug('INTAKE STEP 5 PASS: Person Account verified, email=' + pa.PersonEmail);

// Step 6: Verify Task created for Volunteer_Review queue
List<Task> tasks = [SELECT Id, Subject, OwnerId, Owner.Name FROM Task
                    WHERE WhatId = :formId AND Subject LIKE '%New volunteer application%'];
System.assert(!tasks.isEmpty(), 'INTAKE FAIL: No Task created for coordinator queue');
System.debug('INTAKE STEP 6 PASS: Task created, Owner=' + tasks[0].Owner.Name);

// Cleanup: delete in reverse dependency order
try {
    delete tasks;
    delete [SELECT Id FROM Applicant WHERE Id = :applicantId];
    delete [SELECT Id FROM ApplicationForm WHERE Id = :formId];
    delete [SELECT Id FROM Account WHERE Id = :app.AccountId AND PersonEmail = :testEmail];
    System.debug('INTAKE CLEANUP PASS: All test records deleted');
} catch (Exception e) {
    System.debug('INTAKE CLEANUP WARNING: ' + e.getMessage());
}

System.debug('=== INTAKE SIMULATION COMPLETE ===');
```

### Execute Intake Simulation

```bash
sf apex run --file scripts/apex/e2e-intake-simulation.apex --target-org [alias]
```

Parse output for `INTAKE STEP [n] PASS` and `INTAKE FAIL` markers.

### Result Interpretation

| Result | Condition | Action |
|--------|-----------|--------|
| **All 6 steps PASS** | Full trigger chain fires | Mark intake simulation as passing |
| **STEP 1 FAIL** | Controller threw exception | Check `VolunteerIntakeGuestController`, `VolunteerIntakeService`, ApplicationForm RT |
| **STEP 3 FAIL** | Applicant not linked to Account | Check `NpcVolunteerApplicantService.handleAfterInsert`, Person Account RT, trigger |
| **STEP 4 FAIL** | Form AccountId mismatch | Check `syncApplicationFormsFromApplicants` in the service |
| **STEP 5 FAIL** | Not a Person Account | Verify Person Accounts are enabled in the org |
| **STEP 6 FAIL** | No Task created | Check `Volunteer_Review` queue exists, `resolveTaskOwnerId()` |
| **CLEANUP WARNING** | Non-blocking | Report but mark simulation as passing |

---

## Flow Execution & Automation Chain Testing

**Goal**: Go beyond checking that flows/triggers exist — actually fire them and verify their side effects.

### Record-Triggered Flow/Trigger Verification

To verify a record-triggered flow or trigger fires correctly:

1. **Insert or update a test record** that matches the trigger criteria
2. **Query for expected side effects** (new records, field updates, Tasks, platform events)
3. **Clean up** the test record and side effects

**Pattern — Verify Applicant Trigger Chain**:

```apex
System.debug('=== TRIGGER CHAIN TEST START ===');

// Create a test application (this fires the Applicant trigger via VolunteerIntakeService)
Map<String, String> result = VolunteerIntakeGuestController.submitVolunteer(
    'TriggerTest', 'Validation', 'trigger.test.' + DateTime.now().getTime() + '@example.com',
    '555-0100', 'Tutor', 'Altgeld-Murray'
);
Id formId = Id.valueOf(result.get('applicationFormId'));
Id applicantId = Id.valueOf(result.get('applicantId'));

// Verify trigger side effect 1: Applicant linked to Person Account
Applicant app = [SELECT AccountId, ContactId FROM Applicant WHERE Id = :applicantId];
System.assert(app.AccountId != null, 'TRIGGER FAIL: Applicant not linked to Account');
System.debug('TRIGGER PASS: Applicant → Person Account link');

// Verify trigger side effect 2: ApplicationForm linked to same Account
ApplicationForm form = [SELECT AccountId FROM ApplicationForm WHERE Id = :formId];
System.assertEquals(app.AccountId, form.AccountId, 'TRIGGER FAIL: Form AccountId mismatch');
System.debug('TRIGGER PASS: ApplicationForm → Account link');

// Verify trigger side effect 3: Task created for coordinator queue
List<Task> tasks = [SELECT Id, OwnerId, Owner.Name FROM Task WHERE WhatId = :formId];
System.assert(!tasks.isEmpty(), 'TRIGGER FAIL: No Task created');
System.debug('TRIGGER PASS: Task created, owner=' + tasks[0].Owner.Name);

// Cleanup
delete tasks;
delete [SELECT Id FROM Applicant WHERE Id = :applicantId];
delete [SELECT Id FROM ApplicationForm WHERE Id = :formId];
delete [SELECT Id FROM Account WHERE Id = :app.AccountId];
System.debug('=== TRIGGER CHAIN TEST COMPLETE ===');
```

### Screen Flow Invocation via REST API

To invoke a Screen Flow (or Autolaunched Flow) programmatically and verify its outputs:

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint(URL.getOrgDomainURL().toExternalForm()
    + '/services/data/v62.0/actions/custom/flow/Acme_Volunteer_Intake');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setBody(JSON.serialize(new Map<String, Object>{
    'inputs' => new List<Object>{
        new Map<String, Object>{
            'firstName' => 'FlowTest',
            'lastName' => 'Validation',
            'email' => 'flow.test@example.com',
            'phone' => '555-0101',
            'interestedRole' => 'Tutor',
            'preferredSite' => 'Altgeld-Murray'
        }
    }
}));
Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Flow invocation response: ' + res.getStatusCode() + ' ' + res.getBody());

// Verify the flow's side effects
if (res.getStatusCode() == 200) {
    // Parse response for output variables
    Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    System.debug('FLOW PASS: Flow executed successfully');
    // Query for flow-created records and verify...
} else {
    System.debug('FLOW FAIL: HTTP ' + res.getStatusCode());
}

// Cleanup flow-created records...
```

### Automation Chain Verification Pattern

For complex chains (insert → trigger → flow → secondary DML → notification), verify each link:

```apex
// Step 1: Create trigger input
insert testRecord;

// Step 2: Verify immediate trigger effects (synchronous)
TestRecord refreshed = [SELECT TriggerField__c FROM TestObject WHERE Id = :testRecord.Id];
System.assert(refreshed.TriggerField__c != null, 'CHAIN FAIL: Trigger did not update field');

// Step 3: Verify flow effects (may be async — add brief delay or query with retry)
List<Task> flowTasks = [SELECT Id FROM Task WHERE WhatId = :testRecord.Id];
System.assert(!flowTasks.isEmpty(), 'CHAIN FAIL: Flow did not create Task');

// Step 4: Verify final state
// ... check all expected downstream records exist ...

// Cleanup in reverse dependency order
```

### Flow Test Framework (Preferred — Run Before Side-Effect Simulation)

The most reliable way to validate a flow is an authored `.flowtest-meta.xml`. Run them via the unified runner (preferred for CI):

```bash
sf logic run test --tests "FlowTesting.<flow-test-name>" --target-org [alias] --synchronous --code-coverage --json
# or legacy runner:
sf flow run test --tests <FlowTestName> --target-org [alias] --json
```

Parse results for pass/fail. **If no FlowTest covers the behavior the demo step claims, author one before validation** — see [sf-flow/references/flow-test-authoring.md](../../sf-flow/references/flow-test-authoring.md) for schema + verified examples. Files live at `force-app/main/default/flowtests/<Flow>_<Test>.flowtest-meta.xml`. Authoring path: Setup → Flow → Debug → Convert to Test → `sf project retrieve start --metadata FlowTest:<Flow>.<Test>`.

---

## Coordinator Simulation (Internal User Path)

**Goal**: Simulate the internal coordinator's demo workflow — opening the app, viewing applications, reviewing records, and updating status — to verify the CRM side of the demo works.

### Coordinator User Resolution

```bash
sf data query --query "SELECT Id, Username, Profile.Name, IsActive FROM User WHERE Username = '[coordinatorUsername]' AND IsActive = true" --target-org [alias] --json
```

If the demoscript says "your sandbox admin", use the current CLI user. Verify the `Acme Volunteer Coordinator` perm set is assigned.

### App and Tab Accessibility

Verify the coordinator's perm set grants access to the app and its tabs:

```bash
sf data query --query "SELECT Id, PermissionSet.Name FROM PermissionSetAssignment WHERE Assignee.Username = '[coordinatorUsername]' AND PermissionSet.Name = 'Acme_Volunteer_Coordinator'" --target-org [alias] --json
```

Then verify the app exists and contains expected tabs:

```bash
sf project retrieve start --metadata CustomApplication:Acme_Volunteer_Demo --target-org [alias] --output-dir temp-retrieve --json
```

### List View Data Verification

Verify the list view the coordinator would use shows data:

```bash
sf data query --query "SELECT Id, Title, ApplicationStatus, AccountId FROM ApplicationForm WHERE UsageType = 'Volunteer' ORDER BY CreatedDate DESC LIMIT 10" --target-org [alias] --json
```

Pass: At least 1 row with `ApplicationStatus = 'Submitted'` (something for the coordinator to review). Fail: No applications to demonstrate.

### Record Page Data Verification

Verify a demo-ready ApplicationForm record has complete data:

```bash
sf data query --query "SELECT Id, Title, ApplicationStatus, UsageType, AccountId, Account.Name, (SELECT Id, FirstName, LastName, Email FROM Applicants) FROM ApplicationForm WHERE UsageType = 'Volunteer' AND ApplicationStatus = 'Submitted' LIMIT 1" --target-org [alias] --json
```

Pass: Record has a linked Account (Person Account) and at least one Applicant with name/email. Fail: Incomplete record would confuse the presenter.

### Status Update Simulation (Act 3)

Simulate the coordinator updating the application status and verify automation fires:

```apex
System.debug('=== COORDINATOR SIM START ===');

// Find a Submitted application to approve
ApplicationForm form = [
    SELECT Id, ApplicationStatus, Title
    FROM ApplicationForm
    WHERE UsageType = 'Volunteer' AND ApplicationStatus = 'Submitted'
    ORDER BY CreatedDate DESC LIMIT 1
];
String originalStatus = form.ApplicationStatus;
System.debug('COORD STEP 1: Found application — ' + form.Title);

// Update status to Approved (same as coordinator would do)
form.ApplicationStatus = 'Approved';
update form;
System.debug('COORD STEP 2: Status updated to Approved');

// Verify any record-triggered flow side effects
// (e.g., Task reassigned, email acknowledgment sent)
List<Task> flowTasks = [
    SELECT Id, Subject, Status, OwnerId, Owner.Name
    FROM Task
    WHERE WhatId = :form.Id AND CreatedDate = TODAY
    ORDER BY CreatedDate DESC
];
if (!flowTasks.isEmpty()) {
    System.debug('COORD STEP 3 PASS: Flow created ' + flowTasks.size() + ' task(s)');
} else {
    System.debug('COORD STEP 3 INFO: No flow-triggered tasks found (flow may not be configured for status change)');
}

// Roll back status to preserve demo state
form.ApplicationStatus = originalStatus;
update form;
System.debug('COORD CLEANUP: Status rolled back to ' + originalStatus);

System.debug('=== COORDINATOR SIM COMPLETE ===');
```

### Coordinator Simulation via Deployed Test Class (Approach B)

For permission-context testing, deploy a test class:

```apex
@IsTest
private class E2E_CoordinatorValidation_Temp {
    @IsTest
    static void testCoordinatorCanViewAndUpdateApplications() {
        // Use the actual coordinator user (or a user with the coordinator perm set)
        User coord = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(coord) {
            // Verify coordinator can query ApplicationForm
            List<ApplicationForm> forms = [SELECT Id, Title, ApplicationStatus FROM ApplicationForm WHERE UsageType = 'Volunteer' LIMIT 5];
            System.assert(!forms.isEmpty(), 'Coordinator cannot see ApplicationForm records');

            // Verify coordinator can update status
            if (!forms.isEmpty()) {
                forms[0].ApplicationStatus = 'Approved';
                update forms[0];
                System.debug('COORD PASS: Coordinator can update ApplicationStatus');
            }
            // Auto-rollback by test framework
        }
    }
}
```

---

## Dashboard

**Goal**: Verify that reports, custom report types, and dashboards exist and display data.

### Report Type Existence

```bash
sf data query --query "SELECT Id, DeveloperName, Label FROM ReportType WHERE DeveloperName = '[ReportTypeDevName]'" --target-org [alias] --json --use-tooling-api
```

### Report Existence

```bash
sf data query --query "SELECT Id, Name, DeveloperName, FolderName FROM Report WHERE DeveloperName = '[ReportDevName]'" --target-org [alias] --json
```

### Dashboard Existence

```bash
sf data query --query "SELECT Id, Title, DeveloperName, FolderName FROM Dashboard WHERE DeveloperName = '[DashboardDevName]'" --target-org [alias] --json
```

### Dashboard Component Verification

After confirming the dashboard exists, verify it has the expected components:

```bash
sf data query --query "SELECT Id, Name FROM DashboardComponent WHERE DashboardId = '[DashboardId]'" --target-org [alias] --json --use-tooling-api
```

### Fallback: Creation via Analytics REST API

When direct metadata deployment of reports fails (common with NPC/Industry Cloud objects like `JobPositionAssignment` or `JobPositionShift`), use a 2-step approach:

1. **Deploy custom report types via Metadata API** (these DO deploy successfully — use relationship names for lookup fields, e.g., `AssignedContact` not `AssignedContactId`)
2. **Create reports and dashboards via Analytics REST API** using the deployed report types

**CRITICAL**: Custom report types use a `__c` suffix in the REST API. A report type deployed as `Acme_Volunteer_Assignments` is referenced as `Acme_Volunteer_Assignments__c` in the API.

**CRITICAL**: Lookup column references need the dotted `.Name` format (e.g., `JobPositionAssignment.AssignedContact.Name`). Discover valid columns via the describe endpoint: `GET /services/data/v62.0/analytics/report-types/[TypeName__c]`.

```apex
// Step 1: Create folder (use /folders not /analytics/folders)
HttpRequest req = new HttpRequest();
req.setEndpoint(URL.getOrgDomainURL().toExternalForm() + '/services/data/v62.0/folders');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setBody('{"label":"Acme Volunteer Reports","name":"Acme_Volunteer_Reports","type":"report"}');
Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Folder: ' + res.getBody());
```

> Full Analytics REST API fix patterns: [fix-strategies.md](fix-strategies.md)

---

## Agentforce

**Goal**: Verify that Agentforce agents are deployed, configured with topics and actions, and functioning correctly.

### Agent Metadata Existence

```bash
sf data query --query "SELECT Id, DeveloperName, MasterLabel FROM GenAiPlugin WHERE DeveloperName = '[AgentDevName]'" --target-org [alias] --json --use-tooling-api
```

Pass: Returns 1 row. Fail: Agent not deployed.

### Agent Topics and Actions

```bash
sf data query --query "SELECT Id, DeveloperName, MasterLabel FROM GenAiFunction WHERE DeveloperName LIKE '[AgentPrefix]%'" --target-org [alias] --json --use-tooling-api
```

Cross-reference against the demoscript to verify all expected topics/actions are present.

### PromptTemplate Existence

```bash
sf project retrieve start --metadata PromptTemplate:[TemplateName] --target-org [alias] --json
```

Pass: Retrieve succeeds. Fail: Template not deployed — agent will not respond correctly.

### Agent Channel Configuration

Verify the agent is assigned to the correct channel (Experience Cloud, Slack, etc.):

```bash
sf data query --query "SELECT Id, DeveloperName, MasterLabel FROM GenAiPlugin WHERE IsActive = true" --target-org [alias] --json --use-tooling-api
```

### Agent Testing (Optional Deep Validation)

If agent test specs exist in the project, delegate to `sf-ai-agentforce-testing`:

```
Glob: **/*.agentTest-meta.xml
Glob: **/agent-test-specs/**
```

If found, run the test suite and parse results for topic routing accuracy and action execution success.

---

## Data Cloud

**Goal**: Verify that the Data Cloud pipeline is configured, data is flowing, and segments/activations are healthy.

### Data Cloud Enablement

```bash
sf data query --query "SELECT Id FROM DataSpace LIMIT 1" --target-org [alias] --json
```

Pass: Returns rows (Data Cloud is provisioned). Fail: Data Cloud not enabled in this org.

### Data Streams

Use the Data Cloud REST API or `sf data360` CLI commands:

```bash
sf data query --query "SELECT Id, Name, Status FROM DataStream WHERE Name = '[StreamName]'" --target-org [alias] --json
```

Or use the Ingestion API endpoint to check stream health. Delegate to `sf-datacloud-prepare` for detailed stream validation.

### Data Model Objects (DMOs)

```bash
sf data query --query "SELECT Id, QualifiedApiName, Label FROM EntityDefinition WHERE QualifiedApiName LIKE '%__dll'" --target-org [alias] --json --use-tooling-api
```

Verify the expected DMOs exist and have field mappings. Delegate to `sf-datacloud-harmonize` for mapping validation.

### Identity Resolution

Verify rulesets exist and unified profiles are generating:

```bash
sf data query --query "SELECT Id, Name FROM IdentityResolutionRuleset LIMIT 5" --target-org [alias] --json
```

Delegate to `sf-datacloud-harmonize` for deeper identity resolution checks.

### Segments

```bash
sf data query --query "SELECT Id, Name, Status, MemberCount FROM Segment WHERE Name = '[SegmentName]'" --target-org [alias] --json
```

Pass: Segment exists, Status = 'Published', MemberCount > 0. Fail: Missing, not published, or empty.

Delegate to `sf-datacloud-segment` for segment SQL validation and count verification.

### Activations

Verify activation targets are configured and connected:

```bash
sf data query --query "SELECT Id, Name, Status FROM ActivationTarget WHERE Name = '[TargetName]'" --target-org [alias] --json
```

Delegate to `sf-datacloud-act` for activation health checks.

### Data Cloud Query Verification

Run a Data Cloud SQL query to verify data is accessible:

```bash
sf data360 query --sql "SELECT COUNT(*) FROM [DMO_Name]__dll" --target-org [alias] --json
```

Pass: Returns non-zero count. Fail: 0 rows or query error.

---

## Slack

**Goal**: Verify the Salesforce-side Slack integration is configured. Slack workspace-side validation requires Slack API access and is escalated.

### Slack Connected App

```bash
sf data query --query "SELECT Id, Name, ContactEmail FROM ConnectedApplication WHERE Name LIKE '%Slack%'" --target-org [alias] --json --use-tooling-api
```

Pass: Returns a Slack-related connected app. Fail: No Slack app configured.

### Slack Integration Package

```bash
sf package installed list --target-org [alias] --json
```

Check for packages containing "Slack" in the name. Many Slack integrations require the Salesforce for Slack managed package.

### Slack Notification Flow/Automation

If the demoscript references Slack notifications, verify the automation exists:

```bash
sf data query --query "SELECT Id, ApiName, IsActive FROM FlowDefinitionView WHERE ApiName LIKE '%Slack%' AND IsActive = true" --target-org [alias] --json --use-tooling-api
```

### Slack-Specific Custom Settings/Metadata

```bash
sf data query --query "SELECT Id, DeveloperName FROM CustomMetadataType WHERE DeveloperName LIKE '%Slack%'" --target-org [alias] --json --use-tooling-api
```

### Escalation Boundary

**Cannot validate from Salesforce**: Slack workspace permissions, channel existence, bot scopes, Slack workflow builder configs. Report these as requiring manual Slack admin verification.

---

## Marketing Cloud

**Goal**: Verify the Salesforce-side Marketing Cloud integration is configured. MC-side journey and content validation requires MC API access and is escalated.

### MC Connector Package

```bash
sf package installed list --target-org [alias] --json
```

Check for packages containing "Marketing Cloud" or "ExactTarget" in the name.

### MC Connected App

```bash
sf data query --query "SELECT Id, Name FROM ConnectedApplication WHERE Name LIKE '%Marketing%' OR Name LIKE '%ExactTarget%'" --target-org [alias] --json --use-tooling-api
```

### MC Synchronized Objects

Verify objects configured for MC sync:

```bash
sf data query --query "SELECT Id, Name FROM MCSyncObject__mdt" --target-org [alias] --json
```

Or check via the MC connector configuration in Setup.

### Journey Entry Source Data

If the demoscript says "contact submits form → triggers MC journey", verify the trigger data exists:

```bash
sf data query --query "SELECT COUNT() FROM [Object] WHERE [TriggerConditions]" --target-org [alias] --json
```

### Email Templates (Salesforce-side)

```bash
sf data query --query "SELECT Id, Name, DeveloperName, FolderId FROM EmailTemplate WHERE DeveloperName = '[TemplateName]'" --target-org [alias] --json
```

### Escalation Boundary

**Cannot validate from Salesforce**: MC journey status, email content/rendering, audience builder segments, send classification, delivery profiles. Report these as requiring MC admin verification.

---

## Tableau / CRM Analytics

**Goal**: Verify CRM Analytics (Tableau CRM / Einstein Analytics) apps, datasets, dataflows, and dashboards are deployed and contain data.

### Analytics App Existence

```bash
sf data query --query "SELECT Id, Name, DeveloperName, Type FROM Folder WHERE Type = 'Insights' AND DeveloperName = '[AppDevName]'" --target-org [alias] --json
```

### Dataset Existence and Row Count

Use the Wave REST API:

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint(URL.getOrgDomainURL().toExternalForm()
    + '/services/data/v62.0/wave/datasets/[DatasetId]');
req.setMethod('GET');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Dataset: ' + res.getBody());
```

Pass: Dataset exists and `currentVersionLastModifiedDate` is recent. Fail: Dataset missing or stale.

### Dataflow Status

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint(URL.getOrgDomainURL().toExternalForm()
    + '/services/data/v62.0/wave/dataflows');
req.setMethod('GET');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Dataflows: ' + res.getBody());
```

Verify the expected dataflows exist, are scheduled, and have recent successful runs (no `Failed` status).

### Analytics Dashboard Existence

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint(URL.getOrgDomainURL().toExternalForm()
    + '/services/data/v62.0/wave/dashboards?q=[DashboardName]');
req.setMethod('GET');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Dashboard: ' + res.getBody());
```

### Analytics Dashboard Visual Check

Use Playwright to navigate to the analytics dashboard URL and capture a screenshot:

```bash
sf org open --url-only --target-org [alias] --path "/analytics/dashboard/[DashboardId]" --json
```

Then screenshot and verify charts/tables render with data (not empty or error states).

### Recipe Status (Data Prep)

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint(URL.getOrgDomainURL().toExternalForm()
    + '/services/data/v62.0/wave/recipes');
req.setMethod('GET');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Recipes: ' + res.getBody());
```

### Tableau Cloud/Server Embed (if applicable)

If the demo embeds Tableau Cloud or Server dashboards, verify the embed configuration:

```bash
sf data query --query "SELECT Id, Name FROM ConnectedApplication WHERE Name LIKE '%Tableau%'" --target-org [alias] --json --use-tooling-api
```

Tableau-side dashboard existence and data freshness is escalated for manual verification.

---

## OmniStudio

**Goal**: Verify OmniStudio components (OmniScripts, FlexCards, Integration Procedures, Data Mappers) are deployed and active.

### Namespace Detection

Before querying OmniStudio objects, detect the namespace. Delegate to `sf-industry-commoncore-omnistudio-analyze`:

```bash
sf data query --query "SELECT NamespacePrefix FROM ApexClass WHERE Name = 'OmniProcess' LIMIT 1" --target-org [alias] --json --use-tooling-api
```

Namespace determines object/field prefixes: `omnistudio__` (Core), `vlocity_cmt__` (Communications), `vlocity_ins__` (Insurance).

### OmniScript Existence and Active Status

```bash
sf data query --query "SELECT Id, [ns]Type__c, [ns]SubType__c, [ns]Language__c, [ns]IsActive__c, [ns]Version__c FROM [ns]OmniProcess__c WHERE [ns]Type__c = '[Type]' AND [ns]SubType__c = '[SubType]' AND [ns]IsActive__c = true ORDER BY [ns]Version__c DESC LIMIT 1" --target-org [alias] --json
```

Replace `[ns]` with the detected namespace prefix.

Pass: Returns 1 active row. Fail: OmniScript missing or inactive.

### FlexCard Existence

```bash
sf data query --query "SELECT Id, Name, [ns]IsActive__c FROM [ns]OmniUiCard__c WHERE Name = '[CardName]' AND [ns]IsActive__c = true" --target-org [alias] --json
```

### Integration Procedure Existence

```bash
sf data query --query "SELECT Id, [ns]Type__c, [ns]SubType__c, [ns]IsActive__c FROM [ns]OmniProcess__c WHERE [ns]Type__c = 'Integration Procedure' AND [ns]SubType__c = '[IPName]' AND [ns]IsActive__c = true" --target-org [alias] --json
```

### Data Mapper Existence

```bash
sf data query --query "SELECT Id, Name, [ns]Type__c FROM [ns]OmniDataTransform__c WHERE Name = '[MapperName]'" --target-org [alias] --json
```

### OmniStudio Visual Check

Use Playwright to load the OmniScript or FlexCard preview URL and verify it renders:

```bash
sf org open --url-only --target-org [alias] --path "/lightning/cmp/[ns]__omniscriptPreview?type=[Type]&subType=[SubType]&language=[Language]" --json
```

Screenshot and verify the component renders with data, no error panels, and correct step progression.

---

## Visual Validation

**Goal**: Capture a screenshot of the Salesforce page and visually verify that the UI matches the expected state described in the demo step.

Visual validation triggers when a step includes a `**Visual**` block or a `<!-- visual: true -->` tag. It runs **after** the SOQL/metadata checks for that step.

### Prerequisites Check

Before attempting visual validation, verify Playwright is available:

```bash
node -e "require('playwright')" 2>/dev/null && echo "OK" || echo "MISSING"
```

If missing, report:
```
VISUAL SKIP: Playwright not installed. Run: npm install playwright && npx playwright install chromium
```

Continue with non-visual validation -- do not fail the step.

### Step 1: Get Authenticated URL

```bash
sf org open --url-only --target-org [alias] --path "[visual_path]" --json
```

The `visual_path` comes from the step's `<!-- visual_path: ... -->` tag. If no tag is present, construct the path from the step description:

| Step Description | Inferred Path |
|-----------------|---------------|
| "Open [AppName] app" | `/lightning/app/[AppDevName]` |
| "View [Object] list" | `/lightning/o/[ObjectApiName]/list` |
| "Open record [Name]" | Query for ID, then `/lightning/r/[Object]/[Id]/view` |
| "Go to Setup" | `/lightning/setup/SetupOneHome/home` |

Parse the JSON response to extract `result.url`.

### Step 2: Capture Screenshot

```bash
node [skill-path]/scripts/screenshot.js "[url]" "screenshots/step-[n].png"
```

Optional arguments:
- Viewport width (default 1920)
- Viewport height (default 1080)
- CSS selector to wait for before capturing (e.g., `lightning-app-builder` or `.slds-page-header`)

The script:
1. Launches headless Chromium
2. Navigates with `waitUntil: 'networkidle'`
3. Waits an additional 3 seconds for Lightning component rendering
4. Optionally waits for a specific CSS selector
5. Saves the screenshot as PNG
6. Returns JSON with `{ success: true, path: "..." }` or `{ success: false, error: "..." }`

### Step 3: Analyze Screenshot

Read the saved PNG using the Read tool (which natively supports image files):

```
Read: screenshots/step-[n].png
```

Compare the screenshot against the visual expectations:

**If the step has a `**Visual**` block**, check each bullet point:
- Are the described components/sections visible?
- Are the layouts and positioning correct?
- Are the expected data values shown?
- Are there any error messages, broken components, or empty sections?

**If the step has `<!-- visual: true -->` only**, use the `**Expected**` text as the visual criteria.

### Step 4: Record Result

| Result | Condition | Action |
|--------|-----------|--------|
| **VISUAL PASS** | Screenshot matches all visual expectations | Mark step visual check as passing |
| **VISUAL FAIL** | Screenshot shows missing components, wrong layout, errors, or blank areas | Report with screenshot path and description of mismatch |
| **VISUAL SKIP** | Playwright not installed or screenshot failed | Report skip reason, do not fail the step |
| **VISUAL ERROR** | URL generation or browser launch failed | Report error details |

Visual failures are always reported but **never auto-fixed** -- they require manual UI changes (Lightning App Builder, page layout editor, component placement).

### Lightning-Specific Wait Strategies

Salesforce Lightning pages load asynchronously. The screenshot script handles this with `networkidle` + a 3-second buffer, but for specific components you can add a `wait_selector` to the visual_path tag:

```markdown
<!-- visual_path: /lightning/r/Case/[Id]/view -->
<!-- wait_selector: .knowledge-sidebar -->
```

Common selectors for Lightning components:

| Component | Selector |
|-----------|----------|
| Record page loaded | `records-record-layout-section` |
| List view loaded | `lightning-list-view-table` |
| Related list | `lst-related-list-single-container` |
| Highlights panel | `records-highlights-details` |
| Page header | `.slds-page-header` |

---

## Result Interpretation

For all checks, classify results as:

| Result | Condition | Action |
|--------|-----------|--------|
| **PASS** | Query returns expected rows/values; retrieve succeeds | Mark step as passing |
| **FAIL - Missing** | Query returns 0 rows; retrieve fails | Route to fix strategy |
| **FAIL - Inactive** | Item exists but is inactive (flow, trigger, validation rule) | Route to activation fix |
| **FAIL - Wrong Value** | Item exists but field values don't match expected | Report discrepancy, do not overwrite |
| **FAIL - Access Denied** | Query fails with insufficient access | Check running user permissions |
| **VISUAL FAIL** | Screenshot does not match visual expectations | Report with screenshot path; escalate (no auto-fix) |
| **VISUAL SKIP** | Playwright unavailable or screenshot failed | Log skip reason; do not fail the step |
| **ERROR** | Command itself fails (network, auth, syntax) | Report error, check org connection |

---

## Tooling API vs Standard API

Some objects require `--use-tooling-api`:

| Requires Tooling API | Standard API |
|----------------------|--------------|
| `FlowDefinitionView` | `Case`, `Account`, etc. (data objects) |
| `ApexTrigger`, `ApexClass` | `PermissionSetAssignment` |
| `LightningComponentBundle` | `ObjectPermissions`, `FieldPermissions` |
| `AuraDefinitionBundle` | `RecordType` |
| `FlexiPage` | `NamedCredential` |
| `ValidationRule` | `Profile` |
| `Layout` | `PermissionSet` |
| `AppDefinition` | Standard/custom objects |
| `EntityDefinition`, `FieldDefinition` | |
| `ExternalServiceRegistration` | |
| `ConnectedApplication` | |
