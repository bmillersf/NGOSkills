# Fix Strategies by Issue Type

This document defines how `sf-demo-validate` autonomously repairs failing demo steps. Each issue type maps to a specific fix pattern and cross-skill delegation.

---

## Fix Loop Rules

1. **Max 3 iterations** -- after 3 fix-then-validate cycles, escalate remaining failures
2. **Deploy order matters** -- Objects/Fields --> Permission Sets --> Apex --> Flows (Draft) --> Activate Flows --> Data
3. **Always dry-run first** -- `sf project deploy start --dry-run` before real deploy
4. **Never overwrite unknowns** -- if something exists but differs from the script, report it rather than clobber it
5. **Batch related fixes** -- deploy all metadata fixes in one operation when possible

---

## Fix Decision Tree

```
Step failed
  |
  ├── Platform prerequisite missing?
  |     ├── Person Accounts not enabled ----> BLOCKING: Escalate (requires org feature enable)
  |     ├── NPC object missing -------------> Escalate (requires Nonprofit Cloud package)
  |     ├── ApplicationForm RT missing -----> Create + deploy via sf-metadata
  |     ├── Custom field missing -----------> Create + deploy via sf-metadata
  |     ├── Queue missing ------------------> Create queue via Anonymous Apex or metadata
  |     └── Provisioner script missing -----> Report (check source control)
  |
  ├── Missing entirely?
  |     ├── Metadata (object/field/layout) --> Create + Deploy (sf-metadata, sf-deploy)
  |     ├── Data (records) -----------------> Insert records (sf-data)
  |     ├── Permission set -----------------> Create perm set + assign (sf-permissions, sf-deploy)
  |     ├── Component (LWC/Aura) -----------> Check local source, deploy (sf-lwc, sf-deploy)
  |     ├── Automation (flow/trigger) ------> Check local source, deploy + activate (sf-flow, sf-deploy)
  |     └── Integration (named cred) -------> Report (cannot auto-create credentials)
  |
  ├── Exists but inactive?
  |     ├── Flow ---------------------------> Activate via deploy (sf-deploy)
  |     ├── Trigger ------------------------> Deploy with Active status (sf-deploy)
  |     └── Validation rule ----------------> Activate via deploy (sf-deploy)
  |
  ├── Exists but wrong value?
  |     ├── Data field mismatch ------------> Update record (sf-data)
  |     ├── Config mismatch ----------------> Report (do not overwrite without confirmation)
  |     ├── Relationship missing -----------> Create/update lookup (sf-data)
  |     └── Jamie TimeZoneSidKey wrong -----> Update User via sf data update record
  |
  ├── Data quality / freshness?
  |     ├── Location fields incomplete -----> Update Location records with missing data (sf-data, Apex)
  |     ├── Shifts all expiring soon -------> Bump shift dates forward via Anonymous Apex
  |     ├── All shifts at 0 capacity -------> Increase MaximumAttendeesCount or clear to null (Apex)
  |     ├── Stale test data found ----------> Delete test ApplicationForms, Applicants, Assignments (Apex)
  |     └── Duplicate Jamie assignments ----> Delete stale assignments (Apex)
  |
  ├── Access denied?
  |     ├── FLS missing --------------------> Add to permission set (sf-permissions, sf-deploy)
  |     ├── Object access missing ----------> Add to permission set (sf-permissions, sf-deploy)
  |     ├── Perm set not assigned ----------> Assign via CLI (sf-permissions)
  |     ├── Perm set missing Apex class ----> Add class access to perm set XML, redeploy
  |     ├── Network member group wrong -----> Escalate (requires Experience site Setup)
  |     └── Profile issue ------------------> Report (never modify profiles directly)
  |
  ├── Apex / code health?
  |     ├── Class not compiling ------------> Fix code via sf-apex + deploy
  |     └── App tab config wrong -----------> Update app XML + deploy (sf-metadata)
  |
  ├── Dashboard/Report failed?
  |     ├── Report type deploy failed ------> Analytics REST API via Anonymous Apex
  |     ├── Report deploy failed -----------> Analytics REST API via Anonymous Apex
  |     ├── Dashboard deploy failed --------> Analytics REST API via Anonymous Apex
  |     └── REST API also failed -----------> Escalate with manual Setup steps
  |
  ├── Experience site issue?
  |     ├── Site not published -------------> Escalate (cannot publish via CLI)
  |     ├── Public URL unreachable ---------> Escalate (DNS, publish status, or site config)
  |     ├── Guest can't see data -----------> Fix guest profile Apex class access + sharing
  |     ├── Components not rendering -------> Deploy LWC bundles (sf-lwc, sf-deploy)
  |     ├── Member login fails ------------> Check Community license + site profile assignment
  |     └── Data not showing on page -------> Fix controller queries + data (sf-apex, sf-data)
  |
  ├── E2E simulation (shift sign-up) failed?
  |     ├── Permission denied in runAs -----> Add perms to demo user perm set (sf-permissions)
  |     ├── No data for action ------------> Create required data (sf-data)
  |     ├── Controller exception -----------> Fix controller code (sf-apex)
  |     └── Cleanup failed ----------------> Report (non-blocking)
  |
  ├── Intake simulation (guest apply) failed?
  |     ├── submitVolunteer exception ------> Check VolunteerIntakeService + RT (sf-apex)
  |     ├── Applicant not linked to PA -----> Check NpcVolunteerApplicantService trigger (sf-apex)
  |     ├── Task not created ---------------> Check Volunteer_Review queue exists
  |     ├── Person Account not created -----> Verify Person Accounts enabled (BLOCKING)
  |     └── Cleanup failed ----------------> Report (non-blocking)
  |
  ├── Agentforce issue?
  |     ├── Agent metadata missing ---------> Check local source, deploy (sf-ai-agentforce)
  |     ├── Topic/action misconfigured -----> Fix via sf-ai-agentforce, redeploy
  |     ├── PromptTemplate broken ----------> Fix template, redeploy
  |     ├── Agent test failures ------------> Delegate to sf-ai-agentforce-testing
  |     └── Agent channel not configured ---> Escalate (requires Setup UI)
  |
  ├── Data Cloud issue?
  |     ├── Data Cloud not provisioned -----> BLOCKING: Escalate (requires licensing)
  |     ├── Stream not ingesting -----------> Delegate to sf-datacloud-prepare
  |     ├── DMO mapping incomplete ---------> Delegate to sf-datacloud-harmonize
  |     ├── Segment empty/not published ----> Delegate to sf-datacloud-segment
  |     ├── Activation target broken -------> Delegate to sf-datacloud-act
  |     └── Data Cloud query fails ---------> Delegate to sf-datacloud-retrieve
  |
  ├── Slack issue?
  |     ├── Connected app missing ----------> Deploy from source or escalate
  |     ├── Package not installed ----------> Escalate (managed package install)
  |     ├── Notification Flow missing ------> Deploy from source (sf-flow)
  |     └── Workspace-side issue -----------> Escalate (requires Slack admin)
  |
  ├── Marketing Cloud issue?
  |     ├── MC connector not installed -----> Escalate (AppExchange install)
  |     ├── Connected app missing ----------> Escalate (requires MC API credentials)
  |     ├── Sync objects not configured ----> Escalate (requires Setup UI)
  |     └── MC-side issue ------------------> Escalate (requires MC admin)
  |
  ├── Tableau / CRM Analytics issue?
  |     ├── Analytics app missing ----------> Deploy from source (sf-deploy)
  |     ├── Dataset empty/missing ----------> Check dataflow, escalate if failed
  |     ├── Dataflow failed ----------------> Escalate (Analytics Studio repair)
  |     ├── Dashboard missing --------------> Deploy from source (sf-deploy)
  |     └── Tableau embed broken -----------> Escalate (requires Tableau admin)
  |
  ├── OmniStudio issue?
  |     ├── OmniScript missing/inactive ----> Deploy + activate (sf-industry-commoncore-omniscript)
  |     ├── FlexCard missing/inactive ------> Deploy + activate (sf-industry-commoncore-flexcard)
  |     ├── IP missing ---------------------> Deploy (sf-industry-commoncore-integration-procedure)
  |     ├── Data Mapper misconfigured ------> Fix mappings (sf-industry-commoncore-datamapper)
  |     └── Namespace mismatch ------------> Detect + re-query (sf-industry-commoncore-omnistudio-analyze)
  |
  └── Visual mismatch?
        ├── Component missing from page ----> Escalate (requires Lightning App Builder)
        ├── Wrong layout/arrangement -------> Escalate (requires page layout editor)
        ├── Error/broken UI ----------------> Escalate (check browser console)
        └── Blank/empty page ---------------> Escalate (check access + dependencies)
```

---

## Metadata Fixes

### Missing Custom Object

**Delegate to**: sf-metadata --> sf-deploy

1. Use sf-metadata to generate the `.object-meta.xml` with required fields
2. Include all fields referenced in the demoscript step
3. Deploy:
   ```bash
   sf project deploy start --dry-run --source-dir force-app --target-org [alias]
   sf project deploy start --source-dir force-app --target-org [alias]
   ```

### Missing Custom Field

**Delegate to**: sf-metadata --> sf-deploy

1. Use sf-metadata to generate the `.field-meta.xml`
2. Match the field type from the demoscript description:
   - "Amount", "Price", "$" --> Currency
   - "Date", "Due Date" --> Date
   - "Status", dropdown values --> Picklist
   - "Description", "Notes" --> LongTextArea
   - "Name", "Title" --> Text
   - "Count", "Number" --> Number
   - "Yes/No", "Is Active" --> Checkbox
   - Reference to another object --> Lookup or MasterDetail
3. Deploy the field

### Missing Record Type

**Delegate to**: sf-metadata --> sf-deploy

1. Generate the record type XML under the object directory
2. Include picklist value mappings if mentioned in the demoscript
3. Deploy

### Missing Page Layout

**Delegate to**: sf-metadata --> sf-deploy

1. Generate layout XML
2. Include sections and field placements inferred from the demoscript
3. Deploy

---

## Data Fixes

### Missing Records

**Delegate to**: sf-data

Strategy depends on the record count and complexity:

**Single record** (named record like "INV-001"):
```bash
sf data create record --sobject [Object] --values "Name='[Name]' [Field1]='[Value1]' [Field2]='[Value2]'" --target-org [alias] --json
```

**Multiple records** (e.g., "at least 5 Accounts"):
Use anonymous Apex via sf-data for bulk creation:
```bash
sf apex run --file create-demo-data.apex --target-org [alias]
```

Where `create-demo-data.apex` contains:
```apex
List<Account> accounts = new List<Account>();
for (Integer i = 1; i <= 5; i++) {
    accounts.add(new Account(Name = 'Demo Customer ' + i, Type = 'Customer'));
}
insert accounts;
```

**Records with relationships** (parent + child):
Create parents first, then children referencing parent IDs.

### Wrong Field Values

**Delegate to**: sf-data

```bash
sf data update record --sobject [Object] --record-id [Id] --values "[Field]='[CorrectValue]'" --target-org [alias] --json
```

Only update if the demoscript specifies an exact expected value and the current value is clearly demo data (not user-created data).

### Missing Related Records

**Delegate to**: sf-data

1. Query the parent record to get its ID
2. Create child records referencing the parent:
```bash
sf data create record --sobject Contact --values "AccountId='[ParentId]' LastName='Demo Contact' FirstName='Test'" --target-org [alias] --json
```

---

## Platform Prerequisite Fixes

### Person Accounts Not Enabled

**Cannot auto-enable.** Escalate:

```
ESCALATION: Person Accounts are not enabled in this org.
  Impact: BLOCKING — intake form, trigger chain, and shift sign-up all depend on Person Accounts.
  Recommendation: Enable Person Accounts via Setup > Account Settings > Person Accounts > Enable.
  Note: This is irreversible and requires careful consideration in production orgs.
```

### ApplicationForm Record Type Missing

**Delegate to**: sf-metadata --> sf-deploy

1. Generate a `RecordType` for `ApplicationForm` with `DeveloperName = 'Programs'`
2. Deploy via metadata API

### Custom Field Missing (e.g., Description__c)

**Delegate to**: sf-metadata --> sf-deploy

1. Generate the `.field-meta.xml` for the missing custom field
2. Deploy to the org

### Volunteer_Review Queue Missing

**Delegate to**: sf-data (Anonymous Apex)

```apex
Group q = new Group(
    Name = 'Volunteer Review',
    DeveloperName = 'Volunteer_Review',
    Type = 'Queue'
);
insert q;

QueueSObject qso = new QueueSObject(
    QueueId = q.Id,
    SobjectType = 'Task'
);
insert qso;
System.debug('Queue created: ' + q.Id);
```

---

## Data Quality & Freshness Fixes

### Location Fields Incomplete

**Delegate to**: sf-data (Anonymous Apex)

For locations missing `Description`, `DrivingDirections`, or `TimeZone`, update with reasonable defaults:

```apex
List<Location> locs = [SELECT Id, Name, Description, DrivingDirections, TimeZone
                       FROM Location WHERE IsActive = true AND Description = null];
for (Location l : locs) {
    if (l.Description == null) l.Description = l.Name + ' club site';
    if (l.DrivingDirections == null) l.DrivingDirections = 'See Google Maps for directions to ' + l.Name;
    if (l.TimeZone == null) l.TimeZone = 'America/Chicago';
}
update locs;
```

### Shift Dates Expiring Soon

**Delegate to**: sf-data (Anonymous Apex)

Bump all future shifts forward by N days to ensure adequate demo lead time:

```apex
Integer daysToAdd = 30;
List<JobPositionShift> shifts = [SELECT Id, StartDate, EndDate
                                  FROM JobPositionShift
                                  WHERE StartDate < :Date.today().addDays(14)
                                  AND Status = 'Published'];
for (JobPositionShift s : shifts) {
    s.StartDate = s.StartDate.addDays(daysToAdd);
    if (s.EndDate != null) s.EndDate = s.EndDate.addDays(daysToAdd);
}
update shifts;
```

### All Shifts at Zero Capacity

**Delegate to**: sf-data (Anonymous Apex)

```apex
List<JobPositionShift> shifts = [SELECT Id, MaximumAttendeesCount, RemainingCapacity
                                  FROM JobPositionShift
                                  WHERE StartDate >= TODAY AND RemainingCapacity = 0];
for (JobPositionShift s : shifts) {
    s.MaximumAttendeesCount = s.MaximumAttendeesCount + 10;
}
update shifts;
```

### Stale Test Data

**Delegate to**: sf-data (Anonymous Apex)

```apex
// Delete stale test assignments
List<JobPositionAssignment> staleAssignments = [
    SELECT Id FROM JobPositionAssignment
    WHERE ScheduledStartTime < TODAY
    OR Name LIKE '%E2E%' OR Name LIKE '%Test%'
    LIMIT 200
];
if (!staleAssignments.isEmpty()) delete staleAssignments;

// Delete stale test application forms
List<ApplicationForm> staleForms = [
    SELECT Id FROM ApplicationForm
    WHERE Title LIKE '%E2E%' OR Title LIKE '%e2e%' OR Title LIKE '%Test%'
    LIMIT 200
];
if (!staleForms.isEmpty()) {
    delete [SELECT Id FROM Applicant WHERE ApplicationFormId IN :staleForms];
    delete staleForms;
}
```

### Jamie Duplicate Assignments

**Delegate to**: sf-data (Anonymous Apex)

```apex
List<Account> jamiePA = [SELECT Id, PersonContactId FROM Account
                          WHERE PersonEmail = 'bth.volunteerdemo@example.com' LIMIT 1];
if (!jamiePA.isEmpty()) {
    List<JobPositionAssignment> dupes = [
        SELECT Id FROM JobPositionAssignment
        WHERE AssignedContactId = :jamiePA[0].PersonContactId
    ];
    if (!dupes.isEmpty()) {
        delete dupes;
        System.debug('Deleted ' + dupes.size() + ' stale Jamie assignments');
    }
}
```

### Jamie TimeZoneSidKey Wrong

**Delegate to**: sf-data

```bash
sf data query --query "SELECT Id FROM User WHERE Alias = 'JVolunte' AND IsActive = true" --target-org [alias] --json
```

Then update:

```bash
sf data update record --sobject User --record-id [userId] --values "TimeZoneSidKey='America/Chicago'" --target-org [alias] --json
```

---

## Permission Fixes

### Missing Permission Set

**Delegate to**: sf-permissions --> sf-deploy

1. Use sf-permissions to generate a `.permissionset-meta.xml`
2. Include object permissions and FLS for all objects/fields referenced in the demoscript
3. Deploy

### Permission Set Not Assigned

**Delegate to**: sf-permissions

Assign via SOQL to find the user, then assign:
```bash
sf data create record --sobject PermissionSetAssignment --values "AssigneeId='[UserId]' PermissionSetId='[PermSetId]'" --target-org [alias] --json
```

To find the IDs:
```bash
sf data query --query "SELECT Id FROM User WHERE Alias = '[UserAlias]'" --target-org [alias] --json
sf data query --query "SELECT Id FROM PermissionSet WHERE Name = '[PermSetName]'" --target-org [alias] --json
```

### Missing Field-Level Security

**Delegate to**: sf-permissions --> sf-deploy

Add the field to the existing permission set's XML and redeploy:
```xml
<fieldPermissions>
    <editable>true</editable>
    <field>[Object].[Field]</field>
    <readable>true</readable>
</fieldPermissions>
```

### Missing Object Access

**Delegate to**: sf-permissions --> sf-deploy

Add object permissions to the permission set XML:
```xml
<objectPermissions>
    <allowCreate>true</allowCreate>
    <allowDelete>false</allowDelete>
    <allowEdit>true</allowEdit>
    <allowRead>true</allowRead>
    <object>[ObjectApiName]</object>
    <viewAllRecords>false</viewAllRecords>
    <modifyAllRecords>false</modifyAllRecords>
</objectPermissions>
```

### Missing Apex Class Access on Permission Set

**Delegate to**: sf-permissions --> sf-deploy

Add Apex class access to the permission set XML:

```xml
<classAccesses>
    <apexClass>[ClassName]</apexClass>
    <enabled>true</enabled>
</classAccesses>
```

Then redeploy the permission set. Verify the fix:

```bash
sf data query --query "SELECT Id FROM SetupEntityAccess WHERE ParentId IN (SELECT Id FROM PermissionSet WHERE Name = '[PermSetName]') AND SetupEntityType = 'ApexClass'" --target-org [alias] --json
```

### Network Member Group Wrong

**Cannot auto-fix.** Escalate:

```
ESCALATION: Experience site "[SiteName]" does not include the required member license.
  Expected: Customer Community Plus Login User
  Recommendation: Setup > Digital Experiences > [SiteName] > Administration > Members > Add the profile/license.
```

### Profile Issue

**NEVER modify profiles directly.** Report the issue:

```
ESCALATION: Step [n] requires profile-level access that cannot be auto-fixed.
  Issue: Profile "[ProfileName]" lacks [access type] for [Object/Field]
  Recommendation: Create a Permission Set with the required access and assign it
```

---

## Automation Fixes

### Missing Flow

**Delegate to**: sf-flow --> sf-deploy

1. Check local project source for the flow XML:
   ```
   Glob: **/flows/[FlowApiName].flow-meta.xml
   ```
2. If found locally, deploy it:
   ```bash
   sf project deploy start --metadata Flow:[FlowApiName] --target-org [alias]
   ```
3. If not found locally, escalate -- auto-generating flows is complex and risky

### Inactive Flow

**Delegate to**: sf-deploy

1. Retrieve the current flow:
   ```bash
   sf project retrieve start --metadata Flow:[FlowApiName] --target-org [alias] --output-dir temp-retrieve
   ```
2. Change `<status>Draft</status>` to `<status>Active</status>` in the XML
3. Deploy:
   ```bash
   sf project deploy start --source-dir temp-retrieve --target-org [alias]
   ```

### Missing Apex Trigger

**Delegate to**: sf-apex --> sf-deploy

1. Check local source:
   ```
   Glob: **/triggers/[TriggerName].trigger
   ```
2. If found, deploy it
3. If not found, escalate -- auto-generating triggers requires domain knowledge

### Inactive Trigger

Triggers cannot be selectively deactivated/activated via metadata. If a trigger is inactive, it was likely not deployed. Deploy the source.

---

## Component Fixes

### Missing LWC

**Delegate to**: sf-lwc --> sf-deploy

1. Check local source:
   ```
   Glob: **/lwc/[componentName]/**
   ```
2. If found, deploy the bundle:
   ```bash
   sf project deploy start --metadata LightningComponentBundle:[componentName] --target-org [alias]
   ```
3. If not found locally, escalate

### Missing Aura Component

1. Check local source:
   ```
   Glob: **/aura/[componentName]/**
   ```
2. If found, deploy
3. If not found, escalate

### Component Not on Page

If the component exists in the org but isn't placed on the expected FlexiPage, escalate. Auto-modifying page layouts is risky.

```
ESCALATION: Component "[componentName]" is deployed but not placed on page "[pageName]".
  Recommendation: Use Lightning App Builder to add the component to the page layout.
```

---

## Integration Fixes

Integration fixes are the most limited because credentials and endpoints involve secrets and external system configuration.

### Missing Named Credential

**Cannot auto-create.** Escalate:

```
ESCALATION: Named Credential "[credentialName]" not found.
  Required endpoint: [endpoint if mentioned in demoscript]
  Recommendation: Create the Named Credential via Setup > Named Credentials
```

### Missing External Service

**Cannot auto-create.** Escalate with details about what's needed.

### Missing Connected App

**Cannot auto-create.** Escalate.

### Missing Remote Site Setting

**Can auto-create** via metadata if the URL is known:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<RemoteSiteSetting xmlns="http://soap.sforce.com/2006/04/metadata">
    <disableProtocolSecurity>false</disableProtocolSecurity>
    <isActive>true</isActive>
    <url>[EndpointURL]</url>
</RemoteSiteSetting>
```

Deploy via sf-deploy.

---

## Dashboard / Report Type Fixes

### Metadata Deployment (Primary)

**Delegate to**: sf-metadata --> sf-deploy

1. Generate custom report type XML (`.reportType-meta.xml`)
2. Generate report XML (`.report-meta.xml`) in a report folder
3. Generate dashboard XML (`.dashboard-meta.xml`) in a dashboard folder
4. Deploy in order: ReportType --> Report --> Dashboard

### Analytics REST API Fallback (When Metadata Fails)

When custom report types for Industry Cloud / NPC objects fail to deploy via metadata (common with objects like `JobPositionAssignment`, `JobPositionShift`), use the Analytics REST API via Anonymous Apex.

**Delegate to**: sf-data (Anonymous Apex)

**Step 1: Create Report Folder**

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint(URL.getOrgDomainURL().toExternalForm()
    + '/services/data/v62.0/analytics/folders');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setBody(JSON.serialize(new Map<String, Object>{
    'label' => 'BTH Volunteer Reports',
    'name' => 'BTH_Volunteer_Reports',
    'type' => 'report'
}));
Http http = new Http();
HttpResponse res = http.send(req);
Map<String, Object> folder = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
String folderId = (String) folder.get('id');
System.debug('Report folder created: ' + folderId);
```

**Step 2: Create Report via REST**

**CRITICAL**: Custom report types deployed via Metadata API are referenced in the Analytics REST API with a `__c` suffix. For example, a report type with DeveloperName `BTH_Volunteer_Assignments` must be referenced as `BTH_Volunteer_Assignments__c` in the `reportType.type` field.

**CRITICAL**: Lookup fields in custom report types must use the dotted relationship-to-Name format for column references (e.g., `JobPositionAssignment.AssignedContact.Name`, not `JobPositionAssignment.AssignedContact`). Use the describe endpoint (`/analytics/report-types/[TypeName__c]`) to discover valid column names.

**CRITICAL**: The folder endpoint uses `/services/data/v62.0/folders` (not `/analytics/folders`).

**CRITICAL**: Anonymous Apex does not support `AccessLevel.SYSTEM_MODE` in DML calls. Use standard DML (`insert obj;`) instead.

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint(URL.getOrgDomainURL().toExternalForm()
    + '/services/data/v62.0/analytics/reports');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

Map<String, Object> reportMetadata = new Map<String, Object>{
    'name' => 'BTH Volunteers YTD',
    'developerName' => 'BTH_Volunteers_YTD',
    'reportType' => new Map<String, Object>{ 'type' => 'BTH_Volunteer_Assignments__c' },
    'reportFormat' => 'TABULAR',
    'folderId' => folderId,
    'detailColumns' => new List<String>{
        'JobPositionAssignment.Name',
        'JobPositionAssignment.AssignedContact.Name',
        'JobPositionAssignment.Status',
        'JobPositionAssignment.ScheduledStartTime'
    }
};
req.setBody(JSON.serialize(new Map<String, Object>{
    'reportMetadata' => reportMetadata
}));
HttpResponse res = http.send(req);
System.debug('Report created: ' + res.getBody());
```

**Step 3: Create Dashboard Folder + Dashboard**

Follow the same pattern using `/services/data/v62.0/analytics/dashboards`.

**When to use this fallback**:
- Metadata deploy returns "invalid report type" for NPC/Industry objects
- Custom report types deploy but reports cannot reference them
- The org has objects that aren't supported by the standard report type metadata format

### Dashboard Escalation (Last Resort)

If both metadata and REST API approaches fail:

```
ESCALATION: Dashboard creation failed via both metadata and REST API
  Step: [Step number and title]
  Type: dashboard
  Detail: Custom report types for [ObjectName] are not supported in this org edition
  Recommendation: Create reports and dashboard manually via Setup > Reports
  Manual Steps:
    1. Setup > Report Types > New Custom Report Type
    2. Primary Object: [ObjectName]
    3. Create reports using the custom report type
    4. Add reports to a new Dashboard
```

---

## Experience Cloud Fixes

### Site Not Rendering (Guest)

**Delegate to**: sf-deploy + sf-permissions

1. Verify the site is published:
```bash
sf data query --query "SELECT Id, Name, Status FROM Network WHERE Name = '[SiteName]'" --target-org [alias] --json
```
2. If status is not Active, publish via Setup (escalate -- cannot publish sites via CLI)
3. Check guest user profile has access to required Apex controllers:
```bash
sf data query --query "SELECT Id, SetupEntityId, SetupEntityType FROM SetupEntityAccess WHERE Parent.Name = '[SiteName]' AND SetupEntityType = 'ApexClass'" --target-org [alias] --json
```
4. If controller access is missing, add it to the guest user profile's permission set

### Site Not Showing Data

1. Verify the controller is accessible by guest users (check `@AuraEnabled` and `without sharing` / `with sharing` keywords)
2. Verify data exists that matches the controller's SOQL queries
3. Run the controller methods via Anonymous Apex to confirm they return data
4. Check for sharing rules that might hide records from guest users

### Member Login Not Working

1. Verify the demo user has a Community/Experience license
2. Verify the demo user's profile is assigned to the Experience site
3. Check the demo user's contact is associated with a valid Account

---

## E2E Simulation Fixes

### Permission Failure

**Delegate to**: sf-permissions --> sf-deploy

1. Parse the `System.runAs` exception to identify the missing permission
2. Add the permission to the demo user's permission set
3. Re-run the simulation

### Data Failure

**Delegate to**: sf-data

1. Parse the simulation failure to identify what data is missing
2. Create the required records (shifts, programs, etc.)
3. Re-run the simulation

### Controller Logic Failure

**Delegate to**: sf-apex

1. Parse the exception from the controller method
2. Fix the Apex code
3. Deploy the fix
4. Re-run the simulation

### Cleanup Failure

Non-blocking. Report but do not fail the step:

```
WARNING: E2E simulation cleanup failed
  Records created during simulation: [list of IDs]
  Recommendation: Delete manually via Developer Console or Data Loader
```

---

## Intake Simulation Fixes

### submitVolunteer Exception

**Delegate to**: sf-apex

1. Parse the exception message from the Anonymous Apex output
2. Common causes:
   - `AuraHandledException: no Application Form record type named Programs` — create the RT (see Platform Prerequisite Fixes)
   - `DmlException: Field Description__c does not exist` — create the custom field (see Platform Prerequisite Fixes)
   - `StringException: Invalid id` — check method parameters
3. Fix the root cause, deploy, and re-run the simulation

### Applicant Not Linked to Person Account

**Delegate to**: sf-apex

1. Check that the `NpcVolunteerApplicantService` trigger handler is deployed and the trigger is active:
```bash
sf data query --query "SELECT Id, Name, Status FROM ApexTrigger WHERE TableEnumOrId = 'Applicant' AND Status = 'Active'" --target-org [alias] --json --use-tooling-api
```
2. Verify Person Accounts are enabled (see Platform Prerequisites)
3. Check `handleAfterInsert` logic for the specific failure point

### Task Not Created

1. Verify the `Volunteer_Review` queue exists (see Platform Prerequisites)
2. If it doesn't exist, create it (see Platform Prerequisite Fixes)
3. Re-run the intake simulation

### Intake Cleanup Failed

Non-blocking. Report but do not fail:

```
WARNING: Intake simulation cleanup partially failed
  Records created: ApplicationForm=[id], Applicant=[id], Account=[id]
  Recommendation: Delete manually via Setup > Object Manager or Developer Console
```

---

## Apex & Code Health Fixes

### Apex Class Not Compiling

**Delegate to**: sf-apex --> sf-deploy

1. Query the specific error:
```bash
sf data query --query "SELECT Id, Name, Body FROM ApexClass WHERE Name = '[ClassName]' AND IsValid = false" --target-org [alias] --json --use-tooling-api
```
2. Check local source for the class and compare
3. Fix the code and deploy

### App Tab Configuration Wrong

**Delegate to**: sf-metadata --> sf-deploy

1. Retrieve the current app metadata:
```bash
sf project retrieve start --metadata CustomApplication:[AppDevName] --target-org [alias] --output-dir temp-retrieve --json
```
2. Edit the XML to add/reorder the expected tabs
3. Deploy the updated app

---

## Experience URL Unreachable

**Cannot auto-fix** in most cases. Escalate:

```
ESCALATION: Experience site public URL is unreachable (HTTP [code])
  URL: [url]
  Possible causes:
    - Site not published: Run "sf community publish" or publish via Setup > Digital Experiences
    - DNS not propagated: Wait 24-48 hours after site creation
    - Site deactivated: Check Setup > Digital Experiences > [SiteName] > Status
```

If the site exists but returns 403, check guest user profile access to the default page and Apex controllers.

---

## Agentforce Fixes

### Missing Agent Metadata

**Delegate to**: sf-ai-agentforce --> sf-deploy

1. Check local source for `.genAiPlugin-meta.xml`, `.genAiFunction-meta.xml`, and `.promptTemplate-meta.xml` files
2. If found, deploy the metadata bundle
3. If not found, escalate — agent configuration requires Agent Builder UI

### Agent Topic/Action Misconfigured

**Delegate to**: sf-ai-agentforce

1. Retrieve the current agent metadata and compare against demoscript expectations
2. Fix topic descriptions, action mappings, or prompt template content
3. Redeploy

### Agent Test Failures

**Delegate to**: sf-ai-agentforce-testing

1. Run the agent test suite if test specs exist
2. Parse failures for topic routing errors vs action execution errors
3. Fix routing: update topic descriptions/instructions
4. Fix actions: update action Apex, Flow, or PromptTemplate
5. Re-run tests

### PromptTemplate Missing or Broken

**Delegate to**: sf-ai-agentforce --> sf-deploy

1. Generate or fix the `.promptTemplate-meta.xml`
2. Verify merge field references are valid
3. Deploy

---

## Data Cloud Fixes

### Data Cloud Not Provisioned

**Cannot auto-enable.** Escalate:

```
ESCALATION: Data Cloud is not provisioned in this org.
  Recommendation: Enable Data Cloud via Setup > Data Cloud > Get Started.
  Note: Requires specific org edition and licensing.
```

### Data Stream Not Ingesting

**Delegate to**: sf-datacloud-prepare

1. Check stream configuration for source connectivity
2. Verify the source system is accessible
3. If the stream is paused, attempt restart via API
4. If the source is unreachable, escalate

### DMO Mapping Incomplete

**Delegate to**: sf-datacloud-harmonize

1. Identify missing field mappings between DLO and DMO
2. Create mappings via metadata or API
3. Re-run harmonization

### Segment Empty or Not Published

**Delegate to**: sf-datacloud-segment

1. Verify the segment SQL is valid
2. Check that source DMOs have data
3. Republish the segment
4. If still empty, the underlying data may be missing — fix data first

### Activation Target Not Connected

**Delegate to**: sf-datacloud-act

1. Verify the activation target configuration
2. Check credentials and connectivity
3. If the external target is unreachable, escalate

---

## Slack Fixes

### Slack Connected App Missing

**Delegate to**: sf-connected-apps --> sf-deploy

1. Check local source for Slack connected app metadata
2. If found, deploy
3. If not found, escalate — Slack app creation requires both Salesforce Setup and Slack admin

### Slack Package Not Installed

**Cannot auto-install managed packages.** Escalate:

```
ESCALATION: Salesforce for Slack package is not installed.
  Recommendation: Install via Setup > Installed Packages > Install a Package.
  Package ID: (check Salesforce documentation for current version)
```

### Slack Notification Automation Missing

**Delegate to**: sf-flow --> sf-deploy

1. Check local source for Slack-related Flows
2. If found, deploy and activate
3. If not found, escalate

### Slack Workspace-Side Issues

**Cannot fix from Salesforce.** Escalate:

```
ESCALATION: Slack workspace configuration requires manual verification.
  Items to check:
    - Bot has been added to the target channel
    - Bot has correct OAuth scopes
    - Slack workflow is published (if using Slack Workflow Builder)
    - Channel ID matches Salesforce configuration
```

---

## Marketing Cloud Fixes

### MC Connector Package Missing

**Cannot auto-install.** Escalate:

```
ESCALATION: Marketing Cloud Connector package is not installed.
  Recommendation: Install from AppExchange or follow MC Connector setup guide.
```

### MC Connected App Missing

**Delegate to**: sf-connected-apps

1. Check if MC-related connected apps exist
2. If missing, escalate — MC Connected Apps require API credentials from the MC account

### Synchronized Object Configuration

**Cannot auto-configure.** Escalate:

```
ESCALATION: Marketing Cloud synchronized objects are not configured.
  Recommendation: Setup > Marketing Cloud > Configure synchronized objects.
```

### MC-Side Issues

**Cannot fix from Salesforce.** Escalate:

```
ESCALATION: Marketing Cloud configuration requires MC admin verification.
  Items to check:
    - Journey is active and published
    - Email templates render correctly
    - Audience builder segments are populated
    - Send classification and delivery profile are configured
```

---

## Tableau / CRM Analytics Fixes

### Analytics App Missing

**Delegate to**: sf-deploy

1. Check local source for analytics app metadata (`.wapp` files)
2. If found, deploy the analytics template/app
3. If not found, escalate

### Dataset Missing or Empty

1. If the dataset depends on a dataflow, check the dataflow status first
2. If the dataflow failed, report the error and escalate
3. If the dataset is missing entirely, check local source for dataset metadata

### Dataflow Failed

**Cannot auto-fix dataflow logic.** Escalate:

```
ESCALATION: CRM Analytics dataflow "[DataflowName]" has failed.
  Last run status: Failed
  Recommendation: Open Analytics Studio > Data Manager > Dataflows to review the error.
  Common causes: source object permissions, field changes, SAQL syntax errors.
```

### Analytics Dashboard Missing

**Delegate to**: sf-deploy

1. Check local source for analytics dashboard JSON
2. If found, deploy
3. If not found, escalate

### Tableau Cloud/Server Embed Broken

**Cannot fix from Salesforce.** Escalate:

```
ESCALATION: Tableau embed configuration requires manual verification.
  Items to check:
    - Tableau Connected App is configured with correct scopes
    - Tableau dashboard is published and accessible
    - Embed URL is correct and CORS is configured
```

---

## OmniStudio Fixes

### OmniScript Missing or Inactive

**Delegate to**: sf-industry-commoncore-omniscript --> sf-deploy

1. Detect the namespace (`omnistudio__`, `vlocity_cmt__`, `vlocity_ins__`)
2. Check local source for OmniScript metadata
3. If found, deploy and activate
4. If not found, escalate

### FlexCard Missing or Inactive

**Delegate to**: sf-industry-commoncore-flexcard --> sf-deploy

1. Check local source for FlexCard metadata
2. Deploy and activate
3. Verify data source bindings (IP or SOQL) return data

### Integration Procedure Missing

**Delegate to**: sf-industry-commoncore-integration-procedure --> sf-deploy

1. Check local source for IP metadata
2. Deploy
3. Verify the IP executes correctly by calling its remote action endpoint

### Data Mapper Missing or Misconfigured

**Delegate to**: sf-industry-commoncore-datamapper

1. Check local source for Data Mapper metadata
2. Deploy
3. Verify field mappings are correct for the target objects

### Namespace Mismatch

**Delegate to**: sf-industry-commoncore-omnistudio-analyze

If queries fail because the namespace is wrong:

1. Run namespace detection
2. Update all OmniStudio queries to use the correct namespace prefix
3. Re-run validation

---

## Visual/UI Fixes

Visual failures are **always escalated** -- they require manual changes in Lightning App Builder, page layout editor, or component configuration that cannot be automated via CLI or metadata deployment.

### Missing Component on Page

```
ESCALATION: Component not visible on page
  Step: [Step number and title]
  Type: visual
  Screenshot: screenshots/step-[n].png
  Detail: Expected "[ComponentName]" component on the record page but it was not visible in the screenshot
  Recommendation: Open Lightning App Builder for this page, drag the component onto the layout, and activate
```

### Wrong Layout or Arrangement

```
ESCALATION: Page layout does not match expected arrangement
  Step: [Step number and title]
  Type: visual
  Screenshot: screenshots/step-[n].png
  Detail: Expected [description from Visual block] but screenshot shows [what was actually seen]
  Recommendation: Edit the page layout in Lightning App Builder to match the expected arrangement
```

### Error or Broken UI

```
ESCALATION: Page displays error or broken component
  Step: [Step number and title]
  Type: visual
  Screenshot: screenshots/step-[n].png
  Detail: Screenshot shows [error message or broken component description]
  Recommendation: Check browser console for errors. Common causes: missing permissions, undeployed dependencies, or JavaScript errors in custom components
```

### Blank or Empty Page

```
ESCALATION: Page appears blank or empty
  Step: [Step number and title]
  Type: visual
  Screenshot: screenshots/step-[n].png
  Detail: Screenshot shows a blank page or loading spinner that never resolved
  Recommendation: Verify the page exists, the user has access, and all component dependencies are deployed. Check for JavaScript errors in the browser console.
```

Visual escalations always include the screenshot path so the user can review exactly what the agent saw.

---

## Escalation Format

When an issue cannot be auto-fixed, report it clearly:

```
ESCALATION: [Brief description]
  Step: [Step number and title]
  Type: [Issue type]
  Screenshot: [path, if visual]
  Detail: [What was found vs. what was expected]
  Recommendation: [Specific manual action the user should take]
  Skill: [Which sf-* skill to use manually, if applicable]
```

---

## Fix Batching Strategy

To minimize deployments, batch related fixes:

1. **Collect all metadata fixes** from all failing steps before deploying
2. **Deploy in order**: Objects --> Fields --> Permission Sets --> Apex --> Flows
3. **Then handle data fixes** after metadata is deployed (data needs schema to exist)
4. **Then handle permission assignments** after permission sets are deployed
5. **Single dry-run, single deploy** when possible:
   ```bash
   sf project deploy start --dry-run --source-dir force-app --target-org [alias]
   sf project deploy start --source-dir force-app --target-org [alias]
   ```

---

## Cross-Skill Delegation Summary

| Issue | Primary Skill | Supporting Skill | Notes |
|-------|---------------|-----------------|-------|
| Person Accounts not enabled | -- | -- | BLOCKING: Escalate (org feature) |
| NPC object missing | -- | -- | Escalate (requires NPC package) |
| ApplicationForm RT missing | sf-metadata | sf-deploy | Generate RT XML then deploy |
| Custom field missing (NPC) | sf-metadata | sf-deploy | Generate field XML then deploy |
| Queue missing | sf-data | -- | Create via Anonymous Apex |
| Provisioner script missing | -- | -- | Report (check source control) |
| Missing object/field | sf-metadata | sf-deploy | Generate XML then deploy |
| Missing data | sf-data | -- | Insert via CLI or anonymous Apex |
| Wrong data values | sf-data | -- | Update specific records |
| Location fields incomplete | sf-data | -- | Update Location records via Apex |
| Shift dates expiring soon | sf-data | -- | Bump dates forward via Apex |
| All shifts at zero capacity | sf-data | -- | Increase MaximumAttendeesCount via Apex |
| Stale test data | sf-data | -- | Delete old test records via Apex |
| Jamie duplicate assignments | sf-data | -- | Delete stale assignments via Apex |
| Jamie timezone wrong | sf-data | -- | Update User.TimeZoneSidKey |
| Missing perm set | sf-permissions | sf-deploy | Generate XML then deploy |
| Perm set unassigned | sf-permissions | -- | Insert PermissionSetAssignment |
| Missing FLS/object access | sf-permissions | sf-deploy | Update perm set XML then deploy |
| Missing Apex class access | sf-permissions | sf-deploy | Add classAccesses to perm set XML |
| Network member group wrong | -- | -- | Escalate (Experience site Setup) |
| Inactive flow | sf-deploy | -- | Update status XML and deploy |
| Missing flow (in source) | sf-flow | sf-deploy | Deploy from local source |
| Missing flow (no source) | -- | -- | Escalate |
| Missing trigger (in source) | sf-apex | sf-deploy | Deploy from local source |
| Apex compilation error | sf-apex | sf-deploy | Fix code then deploy |
| App tab config wrong | sf-metadata | sf-deploy | Update app XML then deploy |
| Missing LWC (in source) | sf-lwc | sf-deploy | Deploy bundle |
| Named credential missing | -- | -- | Escalate (requires secrets) |
| Remote site missing | sf-metadata | sf-deploy | Generate XML then deploy |
| Post-fix test failures | sf-testing | sf-apex | Run tests, fix failures |
| Report type deploy fail | sf-data | -- | Analytics REST API via Anonymous Apex |
| Report/dashboard deploy fail | sf-data | -- | Analytics REST API via Anonymous Apex |
| Experience guest access | sf-permissions | sf-deploy | Fix guest profile Apex class access |
| Experience URL unreachable | -- | -- | Escalate (publish / DNS / config) |
| Experience data not showing | sf-apex | sf-data | Fix controller + ensure data exists |
| Experience site unpublished | -- | -- | Escalate (cannot publish via CLI) |
| E2E permission failure | sf-permissions | sf-deploy | Add perms to demo user perm set |
| E2E data missing | sf-data | -- | Create required records for the flow |
| E2E controller exception | sf-apex | sf-deploy | Fix Apex controller code |
| E2E cleanup failure | -- | -- | Report (non-blocking warning) |
| Intake submitVolunteer fail | sf-apex | sf-deploy | Fix controller/service code |
| Intake trigger chain fail | sf-apex | sf-deploy | Fix NpcVolunteerApplicantService |
| Intake task not created | sf-data | -- | Create Volunteer_Review queue |
| Intake cleanup failure | -- | -- | Report (non-blocking warning) |
| Agent metadata missing | sf-ai-agentforce | sf-deploy | Deploy from local source |
| Agent topic/action broken | sf-ai-agentforce | sf-deploy | Fix config, redeploy |
| Agent test failures | sf-ai-agentforce-testing | sf-ai-agentforce | Run tests, fix routing/actions |
| PromptTemplate broken | sf-ai-agentforce | sf-deploy | Fix template, deploy |
| Agent channel not configured | -- | -- | Escalate (Setup UI) |
| Data Cloud not provisioned | -- | -- | BLOCKING: Escalate (licensing) |
| Data stream not ingesting | sf-datacloud-prepare | -- | Fix stream config |
| DMO mapping incomplete | sf-datacloud-harmonize | -- | Fix field mappings |
| Segment empty/not published | sf-datacloud-segment | -- | Verify SQL, republish |
| Activation target broken | sf-datacloud-act | -- | Fix target config |
| Data Cloud query fails | sf-datacloud-retrieve | -- | Fix SQL or permissions |
| Slack connected app missing | sf-connected-apps | sf-deploy | Deploy from source or escalate |
| Slack package missing | -- | -- | Escalate (managed package install) |
| Slack notification Flow | sf-flow | sf-deploy | Deploy from local source |
| Slack workspace issue | -- | -- | Escalate (Slack admin) |
| MC connector missing | -- | -- | Escalate (AppExchange install) |
| MC connected app missing | -- | -- | Escalate (MC API credentials) |
| MC sync objects | -- | -- | Escalate (Setup UI) |
| MC-side config | -- | -- | Escalate (MC admin) |
| Analytics app missing | sf-deploy | -- | Deploy from source |
| Dataset empty/missing | -- | -- | Check dataflow, escalate |
| Dataflow failed | -- | -- | Escalate (Analytics Studio) |
| Analytics dashboard missing | sf-deploy | -- | Deploy from source |
| Tableau embed broken | -- | -- | Escalate (Tableau admin) |
| OmniScript missing/inactive | sf-industry-commoncore-omniscript | sf-deploy | Deploy + activate |
| FlexCard missing/inactive | sf-industry-commoncore-flexcard | sf-deploy | Deploy + activate |
| IP missing | sf-industry-commoncore-integration-procedure | sf-deploy | Deploy |
| Data Mapper broken | sf-industry-commoncore-datamapper | sf-deploy | Fix mappings, deploy |
| OmniStudio namespace issue | sf-industry-commoncore-omnistudio-analyze | -- | Detect namespace, re-query |
| Visual mismatch | -- | -- | Escalate (requires manual UI changes) |
| Component not on page | -- | -- | Escalate (Lightning App Builder) |
| Blank/error page | -- | -- | Escalate (check access + dependencies) |
