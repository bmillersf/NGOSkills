---
name: sf-devops-center
description: >
  Salesforce DevOps Center + 1GP/2GP/Unlocked packaging architecture with
  130-point scoring. Owns the low-code, GitHub-backed change-management
  pipeline (Work Items → Pipelines → Stages → Change Bundles → Merge →
  Deploy) AND the managed/unlocked package lifecycle (create, version,
  promote, install, AppExchange listing prep). TRIGGER when: user configures
  DevOps Center in Setup, creates Work Items, designs a Dev → UAT → Prod
  Pipeline, resolves merge conflicts between Change Bundles, wires DevOps
  Center to a GitHub repo, inspects Deployment Logs; or builds a 1GP managed
  package, a 2GP managed/unlocked package, runs `sf package version create`,
  promotes a package version, prepares an AppExchange security review, or
  handles branch-based packaging; also phrases like "set up DevOps Center",
  "merge this change bundle", "release pipeline UI-based", "build me an
  unlocked package", "2GP vs 1GP", "AppExchange listing", "install this
  package in prod", "bump package version".
  DO NOT TRIGGER when: user uses the CLI-first `sf project deploy start` /
  `sf project retrieve start` workflow without DevOps Center or packaging
  (use sf-deploy — the general-purpose deployment skill); asks about bulk
  data import/export (use sf-data); writes Apex class code (use sf-apex).
license: MIT
compatibility: "DevOps Center ships free with Enterprise+ editions but requires GitHub integration; 2GP/Unlocked packaging requires Dev Hub enabled on a production org; 1GP is legacy but still supported"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "130 points across 7 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.devops_center.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.packagingGuide.meta/packagingGuide/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/decision-guides/packaging
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_devops.htm
---

# sf-devops-center

Two related shipping surfaces Salesforce customers care about: **DevOps Center** (the UI-based, GitHub-backed release pipeline in Setup) and **Packaging** (1GP, 2GP Managed, and 2GP Unlocked — the way you bundle metadata for ISV distribution, internal reuse, or AppExchange listing). Both are "how code gets from one org to another, reliably and with source control"; both are distinct from the raw CLI `sf project deploy` surface.

---

## 1. When this skill owns the task

Use this skill when the user is working **through the DevOps Center UI**, **with packages (1GP or 2GP)**, or asking about the managed release lifecycle. Delegate when:

| If the user wants... | Route to | Why |
|---|---|---|
| `sf project deploy start --source-dir ...` / `--manifest ...` without DevOps Center | [sf-deploy](../sf-deploy/SKILL.md) | CLI-first, no pipeline UI, no package |
| Bulk load / export records | [sf-data](../sf-data/SKILL.md) | Data, not metadata |
| Create metadata XML (objects, fields, permission sets) | [sf-metadata](../sf-metadata/SKILL.md) | Authoring vs shipping |
| Write Apex classes | [sf-apex](../sf-apex/SKILL.md) | Code authoring |
| Back up the org before a release | [sf-backup-datamask](../sf-backup-datamask/SKILL.md) | Production safety is a cross-skill concern |
| Configure OAuth/JWT for CI/CD auth | [sf-connected-apps](../sf-connected-apps/SKILL.md) | Auth is a dependency, not DevOps Center itself |
| Review/assign permissions that ship with the package | [sf-permissions](../sf-permissions/SKILL.md) | Permission design |

**Key boundary with sf-deploy**: DevOps Center and sf-deploy are **not** mutually exclusive. DevOps Center calls the Metadata API under the hood; `sf project deploy start` uses the same API directly. Choose DevOps Center when the customer needs **non-technical release managers** (admin-led change management, visual pipeline, GitHub abstraction). Choose sf-deploy when the team is dev-first and wants CLI/CI control.

---

## 2. Cross-cloud scope note (replaces Phase 0)

DevOps Center and Packaging are **platform-level** shipping surfaces: they behave identically across Sales, Service, Nonprofit, Marketing Cloud Growth, Revenue, and every industry cloud. **Skip the industry pre-check** — this skill is the destination for any industry's deployment and release work.

However, industry-specific compliance regimes influence the release discipline:

- **Health Cloud / HIPAA** → SOX + HIPAA both require documented change control. DevOps Center's Work Item history + GitHub PR history satisfy "who changed what, when, why." Every prod release gets a signed-off Work Item. Cross-reference [sf-industry-health](../sf-industry-health/SKILL.md).
- **FSC / SOX-regulated** → SOX §404 mandates documented segregation of duties between developer and approver. DevOps Center's Stage approval workflow (Dev → UAT with reviewer, UAT → Prod with separate approver) is the preferred mechanism. Cross-reference [sf-industry-fsc](../sf-industry-fsc/SKILL.md).
- **Public Sector / FedRAMP** → Government Cloud Plus orgs. Packages must be deployed from an approved source-control repo; DevOps Center's GitHub binding provides the audit chain. Cross-reference [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md).
- **Education Cloud / FERPA** → Not heavily affected by release mechanics, but EDA managed package upgrades (1GP) must be coordinated with the institution's change window. Cross-reference [sf-industry-education](../sf-industry-education/SKILL.md).
- **Nonprofit / NPSP 1GP** → NPSP is distributed as a 1GP managed package. Customers do **not** build NPSP; they install it. But nonprofit customers often build **unlocked packages** of their customizations layered on top of NPSP/NPC. Cross-reference [sf-nonprofit-npsp](../sf-nonprofit-npsp/SKILL.md) and [sf-nonprofit-cloud](../sf-nonprofit-cloud/SKILL.md).

Regardless of regime: document every production deployment with a Work Item, require at least one non-author approver, and keep the GitHub repo as the source of truth.

---

## 3. Required context to gather first

Ask or infer:

1. **Scope** — DevOps Center pipeline work, packaging work, or both?
2. **Edition + license** — DevOps Center is free on Enterprise+; 2GP packaging requires a **Dev Hub** org (enabled in Setup → Dev Hub on a production org, typically).
3. **Source control** — DevOps Center requires GitHub (GitHub Enterprise supported). Does the customer have a repo? Who owns it?
4. **Team shape** — admin-led (UI-first) or dev-led (CLI-first)? DevOps Center suits admins; dev teams often prefer `sf` CLI + GitHub Actions.
5. **Environment topology** — how many sandboxes feed prod? Dev → UAT → Prod is the default pipeline; larger orgs run Feature → Dev Shared → QA → UAT → Hotfix → Prod.
6. **Packaging intent** — internal reuse (Unlocked), AppExchange distribution (2GP Managed), or legacy ISV (1GP)?
7. **Namespace** — 2GP Managed and 1GP packages require a namespace registered against a Dev Hub. Unlocked packages can be no-namespace or namespaced.
8. **Target install orgs** — Developer / sandbox / production / scratch? Each has different install-validation behavior (e.g., Apex tests required for prod).
9. **Existing managed packages installed** — NPSP (1GP), EDA (1GP), OmniStudio (1GP vlocity_cmt/_ins), FSC (1GP industries), Revenue Cloud Advanced (2GP) all affect release strategy.

---

## 4. Workflow phases

### Phase 1 — Decide: DevOps Center, Packaging, or both?

Most teams end up with both. The usual pattern:
- **DevOps Center** handles change flow across Dev → UAT → Prod for the customer's custom metadata.
- **Packaging** handles net-new capability bundles (internal reusable component libraries, ISV AppExchange listings, cross-org deployable feature sets).

Route decisions:

| Goal | Tool |
|---|---|
| Move changes from sandbox to prod with visibility | DevOps Center |
| Bundle a reusable component library across our 5 orgs | Unlocked Package |
| List on AppExchange | 2GP Managed Package |
| Maintain a legacy ISV package (already built on 1GP) | 1GP (do not new-build on 1GP; migrate to 2GP) |
| Push configuration changes between a nonprofit admin's sandbox and prod, admin-led | DevOps Center |

### Phase 2 — DevOps Center setup

**Prerequisites**
1. Setup → DevOps Center → Enable DevOps Center (installs the managed package; one-time).
2. Authorize GitHub integration (OAuth to GitHub personal/org account).
3. Create or select the GitHub repo that will hold source metadata.
4. Configure **Environments** (one per sandbox + one for prod): name, target org, authentication.

**Core objects**

| Object | Purpose |
|---|---|
| **Project** | Top-level container for a GitHub repo + its Pipeline |
| **Pipeline** | Ordered list of Stages (Dev → Integration → UAT → Prod) |
| **Stage** | A single step binding an Environment to a GitHub branch |
| **Work Item** | A single unit of change (feature, bugfix). Maps to a GitHub feature branch. |
| **Change Bundle** | The metadata components attached to a Work Item, grouped for review |
| **Deployment Log** | Audit record of a promotion between Stages |

**Typical flow**
1. Admin creates a Work Item → "Add volunteer-hours tracker."
2. DevOps Center creates a feature branch in GitHub (`feature/WI-123`).
3. Admin makes changes in the Dev sandbox → DevOps Center detects changed metadata → admin reviews Change Bundle → attaches components.
4. Admin clicks **Commit** → DevOps Center pushes Change Bundle to the feature branch.
5. Admin clicks **Promote to UAT** → DevOps Center opens a GitHub PR from `feature/WI-123` → `uat` branch → reviewer approves → DevOps Center merges → DevOps Center deploys to UAT environment.
6. Repeat Promote → Prod. UAT approver and Prod approver should be different people (SOX).

**Merge conflicts**
- DevOps Center surfaces conflicts between two concurrent Work Items when both modify the same metadata component.
- Resolution: open the conflicted file in GitHub, resolve manually, re-run the promote. DevOps Center does not auto-resolve.

**Source tracking**
- DevOps Center uses Source Tracking-enabled sandboxes (standard on modern sandboxes). The "Pull Changes" action scans the environment for delta since the last commit.

### Phase 3 — Packaging decision: 1GP vs 2GP Managed vs 2GP Unlocked

| Dimension | 1GP Managed | 2GP Managed | 2GP Unlocked |
|---|---|---|---|
| **New builds?** | No — legacy only | Yes for ISV/AppExchange | Yes for internal |
| **Namespace required** | Yes (one org = one namespace forever) | Yes | Optional |
| **Dev Hub required** | No | Yes | Yes |
| **Source-driven?** | No (org-based) | Yes (branch = version) | Yes |
| **IP protection?** | Yes | Yes | No (subscriber can edit) |
| **Editable post-install?** | No | No | Yes |
| **Versioning model** | Major.minor per release | semver-style (major.minor.patch.build) | semver-style |
| **Upgrade model** | Push upgrades | Push upgrades (and manual) | Manual install of new version |
| **AppExchange-listable?** | Yes | Yes | No |
| **Typical use** | Legacy ISVs (NPSP, EDA) | New ISV products | Customer internal capability bundles |

**Default recommendation**: Unless there's a specific 1GP reason, **do not build on 1GP in 2026**. Use 2GP Managed for AppExchange, 2GP Unlocked for internal.

### Phase 4 — 2GP packaging workflow (managed or unlocked)

**Prerequisites**
1. Dev Hub enabled on a production org.
2. Namespace (for managed) registered + linked to Dev Hub.
3. `sfdx-project.json` configured with package directories and `packageAliases`.
4. GitHub repo (recommended).

**Canonical commands**

```bash
# Create the package (one-time)
sf package create \
  --name MyPackage \
  --package-type Unlocked \
  --path force-app/main/default \
  --target-dev-hub mydevhub

# Create a package version (the shippable artifact)
sf package version create \
  --package MyPackage \
  --installation-key-bypass \
  --wait 30 \
  --target-dev-hub mydevhub \
  --code-coverage

# List versions
sf package version list --target-dev-hub mydevhub

# Install into a target org (Beta version)
sf package install \
  --package "MyPackage@1.0.0-1" \
  --target-org myuat \
  --wait 30 \
  --no-prompt

# Promote to Released (required before installing in production)
sf package version promote \
  --package "MyPackage@1.0.0-1" \
  --target-dev-hub mydevhub \
  --no-prompt

# Install into production (now that it's Released)
sf package install \
  --package "MyPackage@1.0.0-1" \
  --target-org myprod \
  --wait 30
```

**Branch-based packaging**
- Pattern: each git branch builds its own package version stream. `main` → Released stream; `dev` → Beta stream; `feature/*` → preview versions.
- Use `--branch` on `sf package version create` to tag the branch. Dev Hub tracks version ancestry per branch.

**Versioning rules**
- `major.minor.patch.build` — increment major on breaking changes, minor on new features, patch on bugfixes.
- `build` is Dev Hub-assigned at creation time.
- Once a version is **Promoted to Released**, it's immutable and installable in production. Beta versions are for sandbox testing only.

### Phase 5 — AppExchange listing prep (2GP Managed only)

1. Build 2GP Managed package (namespaced).
2. Pass Security Review:
   - Run **Salesforce Code Analyzer v5** against the package (`sf code-analyzer run --workspace force-app`).
   - Review findings; remediate all "High" and "Critical."
   - Submit package version + test org + security-review questionnaire via Partner Community.
   - Review turnaround is weeks; first-time listings take 4-8 weeks.
3. Create AppExchange listing in Partner Community: title, description, screenshots, pricing, videos.
4. Tie the listing to the promoted package version.
5. Publish.

### Phase 6 — Legacy 1GP maintenance (not new builds)

If a customer already owns a 1GP managed package (e.g., a historical internal ISV), the lifecycle is:

```bash
# Convert 1GP to 2GP (GA, sf CLI v2.92.7+)
sf package convert --package <1GP-package-id> --target-dev-hub mydevhub

# Schedule push upgrade (1GP only)
sf package push-upgrade schedule \
  --package <package-id> \
  --start-time "2026-06-15T02:00:00Z"

# Monitor
sf package push-upgrade list --package <package-id>
```

Conversion is one-way and preserves namespace. Recommended for any 1GP still under active development.

### Phase 7 — Package installation + rollback

**Installation options**
- CLI: `sf package install`
- UI: Setup → Package Manager → Install URL (https://login.salesforce.com/packaging/installPackage.apexp?p0=<version-id>)
- Unattended (CI/CD): CLI + JWT auth Connected App

**Install gotchas**
- Some packages require **SecurityType** at install (Full / Custom / None). Choose Custom for production; assign permissions explicitly post-install.
- Apex tests run at install time for prod installs. Failed tests → install fails. Pre-validate in UAT.

**Rollback**
- 2GP: install the prior version. Packages are install-forward; there's no "uninstall and restore state." Carefully test downgrade paths.
- Uninstalling a package removes all package components. Custom data in package-owned objects may be retained per retention period (30 days) then purged.

---

## 5. Scoring rubric (130 points, 7 categories)

| Category | Max | Passing | What to check |
|---|---|---|---|
| **Scope + edition clarity** | 15 | 10 | DevOps Center vs sf-deploy decision justified; Dev Hub confirmed for 2GP; industry regime named |
| **DevOps Center setup + pipeline** | 25 | 17 | Environments configured; Pipeline stages match sandbox topology; GitHub repo + branches correct; approval roles set |
| **Work Item + Change Bundle discipline** | 20 | 14 | One Work Item per unit of change; Change Bundle review step present; merge conflict strategy documented |
| **Packaging decision** | 20 | 14 | 1GP / 2GP Managed / 2GP Unlocked choice matches intent; namespace strategy correct; ancestry planning (branch-based) considered |
| **Package versioning + promotion** | 20 | 14 | Version scheme (semver) explicit; Beta vs Released gates honored; ancestry consistent; `--code-coverage` used in CI |
| **AppExchange / ISV readiness** | 15 | 10 | Only if ISV: Code Analyzer pass; Security Review questionnaire; listing content; partner org |
| **Governance + audit** | 15 | 10 | Segregation of duties (dev ≠ approver); Deployment Log review cadence; rollback plan documented; install key management (if managed) |

**Passing threshold: 89 / 130 (~68%).**

---

## 6. Anti-patterns (min 7)

1. **Building a new managed package on 1GP in 2026.** 1GP is legacy. New ISV builds should start on 2GP Managed; existing 1GP packages should be converted via `sf package convert`.
2. **Bypassing DevOps Center with ad-hoc sf CLI deploys to the same environments.** Mixed tooling creates a state drift — DevOps Center's view of "what's in UAT" diverges from reality. Pick one lane per environment.
3. **Running Dev Hub on a sandbox.** Dev Hub must be on a production org (or a Developer Edition signed up as one). A Dev Hub on a sandbox has limited namespace linkage and disappears on refresh.
4. **Using the same approver for every stage.** SOX segregation of duties requires Dev → UAT approver ≠ UAT → Prod approver. Configure per-stage reviewer lists.
5. **Committing Change Bundles without reviewing conflicts.** DevOps Center surfaces conflicts in the bundle view; ignoring them means the later deploy overwrites someone else's work. Always resolve in GitHub before promoting.
6. **Installing a Beta package version in production.** Beta versions are for sandbox testing only. Promote to Released first.
7. **Skipping `--code-coverage` on `sf package version create`.** Without coverage data baked into the version, installing in a production target can fail with insufficient coverage. Always `--code-coverage`.
8. **Assuming Unlocked package IP is protected.** Unlocked packages are source-visible post-install. Anything proprietary must ship in a 2GP Managed package.
9. **Letting namespace assignment drift**: A namespace is permanently bound to one Dev Hub. Losing access to that Dev Hub org (expired license, lost admin) orphans the namespace. Document Dev Hub ownership formally.
10. **AppExchange submission without Code Analyzer remediation.** Security Review rejects packages with unresolved High / Critical findings. Run the analyzer before submitting.
11. **Treating DevOps Center as a backup.** DevOps Center + GitHub is source control, not a disaster-recovery backup of org data. Use [sf-backup-datamask](../sf-backup-datamask/SKILL.md) for data backup.
12. **Not pinning the sfdx-project.json `sourceApiVersion`.** Drifting API versions cause deploy failures when a target org hasn't caught up. Pin explicitly and bump deliberately.

---

## 7. Common failure modes + remediation

| Symptom | Root cause | Fix |
|---|---|---|
| "DevOps Center shows `Authorization Failed` for the prod environment" | OAuth token for the target org expired, or the Connected App policies changed | Re-authorize the Environment in DevOps Center; check the target org's session settings for forced timeout |
| "Promote to UAT says `Merge conflict in classes/DonorService.cls`" | Two Work Items modified the same class on the same lines | Open the GitHub PR, resolve the conflict manually, commit, re-trigger promote from DevOps Center |
| "`sf package version create` fails with `MISSING_DEPENDENCY` on a metadata type" | Component in the package references something outside the package directory (common: managed-package field) | Add the dependency as an `dependencies` entry in `sfdx-project.json`, or extract to its own package |
| "Install fails in prod: `Apex test failures — coverage below 75%`" | Package version was built without `--code-coverage`, or coverage is real-low | Rebuild version with `--code-coverage`; fix test gaps; re-promote; re-install |
| "Promote to Released fails: `ancestor missing`" | Branch-based packaging has a version on feature branch but no ancestor on main | Create the ancestor version on main first, then promote the feature branch's version |
| "DevOps Center `Pull Changes` returns empty but I know I changed a Validation Rule" | Source Tracking didn't detect the change (rare edge case on older sandboxes) | Force a metadata refresh: `sf project retrieve start --metadata ValidationRule:MyObj.MyRule`, then commit via CLI; or refresh the sandbox (costly but definitive) |
| "Unlocked package install in sandbox overwrites a customization subscribers had made" | Unlocked packages do not preserve subscriber edits on upgrade — they overwrite | Educate subscribers: Unlocked is editable but upgradeable via overwrite. For editable + preserved-on-upgrade, use Extension Packages on top of a stable base |
| "AppExchange Security Review rejects package for `CRUD/FLS not enforced in Apex`" | Apex DML without `with sharing` + WITH SECURITY_ENFORCED / Security.stripInaccessible | Refactor using `with sharing` + explicit permission checks; re-run Code Analyzer; resubmit |
| "Package install in prod times out at 60 minutes" | Install runs all local Apex tests; large test suite exceeds window | Increase `--wait`; split package into smaller pieces; pre-validate test health in UAT |

---

## 8. Cheat sheet

### Minimal `sfdx-project.json` for 2GP Unlocked

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true,
      "package": "NGOCustomizations",
      "versionName": "ver 1.0",
      "versionNumber": "1.0.0.NEXT"
    }
  ],
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "62.0",
  "packageAliases": {
    "NGOCustomizations": "0Ho..."
  }
}
```

### End-to-end 2GP Managed package — first release

```bash
# One-time: register namespace (UI in Dev Hub org: Setup → Namespace Registries)

# 1. Create the package object
sf package create \
  --name NGOManagedApp \
  --package-type Managed \
  --path force-app \
  --description "NGO managed customizations" \
  --target-dev-hub mydevhub

# 2. Create first version (beta)
sf package version create \
  --package NGOManagedApp \
  --version-number 1.0.0.NEXT \
  --installation-key mysecretkey123 \
  --code-coverage \
  --wait 30 \
  --target-dev-hub mydevhub

# 3. Install in UAT to validate
sf package install \
  --package "NGOManagedApp@1.0.0-1" \
  --installation-key mysecretkey123 \
  --target-org nguat \
  --wait 30

# 4. Run Security Review steps (Code Analyzer, questionnaire, Partner Community)

# 5. Promote (makes it installable in prod)
sf package version promote \
  --package "NGOManagedApp@1.0.0-1" \
  --target-dev-hub mydevhub \
  --no-prompt

# 6. Install in prod (or distribute install URL)
sf package install \
  --package "NGOManagedApp@1.0.0-1" \
  --installation-key mysecretkey123 \
  --target-org ngprod \
  --wait 60
```

### DevOps Center pipeline topology (typical)

```
GitHub repo: ngo-org-metadata
  main (prod branch)   <── merges from `uat`
  uat                  <── merges from `integration`
  integration          <── merges from `feature/*`
  feature/WI-123-...

DevOps Center Pipeline:
  Stage 1: Dev         → Environment: ng-dev-sandbox   (branch: feature/*)
  Stage 2: Integration → Environment: ng-int-sandbox   (branch: integration)
  Stage 3: UAT         → Environment: ng-uat-sandbox   (branch: uat) — requires approval
  Stage 4: Prod        → Environment: ng-prod          (branch: main) — requires different approver
```

### Work Item lifecycle (DevOps Center, visual)

```
[Create Work Item "WI-123: Volunteer hours tracker"]
   ↓ (auto-creates feature/WI-123 branch)
[Admin makes changes in Dev sandbox]
   ↓
[DevOps Center Pull Changes → Review Change Bundle]
   ↓
[Commit → pushes to feature/WI-123]
   ↓
[Promote to Integration → opens PR → auto-merge → deploys to Int sandbox]
   ↓
[Promote to UAT → PR → reviewer approves → merges → deploys to UAT]
   ↓
[Promote to Prod → PR → separate reviewer approves → merges → deploys to Prod]
   ↓
[Deployment Log entry → Work Item = Closed]
```

### Converting a 1GP to 2GP

```bash
# List 1GP packages in Dev Hub
sf data query \
  --query "SELECT Id, Name, NamespacePrefix FROM MetadataPackage" \
  --target-org mydevhub --use-tooling-api

# Convert
sf package convert \
  --package 0Ho... \
  --target-dev-hub mydevhub \
  --installation-key bypass
```

### Scratch org definition for package development

```json
{
  "orgName": "NGOCustomizations Dev Scratch",
  "edition": "Enterprise",
  "features": ["EnableSetPasswordInApi", "Communities"],
  "settings": {
    "lightningExperienceSettings": { "enableS1DesktopEnabled": true },
    "securitySettings": { "sessionSettings": { "sessionTimeout": "TwelveHours" } }
  }
}
```

```bash
sf org create scratch \
  --definition-file config/scratch-def.json \
  --alias ngscratch \
  --duration-days 7 \
  --target-dev-hub mydevhub
```

---

## 9. Verified against

- Spring '26 Release Notes — Development, DevOps Center, Packaging
- `help.salesforce.com/s/articleView?id=sf.devops_center.htm`
- `developer.salesforce.com/docs/atlas.en-us.packagingGuide.meta/packagingGuide/`
- `architect.salesforce.com` Packaging decision guides
