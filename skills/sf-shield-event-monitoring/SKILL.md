---
name: sf-shield-event-monitoring
description: >
  Salesforce Shield architecture with 130-point scoring: Event Monitoring,
  Real-Time Event Monitoring, Transaction Security Policies, Platform Encryption,
  Field Audit Trail, Security Center, and Event Monitoring Analytics App.
  TRIGGER when: user enables or investigates Shield Event Monitoring, pulls
  EventLogFile data, designs Real-Time Event Monitoring (LoginEvent, LogoutEvent,
  ApiAnomalyEvent, CredentialStuffingEvent, ReportAnomalyEvent, SessionHijackingEvent,
  ReportEvent, LoginAsEvent), builds Transaction Security Policies, configures
  Platform Encryption (Shield or Classic) with Tenant Secret / Encryption Policy,
  retains Field Audit Trail history up to 10 years, rolls out Security Center
  across multiple orgs, or installs the Event Monitoring Analytics App; also
  phrases like "audit who exported reports", "detect credential stuffing",
  "encrypt PII at rest", "retain field history for 7 years", "cross-org security
  posture", "LoginAs visibility", "TSP block API anomaly".
  DO NOT TRIGGER when: user asks about object/field-level access or permission
  set design (use sf-permissions), Agentforce Session Tracing / STDM / parquet
  telemetry for agent observability (use sf-ai-agentforce-observability), or
  Data Cloud event ingestion and data streams (use sf-datacloud /
  sf-datacloud-prepare).
license: MIT
compatibility: "Requires Salesforce Shield add-on license (Event Monitoring, Platform Encryption, Field Audit Trail) or à-la-carte Event Monitoring; Security Center requires separate license"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "130 points across 7 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.shield.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.event_monitoring.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/decision-guides/trust-security
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
  rubric_ref: "130-pt rubric inline (7 categories: License + scope clarity 15, Event Monitoring design 25, Transaction Security Policies 20, Platform Encryption 25, Field Audit Trail 15, Security Center + multi-org posture 15, Operational readiness 15), mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  shield_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Event Monitoring + Transaction Security policies designed correctly. Maps to Event Monitoring design (25) + Transaction Security Policies (20)."
      automatic_hard_fail_rules:
        - "Any Real-Time Event subscription without retention policy (event log overflow)"
        - "Any Transaction Security Policy without test cases for both block and notify paths"
    - name: Robustness
      max: 25
      hard_fail_below: 18
      description: "Platform Encryption applied correctly. Maps to Platform Encryption (25). Heaviest robustness — losing tenant secret = unrecoverable data loss."
      automatic_hard_fail_rules:
        - "Any encryption rotation without tenant secret backup verified"
        - "Any encrypted field without index/search behavior assessed (queries silently break)"
        - "Any tenant secret rotation cadence longer than compliance requires"
    - name: Fit
      max: 25
      hard_fail_below: 10
      description: "Audit + multi-org posture correct. Maps to Field Audit Trail (15) + Security Center (15)."
      automatic_hard_fail_rules:
        - "Any compliance-bound field without Field Audit Trail enabled"
        - "Any multi-org without Security Center for posture aggregation"
    - name: Performance
      max: 25
      hard_fail_below: 10
      description: "Operational readiness. Maps to Operational readiness (15) + License + scope (15)."
      automatic_hard_fail_rules:
        - "Any Shield deploy without runbook for tenant secret rotation + incident response"
  test_rubric:
    unit:
      required: true
      criteria: "Transaction Security Policy unit-tested with both block and notify scenarios."
    integration:
      required: true
      criteria: "Event Monitoring stream verified to emit expected event types. Encryption applied without breaking existing queries."
    smoke:
      required: true
      criteria: "Tenant secret rotation rehearsed end-to-end. Field Audit Trail captures expected changes. Security Center surfaces posture across orgs."
---

# sf-shield-event-monitoring

Salesforce Shield is a bundle of three trust products plus a multi-org cockpit: **Event Monitoring** (what happened), **Platform Encryption** (data at rest), **Field Audit Trail** (long-term history), and **Security Center** (cross-org posture). This skill owns the end-to-end design and operational playbook for all four, plus the Event Monitoring Analytics App.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). Three subagents grade against the 130-pt rubric in fresh context. Robustness floor at 18 — losing a Platform Encryption tenant secret = unrecoverable data loss. Disable with `eval_harness.enabled: false`.

---

## 1. When this skill owns the task

Use this skill when the request is about **detection, forensic audit, encryption at rest, long-horizon field history, or multi-org security posture**. Delegate when scope narrows to:

| If the user wants... | Route to | Why |
|---|---|---|
| Assign users to permission sets, check FLS on a field, review profile access | [sf-permissions](../sf-permissions/SKILL.md) | Access control is not Shield |
| Trace an Agentforce session, read parquet telemetry, debug agent reasoning | [sf-ai-agentforce-observability](../sf-ai-agentforce-observability/SKILL.md) | STDM is a separate product surface |
| Ingest events into Data Cloud as a data stream or DLO | [sf-datacloud-prepare](../sf-datacloud-prepare/SKILL.md) | Shield → Data Cloud is a downstream step |
| Configure OAuth / Connected App / JWT flow | [sf-connected-apps](../sf-connected-apps/SKILL.md) | Pre-login surface, not audit |
| Set up SSO, MFA, Login Flows, Session Settings | [sf-identity-sso](../sf-identity-sso/SKILL.md) | Identity configuration lives there |
| Back up or restore data after a Shield-detected incident | [sf-backup-datamask](../sf-backup-datamask/SKILL.md) | Recovery is separate from detection |
| Write SOQL against EventLogFile / ApiAnomalyEventStore | [sf-soql](../sf-soql/SKILL.md) | Query authoring, not Shield design |

---

## 2. Cross-cloud scope note (replaces Phase 0)

Shield is a **platform-level** capability: it applies identically across Sales, Service, Marketing Cloud Growth (Core-org), Revenue, Experience Cloud, Nonprofit, and every industry cloud. **Do not run the industry pre-check** — Shield is the destination for any industry's trust requirements.

However, **industry-specific compliance regimes often mandate specific Shield configurations**. When the org is running:

- **Health Cloud / HIPAA-regulated workload** → Platform Encryption (Shield-level with deterministic encryption rarely, probabilistic by default), Field Audit Trail retention ≥ 6 years for PHI (HIPAA 45 CFR §164.316(b)(2)), Real-Time Event Monitoring on ReportEvent + ApiEvent for PHI access audit. Cross-reference [sf-industry-health](../sf-industry-health/SKILL.md).
- **FSC / PCI or SOX workload** → Platform Encryption on Financial_Account__c.AccountNumber, Card PAN fields; Field Audit Trail ≥ 7 years for SOX; Transaction Security Policy on LoginAsEvent for SOX segregation of duties. Cross-reference [sf-industry-fsc](../sf-industry-fsc/SKILL.md).
- **Public Sector / FedRAMP** → Government Cloud Plus deployment; Shield is effectively mandatory; Tenant Secret rotation per FedRAMP Moderate baseline (≥ annual); Real-Time Event Monitoring feeding an external SIEM. Cross-reference [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md).
- **Education Cloud / FERPA** → Field Audit Trail for student record changes; ReportEvent monitoring on directory-info exports; encryption for SSN/DOB. Cross-reference [sf-industry-education](../sf-industry-education/SKILL.md).
- **Nonprofit / donor PII, grantee tax IDs** → Platform Encryption on SSN/EIN fields; Field Audit Trail on Gift Transaction, Funding Award for audit; no federal regime but donor-state AG rules apply. Cross-reference [sf-nonprofit-fundraising](../sf-nonprofit-fundraising/SKILL.md) and [sf-nonprofit-grants](../sf-nonprofit-grants/SKILL.md).

Always ask the user which regime applies **before** choosing encryption scheme or retention policy. A Shield deployment tuned for marketing ops is not a Shield deployment tuned for HIPAA.

---

## 3. Required context to gather first

Ask or infer:

1. **Edition + license** — Enterprise+, and which Shield SKUs are provisioned: Event Monitoring (EM), Platform Encryption (PE), Field Audit Trail (FAT), Security Center (SC). These ship separately; do not assume the full bundle.
2. **Industry workload** — determines compliance regime (see §2).
3. **Goal** — detection/forensics, prevention (TSP), encryption at rest, long-horizon audit, or cross-org posture.
4. **Data volume expectations** — EventLogFiles are generated hourly/daily; an org doing 50M API calls/day will generate multi-GB EventLogFiles that must be exfiltrated within 30 days.
5. **Downstream consumer** — EM Analytics App (in-platform), external SIEM (Splunk / Sumo / Elastic via EventLogFile API or Real-Time Event Streaming), or Data Cloud ingestion.
6. **Existing Tenant Secret state** — if PE is already in use, rotating the Tenant Secret carelessly can orphan encrypted data.
7. **Retention target** — standard Field History is 18 months / 24 months; Field Audit Trail extends to **10 years max**.
8. **Number of orgs** — Security Center is only worth the license above ~3 production orgs.

---

## 4. Workflow phases

### Phase 1 — Classify the request

Decide which Shield surface(s) the task touches. Mixed-surface work (e.g., "detect report exports of PHI and retain for 7 years") spans EM + FAT + PE.

| Surface | Owns |
|---|---|
| Event Monitoring (EM) | EventLogFile (hourly), Real-Time Event Monitoring (streaming), Transaction Security Policies, EM Analytics App |
| Platform Encryption (PE) | Tenant Secret, Encryption Policy, field-level encryption at rest, deterministic vs probabilistic |
| Field Audit Trail (FAT) | HistoryRetentionPolicy, FieldHistoryArchive, up to 10 years |
| Security Center (SC) | Cross-org tenant dashboard, baseline drift detection |

### Phase 2 — Event Monitoring design

**EventLogFile (ELF) — batch, hourly or daily**

- 50+ event types. High-value for nonprofit/enterprise audit: `Login`, `Logout`, `API`, `RestApi`, `BulkApi`, `ReportExport`, `URI`, `ApexExecution`, `ApexCallout`, `ApexSoap`, `LoginAs`, `ContentTransfer`, `QueuedExecution`, `AsyncReportRun`, `Dashboard`, `VisualforceRequest`, `LightningPerformance`, `LightningPageView`, `LightningError`, `InsecureExternalAssets`.
- Files retained **30 days**; must be exfiltrated to a SIEM or Data Cloud for longer retention.
- Query via: `SELECT Id, EventType, LogDate, LogFileLength, LogFile FROM EventLogFile WHERE EventType = 'ReportExport' AND LogDate = YESTERDAY`
- Download via REST: `GET /services/data/vXX.X/sobjects/EventLogFile/{id}/LogFile` → gzipped CSV.

**Real-Time Event Monitoring (RTEM) — streaming, CometD / Pub-Sub API**

- Event types (Storage + Streaming):
  - `LoginEvent` — every login attempt (success + fail)
  - `LogoutEvent`
  - `ApiEvent` — every API call (high-volume; storage-enabled tenants only)
  - `ApiAnomalyEvent` — ML-detected anomalous API pattern (e.g., user pulls 100x their typical record volume)
  - `CredentialStuffingEvent` — ML-detected high-velocity login attempts from distributed IPs
  - `ReportEvent` — report execution
  - `ReportAnomalyEvent` — ML-detected unusual report access (volume, time, sensitivity)
  - `SessionHijackingEvent` — session reuse from unexpected fingerprint
  - `LoginAsEvent` — admin impersonation (critical for SOX segregation of duties)
  - `UriEvent`, `ListViewEvent`, `BulkApiResultEvent`, `ConcurLongRunningApexErrEvent`, `PermissionSetEvent`, `PermissionSetGroupEvent`, `FileEvent`
- Two storage modes: **Streaming only** (subscribe to channel, no backing store) or **Storage + Streaming** (backing `*EventStore` object queryable via SOQL, e.g., `ApiAnomalyEventStore`).
- Enable in Setup → Event Manager per event type.
- Consumers: EM Analytics App subscribes to stores; custom Apex subscribers use Pub-Sub API; external SIEM subscribes via CometD.

**Transaction Security Policies (TSP)**

- **Policy as code**: Apex class implementing `TxnSecurity.EventCondition` or declarative TSP via the Transaction Security Policy UI (Setup → Transaction Security Policies). The declarative UI is the current recommended path.
- Acts **at the event emission point** to: Block, Multi-Factor Challenge (step-up), Notify, or None.
- Bind policy to a Real-Time event type. Example: block `ApiAnomalyEvent` for users in the "Donor Operations" profile between 22:00 and 06:00.
- Keep TSPs **narrow and deterministic**. Broad policies block legitimate users; false positives train users to ignore MFA challenges.

**Event Monitoring Analytics App**

- Managed CRM Analytics app (requires CRM Analytics license) subscribed to EM + RTEM stores.
- Prebuilt dashboards: Logins, Report Activity, API Usage, Data Export Risk, Setup Audit, File Activity.
- Install from AppExchange → provision → schedule dataflow (default hourly).

### Phase 3 — Platform Encryption design

**Classic Encryption vs Shield Platform Encryption**

| Capability | Classic | Shield Platform |
|---|---|---|
| Field types supported | Text (Encrypted), 175 chars max | Text, Email, Phone, URL, Date, DateTime, long text, rich text, file attachments, CRM Content, Search Index, Chatter |
| Preserves field functions | Limited (no formulas, no reports aggregating) | Most field functions preserved |
| Search | Limited | Full search (deterministic scheme) |
| Key management | Salesforce-managed | Customer Tenant Secret (BYOK supported via Cache-Only Key Service) |
| License | Included | Shield add-on |

**Tenant Secret lifecycle**

1. Generate Tenant Secret (Setup → Platform Encryption → Key Management). Salesforce derives Data Encryption Key (DEK) per tenant.
2. Key types: Data in Salesforce, Search Index, Analytics, Event Bus.
3. Rotate ≥ annually (recommended every 6 months for HIPAA / FedRAMP). Rotation creates a new active secret; previous secrets remain archived to decrypt historical ciphertext.
4. **BYOK (Bring Your Own Key)** via Cache-Only Key Service — key stored in customer KMS, fetched per-tx, never persisted in Salesforce.
5. **Revoking a Tenant Secret** destroys access to all data encrypted under it. Irreversible. Never do this casually.

**Encryption Policy**

- Per-field enablement: Setup → Platform Encryption → Encryption Policies → select object + field.
- **Deterministic vs Probabilistic scheme**:
  - *Probabilistic* (default): stronger security, but field is not searchable, not filterable in reports, not usable in WHERE clauses.
  - *Deterministic*: same plaintext → same ciphertext, enables `WHERE field = 'X'` exact-match queries. Slightly weaker security (frequency analysis risk). Use for indexed lookup fields like SSN, EIN, patient MRN.
- Encrypting a field is a **bulk operation** for existing rows — test in sandbox first. Large orgs schedule encryption in a maintenance window.
- Encrypted fields cannot be used in: formula fields, criteria-based sharing rules, process criteria (most), most roll-up summaries.

### Phase 4 — Field Audit Trail design

- Standard Field History tracks up to **20 fields per object** and retains for 18–24 months (edition-dependent).
- Field Audit Trail (FAT) extends retention to **up to 10 years** via `HistoryRetentionPolicy` metadata on supported objects.
- Two-tier model:
  - **Field History Archive** (queryable via `FieldHistoryArchive` SOQL object after retention period rolls over) — archived rows still queryable but not editable.
  - **Active Field History** (the per-object `*History` object, e.g., `AccountHistory`) — standard behavior for the in-retention window.
- Enable per-object via metadata:

```xml
<!-- Account.object-meta.xml -->
<HistoryRetentionPolicy>
    <archiveAfterMonths>18</archiveAfterMonths>
    <archiveRetentionYears>10</archiveRetentionYears>
    <description>SOX + donor-state AG requirement</description>
</HistoryRetentionPolicy>
```

- Not every field is trackable (e.g., long text, formulas). Verify via Field History Tracking setup before committing.
- FAT storage is billed above a quota; design retention policies per regulatory need, not "forever on everything."

### Phase 5 — Security Center

- Dashboard aggregates security posture across **up to 100 connected tenants**: orgs, scratch orgs, sandboxes.
- Metrics: MFA adoption, login IP restrictions, permission-set drift, session settings delta vs baseline.
- Set one **baseline org** (typically production) and alert on drift in others.
- Licensed separately from Shield; only valuable if the customer runs multiple production orgs or a large sandbox fleet.

### Phase 6 — Deployment + verification

- EventLogFile settings, Real-Time event subscriptions, TSPs, EncryptionPolicy, and HistoryRetentionPolicy are all metadata-deployable.
- Validate in full-copy sandbox first — Platform Encryption changes especially.
- Smoke test after deploy: generate a test login failure, trigger a TSP block, export a report, rotate a Tenant Secret in sandbox.

---

## 5. Scoring rubric (130 points, 7 categories)

| Category | Max | Passing | What to check |
|---|---|---|---|
| **License + scope clarity** | 15 | 10 | Correct Shield SKUs identified (EM vs PE vs FAT vs SC); industry regime named; cross-cloud scope noted |
| **Event Monitoring design** | 25 | 17 | ELF event types selected justify by audit need; RTEM storage vs streaming decision documented; LoginAsEvent and ReportAnomalyEvent explicitly handled |
| **Transaction Security Policies** | 20 | 14 | TSPs are narrow and deterministic; action (Block / MFA / Notify) matches risk tier; false-positive rate estimated |
| **Platform Encryption** | 25 | 17 | Deterministic vs probabilistic per field justified; Tenant Secret rotation cadence set; BYOK/Cache-Only Key considered for regulated workloads; impact on formulas/reports acknowledged |
| **Field Audit Trail** | 15 | 10 | Retention policy aligned to regulatory regime (e.g., 7yr SOX, 6yr HIPAA); HistoryRetentionPolicy XML correct; storage cost estimated |
| **Security Center + multi-org posture** | 15 | 10 | Baseline org chosen; drift alerts configured; worth-the-license justification present if < 3 orgs |
| **Operational readiness** | 15 | 10 | Sandbox validation, EM Analytics App or SIEM destination wired, ELF exfiltration within 30-day window, runbook for Tenant Secret compromise |

**Passing threshold: 88 / 130 (~68%).** Below 88 → revise before delivery.

---

## 6. Anti-patterns (min 7)

1. **Enabling every EventLogFile event type "just in case."** Storage and egress costs balloon; analysts drown. Select events matched to specific audit questions.
2. **Using probabilistic encryption on a field you need to search.** Causes silent report/LOV breakage. Switch to deterministic, accept the frequency-analysis trade-off, and document it.
3. **Rotating Tenant Secret without verifying the previous secret is archived, not destroyed.** Destroying the active secret = instant loss of access to all ciphertext encrypted under it. Always `Archive`, never `Destroy`, unless the business has explicitly green-lit crypto-shredding.
4. **Broad Transaction Security Policies that block common admin workflows.** A TSP that blocks LoginAs for all admins stops incident response. Scope TSPs with specific conditions (IP, time, anomaly score).
5. **Ignoring the 30-day ELF retention window.** Event Log Files older than 30 days are gone — if no SIEM / Data Cloud ingestion pipeline exists, the audit trail is effectively 30 days and SOX auditors will flag it.
6. **Treating Shield as "turn on and forget."** Shield is a continuous discipline: Tenant Secret rotation, TSP tuning, EM dashboard triage, retention policy review. Schedule quarterly security reviews.
7. **Confusing Field History with Field Audit Trail.** Standard Field History is built-in (18-24 months); FAT is the Shield add-on that extends to 10 years via `HistoryRetentionPolicy`. They are not interchangeable, and FAT is not automatically on once you license Shield.
8. **Buying Security Center for a single-org customer.** SC pays off at 3+ production orgs. Single-org customers get more from EM Analytics App.
9. **Encrypting fields that are used in formulas, process builder criteria, or roll-up summaries** without first refactoring those dependencies. The deploy fails or the feature silently breaks.
10. **Relying on RTEM streaming mode alone for compliance.** Streaming-only means no backing store → no SOQL queryability → evidence is ephemeral. Enable Storage mode for events that auditors will ask about (LoginEvent, LoginAsEvent, ReportEvent).

---

## 7. Common failure modes + remediation

| Symptom | Root cause | Fix |
|---|---|---|
| "EventLogFile query returns no rows for recent dates" | EM license not provisioned, or EventType not yet populated (1-hour lag for hourly events, 24-hour for daily) | Verify Setup → Company Information shows Event Monitoring add-on; confirm EventType publishes on the expected cadence (e.g., `ReportExport` is hourly; check with low-volume event first) |
| "Field encryption deploy fails with 'Field cannot be encrypted because it is referenced in formula X'" | Formula field depends on a field being enabled for encryption | Either (a) refactor the formula to drop the dependency, (b) skip encrypting that field, or (c) move the logic to Apex/Flow if the requirement is firm |
| "Transaction Security Policy fires on LoginEvent for every external partner login" | Policy condition too broad (e.g., `LoginType == 'ApplicationSSO'` matches all SSO) | Narrow to specific username / profile / IP / time / anomaly-score combination; re-test in staging |
| "Tenant Secret rotated, historical encrypted data now unreadable in reports" | Old Tenant Secret was accidentally `Destroyed` instead of `Archived` | Recovery path is limited — Salesforce support may be able to recover if destruction was recent; otherwise the ciphertext is permanently inaccessible. This is why `Destroy` is a rare, deliberate, documented action |
| "Field Audit Trail `HistoryRetentionPolicy` deploy fails 'not supported for object X'" | FAT is only supported on a specific subset of objects (Account, Asset, Campaign, Case, Contact, Contract, Entitlement, Lead, Opportunity, Order, Product, Solution + ~custom) | Check the supported-object list in Salesforce Help; for unsupported objects, build custom history via Apex + a `__History__c` object (less clean, but necessary) |
| "CredentialStuffingEvent fires many false positives at 9am Monday" | Normal volume spike when users return from weekend; ML model had too little training data | Wait 30 days for model to stabilize; in the meantime, tune TSP response to `Notify` instead of `Block` |
| "Security Center baseline drift alert fires daily for sandbox refreshes" | Sandbox refresh resets permission settings, registering as drift | Exclude sandbox tenants from drift alerting; only alert on production peers |

---

## 8. Cheat sheet

### Enable EventLogFile access via permission set

```xml
<!-- EventMonitoringAccess.permissionset-meta.xml -->
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Event Monitoring Access</label>
    <hasActivationRequired>false</hasActivationRequired>
    <userPermissions>
        <enabled>true</enabled>
        <name>ViewEventLogFiles</name>
    </userPermissions>
    <userPermissions>
        <enabled>true</enabled>
        <name>ViewRealTimeEventMonitoringData</name>
    </userPermissions>
</PermissionSet>
```

### SOQL patterns

```sql
-- Today's report exports
SELECT Id, EventType, LogDate, LogFileLength, LogFile
FROM EventLogFile
WHERE EventType = 'ReportExport' AND LogDate = TODAY

-- Recent API anomalies (Storage mode required)
SELECT EventDate, Username, Score, Summary, Operation, SourceIp
FROM ApiAnomalyEventStore
WHERE EventDate = LAST_N_DAYS:7
ORDER BY Score DESC LIMIT 100

-- LoginAs usage over the last 30 days
SELECT EventDate, DelegatedUsername, TargetUserId, Username, SourceIp, LoginHistoryId
FROM LoginAsEventStore
WHERE EventDate = LAST_N_DAYS:30
ORDER BY EventDate DESC

-- Archived field history (after FAT archival window)
SELECT ParentId, FieldName, OldValue, NewValue, CreatedDate
FROM Account__FieldHistoryArchive
WHERE CreatedDate < LAST_N_YEARS:2
LIMIT 200
```

### Download an EventLogFile (REST)

```bash
# Get the log file ID
sf data query \
  --query "SELECT Id, EventType, LogDate FROM EventLogFile WHERE EventType='ReportExport' AND LogDate=YESTERDAY LIMIT 1" \
  --target-org myorg --json

# Download the gzipped CSV body
INSTANCE_URL=$(sf org display --target-org myorg --json | jq -r '.result.instanceUrl')
ACCESS_TOKEN=$(sf org display --target-org myorg --json | jq -r '.result.accessToken')
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  "$INSTANCE_URL/services/data/v62.0/sobjects/EventLogFile/<ID>/LogFile" \
  --output report-export-log.csv.gz
gunzip report-export-log.csv.gz
```

### Transaction Security Policy (declarative, in metadata)

```xml
<!-- BlockOffHoursApiAnomaly.transactionSecurityPolicy-meta.xml -->
<TransactionSecurityPolicy xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>Block Off-Hours API Anomaly</masterLabel>
    <developerName>BlockOffHoursApiAnomaly</developerName>
    <eventType>ApiAnomalyEvent</eventType>
    <resourceName>ApiAnomalyEvent</resourceName>
    <active>true</active>
    <actionConfig>
        <action>Block</action>
        <flowName>NotifySecurityOpsFlow</flowName>
    </actionConfig>
    <executionUser>Automated Process</executionUser>
    <description>Block API anomalies detected between 22:00-06:00 local.</description>
</TransactionSecurityPolicy>
```

### Platform Encryption — enable on a field

```xml
<!-- Account.field-meta.xml (field definition) -->
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>TaxIdentifier__c</fullName>
    <label>Tax Identifier</label>
    <type>Text</type>
    <length>20</length>
    <encrypted>true</encrypted>
    <encryptionScheme>DETERMINISTIC</encryptionScheme>
</CustomField>
```

### Field Audit Trail — 7-year retention

```xml
<!-- Account.object-meta.xml excerpt -->
<fullName>Account</fullName>
<enableHistory>true</enableHistory>
<enableActivities>true</enableActivities>
<historyRetentionPolicy>
    <archiveAfterMonths>12</archiveAfterMonths>
    <archiveRetentionYears>7</archiveRetentionYears>
    <description>SOX retention</description>
</historyRetentionPolicy>
```

### Rotate Tenant Secret (UI path, no CLI)

```
Setup → Platform Encryption → Key Management → [Data in Salesforce key]
  → "Generate Tenant Secret" (creates new Active; previous becomes Archived)
  → Schedule "Mass Re-encrypt" for existing ciphertext under new secret
  → Verify in Setup → Encryption Statistics
```

Never click **Destroy Key Material** unless you have an explicit, documented crypto-shredding decision signed off by the data owner.

---

## 9. Verified against

- Spring '26 Release Notes — Security & Identity
- `help.salesforce.com/s/articleView?id=sf.shield.htm`
- `help.salesforce.com/s/articleView?id=sf.event_monitoring.htm`
- `architect.salesforce.com` Trust & Security decision guides
