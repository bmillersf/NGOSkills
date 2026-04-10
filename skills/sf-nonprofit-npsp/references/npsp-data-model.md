# NPSP Data Model Reference

## Constituent Model

### Contact (Individual)

Primary record for individual constituents in NPSP. Every person is a Contact.

- **Key fields**: FirstName, LastName, Email, MailingAddress, Phone
- **NPSP fields**: npsp__Primary_Affiliation__c, npe01__PreferredPhone__c, npe01__Preferred_Email__c
- **Rollup fields**: npo02__TotalOppAmount__c, npo02__NumberOfClosedOpps__c, npo02__LastCloseDate__c, npo02__LargestAmount__c, npo02__FirstCloseDate__c, npo02__Best_Gift_Year__c
- **Household**: Auto-assigned to Household Account via AccountId

### Household Account

Auto-created Account grouping Contacts into a household unit.

- **Record type**: Household Account
- **Naming fields**: npsp__Formal_Greeting__c, npsp__Informal_Greeting__c
- **Member count**: npsp__Number_of_Household_Members__c
- **Rollup fields**: npo02__TotalOppAmount__c, npo02__NumberOfClosedOpps__c (rolled up from all member Opportunities)
- **Naming rules**: Configurable in NPSP Settings → People → Household Naming

### Organization Account

Standard Account record type for businesses, foundations, agencies.

- **Record type**: Organization
- **Use**: Corporate donors, employer affiliations, grant funders
- **Rollup fields**: Same rollup fields as Household (aggregate of Opportunities where Account is primary)

---

## Relationships

### Relationship (npe4__)

Person-to-person link.

```
Contact A ←→ Contact B
  npe4__Relationship__c
  ├── npe4__Contact__c = A
  ├── npe4__RelatedContact__c = B
  ├── npe4__Type__c = "Spouse"
  └── npe4__Status__c = "Current"

  Mirror (auto-created):
  ├── npe4__Contact__c = B
  ├── npe4__RelatedContact__c = A
  ├── npe4__Type__c = "Spouse"
  └── npe4__Status__c = "Current"
```

**Common types**: Spouse, Partner, Parent, Child, Sibling, Friend, Employer, Employee, Coworker, Mentor, Mentee

### Affiliation (npe5__)

Person-to-organization link.

```
Contact ←→ Organization Account
  npe5__Affiliation__c
  ├── npe5__Contact__c = Contact
  ├── npe5__Organization__c = Org Account
  ├── npe5__Role__c = "Board Member"
  ├── npe5__Status__c = "Current"
  ├── npe5__StartDate__c = 2023-01-01
  ├── npe5__EndDate__c = null
  └── npe5__Primary__c = true
```

**Common roles**: Board Member, Employee, Volunteer, Client, Consultant, Advisor

---

## Donation Objects

### Opportunity (Donation)

Primary donation record. Contact Role links the donor.

```
Opportunity
├── Amount = 500
├── CloseDate = 2024-03-15
├── StageName = "Closed Won"
├── npsp__Primary_Contact__c = Contact (donor)
├── AccountId = Household Account (auto-set)
├── CampaignId = Annual Fund Campaign
├── RecordTypeId = Donation
└── npsp__Acknowledgment_Status__c = "To Be Acknowledged"
```

### Payment (npe01__OppPayment__c)

Individual payment against an Opportunity. Auto-created by NPSP.

```
npe01__OppPayment__c
├── npe01__Opportunity__c = Opportunity
├── npe01__Payment_Amount__c = 500
├── npe01__Payment_Date__c = 2024-03-15
├── npe01__Paid__c = true
├── npe01__Payment_Method__c = "Credit Card"
└── npe01__Check_Reference_Number__c = null
```

### Recurring Donation (npe03__)

Enhanced Recurring Donation (ERD) for ongoing giving.

```
npe03__Recurring_Donation__c
├── npe03__Contact__c = Contact (donor)
├── npe03__Amount__c = 50
├── npsp__InstallmentFrequency__c = 1
├── npe03__Installment_Period__c = "Monthly"
├── npsp__Day_of_Month__c = "15"
├── npsp__Status__c = "Active"
├── npsp__StartDate__c = 2024-01-15
├── npe03__Date_Established__c = 2024-01-15
└── npsp__RecurringType__c = "Open"
```

**Installment generation**: NPSP batch job creates Opportunity + Payment per schedule period.

### GAU & Allocation

```
npsp__General_Accounting_Unit__c
├── Name = "Youth Programs"
├── npsp__Active__c = true
└── npsp__Description__c = "Youth program funding"

npsp__Allocation__c
├── npsp__General_Accounting_Unit__c = GAU
├── npsp__Opportunity__c = Opportunity
├── npsp__Amount__c = 300
└── npsp__Percent__c = 60
```

### Partial Soft Credit

```
npsp__Partial_Soft_Credit__c
├── npsp__Contact__c = Contact (credited person)
├── npsp__Opportunity__c = Opportunity
├── npsp__Amount__c = 250
└── npsp__Role_Name__c = "Solicitor"
```

---

## Batch Gift Entry Objects

### Data Import Batch

```
npsp__DataImportBatch__c
├── Name = "March Direct Mail"
├── npsp__Batch_Status__c = "Open"
├── npsp__Expected_Count_of_Gifts__c = 150
└── npsp__Expected_Total_Batch_Amount__c = 12500
```

### Data Import Row

```
npsp__DataImport__c
├── npsp__NPSP_Data_Import_Batch__c = Batch
├── npsp__Contact1_Firstname__c = "Jane"
├── npsp__Contact1_Lastname__c = "Doe"
├── npsp__Contact1_Personal_Email__c = "jane@example.com"
├── npsp__Donation_Amount__c = 100
├── npsp__Donation_Date__c = 2024-03-01
├── npsp__Payment_Method__c = "Check"
├── npsp__Payment_Check_Reference_Number__c = "4521"
└── npsp__Status__c = "Ready to Process"
```

---

## Object Relationship Summary

```
Contact
├── AccountId → Household Account
├── npe5__Affiliation__c → Organization Account
├── npe4__Relationship__c → Other Contact
├── Opportunity (via npsp__Primary_Contact__c / Contact Role)
│   ├── npe01__OppPayment__c
│   ├── npsp__Allocation__c → npsp__General_Accounting_Unit__c
│   └── npsp__Partial_Soft_Credit__c
├── npe03__Recurring_Donation__c → Opportunities (auto-generated)
├── npsp__Engagement_Plan__c → npsp__Engagement_Plan_Template__c → Tasks
├── npsp__Level__c (stamped from Level definitions)
└── CampaignMember → Campaign

Household Account
├── Contacts (members)
├── npsp__Address__c (multiple — one default, optional seasonal)
├── Opportunities (rolled up from members)
└── Rollup fields (npo02__ — totals, counts, dates)

npsp__Engagement_Plan_Template__c
└── npsp__Engagement_Plan_Task__c (ordered task definitions)
    └── npsp__Engagement_Plan_Task__c (dependent child tasks)

npsp__Level__c (definition records — evaluated by batch job)
```

---

## Engagement Plan Objects

### Engagement Plan Template

```
npsp__Engagement_Plan_Template__c
├── Name = "New Major Donor Stewardship"
├── npsp__Description__c = "90-day stewardship cadence for gifts $10K+"
├── npsp__Reschedule_To__c = "Monday"
└── npsp__Skip_Weekends__c = true
```

### Engagement Plan Task

```
npsp__Engagement_Plan_Task__c
├── npsp__Engagement_Plan_Template__c = Template
├── Name = "Personal thank-you call"
├── npsp__Priority__c = "High"
├── npsp__Days_After__c = 1
├── npsp__Assigned_To__c = User (development officer)
├── npsp__Type__c = "Call"
├── npsp__Comments__c = "Call donor to thank them personally"
└── npsp__Parent_Task__c = null (or prior task for dependency chains)
```

### Engagement Plan (Instance)

```
npsp__Engagement_Plan__c
├── npsp__Engagement_Plan_Template__c = Template
├── npsp__Contact__c = Contact (or lookup to Opp, Campaign, RD)
└── (auto-creates Task records per template)
```

---

## Level Object

```
npsp__Level__c
├── Name = "Gold Donor"
├── npsp__Target__c = "Contact"
├── npsp__Source_Field__c = "npo02__TotalOppAmount__c"
├── npsp__Level_Field__c = "npsp__Level__c"
├── npsp__Minimum_Amount__c = 5000
├── npsp__Maximum_Amount__c = 24999.99
├── npsp__Active__c = true
└── npsp__Previous_Level_Field__c = "npsp__Previous_Level__c"
```

---

## Address Object

```
npsp__Address__c
├── npsp__Household_Account__c = Household Account
├── npsp__MailingStreet__c = "123 Main St"
├── npsp__MailingCity__c = "Portland"
├── npsp__MailingState__c = "OR"
├── npsp__MailingPostalCode__c = "97201"
├── npsp__MailingCountry__c = "US"
├── npsp__Default_Address__c = true
├── npsp__Address_Type__c = "Home"
├── npsp__Seasonal_Start_Month__c = null
├── npsp__Seasonal_Start_Day__c = null
├── npsp__Seasonal_End_Month__c = null
└── npsp__Seasonal_End_Day__c = null
```

Seasonal address example (summer home):

```
npsp__Address__c
├── npsp__Household_Account__c = Household Account
├── npsp__MailingStreet__c = "456 Lake Rd"
├── npsp__MailingCity__c = "Lake Tahoe"
├── npsp__MailingState__c = "CA"
├── npsp__MailingPostalCode__c = "96150"
├── npsp__Default_Address__c = false
├── npsp__Address_Type__c = "Vacation"
├── npsp__Seasonal_Start_Month__c = "6"
├── npsp__Seasonal_Start_Day__c = "1"
├── npsp__Seasonal_End_Month__c = "8"
└── npsp__Seasonal_End_Day__c = "31"
```

---

## NPSP Settings Objects

### Trigger Handler

```
npsp__Trigger_Handler__c
├── npsp__Object__c = "Opportunity"
├── npsp__Class__c = "TDTM_Runnable"
├── npsp__Load_Order__c = 1
├── npsp__Active__c = true
├── npsp__Asynchronous__c = false
└── npsp__Trigger_Action__c = "BeforeInsert;AfterInsert;BeforeUpdate;AfterUpdate"
```

### Error Record

```
npsp__Error__c
├── npsp__Error_Type__c = "Apex"
├── npsp__Full_Message__c = "..."
├── npsp__Stack_Trace__c = "..."
├── npsp__Object_Type__c = "Opportunity"
├── npsp__Datetime__c = 2024-03-15T10:30:00Z
└── npsp__Posted_in_Chatter__c = false
```
