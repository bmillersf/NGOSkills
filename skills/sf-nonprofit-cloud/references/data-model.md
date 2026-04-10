# Nonprofit Cloud Data Model Reference

## Constituent Model

### Person Account

Unified record for individual constituents. Combines Account + Contact fields. Primary model in NPC for donors, volunteers, clients, and staff.

- **Key fields**: FirstName, LastName, PersonEmail, PersonMailingAddress, GenderIdentity
- **Relationships**: Links to Households (Party Relationship Group), Organizations (Business Account), other Person Accounts

### Business Account

Organizations: foundations, companies, government agencies, other nonprofits.

- **Key fields**: Name, Type, BillingAddress
- **Use**: Grant applicants, corporate donors, partner organizations

### Household (Party Relationship Group)

Group of individuals sharing an address or relationship. Type = "Household."

- **Members**: Connected via account-contact relationships
- **Features**: Auto-naming, formal/informal greetings, primary contact designation
- **Flexibility**: Split, merge, multiple group membership

### Party Relationship

Connects Person Accounts to Households and other entities. Defines relationship type (Household, Spouse, Organization, etc.).

---

## Fundraising

### Gift

Donation transaction. Replaces Opportunity for donation tracking in NPC.

- **Key fields**: Amount, Gift Date, Payment Method, Campaign, GAU Allocation
- **Relationships**: Person Account (donor), Campaign, Payment

### Payment

Individual payment against a Gift. Supports split payments and recurring gifts.

### Campaign

Outreach initiatives. Tracks ROI and attribution.

### Soft Credit

Attribution of gift to additional constituents (e.g., board member who secured donation).

### GAU (General Accounting Unit)

Accounting structure for gift allocation. Drives reporting and fund attribution.

---

## Grantmaking

### Grant Application

Application from grantee. Tracks status through review and award.

- **Key fields**: Applicant (Account), Program, Status, Requested Amount
- **Relationships**: Funding Award, Disbursement, Budget

### Funding Award

Approved grant. Links to Grant Application.

### Disbursement

Payment against a Funding Award. Tracks spending against budget.

### Budget

Grantee budget. Tracks amendments and progress.

---

## Program Management

### Program

Service or initiative offered by the organization.

- **Key fields**: Name, Start Date, End Date, Status
- **Relationships**: Program Enrollment, Outcome

### Program Enrollment

Individual's participation in a program.

- **Key fields**: Person Account, Program, Enrollment Date, Status
- **Relationships**: Service Delivery, Case

### Service Delivery

Record of service provided to a participant. Links to Program Enrollment.

### Case

Support or intervention case. Can link to Program Enrollment for wraparound care.

---

## Outcome Management

### Outcome

Defined result or impact measure. Links to Program.

- **Key fields**: Name, Target, Measurement Type
- **Relationships**: Outcome Activity, Program

### Outcome Activity

Instance of outcome measurement. Tracks progress toward targets.

### Assessment

Data collection instrument. Streamlines outcome data from participants.

---

## Volunteer Management

### Volunteer Job

Position or opportunity. Defines skills, location, capacity.

### Volunteer Shift

Scheduled slot within a Volunteer Job.

- **Key fields**: Start/End DateTime, Capacity, Status
- **Relationships**: Volunteer Hours

### Volunteer Hours

Record of volunteer participation. Links Person Account to Shift.

---

## Object Relationship Summary

```
Person Account
├── Party Relationship → Household (Business Account)
├── Gift (donor)
├── Program Enrollment
├── Volunteer Hours
├── Grant Application (applicant contact)
└── Soft Credit

Program
├── Program Enrollment
├── Outcome
└── Grant (funding source)

Grant Application
├── Funding Award
├── Disbursement
└── Budget
```
