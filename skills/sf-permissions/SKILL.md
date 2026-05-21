---
name: sf-permissions
description: >
  Permission Set analysis, hierarchy viewer, and access auditing.
  TRIGGER when: user asks "who has access to X?", analyzes permission sets/groups,
  or touches .permissionset-meta.xml / .permissionsetgroup-meta.xml files;
  also phrases like "who can see this field", "why can't users access [object]",
  "grant access to [object]", "audit permissions for this user".
  DO NOT TRIGGER when: creating new metadata (use sf-metadata), deploying
  permission sets (use sf-deploy), or Apex sharing logic (use sf-apex).
license: MIT
metadata:
  version: "1.1.0"
  author: "Jag Valaiyapathy"
  inspiration: "PSLab by Oumaima Arbani (github.com/OumArbani/PSLab)"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.perm_sets_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.securityImplGuide.meta/securityImplGuide/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/security
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_security.htm
metadata:
  scoring: "100 points across 5 categories — pass/fail emphasis (permissions either grant or deny; harness grades whether least-privilege + audit trail are honored)"
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "100-pt rubric (5 categories: Least Privilege 30, Permission Set Architecture 20, Audit + Documentation 20, FLS + Object Permissions Correctness 20, Profile Hygiene 10) — newly authored 2026-05-21. Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  permissions_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "FLS + object permissions correct. Maps to FLS + Object Permissions Correctness (20). Permissions either grant the right access or grant too much/too little — pass/fail at the field level, scored at the bundle level."
      automatic_hard_fail_rules:
        - "Any permission set granting Read on a field marked Sensitive without explicit business justification documented"
        - "Any object permission granting Modify All / View All without privileged-role tag"
        - "Any FLS gap: a field referenced in the org's Apex/LWC/Flow that no permission set grants Read access to"
    - name: Robustness
      max: 25
      hard_fail_below: 18
      description: "Least-privilege adherence. Maps to Least Privilege (30). Heaviest robustness floor — over-provisioned permissions are the #1 path to compliance violations and breach blast-radius."
      automatic_hard_fail_rules:
        - "Any permission set granting Modify All Data, View All Data, or Customize Application without 'requires_admin_approval: true' tag"
        - "Any production user assigned to a permission set that grants Manage Users (excluded from least-privilege by default)"
        - "Any guest-user profile or permission set granting CRUD on any PII-bearing object"
        - "Any service account permission set without IP-allowlist or certificate-bound auth requirement documented"
    - name: Fit
      max: 25
      hard_fail_below: 10
      description: "Permission set architecture. Maps to Permission Set Architecture (20). Permission Sets + Permission Set Groups for everything; Profiles only as the minimal baseline."
      automatic_hard_fail_rules:
        - "Any permission added directly to a Profile when a Permission Set could carry it (Profiles are migration debt)"
        - "Any Permission Set Group with circular or contradictory member sets"
        - "Any new permission set without a corresponding Permission Set Group entry (orphan perm sets accumulate)"
    - name: Performance
      max: 25
      hard_fail_below: 10
      description: "Audit + documentation. Maps to Audit + Documentation (20) + Profile Hygiene (10). Every permission grant traceable to a business reason; profiles cleaned of legacy grants."
      automatic_hard_fail_rules:
        - "Any permission set without description explaining who it's for and why"
        - "Any user assignment without business-reason field populated"
  test_rubric:
    unit:
      required: true
      criteria: "Permission set XML validates. SetupEntityAccess entries match the documented intent. No FLS gaps for fields referenced in org code."
    integration:
      required: true
      criteria: "Permission set deploys to a connected org. Test user assigned to the set can perform their declared actions and is denied undocumented ones (verified via runAs Apex or sf-permissions probe)."
    smoke:
      required: true
      criteria: "Quarterly permission audit reproduces the same allow/deny matrix. No drift between deployed perm sets and source-of-truth declarations."
---

# sf-permissions

> Salesforce Permission Set analysis, visualization, and auditing tool

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 100-pt rubric authored 2026-05-21 to fill the harness coverage gap. Robustness floor at 18 — over-provisioned permissions are the #1 path to compliance violations and breach blast-radius. Hard-fail rules block guest-user CRUD on PII, undocumented Modify All Data grants, and FLS gaps. Disable with `eval_harness.enabled: false`.

## When to Use This Skill

Use `sf-permissions` when the user needs to:
- Visualize Permission Set and Permission Set Group hierarchies
- Find out "who has access to X?" (objects, fields, Apex classes, custom permissions)
- Analyze what permissions a specific user has
- Export Permission Set configurations for auditing
- Generate Permission Set XML metadata
- Grant agent access via `<agentAccesses>` element

## Capabilities

| Capability | Description |
|------------|-------------|
| **Hierarchy Viewer** | Visualize all PS/PSG in an org as ASCII trees |
| **Permission Detector** | Find which PS/PSG grant a specific permission |
| **User Analyzer** | Show all permissions assigned to a user |
| **CSV Exporter** | Export PS configuration for documentation |
| **Metadata Generator** | Generate Permission Set XML (delegates to sf-metadata) |
| **Tooling API** | Query tab settings, system permissions via Tooling API |

## Prerequisites

```bash
pip install simple-salesforce rich  # Python dependencies
sf --version                         # Must be installed and authenticated
sf org display                       # Check current org
```

---

## Phase 1: Understanding the Request

| User Says | Capability | Function |
|-----------|------------|----------|
| "Show permission hierarchy" | Hierarchy Viewer | `hierarchy_viewer.py` |
| "Who has access to Account?" | Permission Detector | `permission_detector.py` |
| "What permissions does John have?" | User Analyzer | `user_analyzer.py` |
| "Export Sales_Manager PS to CSV" | CSV Exporter | `permission_exporter.py` |
| "Generate PS XML with these permissions" | Metadata Generator | `permission_generator.py` |

---

## Phase 2: Connecting to the Org

```bash
sf org list                          # List available orgs
sf org display --target-org <alias>  # Check specific org
```

```python
# Run from sf-permissions/scripts/
from auth import get_sf_connection
sf = get_sf_connection('myorg')  # or None for default
```

---

## Phase 3: Executing Queries

### 3.1 Permission Hierarchy Viewer

```bash
cd ~/.claude/plugins/marketplaces/sf-skills/sf-permissions/scripts
python cli.py hierarchy [--target-org ALIAS] [--format ascii|mermaid]
```

**Output Example**:
```
📦 ORG PERMISSION HIERARCHY
════════════════════════════════════════

📁 Permission Set Groups (3)
├── 🔒 Sales_Cloud_User (Active)
│   ├── View_All_Accounts
│   ├── Edit_Opportunities
│   └── Run_Reports
└── 🔒 Service_Cloud_User (Active)
    └── Case_Management

📁 Standalone Permission Sets (12)
├── Admin_Tools
├── API_Access
└── ... (10 more)
```

### 3.2 Permission Detector ("Who has access to X?")

**Supported Permission Types**: `object`, `field`, `apex`, `vf`, `flow`, `custom`, `tab`

```bash
python cli.py detect object Account --access delete
python cli.py detect field Account.AnnualRevenue --access edit
python cli.py detect apex MyApexClass
python cli.py detect custom Can_Approve_Expenses
```

### 3.3 User Permission Analyzer

```bash
python cli.py user "john.smith@company.com"
python cli.py user 005xx000001234AAA  # User ID also works
```

### 3.4 Permission Set Exporter

```bash
python cli.py export Sales_Manager --output /tmp/sales_manager.csv
```

### 3.5 Agent Access Permissions

> See [references/agent-access-guide.md](references/agent-access-guide.md) for full `<agentAccesses>` XML structure, deploy steps, and visibility troubleshooting (missing icon, name mismatch, CopilotSalesforceUser PS).

Employee Agents require `<agentAccesses>` in a Permission Set — `<agentName>` must match the agent's `developer_name` exactly.

---

## Phase 4: Rendering Output

- **ASCII Tree** (Terminal): Uses `rich` library for trees, tables, panels
- **Mermaid Diagrams** (Docs): `python cli.py hierarchy --format mermaid > hierarchy.md`

## Phase 5: Generating Metadata

```bash
python cli.py generate \
    --name "New_Sales_PS" \
    --label "New Sales Permission Set" \
    --objects Account:crud,Opportunity:cru \
    --fields Account.AnnualRevenue:rw \
    --apex MyApexClass,AnotherClass \
    --output /tmp/New_Sales_PS.permissionset-meta.xml
```

Or delegate to `sf-metadata` for more complex generation.

---

## SOQL Reference

> See [references/soql-reference.md](references/soql-reference.md) for the complete query catalog: Permission Set/Group queries, object permissions, field permissions, setup entity access (Apex, VF, Flows, Custom Permissions).

**Quick queries:**
```sql
-- All Permission Sets (non-profile)
SELECT Id, Name, Label FROM PermissionSet WHERE IsOwnedByProfile = false AND Type != 'Group'

-- User's PS Assignments
SELECT PermissionSetId, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = '005...'

-- Find PS with delete access to Account
SELECT Parent.Name FROM ObjectPermissions WHERE SobjectType = 'Account' AND PermissionsDelete = true
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `INVALID_SESSION_ID` | Re-authenticate: `sf org login web --alias myorg` |
| Slow queries | Filter by name: `WHERE Name LIKE 'Sales%'` |
| Tab settings | Requires Tooling API: `tooling_query(sf, ...)` |

---

## Common Workflows & Examples

> See [references/workflow-examples.md](references/workflow-examples.md) for detailed step-by-step workflows: audit "Who can delete Accounts?", troubleshoot user access, document a Permission Set, full org audit, security review, and PS creation examples.

---

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `sf-metadata` | Generate Permission Set XML from analysis results |
| `sf-apex` | Identify Apex classes to grant access to |
| `sf-deploy` | Deploy generated Permission Sets |
| `sf-data` | Query user assignments in bulk |
