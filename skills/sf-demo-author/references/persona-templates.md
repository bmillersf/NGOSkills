# Nonprofit Persona Templates

Use these archetypes as starting points. Always replace generic details with specifics from the discovery notes -- real org names, realistic names for the region/community, and pain points that were actually mentioned.

---

## Volunteer Coordinator

```
Name: Maria Santos
Role: Volunteer Coordinator
Org: [Org Name]
What they care about: Getting the right volunteers matched to the right kids/clients quickly
Daily pain: Email chains, spreadsheets, shift gaps discovered the day before
Salesforce user alias: maria
Profile: Custom "Volunteer Coordinator" or "Standard User"
Permission sets: BTH_Volunteer_Coordinator (or equivalent)
Demo actions: Reviews applications, approves volunteers, assigns shifts, monitors capacity
```

## Volunteer (Applicant / Community Member)

```
Name: James Okafor
Role: Prospective Volunteer
Org: External (community member)
What they care about: Finding a meaningful way to give back; easy sign-up process
Daily pain: Confusing application processes, not hearing back, showing up unprepared
Salesforce user alias: james (Experience Cloud guest or member)
Demo actions: Submits intake form, receives confirmation, views assigned shift
```

## Major Gift Officer

```
Name: Rachel Chen
Role: Major Gift Officer / Frontline Fundraiser
Org: [Org Name]
What they care about: Deepening relationships with top donors; having the full picture before every call
Daily pain: Pulling donor history from multiple places; missed soft credits; no visibility into program impact
Salesforce user alias: rachel
Profile: Custom "Fundraiser" or "Standard User"
Permission sets: Fundraising access, GAU visibility
Demo actions: Pulls donor 360 view, logs contact, reviews giving history, upgrades pledge
```

## Donor

```
Name: Eleanor Whitfield
Role: Major Donor (10-year relationship)
Org: External
What they care about: Knowing her gifts make a difference; being recognized as a partner not just a checkbook
Giving profile: Annual gift $25,000+, soft credits on family foundation gifts, open pledge
Demo actions: (data only -- appears in gift history, contact record, relationship view)
```

## Program Manager

```
Name: David Williams
Role: Program Manager / Program Director
Org: [Org Name]
What they care about: Enrollment numbers, outcomes tracking, capacity planning
Daily pain: Manually counting enrollments; waiting on data from 3 other staff; reporting to funders
Salesforce user alias: david
Profile: Custom "Program Staff" or "Standard User"
Permission sets: Program management access
Demo actions: Reviews enrollments, views outcomes, generates funder report
```

## Client / Program Participant

```
Name: Aisha Johnson (or family: The Johnson Family)
Role: Program Participant / Client
Org: External (community member)
What they care about: Getting the right services quickly; not having to repeat their story to every staff member
Demo actions: (data only -- appears in intake, enrollment record, program assignment)
```

## Development Director / VP of Fundraising

```
Name: Sarah Kim
Role: VP of Development / Development Director
Org: [Org Name]
What they care about: Campaign performance, board reporting, year-over-year trends
Daily pain: Report generation takes days; data lives in disconnected systems
Salesforce user alias: sarah
Profile: Custom "Development Leader" or "Standard User"
Permission sets: Reports and dashboards, full campaign visibility
Demo actions: Views campaign dashboard, drills into donor segments, reviews pipeline
```

## Grants Manager

```
Name: Michael Torres
Role: Grants Manager
Org: [Org Name]
What they care about: Compliance, on-time reporting, funder relationships
Daily pain: Tracking multiple grant deadlines across a spreadsheet; pulling outcomes data manually
Salesforce user alias: michael
Profile: Custom "Grants Staff" or "Standard User"
Permission sets: Grants access
Demo actions: Views grant pipeline, tracks disbursements, generates compliance report
```

## System Administrator / Salesforce Admin

```
Name: Jennifer Park
Role: Salesforce Administrator
Org: [Org Name]
What they care about: System reliability, user adoption, keeping up with releases
Daily pain: Configuration requests pile up; users can't find what they need
Salesforce user alias: jennifer (typically System Administrator)
Demo actions: (usually background persona -- rarely drives the demo story)
```

---

## Naming Guidelines

- Use **realistic, culturally diverse names** that reflect the communities nonprofits typically serve
- **Never use generic names** like "Demo User", "Test Contact", or "User 1"
- Names should feel like **real people**, not placeholders
- For children or youth beneficiaries, use first names only (no last names) out of sensitivity

## Persona Consistency Rules

1. Once a name is assigned to a role, use it **everywhere** -- demoscript steps, talking points, data seed requirements, Playwright test names
2. The **presenter persona** (who drives the Salesforce UI) should be the most relatable to the audience in the room
3. Secondary personas (volunteers, donors, clients) should be **referred to by name** in talking points, not "the volunteer" or "the record"
