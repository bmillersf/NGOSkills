---
name: sf-metadata
description: >
  Salesforce metadata generation and querying with 120-point scoring.
  TRIGGER when: user creates custom objects, fields, validation rules, or touches
  .object-meta.xml, .field-meta.xml, .profile-meta.xml files; also phrases like
  "add a custom field", "create a new object", "define a validation rule".
  DO NOT TRIGGER when: permission set analysis (use sf-permissions),
  field-level security / user access questions (use sf-permissions), deploying
  metadata (use sf-deploy), or Flow XML (use sf-flow).
license: MIT
metadata:
  version: "1.2.0"
  author: "Jag Valaiyapathy"
  scoring: "120 points across 6 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/metadata
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_metadata.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric in references/best-practices-scoring.md (6 categories: Structure & Format 20, Naming Conventions 20, Data Integrity 20, Security & FLS 20, Documentation 20, Best Practices 20), mapped onto the 4-dimension default rubric from skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  metadata_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 15
      description: "Metadata XML is valid and deploys cleanly. Maps to Structure & Format (20). Valid XML, correct Salesforce namespace, API version >= 65.0, all required elements present."
      automatic_hard_fail_rules:
        - "Any XML with parse error (broken tags, unclosed elements)"
        - "Missing or wrong xmlns (must be http://soap.sforce.com/2006/04/metadata)"
        - "Missing apiVersion or apiVersion < 65.0 (deploy will fail or use deprecated behavior)"
    - name: Robustness
      max: 25
      hard_fail_below: 12
      description: "Metadata respects security boundaries + integrity constraints. Maps to Security & FLS (20) + Data Integrity (20). Sensitive fields flagged, FLS documented, required fields have defaults, picklists properly defined."
      automatic_hard_fail_rules:
        - "Any sensitive field type (SSN, credit card, password) without explicit FLS restriction"
        - "Any required field without default value or validation rule (deploy succeeds, runtime breaks)"
        - "Any object with ControlledByParent sharing on PII without explicit reason"
    - name: Fit
      max: 25
      hard_fail_below: 10
      description: "Metadata follows Salesforce naming conventions + platform patterns. Maps to Naming Conventions (20). Custom objects/fields end with __c, PascalCase API names, meaningful labels (no abbreviations)."
      automatic_hard_fail_rules:
        - "Any custom object or field API name not ending in __c"
        - "Any API name in snake_case or camelCase instead of PascalCase_With_Underscores"
        - "Any custom field reusing a standard object's API name (e.g., Lead__c when Lead exists)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Metadata deploys efficiently and respects limits. Maps to Documentation (20) + Best Practices (20). ApexDoc-style descriptions, indexed fields where appropriate, no excessive picklist values."
      automatic_hard_fail_rules:
        - "Any picklist with >1000 values (governor limit) or >100 without GlobalValueSet (maintenance hell)"
        - "Any custom object exceeding 800 custom fields (close to platform limit)"
  test_rubric:
    unit:
      required: true
      criteria: "Metadata XML validates against the Salesforce Metadata API schema (sf project deploy validate or equivalent dry-run)."
    integration:
      required: true
      criteria: "Metadata deploys to a connected scratch or sandbox org without errors. Object/field/permset visible via sf org list metadata."
    smoke:
      required: true
      criteria: "Created records via Anonymous Apex respect the metadata's required fields, validation rules, and FLS. Field types render correctly on the page layout."
---

# sf-metadata: Salesforce Metadata Generation and Org Querying

Expert Salesforce administrator specializing in metadata architecture, security model design, and schema best practices. Generate production-ready metadata XML and query org structures using sf CLI v2.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). Three subagents (planner / implementer / evaluator) loop against the 120-pt rubric in fresh context.

**Why metadata needs the harness:** the most damaging metadata failures deploy clean and break later. Required fields without defaults pass deploy validation but block runtime inserts. Sensitive fields without FLS leak through queries. PascalCase violations create shadow APIs that slowly diverge. Self-eval doesn't catch these because the deploy succeeds; adversarial eval grades the metadata against deploy-success-AND-runtime-correctness.

**Composition:** rubric in references/best-practices-scoring.md (120 pts, 6 categories). Frontmatter `metadata_dimensions` block maps onto 4 SPEC dimensions with hard-fail floors.

**Disabling:** set `eval_harness.enabled: false` in frontmatter.

---

## Core Responsibilities

1. **Metadata Generation**: Create Custom Objects, Fields, Profiles, Permission Sets, Validation Rules, Record Types, Page Layouts
2. **Org Querying**: Describe objects, list fields, query metadata using sf CLI v2
3. **Validation & Scoring**: Score metadata against 6 categories (0-120 points)
4. **Cross-Skill Integration**: Provide metadata discovery for sf-apex and sf-flow
5. **Deployment Integration**: Deploy metadata via sf-deploy skill

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **PermSet auto-gen** | [references/permset-auto-generation.md](references/permset-auto-generation.md) | Phase 3.5 rules, field type filters, XML example |
| **Scoring details** | [references/best-practices-scoring.md](references/best-practices-scoring.md) | 6-category breakdown, field template tips |
| **Field & CLI ref** | [references/field-and-cli-reference.md](references/field-and-cli-reference.md) | Field types, relationships, validation patterns, CLI commands |
| **Naming** | [references/naming-conventions.md](references/naming-conventions.md) | API name conventions |
| **Orchestration** | [references/orchestration.md](references/orchestration.md) | Extended orchestration patterns |

---

## CRITICAL: Orchestration Order

**sf-metadata → sf-flow → sf-deploy → sf-data** (you are here: sf-metadata)

sf-data requires objects deployed to org. Always deploy BEFORE creating test data.

---

## CRITICAL: Field-Level Security

**Deployed fields are INVISIBLE until FLS is configured!** Always prompt for Permission Set generation after creating objects/fields. See [references/permset-auto-generation.md](references/permset-auto-generation.md) for auto-generation workflow.

---

## Workflow (5-Phase Pattern)

### Phase 1: Requirements Gathering

**Ask the user** to gather:
- Operation type: **Generate** metadata OR **Query** org metadata
- If generating: Metadata type, target object, specific requirements
- If querying: Query type, target org alias, object name or metadata type

**Then**: Check existing metadata (`Glob: **/*-meta.xml`), verify sfdx-project.json exists.

### Phase 1.5: Org Discovery

Before generating ANY metadata, query the target org to avoid creating duplicates or misconfigurations.

**Existence check** — verify whether the object/field already exists:
```bash
sf sobject describe --sobject <ObjectApiName> --target-org <alias> --json
```

**Record type check** — confirm no existing record type serves the same purpose:
```bash
sf data query --query "SELECT Id, DeveloperName, Name, IsActive FROM RecordType WHERE SObjectType = '<Object>'" --target-org <alias> --json
```

**Layout resolution** — identify the correct page layout for the target profile + record type:
```bash
sf data query --query "SELECT Layout.Name, RecordType.DeveloperName, Profile.Name FROM ProfileLayout WHERE SObjectType = '<Object>'" --target-org <alias> --use-tooling-api --json
```

**Decision rules**:
- If the metadata **already exists and matches** the requirement: skip creation, report "already present"
- If the metadata **already exists but differs**: present a diff to the user and ask before proceeding
- If adding a field to a page layout: use the layout query result to find the correct layout — never default to `System Administrator` or the first layout found
- If the object **does not exist**: proceed to Phase 2

### Phase 2: Template Selection / Query Execution

#### For Generation

| Metadata Type | Template |
|---------------|----------|
| Custom Object | `assets/objects/custom-object.xml` |
| Text/Number/Currency/Date/Checkbox Field | `assets/fields/[type]-field.xml` |
| Picklist / Multi-Select Picklist | `assets/fields/picklist-field.xml` / `multi-select-picklist.xml` |
| Lookup / Master-Detail | `assets/fields/lookup-field.xml` / `master-detail-field.xml` |
| Formula / Roll-Up Summary | `assets/fields/formula-field.xml` / `rollup-summary-field.xml` |
| Email/Phone/URL/Text Area | `assets/fields/[type]-field.xml` |
| Profile / Permission Set | `assets/profiles/profile.xml` / `assets/permission-sets/permission-set.xml` |
| Validation Rule / Record Type / Layout | `assets/[type]/` |

**Template Path Resolution** (try in order):
1. Marketplace: `~/.claude/plugins/marketplaces/sf-skills/sf-metadata/assets/[path]`
2. Project: `[project-root]/sf-metadata/assets/[path]`

#### For Querying (sf CLI v2)

| Query Type | Command |
|------------|---------|
| Describe object | `sf sobject describe --sobject [Name] --target-org [alias] --json` |
| List custom objects | `sf org list metadata --metadata-type CustomObject --target-org [alias] --json` |
| List metadata types | `sf org list metadata-types --target-org [alias] --json` |

> See [references/field-and-cli-reference.md](references/field-and-cli-reference.md) for complete CLI commands and interactive generation.

### Phase 3: Generation / Validation

**File locations**:
- Objects: `force-app/main/default/objects/[ObjectName__c]/[ObjectName__c].object-meta.xml`
- Fields: `force-app/main/default/objects/[ObjectName]/fields/[FieldName__c].field-meta.xml`
- Permission Sets: `force-app/main/default/permissionsets/[PermSetName].permissionset-meta.xml`
- Validation Rules: `force-app/main/default/objects/[ObjectName]/validationRules/[RuleName].validationRule-meta.xml`

**Validation Report Format**:
```
Score: 105/120 ⭐⭐⭐⭐ Very Good
├─ Structure & Format:  20/20 (100%)
├─ Naming Conventions:  18/20 (90%)
├─ Data Integrity:      15/20 (75%)
├─ Security & FLS:      20/20 (100%)
├─ Documentation:       18/20 (90%)
└─ Best Practices:      14/20 (70%)
```

> See [references/best-practices-scoring.md](references/best-practices-scoring.md) for detailed category breakdowns and field template tips.

### Phase 3.5: Permission Set Auto-Generation

> See [references/permset-auto-generation.md](references/permset-auto-generation.md) for the complete workflow, field type rules, and XML template.

**Quick rules**: Exclude required fields (auto-visible) and Name fields. Formula/Roll-Up fields get `editable: false`. Master-Detail controlled by parent.

### Phase 4: Deployment

Use the **sf-deploy** skill: "Deploy metadata at force-app/main/default/objects/[ObjectName] to [target-org]"

Post-deployment: `sf org assign permset --name [ObjectName]_Access --target-org [alias]`

### Phase 5: Verification

Verify in Setup → Object Manager, check FLS for new fields, add to Page Layouts if needed.

---

## Scoring (120 Points)

> See [references/best-practices-scoring.md](references/best-practices-scoring.md) for full criteria.

**Categories**: Structure & Format (20), Naming Conventions (20), Data Integrity (20), Security & FLS (20), Documentation (20), Best Practices (20).

**Thresholds**: 108+ Excellent | 96+ Good | 84+ Acceptable | <72 BLOCKED

---

## Cross-Skill Integration

| From Skill | To sf-metadata | When |
|------------|----------------|------|
| sf-apex | → sf-metadata | "Describe Invoice__c" (discover fields before coding) |
| sf-flow | → sf-metadata | "Describe object fields, record types, validation rules" |
| sf-data | → sf-metadata | "Describe Custom_Object__c fields" (discover structure) |

| From sf-metadata | To Skill | When |
|------------------|----------|------|
| sf-metadata | → sf-deploy | "Deploy with --dry-run" |
| sf-metadata | → sf-flow | After creating objects/fields that Flow will reference |

---

## Metadata Anti-Patterns

| Anti-Pattern | Fix |
|--------------|-----|
| Profile-based FLS | Use Permission Sets for granular access |
| Hardcoded IDs in formulas | Use Custom Settings or Custom Metadata |
| Validation rule without bypass | Add `$Permission.Bypass_Validation__c` check |
| Too many picklist values (>200) | Consider Custom Object instead |
| Auto-number without prefix | Add meaningful prefix: `INV-{0000}` |
| No description on custom objects | Always document purpose |

---

## Key Insights

| Insight | Issue | Fix |
|---------|-------|-----|
| FLS is the Silent Killer | Deployed fields invisible without FLS | Always prompt for Permission Set generation |
| Required Fields ≠ Permission Sets | Salesforce rejects required fields in PS | Filter out required fields from fieldPermissions |
| Orchestration Order | sf-data fails if objects not deployed | sf-metadata → sf-flow → sf-deploy → sf-data |

## Common Errors

| Error | Fix |
|-------|-----|
| `Cannot deploy to required field` | Remove from fieldPermissions (auto-visible) |
| `Field does not exist` | Create Permission Set with field access |
| `SObject type 'X' not supported` | Deploy metadata first |
| `Element X is duplicated` | Reorder XML elements alphabetically |

---

## Validation

```bash
python3 ~/.claude/plugins/marketplaces/sf-skills/sf-metadata/hooks/scripts/validate_metadata.py <file_path>
```

**Scoring**: 120 points / 6 categories. Minimum 84 (70%) for deployment.

---

## Dependencies

**Docs**: `references/` folder — metadata-types-reference, field-types-guide, fls-best-practices, naming-conventions
**Required**: sf-deploy (optional) for deployment | API 66.0 | Block if score < 72
