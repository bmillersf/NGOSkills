---
name: sf-backup-datamask
description: >
  Salesforce Backup (formerly Backup & Restore) and Salesforce Data Mask
  architecture with 120-point scoring: automated daily backups of data + metadata
  + Chatter, retention and restore policies, point-in-time recovery, and
  irreversible sandbox masking (anonymize PII so sandboxes are FERPA / HIPAA /
  PCI / GDPR safe). TRIGGER when: user enables Salesforce Backup, designs
  retention or restore workflows, runs point-in-time recovery, configures
  Data Mask policies/rules, anonymizes a sandbox before giving developers
  access, chooses random vs consistent vs format-preserving replacement
  strategies, or asks "how do we back up the org", "restore from yesterday",
  "mask production data in sandbox", "scrub PII before the partner sees it",
  "recover the deleted opportunities".
  DO NOT TRIGGER when: user runs one-off `sf data import/export` for
  development or migration (use sf-data), deploys metadata or builds a
  package.xml (use sf-deploy / sf-devops-center), or configures permission
  set access to backup/restore admin features (use sf-permissions).
license: MIT
compatibility: "Salesforce Backup is a paid add-on (per-org license); Data Mask is a paid add-on and ships with a mandatory managed package installed in each sandbox"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "120 points across 6 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-04
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.backup_restore.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.data_mask.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/decision-guides/data-protection
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_security.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric inline (6 categories: Scope + license clarity 15, Backup retention + restore design 25, Data Mask policy design 25, Irreversibility safeguards 15, GDPR/erasure + compliance alignment 15, Operational runbook 25), mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  backup_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 18
      description: "Backup + restore design correct. Maps to Backup retention + restore design (25). Heaviest correctness — broken backup = unrecoverable disaster."
      automatic_hard_fail_rules:
        - "Any backup retention without verified restore drill (untested backups are not backups)"
        - "Any backup schedule slower than RPO requires"
        - "Any backup without offline / immutable copy (ransomware risk)"
    - name: Robustness
      max: 25
      hard_fail_below: 12
      description: "Data Mask policy + irreversibility. Maps to Data Mask policy design (25) + Irreversibility safeguards (15)."
      automatic_hard_fail_rules:
        - "Any Data Mask run on production without explicit org-type guard (catastrophic)"
        - "Any irreversible mask without 'are you sure' double confirmation"
        - "Any mask policy that doesn't redact all PII patterns (SSN, credit card, email)"
    - name: Fit
      max: 25
      hard_fail_below: 10
      description: "GDPR + compliance + scope. Maps to Scope + license clarity (15) + GDPR/erasure (15)."
      automatic_hard_fail_rules:
        - "Any GDPR / right-to-erasure flow without verified end-to-end deletion across backups"
    - name: Performance
      max: 25
      hard_fail_below: 18
      description: "Operational runbook is load-bearing. Maps to Operational runbook (25). Heaviest performance — backup ops are runbook-driven; if the runbook is wrong, recovery fails."
      automatic_hard_fail_rules:
        - "Any backup deploy without quarterly restore drill scheduled"
        - "Any DR plan without RTO + RPO documented"
  test_rubric:
    unit:
      required: true
      criteria: "Mask policy unit-tested against PII pattern fixtures (SSN, credit card, email, phone)."
    integration:
      required: true
      criteria: "Backup runs to completion. Restore drill rehearsed end-to-end against a sandbox."
    smoke:
      required: true
      criteria: "Quarterly restore drill produces a working sandbox from the most recent backup. RTO + RPO measured against drill."
---

# sf-backup-datamask

Two related but distinct add-ons: **Salesforce Backup** (production resilience — daily backup of data, metadata, Chatter, with selective restore and point-in-time recovery) and **Salesforce Data Mask** (sandbox privacy — irreversibly anonymize PII so non-production environments are safe for partners, offshore teams, and students).

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). Three subagents grade against the 120-pt rubric in fresh context. Correctness AND Performance floors both at 18 — untested backups aren't backups; runbook errors compound during disaster recovery. Disable with `eval_harness.enabled: false`.

They share the same audience (security / platform operations) and the same failure mode ("we thought we were covered, we weren't"), so this skill owns both.

---

## 1. When this skill owns the task

Use this skill when the request is about **disaster recovery, accidental-deletion recovery, retention, point-in-time restore, or sandbox anonymization**. Delegate when scope narrows to:

| If the user wants... | Route to | Why |
|---|---|---|
| Export a CSV for reporting or migration, bulk load test data, refresh a sandbox from a specific dataset | [sf-data](../sf-data/SKILL.md) | `sf data export/import` is development tooling, not backup |
| Retrieve metadata-only for source-control handoff | [sf-deploy](../sf-deploy/SKILL.md) / [sf-devops-center](../sf-devops-center/SKILL.md) | Metadata-only retrieve ≠ backup |
| Grant users access to Backup/Restore admin UI | [sf-permissions](../sf-permissions/SKILL.md) | Access control is not the product |
| Detect that data was exfiltrated (audit) | [sf-shield-event-monitoring](../sf-shield-event-monitoring/SKILL.md) | Detection vs recovery are different surfaces |
| Generate synthetic test data that doesn't exist in prod | [sf-data](../sf-data/SKILL.md), [sf-nonprofit-demo-data](../sf-nonprofit-demo-data/SKILL.md) | Data Mask anonymizes **real** prod data in sandboxes; it does not generate fake data |

---

## 2. Cross-cloud scope note (replaces Phase 0)

Backup and Data Mask are **platform-level** add-ons: they operate identically across Sales, Service, Marketing Cloud Growth, Revenue, Nonprofit, and every industry cloud — they back up / mask Salesforce objects regardless of cloud.

However, **industry compliance regimes drive the masking and retention design**:

- **Health Cloud / HIPAA** → Data Mask is effectively mandatory on any sandbox used by developers who haven't signed BAAs. Mask all 18 HIPAA Safe Harbor identifiers (name, DOB, SSN, MRN, address below state, phone, email, device ID, biometrics, photo). Backup retention ≥ 6 years for PHI per 45 CFR §164.530(j)(2). Cross-reference [sf-industry-health](../sf-industry-health/SKILL.md).
- **FSC / PCI-DSS + SOX** → Mask PAN, CVV, SSN, account numbers in sandboxes. PCI requires that cardholder data never enter non-production. Backup retention ≥ 7 years for SOX-relevant records. Cross-reference [sf-industry-fsc](../sf-industry-fsc/SKILL.md).
- **Public Sector / FedRAMP** → Government Cloud Plus; Backup is usually required by the ATO. Data Mask policies must be reviewed by the agency's privacy officer. Cross-reference [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md).
- **Education Cloud / FERPA** → Mask student names, DOB, SSN, parent contact, grades when sandboxes are accessed by vendors or student workers. Cross-reference [sf-industry-education](../sf-industry-education/SKILL.md).
- **Nonprofit / donor PII** → Mask donor names, email, phone, home address, giving history in sandboxes before partner / consultant access. Backup retention per the organization's gift-acknowledgment and state AG record-keeping rules. Cross-reference [sf-nonprofit-fundraising](../sf-nonprofit-fundraising/SKILL.md).
- **GDPR / right-to-erasure** → Backup retention creates a legal wrinkle: erasure requests must propagate to backups, not just live data. Salesforce Backup supports targeted delete-from-backup for exactly this reason.

Always confirm the regime **before** proposing a retention policy or masking rule set. A generic "keep 90 days" answer fails HIPAA.

---

## 3. Required context to gather first

Ask or infer:

1. **Which product is in scope** — Backup, Data Mask, or both.
2. **License status** — both are paid add-ons. Confirm the org has the SKU provisioned (Setup → Company Information → Subscribed Products).
3. **Edition + org type** — Data Mask runs in **sandboxes only** and requires the managed package installed in each target sandbox.
4. **Industry regime** — drives retention window and mask-field list (see §2).
5. **RPO / RTO target** — Recovery Point Objective (how much data can we lose?) and Recovery Time Objective (how fast must we be back?). Backup's SLA is ~daily RPO and hours-to-days RTO; if the business needs sub-hour RPO, Backup alone is insufficient and the customer needs a secondary replication strategy.
6. **Scope of backup** — all objects / custom objects only / subset. Backup defaults to "all supported objects"; for large orgs with massive transactional volume (e.g., Platform Events, Big Objects), the cost and restore time make per-object scoping preferable.
7. **Sandbox refresh cadence** — Data Mask runs after each sandbox refresh; if sandboxes refresh weekly, the mask job must complete within that window.
8. **Data sensitivity classification** — which fields are PII / PHI / PCI / FERPA-protected? A masking policy without a data-classification exercise first is a guess.
9. **Restore runbook owner** — point-in-time restore is not self-service; who runs it, who approves it, how is the restore verified?

---

## 4. Workflow phases

### Phase 1 — Decide: Backup, Data Mask, or both?

| User need | Product |
|---|---|
| "Developer deleted the wrong records; get them back" | Backup (with selective restore) |
| "Production went sideways; roll the whole org back 24 hours" | Backup (point-in-time recovery) |
| "Offshore dev team needs a sandbox but can't see donor PII" | Data Mask |
| "Regulator wants proof we can recover from ransomware" | Backup (with documented restore runbook) |
| "GDPR erasure request — remove this person from everywhere including backups" | Backup (targeted delete-from-backup) |
| "Give the QA team a realistic sandbox without real patient data" | Data Mask |

Both run independently; no dependency between them.

### Phase 2 — Salesforce Backup design

**Scope**
- Supported: standard + custom objects, Files / ContentVersion, Chatter feed items, metadata (with metadata backup enabled).
- Not in scope: Big Objects (limited support), Platform Events streaming history, Einstein Search index, some managed-package internal data.
- Backup is a **managed service** run by Salesforce — not a customer-run job.

**Schedule + retention**
- Default: daily backup, automatic.
- Retention window is configurable; typical values 30 / 90 / 365 days. **The practical retention cap is based on storage cost**, not a hard ceiling.
- Incremental + full snapshots; the service manages the delta.

**Restore modes**
1. **Point-in-time restore** — roll the entire org (or a specified subset of objects) back to a given snapshot. Destructive for rows created after that point — review with stakeholders.
2. **Selective restore** — restore specific records (by Id, by filter) from a specific snapshot into the live org. Most common mode; supports "undo the bad batch update."
3. **Restore to a different org** — restore a prod snapshot into a sandbox for forensic analysis.
4. **Targeted delete-from-backup** — honor GDPR erasure by removing a specific record from all snapshots.

**Verification**
- Quarterly **fire-drill** restore into a sandbox. A backup you've never restored is not a backup — it's a hope.
- Document the actual RTO (wall-clock time from "start restore" to "verified data is back"). Update the DR runbook with real numbers.

### Phase 3 — Salesforce Data Mask design

**Prerequisites**
1. Install the Data Mask managed package into the target sandbox (AppExchange; one-time per sandbox).
2. Assign the "Data Mask" permission set group to the operator user.
3. Sandbox should be newly refreshed from production — mask on fresh data, not on already-mutated dev data.

**Three core artifacts**

1. **Mask Configuration** (per object) — the top-level container naming the sandbox and object scope.
2. **Masking Policy** (per run) — which fields, which replacement strategy, any filter conditions.
3. **Masking Rule** (per field) — the specific replacement strategy for that field.

**Replacement strategies**

| Strategy | Use when | Example |
|---|---|---|
| **Random** | Field has no downstream dependency on value | Phone: `555-391-7482` (fresh random per row) |
| **Library** (built-in dictionaries) | Need realistic-looking fake names, addresses, emails | Name: `Jordan Chen`, Email: `jchen@example.com` |
| **Anonymous** | PII replaced with fixed token | Email: `user-xxxx@masked.invalid` |
| **Delete value** | Field must be null post-mask | SSN: cleared entirely |
| **Consistent** | Same plaintext → same masked value (across rows + runs) | User.Email: `alice@acme.com` → always `mkt1923@example.com` so relationships stay intact |
| **Format-preserving** | Downstream systems validate format | SSN: `123-45-6789` → `847-29-3061` (valid SSN format, not real) |
| **Pattern (regex)** | Custom requirements | Custom SKU fields |
| **Criteria-based subset** | Mask only rows matching condition | Mask accounts where `BillingCountry = 'US'` only |

**Exclusion list**
- Some fields must NOT be masked (FK references, System fields, URLs used in Experience Cloud routing). Explicitly exclude via policy.

**Irreversible by design**
- Data Mask overwrites the sandbox data. There is **no unmask**. If you mask the wrong field, the only recovery is a sandbox refresh from prod (which costs you whatever dev work was in that sandbox).
- Mask in a scratch sandbox first, validate, then mask the dev/QA sandbox.

**Mask scheduling**
- Triggerable via the Data Mask UI, a Flow, Apex (`DataMask.Mask`), or the Salesforce CLI (`sf data-mask run` in the Data Mask plugin).
- Typical pattern: sandbox refresh → automated mask → notify developers the sandbox is ready.

### Phase 4 — Governance + runbook

**Backup**
- Document: retention policy, restore approval workflow, fire-drill cadence, actual measured RTO.
- Assign a DR owner; rotate annually.

**Data Mask**
- Data classification inventory first — which fields are PII/PHI/PCI/FERPA-sensitive? Check against organization data classification policy, not just developer intuition.
- Sign-off from privacy / compliance officer on the masking policy before first run in a regulated workload.
- Automate mask-after-refresh for all non-production sandboxes; manual masking drifts.

### Phase 5 — Verification

- **Backup**: quarterly restore fire drill → record (date, RTO, issues, resolution).
- **Data Mask**: post-run validation query against each masked field (`WHERE <field> LIKE '%<known-prod-value>%'` should return 0). Sample 10 rows and eyeball.
- **Combined**: any restore of a prod snapshot into a sandbox must be followed by a mask run before non-BAA'd developers access it.

---

## 5. Scoring rubric (120 points, 6 categories)

| Category | Max | Passing | What to check |
|---|---|---|---|
| **Scope + license clarity** | 15 | 10 | Backup and/or Data Mask licensed; target org/sandbox identified; industry regime named |
| **Backup retention + restore design** | 25 | 17 | RPO/RTO documented; retention aligned to regulatory regime; restore mode (point-in-time / selective / cross-org) matched to use case; fire-drill cadence set |
| **Data Mask policy design** | 25 | 17 | Data classification inventory done first; replacement strategy per field justified; consistent-mask used where relationships must survive; exclusion list explicit |
| **Irreversibility safeguards** | 15 | 10 | Scratch-sandbox validation step; privacy officer sign-off; post-mask verification query; no "unmask" assumed |
| **GDPR / erasure + compliance alignment** | 15 | 10 | Targeted delete-from-backup covered for erasure requests; retention matches HIPAA/SOX/FERPA/PCI regime |
| **Operational runbook** | 25 | 17 | Named owner; restore approval workflow; automated mask-after-refresh; measured RTO recorded, not estimated |

**Passing threshold: 81 / 120 (~68%).**

---

## 6. Anti-patterns (min 7)

1. **Treating the Recycle Bin as a backup.** The Recycle Bin holds records for 15 days and has a hard size cap. It is not disaster recovery. Salesforce Backup is the recovery tool; the Recycle Bin is a convenience.
2. **Assuming a sandbox refresh is a backup.** A sandbox refresh is a point-in-time clone, not an incremental historical record. You can't restore selective records from a sandbox into live prod without orchestration.
3. **Skipping the quarterly restore fire drill.** The first time you run a restore in anger should not be during an actual incident. Test quarterly, measure RTO, fix gaps.
4. **Masking fields without a data classification inventory.** Ad-hoc masking misses fields (custom text fields with embedded PII, long-text notes, attachments). Inventory first.
5. **Masking with "random" when downstream systems need referential integrity.** If User.Email is a foreign key target for `CreatedById` lookups across objects, random per-row masking breaks every join. Use **consistent** strategy.
6. **Running Data Mask on a sandbox already populated with dev data.** Mask alters real prod data that was refreshed; dev data created after the refresh is not masked by default. Mask immediately after refresh.
7. **Skipping the privacy officer sign-off in regulated workloads.** A HIPAA sandbox with incomplete masking is a reportable breach. Get sign-off in writing.
8. **Using Data Mask as a synthetic-data generator.** It's not. It transforms existing prod data. If you need fake data for a net-new sandbox, use sf-data / sf-nonprofit-demo-data instead.
9. **Letting Backup retention creep to "forever."** Storage cost scales linearly; retention should match regulatory need, not maximum comfort. Quarterly retention review.
10. **Forgetting that Backup retains deleted records too.** A GDPR erasure request must include a `Targeted Delete from Backup` step, or the backup itself becomes a compliance violation.
11. **Restoring an entire org "point-in-time" without stakeholder review.** Every row created between the snapshot and now will be lost. Always pair point-in-time with a documented acceptance of that data loss.

---

## 7. Common failure modes + remediation

| Symptom | Root cause | Fix |
|---|---|---|
| "Backup restore returned `BACKUP_NOT_FOUND` for yesterday's snapshot" | Salesforce Backup managed package not yet installed, license/permission set not assigned, or first-run snapshot still processing (24-48h lead time after activation) | Install the Salesforce Backup managed package (via subscription order-form link), assign the Salesforce Backup license + permission set, verify the Backup app dashboard shows "Healthy"; the first snapshot completes within 48h of activation — you cannot restore before then |
| "Storage bill spiked after enabling Backup" | Effective file-storage charge is 10% of actual GB used in Backup (per current Salesforce Help pricing note) — customers often size retention before knowing the multiplier | Re-scope retention / per-object overrides; confirm the 10% effective-GB rule with Account Exec before sizing contract; Salesforce does not expose Backup product data consumption in the UI — open a Support case to get actuals |
| "Selective restore imported duplicates — records already existed" | Restore mode set to "Insert" instead of "Upsert by External ID" | Use Upsert mode with a stable external key; if no external key exists, use Salesforce Id match with `overwrite existing` explicitly confirmed |
| "Data Mask run failed with `INSUFFICIENT_ACCESS_OR_READONLY`" | Operator user doesn't have the Data Mask permission set group, or the object has an active validation rule / required field that fails post-mask | Assign `Data Mask` PSG; temporarily deactivate validation rules on masked objects (Data Mask UI has a flag for this), re-enable after mask |
| "Masked sandbox still contains real donor emails after run" | Custom long-text field (`Notes__c`) contains embedded PII not covered by the rule | Add pattern-based masking rule for custom text fields; scan first with a grep-style query for `@` + top-level domains to find missed fields |
| "Post-restore: Reports show missing rows despite restore success" | Record-level sharing rules didn't propagate for restored records (OWD + sharing recalc pending) | Run "Recalculate Sharing" from Setup after restore; some sharing recalcs are async and take hours on large orgs |
| "Data Mask took 18 hours on a 20M-row sandbox" | Large volume + consistent-mask strategy (which requires a lookup against prior runs) | Chunk the mask policy by object; mask high-volume objects (Task, Event, ContentVersion) in separate runs; schedule overnight |
| "Restoring into a sandbox populated real PII where developers could see it" | Restore completed but mask-after-restore step was skipped | Encode restore + mask as a single runbook; never expose an unmasked prod snapshot to non-BAA'd developers |
| "GDPR erasure request closed, but backup still holds the record" | Only live data was erased | Run `Targeted Delete from Backup` for that record ID across all retained snapshots; document in the erasure log |

---

## 8. Cheat sheet

### Enable Salesforce Backup

```
1. Install the Salesforce Backup managed package
     (link from your subscription order form; Backup is managed-package-based,
      not a built-in Setup node)
2. Assign the Salesforce Backup license + "Salesforce Backup" permission set
     to admin users
3. Open the Salesforce Backup app → Configure connection (secure OAuth link
     between the managed-package app and the org)
4. Plan the Backup strategy (identify high-value / regulated objects first)
5. Build Backup policies in batches
     → Default schedule: daily automatic
     → Per-object retention overrides for high-volume objects
6. First backup completes within 24-48h of activation
7. Storage note: effective GB charged = 10% of actual GB backed up (file data)
```

### Selective restore (UI)

```
Backup → Restore → Select Snapshot Date → Filter by Object + Criteria
  → Review preview (rows to restore, conflict mode)
  → Choose mode: Upsert by External Id (recommended) | Insert | Overwrite
  → Execute → Monitor restore job
```

### Targeted delete from backup (GDPR erasure)

```
Backup → Data Governance → Targeted Delete
  → Object: Contact
  → Filter: Id IN ('003XXX...', '003YYY...')
  → Scope: All retained snapshots
  → Confirm irreversible → Execute
  → Record in erasure log
```

### Data Mask — minimal policy XML

```xml
<!-- SandboxDonorMaskPolicy.maskingPolicy-meta.xml -->
<MaskingPolicy xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>Sandbox Donor Mask</masterLabel>
    <developerName>SandboxDonorMask</developerName>
    <active>true</active>
    <targetObject>Contact</targetObject>
    <rules>
        <field>FirstName</field>
        <strategy>Library</strategy>
        <library>PersonFirstName</library>
    </rules>
    <rules>
        <field>LastName</field>
        <strategy>Library</strategy>
        <library>PersonLastName</library>
    </rules>
    <rules>
        <field>Email</field>
        <strategy>Consistent</strategy>
        <pattern>user{rownum}@example.invalid</pattern>
    </rules>
    <rules>
        <field>Phone</field>
        <strategy>FormatPreserving</strategy>
    </rules>
    <rules>
        <field>SSN__c</field>
        <strategy>DeleteValue</strategy>
    </rules>
    <rules>
        <field>MailingStreet</field>
        <strategy>Library</strategy>
        <library>StreetAddress</library>
    </rules>
    <deactivateValidationRules>true</deactivateValidationRules>
</MaskingPolicy>
```

### Running Data Mask via CLI

```bash
# List masking configs in the target sandbox
sf data-mask list --target-org mysandbox

# Run a specific policy
sf data-mask run --config-name SandboxDonorMaskPolicy --target-org mysandbox --wait 30

# Verify no residual prod PII (sample query)
sf data query \
  --query "SELECT Count() FROM Contact WHERE Email LIKE '%@knowndonordomain.org%'" \
  --target-org mysandbox
# Expected: 0
```

### Flow-trigger mask-after-refresh (sketch)

```
Trigger: Platform Event 'SandboxRefreshComplete__e' received
  → Decision: Is target sandbox in approved list?
    → Yes: Invocable Apex `DataMask.RunPolicy`(configName='SandboxDonorMask')
    → Send Slack notification: "Sandbox X masked + ready"
```

### Fire-drill restore template (quarterly runbook)

```
Q<N> YYYY Backup Fire Drill
---------------------------
Target snapshot: <date, T-7 days>
Objects restored: Account, Contact, Opportunity (sample 100 rows each)
Destination: qa-dr-sandbox
Start time:       ____________
Restore complete: ____________
Verification query: SELECT Count() FROM Contact WHERE CreatedDate <= <snapshot-date>
Expected:         ____________
Actual:           ____________
Measured RTO:     ____________  (update DR runbook)
Issues:           ____________
Sign-off (DR owner + Platform lead): _______________
```

---

## 9. Verified against

- Spring '26 Release Notes — Security & Identity, Data Protection
- `help.salesforce.com/s/articleView?id=sf.backup_restore.htm`
- `help.salesforce.com/s/articleView?id=sf.data_mask.htm`
- `architect.salesforce.com` Data Protection decision guides
