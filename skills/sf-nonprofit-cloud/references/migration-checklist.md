# NPSP-to-Nonprofit Cloud Migration Checklist

## Pre-Migration

### Foundation

- [ ] Set up Nonprofit Cloud org with all prerequisites
- [ ] Enable Person Accounts (required; cannot be disabled after)
- [ ] Configure Program Management
- [ ] Complete internal preparation (greatest predictor of success)

### Data Preparation

- [ ] Audit NPSP data: identify legacy components to retire
- [ ] Map NPSP fields to NPC schema (no 1:1 assumption)
- [ ] Clean data: duplicates, invalid values, orphaned records
- [ ] Determine which data is actually needed post-migration
- [ ] Document custom fields and automations to migrate

### Stakeholder Alignment

- [ ] Assess AppExchange partner compatibility
- [ ] Review technology stack connectivity
- [ ] Plan timeline and resource allocation
- [ ] Communicate operational change (not just product swap)

---

## Migration Execution

### Data Migration

- [ ] Export NPSP data (Data Loader, Salesforce Inspector)
- [ ] Transform data to NPC structure (Person Account, Gift, etc.)
- [ ] Map Contact + Household Account → Person Account where appropriate
- [ ] Map Opportunity (donation) → Gift
- [ ] Preserve relationships (Household membership, soft credit, etc.)
- [ ] Import in dependency order (Accounts → Contacts/Person Accounts → related records)

### Metadata Migration

- [ ] Migrate custom objects and fields
- [ ] Migrate workflows, flows, process builder
- [ ] Migrate validation rules, triggers
- [ ] Update record types and page layouts
- [ ] Migrate reports and dashboards

### Validation

- [ ] Verify record counts match
- [ ] Spot-check key relationships
- [ ] Validate gift totals and attribution
- [ ] Test critical user flows

---

## Post-Migration

### Reporting & Analytics

- [ ] Update reports for new object/field names
- [ ] Rebuild dashboards
- [ ] Validate GAU and allocation reporting
- [ ] Test outcome and impact reports

### Integration & Automation

- [ ] Reconnect external integrations
- [ ] Verify API and middleware compatibility
- [ ] Test automated processes (flows, triggers, scheduled jobs)

### Training & Cutover

- [ ] Train users on Person Account model
- [ ] Document process changes
- [ ] Execute cutover plan
- [ ] Monitor for issues in first weeks

---

## Common Mapping Reference

| NPSP | Nonprofit Cloud |
|------|-----------------|
| Contact (individual donor) | Person Account |
| Account (Household) | Party Relationship Group (Household) + Business Account |
| Opportunity (donation) | Gift |
| Recurring Donation | Recurring Gift / Payment schedule |
| Affiliation | Party Relationship |
| GAU Allocation | GAU Allocation (structure may differ) |
| Campaign | Campaign (similar) |

**Note**: Mapping is not 1:1. Review Salesforce documentation for current schema.
