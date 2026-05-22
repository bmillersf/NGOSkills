---
name: sf-industry-commoncore-omniscript
description: >
  OmniStudio OmniScript creation and validation with 120-point scoring. Use when
  building guided digital experiences, multi-step forms, or interactive processes
  that orchestrate Integration Procedures and Data Mappers.
  TRIGGER when: user creates OmniScripts, designs step flows, configures element
  types, or reviews existing OmniScript configurations; user says "build a guided flow"
  (clarify this is OmniStudio, not sf-flow), "multi-step form", "wizard for users to
  fill out", "step-by-step intake in OmniStudio", or "OmniStudio digital experience".
  DO NOT TRIGGER when: building FlexCards (use sf-industry-commoncore-flexcard), creating Integration
  Procedures directly (use sf-industry-commoncore-integration-procedure), analyzing dependencies
  (use sf-industry-commoncore-omnistudio-analyze), or standard Salesforce Flow (use sf-flow) —
  OmniScript is OmniStudio-specific.
license: MIT
metadata:
  version: "1.0.0"
  author: "David Ryan (weytani)"
  scoring: "120 points across 6 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://developer.salesforce.com/docs/platform/omnistudio/guide/os-omniscripts.html
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.os_create_omniscripts.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/industries
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_omnistudio.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric (6 categories: Design & Structure 25 / Data Integration 20 / Error Handling 20 / Performance 20 / User Experience 20 / Security 15) — mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  omniscript_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 15
      description: "Structural + data-integration correctness. Maps to Design & Structure (25) + Data Integration (20). Type/SubType/Language triplet unique and active, element hierarchy valid (Levels + Order), all DataRaptor / IP references resolve to active bundles, input/output maps wired."
      automatic_hard_fail_rules:
        - "Two active OmniScript versions with the same Type/SubType/Language triplet (only one IsActive allowed)"
        - "Action element references a DataRaptor or Integration Procedure that doesn't exist or is inactive in the target org"
        - "Circular OmniScript embedding (A embeds B which embeds A) — infinite-render loop"
        - "Missing PropertySetConfig on an action element (no inputMap / outputMap)"
        - "Step element with Level≠0 or input element with Level=0 (hierarchy violation that breaks rendering)"
    - name: Robustness
      max: 25
      hard_fail_below: 14
      description: "Error handling + validation. Maps to Error Handling (20). Action elements have showError configured, required inputs validate, fallback behavior defined for empty data sources, user-facing error text is actionable."
      automatic_hard_fail_rules:
        - "IP / DataRaptor Action element without showError + errorMessage configured (silent failure mode)"
        - "Required input element (label='*' or required=true) with no Validation element or pattern enforcing format"
        - "Submit Action with no fallback when postTransformBundle returns empty / errors"
        - "Hardcoded Salesforce ID (e.g., '0015g00000ABC123') in PropertySetConfig — breaks deploy across orgs"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Pattern adherence + UX conventions. Maps to User Experience (20). Step grouping logical (≤7-10 input elements / step), elements named PascalCase, navigation controls (Back/Next/Cancel) configured, conditional visibility used instead of always-shown irrelevant fields."
      automatic_hard_fail_rules:
        - "OmniScript built when a Salesforce Screen Flow would be the right pattern (single-screen data entry, no IP orchestration needed)"
        - "Step exceeding 15 elements (UX cliff — split into multiple steps)"
        - "Element naming with spaces, kebab-case, or non-PascalCase identifiers"
        - "Inapplicable elements always shown (no conditional show expression on context-dependent fields)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Performance + security. Maps to Performance (20) + Security (15). DataRaptor Extracts bounded, lazy loading on step entry, no client-side sensitive data, IP actions own server-side processing, FLS respected."
      automatic_hard_fail_rules:
        - "DataRaptor Extract Action with no filter / limit clause (unbounded fetch)"
        - "All action elements firing on OmniScript load instead of step entry (mass eager-load on first render)"
        - "Sensitive data (password, SSN, token, PHI/PII) materialized in client-side data JSON instead of staying server-side via IP"
        - "Loop Block iterating an unbounded array with no pagination / server-side limit"
  test_rubric:
    unit:
      required: true
      criteria: "OmniScript metadata validates: Type/SubType/Language unique, all element references resolve, PropertySetConfig JSON parses, no circular embeddings."
    integration:
      required: true
      criteria: "Deploys to a connected org. Activation succeeds (IsActive flips with no other active version on the triplet). Each Action element invokes its IP / DataRaptor and receives a non-error response in the deployed org."
    smoke:
      required: true
      criteria: "Walk-through of all paths: happy path completes submission, validation paths surface errors, conditional blocks show/hide correctly, prefill populates from DataRaptor Extract, save-for-later resumes with partial data when configured."
---

# sf-industry-commoncore-omniscript: OmniStudio OmniScript Creation and Validation

Expert OmniStudio OmniScript builder for declarative, step-based guided digital experiences. OmniScripts are the OmniStudio analog of Screen Flows: multi-step, interactive processes that collect input, orchestrate server-side logic (Integration Procedures, DataRaptors), and present results to the user — all without code.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 120-pt rubric across 6 OmniStudio categories, mapped onto the 4-dim shape. Correctness floor at 15 — a broken element hierarchy or duplicate-active-version takes the OmniScript out of production. Hard-fail rules block circular embeddings, broken IP/DataRaptor references, hardcoded Salesforce IDs, unbounded DataRaptor fetches, and client-side sensitive data. Disable with `eval_harness.enabled: false`.

---

## Quick Reference

**Scoring**: 120 points across 6 categories. **Thresholds**: ✅ 90+ (Deploy) | ⚠️ 67-89 (Review) | ❌ <67 (Block - fix required)

---

## Core Responsibilities

1. **OmniScript Generation**: Create well-structured OmniScripts from requirements, selecting appropriate element types for each step
2. **Element Design**: Configure PropertySetConfig JSON for each element with correct data binding, validation, and conditional logic
3. **Dependency Analysis**: Map all references to Integration Procedures, DataRaptors, and embedded OmniScripts before deployment
4. **Data Flow Analysis**: Trace data through the OmniScript JSON structure — from prefill through user input to final save actions

---

## CRITICAL: Orchestration Order

**sf-industry-commoncore-omnistudio-analyze → sf-industry-commoncore-datamapper → sf-industry-commoncore-integration-procedure → sf-industry-commoncore-omniscript → sf-industry-commoncore-flexcard** (you are here: sf-industry-commoncore-omniscript)

OmniScripts consume Integration Procedures and DataRaptors. Build those FIRST. FlexCards may launch OmniScripts — build FlexCards AFTER. Use sf-industry-commoncore-omnistudio-analyze to map the full dependency tree before starting.

---

## Key Insights

| Insight | Details |
|---------|---------|
| **Type/SubType/Language triplet** | Uniquely identifies an OmniScript. All three values are required and form the composite key. Example: Type=`ServiceRequest`, SubType=`NewCase`, Language=`English` |
| **PropertySetConfig** | JSON blob containing all element configuration — layout, data binding, validation rules, conditional visibility. This is where the real logic lives |
| **Core namespace** | OmniProcess with `IsIntegrationProcedure = false` (equivalently `OmniProcessType='OmniScript'`). Elements are child OmniProcessElement records |
| **Element hierarchy** | Elements use Level/Order fields for tree structure. Level 0 = Steps, Level 1+ = elements within steps. Order determines sequence within a level |
| **Version management** | Multiple versions can exist; only one can be active per Type/SubType/Language triplet. Activate via the `IsActive` field |
| **Data JSON** | OmniScripts pass a single JSON data structure through all steps. Elements read from and write to this shared JSON via merge field syntax |

---

## Workflow Design (5-Phase Pattern)

### Phase 1: Requirements Gathering

**Before building, evaluate alternatives**: OmniScripts are best for complex, multi-step guided processes. For simple single-screen data entry, consider Screen Flows. For data display without interaction, consider FlexCards.

**Ask the user** to gather:
- **Type**: The process category (e.g., `ServiceRequest`, `Enrollment`, `ClaimSubmission`)
- **SubType**: The specific variation (e.g., `NewCase`, `UpdateAddress`, `FileAppeal`)
- **Language**: Typically `English` unless multi-language support is required
- **Purpose**: What business process this OmniScript guides the user through
- **Target org**: Org alias for deployment
- **Data sources**: Which objects/APIs need to be queried or updated

**Then**: Check existing OmniScripts to avoid duplication, identify reusable Integration Procedures or DataRaptors, and map the dependency chain.

### Phase 2: Design & Element Selection

Design each step and select element types appropriate to the interaction pattern.

#### Container Elements

| Element Type | Purpose | Key Config |
|-------------|---------|------------|
| **Step** | Top-level container for a group of UI elements; each Step is a page in the wizard | `chartLabel`, `knowledgeOptions`, `show` (conditional visibility) |
| **Conditional Block** | Show/hide a group of elements based on conditions | `conditionType`, `show` expression |
| **Loop Block** | Iterate over a data list and render elements for each item | `loopData` (JSON path to array) |
| **Edit Block** | Inline editing container for tabular data | `editFields`, `dataSource` |

#### Input Elements

| Element Type | Purpose | Key Config |
|-------------|---------|------------|
| **Text** | Single-line text input | `label`, `placeholder`, `pattern` (regex validation) |
| **Text Area** | Multi-line text input | `label`, `maxLength`, `rows` |
| **Number** | Numeric input with optional formatting | `label`, `min`, `max`, `step`, `format` |
| **Date** | Date picker | `label`, `dateFormat`, `minDate`, `maxDate` |
| **Date/Time** | Date and time picker | `label`, `dateFormat`, `timeFormat` |
| **Checkbox** | Boolean toggle | `label`, `defaultValue` |
| **Radio** | Radio button group for single selection | `label`, `options` (static or data-driven) |
| **Select** | Dropdown selection | `label`, `options`, `optionSource` (static/data) |
| **Multi-select** | Multiple item selection | `label`, `options`, `maxSelections` |
| **Type Ahead** | Search/autocomplete input | `label`, `dataSource`, `searchField`, `minCharacters` |
| **Signature** | Signature capture pad | `label`, `penColor`, `backgroundColor` |
| **File** | File upload | `label`, `maxFileSize`, `allowedExtensions` |
| **Currency** | Currency input with locale formatting | `label`, `currencyCode`, `min`, `max` |
| **Email** | Email input with format validation | `label`, `placeholder` |
| **Telephone** | Phone number input with masking | `label`, `mask`, `placeholder` |
| **URL** | URL input with format validation | `label`, `placeholder` |
| **Password** | Masked text input | `label`, `minLength` |
| **Range** | Slider input | `label`, `min`, `max`, `step` |
| **Time** | Time picker | `label`, `timeFormat` |

#### Display Elements

| Element Type | Purpose | Key Config |
|-------------|---------|------------|
| **Text Block** | Static content display (HTML supported) | `textContent`, `HTMLTemplateId` |
| **Headline** | Section heading | `text`, `level` (h1-h6) |
| **Aggregate** | Calculated summary display | `aggregateExpression`, `format` |
| **Disclosure** | Expandable/collapsible content | `label`, `defaultExpanded` |
| **Image** | Image display | `imageURL`, `altText` |
| **Chart** | Data visualization | `chartType`, `dataSource` |

#### Action Elements

| Element Type | Purpose | Key Config |
|-------------|---------|------------|
| **DataRaptor Extract Action** | Pull data from Salesforce | `bundle`, `inputMap`, `outputMap` |
| **DataRaptor Load Action** | Push data to Salesforce | `bundle`, `inputMap` |
| **Integration Procedure Action** | Call server-side Integration Procedure | `ipMethod` (Type_SubType), `inputMap`, `outputMap`, `remoteOptions` |
| **Remote Action** | Call Apex @RemoteAction or REST | `remoteClass`, `remoteMethod`, `inputMap` |
| **Navigate Action** | Page navigation or redirection | `targetType`, `targetId`, `URL` |
| **DocuSign Envelope Action** | Trigger DocuSign envelope | `templateId`, `recipientMap` |
| **Email Action** | Send email | `emailTemplateId`, `recipientMap` |

#### Logic Elements

| Element Type | Purpose | Key Config |
|-------------|---------|------------|
| **Set Values** | Variable assignment and data transformation | `elementValueMap` (key-value pairs) |
| **Validation** | Input validation rules with custom messages | `validationFormula`, `errorMessage` |
| **Formula** | Calculate values using formula expressions | `expression`, `dataType` |
| **Submit Action** | Final submission of collected data | `postMessage`, `preTransformBundle`, `postTransformBundle` |

### Phase 3: Generation & Validation

```bash
# Verify no duplicate Type/SubType/Language exists
sf data query -q "SELECT Id,Name,Type,SubType,Language,IsActive,VersionNumber FROM OmniProcess WHERE Type='<Type>' AND SubType='<SubType>' AND Language='<Language>' AND OmniProcessType='OmniScript'" -o <org>
```

**Build the OmniScript**:
1. Create the OmniProcess record with Type, SubType, Language, and OmniProcessType='OmniScript'
2. Create OmniProcessElement child records for each Step (Level=0)
3. Create OmniProcessElement child records for each element within Steps (Level=1+, ordered by Order field)
4. Configure PropertySetConfig JSON for each element
5. Wire action elements to their Integration Procedures / DataRaptors

**Validation (STRICT MODE)**:
- **BLOCK**: Missing Type/SubType/Language, circular OmniScript embedding, broken IP/DataRaptor references, missing required PropertySetConfig fields
- **WARN**: Steps with no elements, input elements without validation, missing error handling on actions, unused data paths, deeply nested elements (>4 levels)

**Validation Report Format** (6-Category Scoring 0-120):
```
Score: 102/120 ---- Very Good
-- Design & Structure: 22/25 (88%)
-- Data Integration: 18/20 (90%)
-- Error Handling: 17/20 (85%)
-- Performance: 18/20 (90%)
-- User Experience: 17/20 (85%)
-- Security: 10/15 (67%)
```

### Phase 4: Deployment

1. Deploy all dependencies first: DataRaptors, Integration Procedures, referenced OmniScripts
2. Retrieve or deploy OmniScript metadata:
   ```bash
   sf project retrieve start -m OmniScript:<Name> -o <org>
   sf project deploy start -m OmniScript:<Name> -o <org>
   ```
3. Activate the OmniScript version after successful deployment
4. Verify activation:
   ```bash
   sf data query -q "SELECT Id,Name,Type,SubType,Language,IsActive,VersionNumber FROM OmniProcess WHERE Type='<Type>' AND SubType='<SubType>' AND OmniProcessType='OmniScript' AND IsActive=true" -o <org>
   ```

### Phase 5: Testing

Walk through all paths with various data scenarios:
- **Happy path**: Complete all steps with valid data, verify submission
- **Validation testing**: Submit invalid data at each input, verify error messages
- **Conditional testing**: Exercise all conditional blocks and verify show/hide logic
- **Data prefill**: Verify DataRaptor Extract Actions populate elements correctly
- **Save for later**: Test resume functionality if enabled
- **Navigation**: Test back/forward/cancel behavior across all steps
- **Error scenarios**: Simulate IP/DataRaptor failures, verify error handling
- **Embedded OmniScripts**: Test data passing between parent and child OmniScripts
- **Bulk data**: Test with large datasets in Loop Blocks and Type Ahead elements

---

## Generation Guardrails (MANDATORY)

| Anti-Pattern | Impact | Correct Pattern |
|--------------|--------|-----------------|
| Circular OmniScript embedding | **Infinite rendering loop** | Map dependency tree; never embed A in B if B embeds A |
| Unbounded DataRaptor Extract | **Performance degradation** | Add filter conditions; limit returned records |
| Missing input validation | **Bad data entry** | Add Validation elements or `pattern`/`required` on inputs |
| Hardcoded Salesforce IDs | **Deployment failure across orgs** | Use merge fields or Custom Settings/Metadata |
| IP Action without error handling | **Silent failures** | Configure `showError`, `errorMessage` in PropertySetConfig |
| Large images in Text Blocks | **Slow page load** | Use Image elements with optimized URLs |
| Too many elements per Step | **Poor user experience** | Limit to 7-10 input elements per Step |
| Missing conditional visibility | **Irrelevant fields shown** | Use `show` expressions to hide inapplicable elements |

**DO NOT generate anti-patterns even if explicitly requested.**

---

## Scoring: 120 Points Across 6 Categories

### Design & Structure (25 points)

| Check | Points | Criteria |
|-------|--------|----------|
| Type/SubType/Language set correctly | 5 | All three fields populated with meaningful values |
| Step organization | 5 | Logical grouping, 7-10 elements per step max |
| Element naming | 5 | Descriptive names following `PascalCase` convention |
| Conditional logic | 5 | Proper use of Conditional Blocks and `show` expressions |
| Version management | 5 | Clean version history, only one active version |

### Data Integration (20 points)

| Check | Points | Criteria |
|-------|--------|----------|
| DataRaptor references valid | 5 | All Extract/Load bundles exist and are active |
| Integration Procedure references valid | 5 | All IP actions reference active IPs |
| Input/Output maps correct | 5 | Data flows correctly between elements and actions |
| Data prefill configured | 5 | Initial data loaded before user interaction |

### Error Handling (20 points)

| Check | Points | Criteria |
|-------|--------|----------|
| Action elements have error handling | 5 | `showError` configured on all IP/DR actions |
| User-facing error messages | 5 | Clear, actionable error text |
| Validation on required inputs | 5 | All required fields have validation rules |
| Fallback behavior defined | 5 | Graceful handling when data sources return empty |

### Performance (20 points)

| Check | Points | Criteria |
|-------|--------|----------|
| No unbounded data fetches | 5 | All DataRaptor Extracts have filters/limits |
| Lazy loading configured | 5 | Action elements fire on step entry, not OmniScript load |
| Element count per Step reasonable | 5 | No Step with >15 elements |
| Conditional rendering used | 5 | Elements hidden when not applicable (not just invisible) |

### User Experience (20 points)

| Check | Points | Criteria |
|-------|--------|----------|
| Logical step flow | 5 | Steps follow natural task progression |
| Input labels and help text | 5 | All inputs have clear labels and contextual help |
| Navigation controls | 5 | Back, Next, Cancel, Save for Later configured appropriately |
| Responsive layout | 5 | Elements configured for mobile and desktop breakpoints |

### Security (15 points)

| Check | Points | Criteria |
|-------|--------|----------|
| No sensitive data in client-side JSON | 5 | Passwords, SSNs, tokens kept server-side |
| IP actions use server-side processing | 5 | Sensitive logic in Integration Procedures, not client OmniScript |
| Field-level access respected | 5 | Data access matches user profile/permission set |

---

## CLI Commands

```bash
# List active OmniScripts
sf data query -q "SELECT Id,Name,Type,SubType,Language,IsActive,VersionNumber FROM OmniProcess WHERE IsActive=true AND OmniProcessType='OmniScript'" -o <org>

# Query elements for a specific OmniScript
sf data query -q "SELECT Id,Name,ElementType,PropertySetConfig,Level,Order FROM OmniProcessElement WHERE OmniProcessId='<id>' ORDER BY Level,Order" -o <org>

# Retrieve OmniScript metadata
sf project retrieve start -m OmniScript:<Name> -o <org>

# Deploy OmniScript metadata
sf project deploy start -m OmniScript:<Name> -o <org>

# Check OmniScript versions
sf data query -q "SELECT Id,VersionNumber,IsActive,LastModifiedDate FROM OmniProcess WHERE Type='<Type>' AND SubType='<SubType>' AND OmniProcessType='OmniScript' ORDER BY VersionNumber DESC" -o <org>
```

---

## Cross-Skill Integration

| From Skill | To sf-industry-commoncore-omniscript | When |
|------------|------------------|------|
| sf-industry-commoncore-omnistudio-analyze | -> sf-industry-commoncore-omniscript | "Analyze dependencies before building OmniScript" |
| sf-industry-commoncore-datamapper | -> sf-industry-commoncore-omniscript | "DataRaptor ready, build the OmniScript that uses it" |
| sf-industry-commoncore-integration-procedure | -> sf-industry-commoncore-omniscript | "IP ready, wire it into the OmniScript action" |

| From sf-industry-commoncore-omniscript | To Skill | When |
|--------------------|----------|------|
| sf-industry-commoncore-omniscript | -> sf-industry-commoncore-flexcard | "Build FlexCard that launches this OmniScript" |
| sf-industry-commoncore-omniscript | -> sf-deploy | "Deploy OmniScript to target org" |
| sf-industry-commoncore-omniscript | -> sf-industry-commoncore-omnistudio-analyze | "Map full dependency tree before deployment" |
| sf-industry-commoncore-omniscript | -> sf-industry-commoncore-integration-procedure | "Need a new IP for this OmniScript action" |
| sf-industry-commoncore-omniscript | -> sf-industry-commoncore-datamapper | "Need a DataRaptor for data prefill" |

---

## Edge Cases

| Scenario | Solution |
|----------|----------|
| Multi-language OmniScript | Create separate versions per Language with shared Type/SubType. Use translation workbench for labels |
| Embedded OmniScript data passing | Map parent data JSON keys to child OmniScript input via `prefillJSON`. Test data round-trip |
| Large Loop Block datasets | Paginate or limit DataRaptor results. Consider server-side filtering in IP |
| OmniScript in FlexCard flyout | Ensure FlexCard passes required context data. Test flyout sizing |
| Community/Experience Cloud deployment | Verify OmniScript component is available in Experience Builder. Check guest user permissions |
| Save & Resume (Save for Later) | Configure `saveNameTemplate`, `saveExpireInDays`. Test resume with partial data |
| Versioning conflicts | Deactivate old version before activating new. Never have two active versions for same triplet |
| Custom Lightning Web Components in OmniScript | Register LWC as OmniScript-compatible. Follow `omniscript-lwc` namespace conventions |

**Debug**: OmniScript not rendering -> check activation status + element hierarchy | Data not prefilling -> verify DataRaptor Extract output mapping + JSON path | IP action failing -> check IP independently first + verify input map | Steps not showing -> review conditional visibility expressions

---

## Notes

**Dependencies** (required): sf-industry-commoncore-datamapper, sf-industry-commoncore-integration-procedure | **Dependencies** (optional): sf-deploy, sf-industry-commoncore-flexcard, sf-industry-commoncore-omnistudio-analyze | **API**: 66.0 | **Mode**: Strict (warnings block) | **Scoring**: Block deployment if score < 67 | **Reference docs**: See `references/` for element types and best practices

**Creating OmniScripts programmatically**: Use REST API (`sf api request rest --method POST --body @file.json`). Required fields: `Name`, `Type`, `SubType`, `Language`, `VersionNumber`. OmniScripts default to `IsIntegrationProcedure=false` (do NOT set `OmniProcessType` — it is computed). The `sf data create record --values` flag cannot handle JSON textarea fields like `PropertySetConfig`. Create child `OmniProcessElement` records via REST API for each Step and element.

---

## License

MIT License.
Copyright (c) 2026 David Ryan (weytani)
