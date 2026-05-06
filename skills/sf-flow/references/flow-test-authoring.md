<!-- Parent: sf-flow/SKILL.md -->
# Authoring Salesforce FlowTest metadata (`.flowtest-meta.xml`)

> **Scope**: writing the `.flowtest-meta.xml` files that `sf flow run test` (and the unified `sf logic run test`) executes. For path-coverage strategy, bulk testing, and edge cases, see `testing-guide.md`. For the test-execution checklist, see `testing-checklist.md`.
>
> **Available**: API 55.0+ (Spring '23). Required `<testType>` element added at API 66.0+. Authored from Flow Builder UI (Open Flow → Debug → Save as Test) or hand-edited; `.flowtest-meta.xml` deploys like any other metadata.

---

## When to author a FlowTest

Author a FlowTest whenever the flow is intended to ship behavior — record-triggered automation, screen flows that update records, autolaunched flows called from Apex, scheduled paths. Treat it the same way you'd treat an Apex test: no test, no merge.

**Prefer FlowTests over the older "insert a record and check side-effects" pattern** because:

- They run as part of `sf flow run test` / `sf logic run test` and are part of the test-pyramid signal in CI.
- They support `--code-coverage` (the same flag as Apex), so flow-coverage is reportable per the CLI.
- Assertions on intermediate elements (e.g. "did the `Create_Onboarding_Task` action visit, and did it have an error?") are first-class — much harder to reproduce with side-effect inspection.
- They don't leave records behind; flow tests evaluate without committing DML, the same way Apex test runs roll back.

When the flow has no FlowTest defined yet and a demo or validation pass needs to prove it fires, **author the FlowTest first** rather than reaching for `sf data create record` + side-effect verification.

---

## File location and naming

- **Folder**: `force-app/main/default/flowtests/` (lowercase `flowtests`).
- **Suffix**: `.flowtest-meta.xml` in SFDX source format.
- **One file = one test.** Multiple tests for one flow → multiple files in the same folder. Each file has its own `<FlowTest>` root.
- **Naming convention** observed in published Salesforce projects: `<FlowApiName>_<TestLabelInSnakeCase>.flowtest-meta.xml` — e.g. `AccountTrigger_Test_Create_Onboarding_Task.flowtest-meta.xml`.
- The file name (without suffix) becomes the test's `fullName` — there is **no `<fullName>` element** inside the file.

CLI test-name addressing for `sf logic run test`: `--tests "FlowTesting.<flow-test-name>"` (the `FlowTesting.` namespace prefix is required even though the file lives under `flowtests/`).

---

## Schema

Root + namespace:

```xml
<FlowTest xmlns="http://soap.sforce.com/2006/04/metadata">
```

### Top-level elements of `<FlowTest>`

| Element | Required | Notes |
|---|---|---|
| `<flowApiName>` | **yes** | API name of the flow under test. |
| `<label>` | **yes** | Human-readable test label. (Note: `<label>`, not `<masterLabel>`.) |
| `<description>` | optional | Free text. |
| `<testType>` | **API 66+** | Enum `WithAssertion`. Doc lists as required at API 66+; many existing files predate it. New files at API 66+ should include it. |
| `<flowTestFlowVersions>` | optional | API 66+. Pins the test to a specific flow version. Subtype: `<flowVersionNumber>`. Rare in practice; doc-only. |
| `<testPoints>` | optional, repeatable | Almost always 2 per file: one for `Start`, one for `Finish`. |
| `<flowTestDataSources>` | optional | "Reserved for future use." Don't use yet. |
| `<isolatedObjectExternalKeys>` | optional | "Reserved for future use." |

### `<testPoints>` (`FlowTestPoint`)

The canonical pattern is **two `<testPoints>` per file**:
- The **Start** point holds `<parameters>` (test inputs).
- The **Finish** point holds `<assertions>` (expected outcomes).

| Child | Required | Notes |
|---|---|---|
| `<elementApiName>` | **yes** | Only valid values: `Start` or `Finish`. |
| `<parameters>` | optional, repeatable | Use on the `Start` point. |
| `<assertions>` | optional, repeatable | Use on the `Finish` point. |
| `<isUseMockOuput>` | optional | (sic — typo is in the official doc.) "Reserved for future use." |

### `<parameters>` (`FlowTestParameter`)

Note that the field names the test **input** (record under test, scheduled path), not output assertions.

| Child | Required | Notes |
|---|---|---|
| `<leftValueReference>` | **yes** | For `InputTriggeringRecordInitial` / `InputTriggeringRecordUpdated`, this MUST be the literal `$Record`. For `ScheduledPath`, it MUST be the literal `ScheduledPathApiName`. |
| `<type>` | **yes** | Enum: `InputTriggeringRecordInitial`, `InputTriggeringRecordUpdated`, `InputVariable` (reserved — not yet usable), `ScheduledPath` (API 56+). |
| `<value>` | **yes** | A `FlowTestReferenceOrValue` wrapper — see typed children below. |

### `<assertions>` (`FlowTestAssertion`)

| Child | Required | Notes |
|---|---|---|
| `<conditions>` | optional, repeatable | At least one per assertion in practice. |
| `<errorMessage>` | optional | Custom failure message shown in Flow Builder + CLI test results. |

### `<conditions>` (`FlowTestCondition`)

| Child | Required | Notes |
|---|---|---|
| `<leftValueReference>` | **yes** | Field path or element API name. Examples: `$Record.Industry`, `$Record.Latitude`, `Update_description` (decision-outcome name), `Create_Onboarding_Task` (action API name, used with `WasVisited`/`HasError`). |
| `<operator>` | **yes** | `FlowComparisonOperator` enum — see below. |
| `<rightValue>` | optional | A `FlowTestReferenceOrValue` wrapper — see typed children below. |

### `FlowComparisonOperator` enum (when each became available)

`Contains`, `EndsWith`, `EqualTo`, `GreaterThan`, `GreaterThanOrEqualTo`, `IsChanged`, `IsNull`, `LessThan`, `LessThanOrEqualTo`, `NotEqualTo`, `StartsWith`, `WasSelected`, `WasSet`, `WasVisited` (API 55.0).

`In`, `NotIn` (API 56.0). `IsBlank`, `IsEmpty` (API 61.0). `HasError` (API 64.0).

### `FlowTestReferenceOrValue` (the wrapper for `<value>` and `<rightValue>`)

Pick **exactly one** typed child. Available types:

`<booleanValue>`, `<dateTimeValue>`, `<dateValue>`, `<numberValue>` (double), `<stringValue>`, `<sobjectValue>` (XML-escaped JSON of the record), `<timeValue>`.

`<elementReference>` and `<jsonValue>` are reserved — don't use yet.

### Run-as user

There is **no** `<runAsUser>` / `<runAs>` element on `FlowTest`. The flow test executes as the user invoking `sf flow run test` / `sf logic run test`. To test under a specific persona, run the CLI command from that user's auth (e.g. `--target-org coordinator-alias`).

---

## Working examples (all from real, published Salesforce projects)

### Example 1 — Record-triggered flow (single record initial state)

**Flow type**: record-triggered Opportunity (after-save). **Asserts**: a decision outcome was visited and a field was cleared.

Source: [salesforcecli/plugin-apex test fixture](https://github.com/salesforcecli/plugin-apex/blob/b8fc17ef/test/nuts/unifiedFrameworkProject/force-app/main/default/flowtests/test_opportunity_updates.flowtest-meta.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<FlowTest xmlns="http://soap.sforce.com/2006/04/metadata">
    <flowApiName>Populate_opp_description</flowApiName>
    <label>Test opportunity updates</label>
    <testPoints>
        <elementApiName>Start</elementApiName>
        <parameters>
            <leftValueReference>$Record</leftValueReference>
            <type>InputTriggeringRecordInitial</type>
            <value>
                <sobjectValue>{&quot;attributes&quot;:{&quot;type&quot;:&quot;Opportunity&quot;},&quot;AccountId&quot;:&quot;001D300000xpC0lIAE&quot;,&quot;Description&quot;:&quot;Agriculture&quot;,&quot;StageName&quot;:&quot;Prospecting&quot;,&quot;Probability&quot;:10,&quot;CloseDate&quot;:&quot;2026-10-01&quot;,&quot;Name&quot;:&quot;Test opp&quot;,&quot;OwnerId&quot;:&quot;005D3000007DeERIA0&quot;,&quot;ForecastCategoryName&quot;:&quot;Pipeline&quot;,&quot;IsPrivate&quot;:false}</sobjectValue>
            </value>
        </parameters>
    </testPoints>
    <testPoints>
        <assertions>
            <conditions>
                <leftValueReference>Update_description</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue><booleanValue>true</booleanValue></rightValue>
            </conditions>
        </assertions>
        <assertions>
            <conditions>
                <leftValueReference>$Record.Description</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue><stringValue></stringValue></rightValue>
            </conditions>
        </assertions>
        <elementApiName>Finish</elementApiName>
    </testPoints>
</FlowTest>
```

**Key elements**: `$Record` sobjectValue holds the inbound record as XML-escaped JSON. The first assertion proves the `Update_description` decision outcome was taken. The second proves the field is now empty.

### Example 2 — Before-update with Initial + Updated record snapshots

**Flow type**: before-save record-triggered. **Asserts**: numeric fields propagate to the post-update record.

Source: [SFDC-Assets/PSA-Location-Toolkit](https://github.com/SFDC-Assets/PSA-Location-Toolkit/blob/acb4b294/force-app/main/default/flowtests/PushAddressLatLongToItsParentLocation_flowTest.flowtest-meta.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<FlowTest xmlns="http://soap.sforce.com/2006/04/metadata">
    <flowApiName>PushAddressLatLongToItsParentLocation</flowApiName>
    <label>flowTest</label>
    <testPoints>
        <elementApiName>Start</elementApiName>
        <parameters>
            <leftValueReference>$Record</leftValueReference>
            <type>InputTriggeringRecordInitial</type>
            <value><sobjectValue>{&quot;City&quot;:&quot;McLean&quot;,&quot;Latitude&quot;:&quot;0&quot;,&quot;Longitude&quot;:&quot;0&quot;,&quot;attributes&quot;:{&quot;type&quot;:&quot;Address&quot;},&quot;ParentId&quot;:&quot;131a5000000WvMXAA0&quot;}</sobjectValue></value>
        </parameters>
        <parameters>
            <leftValueReference>$Record</leftValueReference>
            <type>InputTriggeringRecordUpdated</type>
            <value><sobjectValue>{&quot;City&quot;:&quot;McLean&quot;,&quot;Latitude&quot;:&quot;38.924428&quot;,&quot;Longitude&quot;:&quot;-77.231237&quot;,&quot;attributes&quot;:{&quot;type&quot;:&quot;Address&quot;},&quot;ParentId&quot;:&quot;131a5000000WvMXAA0&quot;}</sobjectValue></value>
        </parameters>
    </testPoints>
    <testPoints>
        <assertions>
            <conditions>
                <leftValueReference>$Record.Latitude</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue><numberValue>38.924428</numberValue></rightValue>
            </conditions>
            <errorMessage>Latitude value not correct</errorMessage>
        </assertions>
        <assertions>
            <conditions>
                <leftValueReference>$Record.Longitude</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue><numberValue>-77.231237</numberValue></rightValue>
            </conditions>
            <errorMessage>Longitude value not correct</errorMessage>
        </assertions>
        <elementApiName>Finish</elementApiName>
    </testPoints>
</FlowTest>
```

**Key elements**: two `<parameters>` blocks under the same `Start` point — `InputTriggeringRecordInitial` plus `InputTriggeringRecordUpdated` — let you test pre/post update behavior. `<errorMessage>` provides custom failure output.

### Example 3 — Action-element assertions (`WasVisited` / `HasError`)

**Flow type**: record-triggered. **Asserts**: a specific action element ran successfully (didn't just exist).

Source: [Cloud-Code-Academy/flow-to-code](https://github.com/Cloud-Code-Academy/flow-to-code/blob/5c00401e/force-app/lesson-examples/flowtests/AccountTrigger_Test_Create_Onboarding_Task.flowtest-meta.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<FlowTest xmlns="http://soap.sforce.com/2006/04/metadata">
    <flowApiName>AccountTrigger</flowApiName>
    <label>Test Create Onboarding Task</label>
    <testPoints>
        <elementApiName>Start</elementApiName>
        <parameters>
            <leftValueReference>$Record</leftValueReference>
            <type>InputTriggeringRecordInitial</type>
            <value><sobjectValue>{&quot;Name&quot;:&quot;ABC Company&quot;,&quot;Onboarding_Completed__c&quot;:false,&quot;OwnerId&quot;:&quot;005ak00000HQ4qzAAD&quot;}</sobjectValue></value>
        </parameters>
    </testPoints>
    <testPoints>
        <assertions>
            <conditions>
                <leftValueReference>Create_Onboarding_Task</leftValueReference>
                <operator>WasVisited</operator>
                <rightValue><booleanValue>true</booleanValue></rightValue>
            </conditions>
        </assertions>
        <assertions>
            <conditions>
                <leftValueReference>Create_Onboarding_Task</leftValueReference>
                <operator>HasError</operator>
                <rightValue><booleanValue>false</booleanValue></rightValue>
            </conditions>
        </assertions>
        <elementApiName>Finish</elementApiName>
    </testPoints>
</FlowTest>
```

**Key elements**: `<leftValueReference>` points at an action node by its API name (`Create_Onboarding_Task`), not a field path. The `WasVisited` operator confirms the action executed; `HasError` confirms it didn't fault. This is the assertion shape that genuinely catches regressions in side-effect-heavy flows.

---

## CLI integration

### Authoring path: build in UI, retrieve, then version-control

The fastest way to get a syntactically correct first FlowTest is the Flow Builder UI:

1. Setup → Flow → open the flow → **Debug** → set inputs → run → **Convert to Test**.
2. Retrieve to source: `sf project retrieve start --metadata "FlowTest:<FlowName>.<TestName>" --target-org <alias>`.
3. Commit the resulting `.flowtest-meta.xml` and edit further by hand.

Hand-editing from scratch is fine for small additions; for a brand-new file, the UI round-trip avoids enum/casing mistakes.

### Running tests

Older surface (`@salesforce/cli` < 2.107):
```bash
sf flow run test --tests <FlowTestName> --target-org <alias>
sf flow run test --test-level RunAllTestsInOrg --target-org <alias>
sf flow get test --test-run-id <id> --target-org <alias>
```

Current unified runner (preferred for CI — runs Apex + Flow tests together):
```bash
# Single flow test
sf logic run test --tests "FlowTesting.<flow-test-name>" --target-org <alias>

# All flow tests, sync, with coverage
sf logic run test --test-category Flow --test-level RunAllTestsInOrg --code-coverage --synchronous --target-org <alias>

# Async + retrieve
sf logic run test --test-category Flow --test-level RunAllTestsInOrg --target-org <alias>
sf logic get test --test-run-id <id> --target-org <alias>

# Discover every flow test name in the org
sf logic run test --synchronous --test-category Flow --test-level RunAllTestsInOrg --target-org <alias>
```

`--test-category Flow` and `--test-category Apex` are repeatable; omit both to run everything.

### Coverage

`--code-coverage` works for flow tests. The output reports coverage values for the tested flows (and Apex classes, if both categories ran). Treat it as a parity signal with Apex coverage in CI gates.

---

## Limitations & gotchas

- **No Mocking of callouts.** Flow tests don't have a callout-mock framework analogous to Apex's `HttpCalloutMock`. If the flow under test makes a callout, the FlowTest will execute it for real (or fail if the endpoint isn't reachable). Stub the callout via Apex action and mock at the Apex layer, or move the callout out of the flow.
- **`<sobjectValue>` is XML-escaped JSON.** All quotes inside the JSON become `&quot;`. The Flow Builder UI handles this — hand-editing is error-prone. Validate with `xmllint --noout` before deploying.
- **The doc's `ScheduledPath` example contains a typo** (extra `}` brace inside a `sobjectValue`). Don't copy the doc sample verbatim.
- **`<testType>WithAssertion</testType>` is doc-stated as required at API 66.0+** but most existing real-world files omit it (they were authored at lower APIs). New files should include it; old files keep working without it.
- **`InputVariable` parameter type is reserved.** Flow inputs for screen flows / autolaunched flows aren't yet bindable from FlowTest. The supported parameter types today are `InputTriggeringRecordInitial`, `InputTriggeringRecordUpdated`, and `ScheduledPath`. This is the biggest practical limitation — pure screen/autolaunched flows that take input variables can't be fully tested via FlowTest yet.
- **No `runAs`.** Run as a specific user by changing the CLI auth (`--target-org`).
- **One file per test.** No `@TestSetup`-equivalent for shared fixtures; if multiple tests need the same `<sobjectValue>`, copy-paste it.
- **DML rollback behavior**: confirmed by the docs to evaluate without committing real DML. Flow tests do not leave records in the org.

---

## Sources

- Metadata API reference (mirror, API 67.0): https://github.com/Avinava/sf-documentation-knowledge/blob/7902ba8a/knowledge/current/metadata-api/flowtest.md
- Live doc (JS-rendered SPA, may require browser): https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_flowtest.htm
- CLI `sf logic run test`: https://github.com/salesforcecli/plugin-apex/blob/main/messages/runlogictest.md
- CLI `sf logic get test`: https://github.com/salesforcecli/plugin-apex/blob/main/messages/logicgettest.md
- Real example 1 (decision + field assertion): https://github.com/salesforcecli/plugin-apex/blob/b8fc17ef/test/nuts/unifiedFrameworkProject/force-app/main/default/flowtests/test_opportunity_updates.flowtest-meta.xml
- Real example 2 (Initial + Updated): https://github.com/SFDC-Assets/PSA-Location-Toolkit/blob/acb4b294/force-app/main/default/flowtests/PushAddressLatLongToItsParentLocation_flowTest.flowtest-meta.xml
- Real example 3 (action-element assertions): https://github.com/Cloud-Code-Academy/flow-to-code/blob/5c00401e/force-app/lesson-examples/flowtests/AccountTrigger_Test_Create_Onboarding_Task.flowtest-meta.xml

Verify the live Salesforce doc before relying on `<testType>` enum values or `<flowTestFlowVersions>` shape — those fields are doc-asserted but not represented in the real-world samples I could cross-check.
