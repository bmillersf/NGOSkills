# NPSP-to-Nonprofit Cloud Migration Checklist

## Pre-Migration

### Foundation

- [ ] Set up Nonprofit Cloud org with all prerequisites
- [ ] Enable Person Accounts (required; cannot be disabled after)
- [ ] Configure Program Management module
- [ ] Complete internal preparation (greatest predictor of success)
- [ ] Identify NPSP package version and installed companion packages (OFM, Volunteers, etc.)

### Data Preparation

- [ ] Audit NPSP data: identify legacy components to retire
- [ ] Map NPSP fields to NPC schema (no 1:1 assumption — see mapping table below)
- [ ] Clean data: duplicates, invalid values, orphaned records
- [ ] Determine which data is actually needed post-migration
- [ ] Document custom fields and automations to migrate
- [ ] Inventory TDTM trigger handlers and custom rollup definitions

### Stakeholder Alignment

- [ ] Assess AppExchange partner compatibility with NPC
- [ ] Review technology stack connectivity (integrations, middleware, APIs)
- [ ] Plan timeline and resource allocation
- [ ] Communicate operational change (not just a product swap)
- [ ] Train admins on Person Account model differences

---

## Object & Field Mapping

### Constituent Model

| NPSP Source | NPC Target | Notes |
|-------------|-----------|-------|
| Contact (individual) | Person Account | Merge Account+Contact into single Person Account record |
| Household Account | Party Relationship Group (type=Household) | New grouping mechanism — not a direct rename |
| Organization Account | Business Account | Straightforward — same object, different context |
| npe5__Affiliation__c | Account Contact Relationship | Person-to-org links; different object structure |
| npe4__Relationship__c | Contact Contact Relationship | Person-to-person links; different object structure |
| Household naming fields | Party Relationship Group fields | Reconfigure naming rules |

### Fundraising

| NPSP Source | NPC Target | Notes |
|-------------|-----------|-------|
| Opportunity (donation) | Gift Transaction | Different object — requires data transformation |
| npe01__OppPayment__c | Payment data on Gift Transaction | No standalone Payment object in NPC — map to Gift Transaction fields |
| npe03__Recurring_Donation__c | Gift Commitment + Gift Commitment Schedule | Split into two objects in NPC |
| npsp__Partial_Soft_Credit__c | Gift Soft Credit | Different object — map roles |
| Opportunity Contact Role (soft credit) | Gift Soft Credit | Consolidate into Gift Soft Credit object |
| npsp__Allocation__c | Gift Transaction Designation | Similar concept — verify field mapping |
| npsp__General_Accounting_Unit__c | Gift Designation | Similar — verify API names |
| Campaign | Campaign | Similar structure |
| CampaignMember | CampaignMember | Similar structure |

### Grantmaking (OFM → NPC)

| NPSP+OFM Source | NPC Target | Notes |
|-----------------|-----------|-------|
| outfunds__Funding_Request__c | Application | OFM Funding Request is dual-purpose (application + award); NPC splits into separate objects |
| (no OFM equivalent) | Funding Award | OFM uses Funding Request status change; NPC has dedicated Funding Award |
| outfunds__Disbursement__c | Funding Disbursement | Different object |
| outfunds__Requirement__c | Funding Award Requirement | Map compliance tracking |
| outfunds__Funding_Program__c | (Funding Opportunity / custom) | No direct 1:1 equivalent |
| outfunds__Review__c | Application Review | Map reviewer evaluations |
| outfunds__Funding_Request_Role__c | (Contact roles on Application) | Map contact relationships |

### Settings & Configuration

| NPSP Component | NPC Equivalent | Notes |
|----------------|---------------|-------|
| NPSP Settings tab | Standard Setup | No custom settings app |
| TDTM Trigger Handlers | Standard triggers / Flow | Rebuild automation natively |
| Customizable Rollups (CRLP) | Platform rollup summaries / Flow | Redesign rollup strategy |
| npsp__Error__c | Platform error handling | Use Flow fault paths, Apex exception handling |
| Batch Gift Entry (Data Import) | Gift Entry UI | Different mechanism |

---

## Migration Execution

### Data Migration Order

Import in dependency order to preserve relationships:

1. **Accounts** (Organization Accounts → Business Accounts)
2. **Person Accounts** (from Contacts — create Person Account per individual)
3. **Party Relationship Groups** (Households — from Household Accounts)
4. **Contact Contact Relationships + Account Contact Relationships** (from Relationships + Affiliations)
5. **Campaigns** (direct transfer)
6. **Gift Transactions** (from Opportunities — transform fields)
7. **Payment data on Gift Transactions** (from NPSP Payments)
8. **Gift Soft Credits** (from Partial Soft Credits + Opportunity Contact Roles)
9. **Gift Designations + Gift Transaction Designations** (similar structure, verify API names)
10. **Gift Commitments** (from Recurring Donations)
11. **Applications** (from OFM Funding Requests, if applicable)
12. **Funding Awards + Funding Disbursements** (from OFM, if applicable)
13. **Programs + Enrollments** (new in NPC — may not have NPSP source)

### Metadata Migration

- [ ] Migrate custom objects and fields (update API references)
- [ ] Rebuild workflows/flows (NPSP automations won't transfer)
- [ ] Migrate validation rules (update field references)
- [ ] Rebuild triggers (TDTM handlers → standard Apex or Flow)
- [ ] Update record types and page layouts for new objects
- [ ] Migrate reports and dashboards (update object/field references)
- [ ] Rebuild rollups (CRLP → native rollup summaries or Flow)

### Validation

- [ ] Verify record counts match (Contacts → Person Accounts, Opportunities → Gift Transactions)
- [ ] Spot-check key relationships (Household membership, account contact relationships)
- [ ] Validate gift transaction totals and attribution (compare rollup totals pre/post)
- [ ] Test critical user flows (gift entry, recurring giving, reporting)
- [ ] Verify gift soft credit attribution matches original

---

## Post-Migration

### Reporting & Analytics

- [ ] Update reports for new object/field names (Gift Transaction vs Opportunity, etc.)
- [ ] Rebuild dashboards with NPC objects
- [ ] Validate Gift Designation and Gift Transaction Designation reporting totals
- [ ] Test outcome and impact reports (new NPC capability)
- [ ] Compare key KPIs pre/post migration (total giving, donor count, retention)

### Integration & Automation

- [ ] Reconnect external integrations (update API references)
- [ ] Verify API and middleware compatibility (new object API names)
- [ ] Test automated processes (flows, triggers, scheduled jobs)
- [ ] Update any Apex referencing `npsp__` / `npe*__` namespaced fields

### Training & Cutover

- [ ] Train users on Person Account model (vs Contact + Household)
- [ ] Train users on Gift Transaction object (vs Opportunity)
- [ ] Document process changes and new workflows
- [ ] Execute cutover plan (freeze NPSP, switch to NPC)
- [ ] Monitor for issues in first weeks
- [ ] Decommission NPSP package after validation period

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Data loss during transform | Full backup before migration, validation queries after |
| Broken integrations | API audit pre-migration, sandbox testing |
| User resistance | Early communication, training, phased rollout |
| AppExchange incompatibility | Verify partner NPC support before committing |
| Rollup discrepancies | Compare CRLP totals vs NPC rollup totals in sandbox |
| Person Account enablement side effects | Test in sandbox first — cannot be disabled |
