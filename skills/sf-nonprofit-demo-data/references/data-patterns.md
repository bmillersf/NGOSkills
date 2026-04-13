# Nonprofit Demo Data Patterns

Reusable data patterns for common nonprofit demo scenarios. Copy and adapt to the specific persona names and dates from the demoscript.

---

## Pattern 1: Major Donor 360

Creates a 3-year giving history for a major donor persona -- enough to show a meaningful relationship history on the donor 360 view.

**NPC**:
```apex
Id donorId = [SELECT Id FROM Account WHERE PersonEmail = 'eleanor.whitfield@demo.ngo'].Id;
Integer currentYear = Date.today().year();

List<npc__Gift_Transaction__c> gifts = new List<npc__Gift_Transaction__c>{
    new npc__Gift_Transaction__c(npc__Donor__c = donorId, npc__Amount__c = 25000,
        npc__Status__c = 'Closed Won', npc__CloseDate__c = Date.newInstance(currentYear, 3, 15),
        Name = 'Eleanor Whitfield ' + currentYear + ' Annual Gift'),
    new npc__Gift_Transaction__c(npc__Donor__c = donorId, npc__Amount__c = 22500,
        npc__Status__c = 'Closed Won', npc__CloseDate__c = Date.newInstance(currentYear-1, 4, 2),
        Name = 'Eleanor Whitfield ' + (currentYear-1) + ' Annual Gift'),
    new npc__Gift_Transaction__c(npc__Donor__c = donorId, npc__Amount__c = 20000,
        npc__Status__c = 'Closed Won', npc__CloseDate__c = Date.newInstance(currentYear-2, 3, 28),
        Name = 'Eleanor Whitfield ' + (currentYear-2) + ' Annual Gift'),
    // Open pledge for next year
    new npc__Gift_Transaction__c(npc__Donor__c = donorId, npc__Amount__c = 30000,
        npc__Status__c = 'Pledged', npc__CloseDate__c = Date.newInstance(currentYear+1, 6, 30),
        Name = 'Eleanor Whitfield ' + (currentYear+1) + ' Pledge')
};
insert gifts;
```

**What this shows**: Ascending giving trend ($20K → $22.5K → $25K), open pledge, multi-year relationship. The "wow moment" on the donor 360 view.

---

## Pattern 2: Volunteer Application Pipeline

Creates a realistic pipeline of volunteer applications at different stages.

**NPC (IndividualApplication)**:
```apex
List<IndividualApplication__c> apps = new List<IndividualApplication__c>{
    // James Okafor -- the hero persona, pending review
    new IndividualApplication__c(FirstName__c='James', LastName__c='Okafor',
        Email__c='james.okafor@demo.volunteer', Status__c='Submitted',
        VolunteerType__c='Tutor', SubmittedDate__c=Date.today().addDays(-2)),
    // Two others to populate the list view
    new IndividualApplication__c(FirstName__c='Sofia', LastName__c='Ramirez',
        Email__c='sofia.ramirez@demo.volunteer', Status__c='Under Review',
        VolunteerType__c='Mentor', SubmittedDate__c=Date.today().addDays(-5)),
    new IndividualApplication__c(FirstName__c='Andre', LastName__c='Thompson',
        Email__c='andre.thompson@demo.volunteer', Status__c='Approved',
        VolunteerType__c='Tutor', SubmittedDate__c=Date.today().addDays(-10))
};
insert apps;
```

**What this shows**: A real queue for Maria to work through. James is at the top (most recent). The coordinator has context for each step of the review process.

---

## Pattern 3: Open Volunteer Shifts

Creates future-dated shifts for different volunteer types. Shift dates are always in the future so the demo never shows past/stale slots.

```apex
Date baseDate = Date.today();
List<Volunteer_Shift__c> shifts = new List<Volunteer_Shift__c>{
    new Volunteer_Shift__c(Name='After School Tutoring - North Site',
        Shift_Date__c=baseDate.addDays(7), Start_Time__c=Time.newInstance(15,30,0,0),
        End_Time__c=Time.newInstance(17,30,0,0), Spots_Available__c=3,
        Volunteer_Type__c='Tutor', Location__c='North Chicago'),
    new Volunteer_Shift__c(Name='Saturday Mentoring Session',
        Shift_Date__c=baseDate.addDays(10), Start_Time__c=Time.newInstance(9,0,0,0),
        End_Time__c=Time.newInstance(11,0,0,0), Spots_Available__c=2,
        Volunteer_Type__c='Mentor', Location__c='West Side Campus'),
    new Volunteer_Shift__c(Name='After School Tutoring - South Site',
        Shift_Date__c=baseDate.addDays(14), Start_Time__c=Time.newInstance(15,30,0,0),
        End_Time__c=Time.newInstance(17,30,0,0), Spots_Available__c=4,
        Volunteer_Type__c='Tutor', Location__c='South Chicago')
};
insert shifts;
```

---

## Pattern 4: Program Enrollment with Service History

Creates an active enrollment with service delivery history to show program impact tracking.

**NPC**:
```apex
Id contactId = [SELECT Id FROM Account WHERE PersonEmail = 'aisha.johnson@demo.family'].Id;
Id programId = [SELECT Id FROM npc__Program__c WHERE Name = 'After School Tutoring' LIMIT 1].Id;

npc__Program_Enrollment__c enrollment = new npc__Program_Enrollment__c(
    npc__Contact__c = contactId,
    npc__Program__c = programId,
    npc__Status__c = 'Active',
    npc__Start_Date__c = Date.today().addDays(-45)
);
insert enrollment;

// 4 service deliveries to show ongoing engagement
List<npc__Service_Delivery__c> sessions = new List<npc__Service_Delivery__c>();
for (Integer i = 1; i <= 4; i++) {
    sessions.add(new npc__Service_Delivery__c(
        npc__Contact__c = contactId,
        npc__Program_Enrollment__c = enrollment.Id,
        npc__Date__c = Date.today().addDays(-(i * 7)),
        npc__Quantity__c = 1,
        npc__Unit__c = 'Hours',
        npc__Service__c = 'Tutoring Session'
    ));
}
insert sessions;
```

**What this shows**: Aisha has been enrolled for 6 weeks with consistent weekly sessions -- a real engagement pattern, not a single placeholder record.

---

## Pattern 5: Grant Pipeline

Creates a grant pipeline with applications at different stages for a grants management demo.

```apex
Id grantorId = [SELECT Id FROM Account WHERE Name = 'Kresge Foundation' LIMIT 1].Id;
Id orgId = [SELECT Id FROM Account WHERE Name = '[Org Name]' LIMIT 1].Id;

List<outfunds__Funding_Request__c> grants = new List<outfunds__Funding_Request__c>{
    new outfunds__Funding_Request__c(Name='Kresge After School Initiative 2026',
        outfunds__Applying_Organization__c=orgId,
        outfunds__Funding_Opportunity__c=grantorId,
        outfunds__Requested_Amount__c=150000,
        outfunds__Status__c='In Progress',
        outfunds__Application_Date__c=Date.today().addDays(-30)),
    new outfunds__Funding_Request__c(Name='Chicago Community Trust Program Support',
        outfunds__Applying_Organization__c=orgId,
        outfunds__Requested_Amount__c=75000,
        outfunds__Status__c='Awarded',
        outfunds__Application_Date__c=Date.today().addDays(-90),
        outfunds__Awarded_Amount__c=75000)
};
insert grants;
```

---

## Freshness Checklist

Before seeding, verify:
- [ ] All volunteer shifts are at least 5 days in the future
- [ ] Current-year gifts use current calendar year close dates
- [ ] Volunteer applications are 2–7 days old (not today, not last month)
- [ ] Program enrollment started 30–60 days ago (established, not brand new)
- [ ] No record names contain "Test", "User 1", or generic placeholders
- [ ] All demo email addresses use the `@demo.` domain convention
- [ ] Cleanup script targets `@demo.` emails (never touches real data)
