# Sharing Architecture Reference

## Org-Wide Defaults for Nonprofit Portals

Set OWD to Private for objects exposed through portals, then open access via sharing sets and rules.

| Object | Internal OWD | External OWD | Rationale |
|--------|-------------|-------------|-----------|
| Account (Person Account) | Private | Private | Each user sees own account only |
| Program Enrollment | Controlled by Parent | Private | Access via sharing set on Contact |
| PersonExamination | Private | Private | Sensitive; sharing set on ContactId |
| Gift | Private | Private | Donor sees own gifts via sharing set |
| Case | Private | Private | Client sees own cases via sharing set |
| Grant Application | Private | Private | Grantee sees own applications |
| Examination (templates) | Public Read Only | Private | Sharing rule for portal users |
| Program | Public Read Only | Private | Sharing rule for published programs |

---

## Sharing Set Patterns

### Pattern 1: Direct Contact Lookup

Object has a direct Contact or Account lookup field.

```
Portal User (Contact: Taylor Volunteer)
  → Sharing Set: PersonExamination.ContactId = User.ContactId
  → Result: Taylor sees only PersonExamination records where ContactId = Taylor's Contact ID
```

**Configuration:**
- Access Mapping: `User.Contact = PersonExamination.Contact`
- Access Level: Read/Write (or Read Only)

### Pattern 2: Parent Account Lookup

Object relates to Account (Person Account) rather than Contact.

```
Portal User (Account: Taylor's Person Account)
  → Sharing Set: Gift.DonorAccountId = User.AccountId
  → Result: Taylor sees only Gift records where DonorAccountId = Taylor's Account ID
```

### Pattern 3: Junction Object

Object connects to Contact through a junction/intermediate object.

```
Portal User (Contact: Taylor)
  → Program Enrollment (ContactId = Taylor)
  → Service Delivery (ProgramEnrollmentId → Program Enrollment)
```

For junction patterns, the parent sharing (Program Enrollment) may cascade to children (Service Delivery) if the child object's OWD is "Controlled by Parent."

---

## Sharing Rule Patterns

### Criteria-Based Sharing Rule

Share records matching specific criteria with a group of portal users.

**Example: Share active Examination templates with all portal users**

```xml
<sharingRules>
    <sharingCriteriaRules>
        <fullName>Share_Active_Exams_With_Portal_Users</fullName>
        <accessLevel>Read</accessLevel>
        <sharedTo>
            <group>Volunteer_Portal_Users</group>
        </sharedTo>
        <criteriaItems>
            <field>Status</field>
            <operation>equals</operation>
            <value>Active</value>
        </criteriaItems>
    </sharingCriteriaRules>
</sharingRules>
```

### Owner-Based Sharing Rule

Share records owned by a specific role/group with portal users.

**Example: Share Program records owned by Program Managers with portal users**

```
Records owned by: Role "Program Manager"
Shared with: Group "Portal Users"
Access Level: Read Only
```

---

## Guest User Security

### Minimum Viable Access

| Principle | Implementation |
|-----------|---------------|
| No PII exposure | Guest user profile has no access to Person Account fields |
| Read-only public content | Only published Programs, FAQ articles |
| No record creation | Guest cannot create records (use authenticated flows) |
| Rate limiting | Configure login attempt limits |
| CAPTCHA | Enable reCAPTCHA on self-registration |

### Guest User Profile Configuration

1. Remove all object permissions except explicitly needed (e.g., Knowledge Article read)
2. Remove all field-level security for sensitive fields
3. Enable only specific Apex classes needed for public pages
4. Disable API access
5. Regular audit of guest user permissions

---

## Testing Sharing Access

### Login As Portal User

1. Navigate to the Person Account / Contact record
2. Click "Login to Experience as User"
3. Select the Experience Cloud site
4. Verify:
   - User sees only their own records
   - User cannot access other users' records
   - Template/public records are visible
   - Create/edit permissions work as expected
   - Navigation and page access is correct

### Sharing Debug

Use Setup → Security → Sharing Settings → Sharing Calculation to verify:
- Record access reasons (sharing set, sharing rule, ownership)
- Effective access level per user per record

### Test Scenarios

| Scenario | Expected Result |
|----------|----------------|
| User A views own records | Sees only records linked to User A's Contact |
| User A searches for User B's records | No results returned |
| User A creates a new record | Record automatically linked to User A's Contact |
| Guest user browses public pages | Sees only public content, no PII |
| Admin changes OWD | Portal sharing recalculated correctly |

---

## Sharing Set Deployment

Sharing sets are configured via Setup UI, not metadata API. Document configuration for repeatable deployment:

### Manual Configuration Steps

1. Setup → Digital Experiences → Settings → Sharing Sets
2. Click "New" or edit existing
3. Set label, API name, profiles
4. Add access mapping:
   - User field: Account or Contact
   - Target object
   - Target field (lookup to Account/Contact)
   - Access level
5. Save and verify with "Login As"

### Alternative: Sharing Rules via Metadata

Sharing rules (criteria-based and owner-based) can be deployed via metadata API:

```
force-app/main/default/sharingRules/
├── PersonExamination.sharingRules-meta.xml
├── Program.sharingRules-meta.xml
└── Examination.sharingRules-meta.xml
```
