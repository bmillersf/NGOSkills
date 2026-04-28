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

### Contact Contact Relationship

Person-to-person links (e.g., Spouse, Sibling). API: ContactContactRelationship.

### Account Contact Relationship

Person-to-organization links (e.g., employee, board member). API: AccountContactRelationship.

### Account Account Relationship

Organization-to-organization links (e.g., parent/subsidiary, partner). API: AccountAccountRelationship.

---

## Fundraising

### Gift Transaction

Donation transaction (API: GiftTransaction). Core fundraising record. Replaces Opportunity for donation tracking in NPC.

- **Key fields**: Amount, Gift Date, Payment Method, Campaign, Gift Designation
- **Relationships**: Person Account (donor), Campaign, Payment Instrument, Gift Soft Credit

### Payment Instrument

Reusable payment method (card token, bank account). API: PaymentInstrument.

### Campaign

Outreach initiatives. Tracks ROI and attribution.

### Gift Soft Credit

Attribution of gift to additional constituents (API: GiftSoftCredit). E.g., board member who secured donation.

### Gift Designation

Named fund for tracking (API: GiftDesignation). Replaces GAU concept in NPC.

### Gift Transaction Designation

Links Gift Transaction to Gift Designation with amount (API: GiftTransactionDesignation). Enables split allocations across funds.

---

## Grantmaking

### Application

Application from grantee (API: Application). Tracks status through review and award.

- **Key fields**: Applicant (Account), Program, Status, Requested Amount
- **Relationships**: Funding Award, Funding Disbursement, Budget

### Funding Award

Approved grant. Links to Application.

### Funding Disbursement

Payment against a Funding Award (API: FundingDisbursement). Tracks spending against budget.

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
- **Relationships**: Benefit, Benefit Disbursement, Case

### Benefit

Defined service or resource available through a program (API: Benefit). Describes what can be provided.

### Benefit Disbursement

Record of benefit provided to a participant (API: BenefitDisbursement). Links to Program Enrollment and Benefit.

### Case

Support or intervention case. Can link to Program Enrollment for wraparound care.

---

## Outcome Management

### Outcome

Defined result or impact measure. Links to Program.

- **Key fields**: Name, Target, Measurement Type
- **Relationships**: Outcome Activity, Program

### Outcome Activity

Junction between an Outcome and an activity or program. Tracks progress toward targets.

### Indicator Definition

Measurable indicator that defines what is tracked (API: IndicatorDefinition). E.g., "reading level" or "housing stability score."

### Indicator Result

Recorded measurement for an individual against an Indicator Definition (API: IndicatorResult). Captures actual outcome data from participants.

### Indicator Assignment

Links an Indicator Definition to a Program or Benefit, defining which indicators apply where.

### Indicator Performance Period

Time-bound target for an indicator. Defines expected values over a measurement window.

---

## Volunteer Management

### Job Position

Volunteer position or opportunity (API: JobPosition). Defines skills, location, capacity.

### Job Position Shift

Scheduled slot within a Job Position (API: JobPositionShift).

- **Key fields**: Start/End DateTime, Capacity, Status
- **Relationships**: Job Position Assignment

### Job Position Assignment

Record of volunteer participation (API: JobPositionAssignment). Links Person Account to Job Position Shift.

---

## Object Relationship Summary

```
Person Account
├── Contact Contact Relationship → other Person Accounts
├── Account Contact Relationship → Business Accounts / Households
├── Gift Transaction (donor)
├── Program Enrollment
├── Job Position Assignment (volunteer)
├── Application (applicant contact)
└── Gift Soft Credit

Program
├── Program Enrollment
├── Benefit
├── Outcome
└── Indicator Assignment

Gift Transaction
├── Gift Soft Credit
├── Gift Transaction Designation → Gift Designation
└── Payment Instrument

Application
├── Funding Award
├── Funding Disbursement
└── Budget
```
