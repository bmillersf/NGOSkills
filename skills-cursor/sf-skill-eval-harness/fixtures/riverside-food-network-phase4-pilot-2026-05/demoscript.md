---
demo_title: "Riverside Food Network — NPSP Modernization"
demo_duration_minutes: 30
demo_duration_tier: standard
target_step_runtime_seconds: 130
audience:
  - name: Carla Rivera
    role: Operations Director
    attendance: stakeholder + co-presenter persona
  - name: Devon Park
    role: Volunteer & Partner Manager
    attendance: stakeholder + co-presenter persona
  - name: Janet Whitfield
    role: Board Chair
    attendance: skeptical decision-maker (audience only — NOT in users[])
platform: NPSP
out_of_scope:
  - Nonprofit Cloud (NPC) migration — org is on NPSP and is not switching
  - Tableau / advanced analytics — explicitly shelved by customer
  - Donor receipt automation — flagged lower priority and aspirational
  - Setup screens and admin views — Janet's anti-demo
  - New license or product purchase
users:
  - alias: criv
    name: Carla Rivera
    role: Operations Director
    profile: System Administrator
    email: carla.rivera@demo.riverside
  - alias: dpark
    name: Devon Park
    role: Volunteer & Partner Manager
    profile: Standard User
    email: devon.park@demo.riverside
  - alias: mcast
    name: Maria Castillo
    role: Pantry Coordinator (Centro Latino de Hillsboro)
    profile: Customer Community Plus User
    email: maria.castillo@demo.partner
  - alias: jmend
    name: Jordan Mendez
    role: Volunteer
    profile: Customer Community User
    email: jordan.mendez@demo.volunteer
story_summary: >
  Riverside Food Network distributes 2.4M pounds of food a year through 38 partner agencies
  across 3 Oregon counties. Three jobs eat staff time today: Carla rebuilds her Monday
  distribution plan in Excel (90 minutes a week), Devon retypes partner-agency emails into
  a Google Sheet (he calls himself a transcription robot), and 15-20% of volunteers no-show,
  consuming Devon's Tuesdays. In 30 minutes, on the NPSP they already pay for, this demo
  retires all three — with an Experience Cloud partner portal that routes a Monday-9am
  request to Carla's Tuesday dashboard with no human in the loop, a volunteer self-service
  portal that auto-creates a follow-up Case when someone no-shows, and an NPSP dashboard
  that replaces the Excel rebuild with a one-screen Monday-morning view.
---

# Riverside Food Network — NPSP Modernization Demo

## Opening (read aloud, ~2 minutes)

> "Good morning, Janet, Carla, Devon. Riverside Food Network has been running NPSP for years, and the platform isn't the problem — three workflows that should run on it don't, and that costs you staff time every single week. Carla rebuilds Monday's distribution plan in Excel — 90 minutes, every Monday. Devon retypes partner-agency emails into a Google Sheet — he calls himself a transcription robot. And 15-20% of volunteers no-show, eating Devon's Tuesdays. The next 30 minutes are all about replacing those three jobs with NPSP doing what NPSP can already do — no Tableau, no migration, no new licenses. The only thing changing is the time you get back."

---

## Prerequisites

Before running this demo, the org must have:

- NPSP managed package installed (current version)
- Person Accounts disabled (NPSP standard — Account + Contact + npe01__SYSTEMIsIndividual__c)
- Two Experience Cloud licenses provisioned (Customer Community Plus for partner agencies, Customer Community for volunteers)
- Active Experience Cloud site at `/partners` (Customer Community Plus) and `/volunteers` (Customer Community)
- Custom Case Record Types: `Partner_Request`, `Volunteer_NoShow`
- Custom Account fields: `Monthly_Allotment_Lb__c`, `Allotment_Produce_Lb__c`, `Allotment_Protein_Lb__c`, `Allotment_Dry_Goods_Lb__c`, `Allotment_Infant_Formula_Lb__c`
- Custom Case fields on Partner_Request RT: `Requested_Date__c`, `Requested_Produce_Lb__c`, `Requested_Protein_Lb__c`, `Requested_Infant_Formula_Lb__c`, `Total_Requested_Lb__c`, `Truck_Route__c`, `Warehouse_Pull_List__c`
- Custom object `Volunteer_Shift_Assignment__c` with fields: `Volunteer__c` (Lookup → Contact), `Shift_Date__c`, `Shift_Start_Time__c`, `Shift_End_Time__c`, `Shift_Location__c`, `Status__c` (Picklist: Confirmed / Cancelled / No-Show)
- Custom Contact fields: `Volunteer_Status__c`, `Quarterly_NoShow_Count__c`
- Auto-creation Flow: when `Volunteer_Shift_Assignment__c.Status__c` becomes `No-Show`, create a Case (RT: Volunteer_NoShow) owned by Devon Park with the Volunteer follow-up template loaded
- Routing Flow: when a `Partner_Request` Case is created via Portal, assign `Truck_Route__c` and `Warehouse_Pull_List__c` based on `Account.BillingCity` and requested categories
- NPSP Dashboard `Distribution_Plan_Weekly` with tiles: Partner Requests, Truck Routes, Warehouse Pull List, Pounds Pledged by Category, Unfilled Volunteer Slots, Route Map
- NPSP Report `Protein_Shortage_This_Week`
- Email-based personas seeded with `@demo.` domain emails so teardown runs cleanly

---

## Step 1 — Set the three pains (narrative, 90 sec)

<!-- type: narrative -->
<!-- pov: narrative -->

**Action.** Stay on the title slide or NPSP Home. Don't navigate yet. Read the opening paragraph above out loud.

**Talking Points.**
- Three pains. One platform. Zero new licenses. *Time saved* is the only metric that matters here.
- Specifically call out: "90 minutes every Monday for Carla, 5-10 day partner lead time for Devon, 15-20% volunteer no-show rate. We're going to make all three smaller in the next 30 minutes."
- Plant Janet's audit standard: "This whole demo holds itself to one test — does it give staff their time back?"

**Expected.** Audience is leaning in. Janet has heard the staff-time-saved framing twice already. Maria, Devon, Carla, and Jordan are named on screen.

---

## Step 2 — Maria signs in to the partner portal (end_user, 90 sec)

<!-- type: ui -->
<!-- pov: end_user -->
<!-- visual: true -->
<!-- visual_path: /s/partner-home -->

**Action.** Open `https://riverside.my.site.com/partners/s/partner-home` as user `mcast` (Maria Castillo, Centro Latino de Hillsboro). Land on the Partner Home page.

**Expected.** Header reads "Welcome, Maria Castillo." Allotment card displays "4,200 lb available this month." Category breakdown tiles render: Produce 1,200 lb / Protein 800 lb / Dry Goods 1,500 lb / Infant Formula 700 lb. Primary CTA "Request Distribution" is visible.

**Check.**
```sql
SELECT Id, Name, Monthly_Allotment_Lb__c, Allotment_Protein_Lb__c
FROM Account
WHERE Name = 'Centro Latino de Hillsboro' AND Type = 'Partner Agency'
```

**Talking Points.**
- "Today, Maria would be drafting an email to Devon. She isn't."
- The allotment view is hers — partner-scoped sharing means she only sees Centro Latino's data, not other agencies'.
- "This page replaces the email Devon would have transcribed."

---

## Step 3 — Maria submits her food request (end_user, 120 sec)

<!-- type: ui -->
<!-- pov: end_user -->
<!-- visual: true -->
<!-- visual_path: /s/partner-home/request -->

**Action.** Click **Request Distribution**. The guided form opens. Type 400 into Produce, 200 into Protein, 300 into Infant Formula. Select **Wednesday this week**. Click **Submit**.

**Expected.** Toast appears: "Request submitted — reference PR-00184." A row lands in "My Requests": PR-00184 / 900 lb / Wednesday / Status: Submitted. Time-stamp on the new row reads exactly **Monday 09:00 AM** — write the time on the whiteboard, you'll come back to it.

**Check.**
```sql
SELECT CaseNumber, Origin, Status, Total_Requested_Lb__c, CreatedDate
FROM Case
WHERE CaseNumber = 'PR-00184' AND Origin = 'Portal'
```

**Talking Points.**
- "**Watch the time stamp** — it's 9am Monday. Hold that thought."
- "The moment Maria clicked Submit, that request became a Case in NPSP. Devon did not get an email. Devon did not retype anything. **This is where the transcription robot dies.**"
- For Janet: "That round-trip used to take 5 to 10 days. We just did it in 90 seconds. That's a *Devon time saved* moment, and we're 4 minutes into the demo."

---

## Step 4 — Devon's queue: the request landed itself (end_user, 90 sec)

<!-- type: ui -->
<!-- pov: end_user -->

**Action.** Switch to user `dpark` (Devon Park). Navigate to `https://riverside.lightning.force.com/lightning/o/Case/list?filterName=Inbound_Partner_Requests`.

**Expected.** List view "Inbound Partner Requests" shows PR-00184 at the top. Origin column reads "Portal" (not "Email", not "Phone"). Account column reads "Centro Latino de Hillsboro." Created Date reads Monday 09:00 AM. Devon's queue counter incremented. **He has not opened the case.**

**Check.**
```sql
SELECT CaseNumber, Account.Name, Origin, CreatedDate
FROM Case
WHERE Origin = 'Portal' AND CreatedDate = TODAY
ORDER BY CreatedDate DESC
```

**Talking Points.**
- "Devon's first contact with this request is **looking at it on a list view**. He didn't transcribe. He didn't email himself. **He didn't retype.** That is what 'I want to stop being a transcription robot' looks like in NPSP."
- "On any other Monday morning, this same request would still be sitting in his inbox until Wednesday."

---

## Step 5 — Tuesday morning: Carla's dashboard already has the route (end_user, 150 sec — THE WOW)

<!-- type: ui -->
<!-- pov: end_user -->
<!-- visual: true -->
<!-- visual_path: /lightning/r/Dashboard/Distribution_Plan_Weekly/view -->

**Action.** Switch to user `criv` (Carla). Tell the audience "**Now it is Tuesday morning.**" Pause for 2 beats. Open `https://riverside.lightning.force.com/lightning/r/Dashboard/Distribution_Plan_Weekly/view`.

**Expected.** Dashboard title: "Distribution Plan — This Week." The "Partner Requests" tile shows count **7**. The "Truck Routes" tile lists Route 3 — Hillsboro/Forest Grove with **PR-00184 — Centro Latino — 900 lb** bound to it. The "Warehouse Pull List" tile shows Wednesday's pull list including PR-00184's line items (produce 400, protein 200, infant formula 300). Last refreshed timestamp reads Tuesday morning.

**Check.**
```sql
SELECT CaseNumber, Truck_Route__c, Warehouse_Pull_List__c
FROM Case
WHERE CaseNumber = 'PR-00184'
```

**Talking Points.**
- *(Pause, let the screen land before talking.)*
- "Maria submitted yesterday at 9am. **No human transcribed anything between then and now.** And here's her request — already on Carla's dashboard, mapped to Truck Route 3, on Wednesday's pull list."
- Janet test: "Devon's transcription work is gone. Lead time is no longer 5-10 days — it's *next morning*. **That's hours back in Devon's week. Every week.**"
- "And we're still on the NPSP you already pay for. No Tableau, no migration."

---

## Step 6 — Same portal, Jordan's view (end_user, 90 sec)

<!-- type: ui -->
<!-- pov: end_user -->

**Action.** Tell the audience: "Same portal, different user. This is the volunteer side of the same Experience Cloud site." Switch to user `jmend` (Jordan Mendez). Navigate to `https://riverside.my.site.com/volunteers/s/volunteer-home`.

**Expected.** Header reads "Welcome, Jordan Mendez." Three upcoming shifts render as cards: Saturday 9am Mobile Distribution / Tuesday 2pm Warehouse Sort / Thursday 5pm Bethany Pantry. Each card has inline **Reschedule** and **Cancel** buttons.

**Check.**
```sql
SELECT Name, Shift_Date__c, Shift_Location__c, Status__c
FROM Volunteer_Shift_Assignment__c
WHERE Volunteer__r.Email = 'jordan.mendez@demo.volunteer' AND Status__c = 'Confirmed'
ORDER BY Shift_Date__c
```

**Talking Points.**
- "Today, Jordan would be emailing Devon to swap her Saturday shift. **She isn't.**"
- "Three places the data lives today: a Google Form spreadsheet, a printed sign-in sheet, and Devon's head. Today, it lives in NPSP, once."

---

## Step 7 — Jordan reschedules herself (end_user, 90 sec)

<!-- type: ui -->
<!-- pov: end_user -->

**Action.** As Jordan, click **Reschedule** on the Saturday card. Select "Saturday next week 9:00 AM." Click **Confirm**.

**Expected.** Toast: "Shift rescheduled — confirmation sent." My Shifts list updates inline — Saturday next week replaces Saturday this week. The originating slot returns to the open shifts band so someone else can grab it.

**Check.**
```sql
SELECT Name, Shift_Date__c, Status__c
FROM Volunteer_Shift_Assignment__c
WHERE Volunteer__r.Email = 'jordan.mendez@demo.volunteer'
  AND Shift_Location__c = 'Mobile Distribution — Cornelius'
ORDER BY Shift_Date__c DESC
```

**Talking Points.**
- "**Watch what Jordan does NOT do** — she doesn't email Devon. She doesn't text the volunteer coordinator. She doesn't touch a clipboard."
- "And the slot she vacated? It just reopened to other volunteers in the portal. No one had to manually backfill it."

---

## Step 8 — Devon's queue auto-fills with a no-show Case (end_user, 90 sec — WOW)

<!-- type: ui -->
<!-- pov: end_user -->
<!-- visual: true -->
<!-- visual_path: /lightning/o/Case/list?filterName=Volunteer_NoShows -->

**Action.** Switch back to user `dpark` (Devon). Tell the audience: "Same Devon, different day — it's Tuesday morning, and last Thursday a different volunteer no-showed at Bethany Pantry." Navigate to `https://riverside.lightning.force.com/lightning/o/Case/list?filterName=Volunteer_NoShows`.

**Expected.** List view "Volunteer No-Shows" shows one new row. Subject: "No-show: Marcus Halloran — Thursday 5pm Bethany." Origin: "Auto-Created." Status: "New." Owner: "Devon Park."

**Check.**
```sql
SELECT Subject, Origin, Status, Owner.Name
FROM Case
WHERE RecordType.DeveloperName = 'Volunteer_NoShow'
  AND Subject LIKE '%Marcus Halloran%'
```

**Talking Points.**
- "On any other Tuesday, Devon is right now hunting a printed sign-in sheet. **This Tuesday, the case is already in his queue.** The system noticed the shift end-time passed without a check-in and created the Case itself."
- "That's the 15-20% no-show rate translated into 'Devon's Tuesdays back.'"

---

## Step 9 — Devon opens the no-show Case (end_user, 120 sec)

<!-- type: ui -->
<!-- pov: end_user -->

**Action.** Click the "No-show: Marcus Halloran" row. The Case detail page opens.

**Expected.** Case detail shows:
- Subject: "No-show: Marcus Halloran — Thursday 5pm Bethany"
- Related Contact: Marcus Halloran (Volunteer)
- Related Shift: Thursday 5pm Bethany Pantry Mobile Distribution
- Volunteer history component: "Third no-show this quarter"
- Email tab pre-loaded with the "Volunteer Follow-up" template, **Send** button visible

**Check.**
```sql
SELECT Id, Subject, ContactId, Volunteer_Shift__c, Description
FROM Case
WHERE Subject = 'No-show: Marcus Halloran — Thursday 5pm Bethany'
```

**Talking Points.**
- "Three-hour Tuesday → four-click triage. Devon picks the right next step *(send the template, escalate to a coordinator, or remove the volunteer from the active roster)* and moves on."
- "**That is the 90 minutes — sorry, the *3 hours* — Devon got back this Tuesday.** Every Tuesday."
- For Janet: "Same NPSP. No new license. No new product. The only thing that changed is staff time saved — for Devon, every week."

---

## Step 10 — Carla's Monday dashboard, cold open (end_user, 90 sec — WOW)

<!-- type: ui -->
<!-- pov: end_user -->
<!-- visual: true -->
<!-- visual_path: /lightning/r/Dashboard/Distribution_Plan_Weekly/view -->

**Action.** Switch to user `criv` (Carla). Tell the audience: "It's now Monday. Carla just walked in. She has not opened Excel." Open the dashboard cold — `https://riverside.lightning.force.com/lightning/r/Dashboard/Distribution_Plan_Weekly/view`.

**Expected.** Dashboard title: "Distribution Plan — This Week." **Protein tile rendered red** — "600 lb short of Thursday demand." Produce / Dry Goods / Infant Formula tiles green. Open Partner Requests counter: 7. Unfilled Volunteer Slots counter: 4. Route map tile renders 5 active routes.

**Check.**
```sql
SELECT DeveloperName, Title FROM Dashboard
WHERE DeveloperName = 'Distribution_Plan_Weekly'
```

**Talking Points.**
- *(Don't narrate. Let the red tile land.)*
- "**That red tile told Carla in three seconds what used to take her 90 minutes to find.** She's 600 pounds short on protein for Thursday."
- "No Tableau. No new license. **NPSP Reports + Dashboards. The platform you already pay for.**"
- For Janet: "Carla's 90 minutes every Monday is now 30 seconds. **That's 78 hours of Carla's time back per year.** That is the staff time saved you came to see."

---

## Step 11 — Drill into volunteer slots and route map (end_user, 90 sec)

<!-- type: ui -->
<!-- pov: end_user -->

**Action.** As Carla, click the **Unfilled Volunteer Slots** tile. Then click the **Route Map** tile.

**Expected.** Drill-down shows 4 open shifts including **Saturday 9am Mobile Distribution — Cornelius** (the slot Jordan vacated in step 7). Route map drill-down lists Route 3 — Hillsboro/Forest Grove — Wed — **Centro Latino de Hillsboro (PR-00184)** — bound from step 5. Both drill-downs render in the same view, no page refresh.

**Check.**
```sql
SELECT Name, Shift_Date__c, Status__c
FROM Volunteer_Shift_Assignment__c
WHERE Status__c = 'Cancelled' AND Shift_Date__c = THIS_WEEK
```

**Talking Points.**
- "All three streams on one screen — partner requests, volunteer slots, routes. Carla used to need three browser tabs and an Excel file to see this."
- "Notice Saturday's mobile-distribution slot is on the open list. **Jordan vacated it in step 7.** The dashboard already knows."

---

## Step 12 — Carla closes the protein gap inline (end_user, 110 sec)

<!-- type: ui -->
<!-- pov: end_user -->

**Action.** As Carla, click the red **Protein 600 lb short** tile. The drill-down opens partner requests still expecting protein. Click **Bethany Hills Family Pantry**. In the inline edit, change `Requested_Date__c` to "Next Wednesday." Click **Save**.

**Expected.** Drill-down "Partner Requests — Protein" shows 4 requests. Bethany Hills Family Pantry record opens inline with the Requested_Date field editable. After save: Protein tile re-renders to **350 lb short of Thursday demand** in amber, not red. Toast: "Bethany Hills request rescheduled to next Wednesday." Dashboard timestamp updates.

**Check.**
```sql
SELECT CaseNumber, Account.Name, Requested_Protein_Lb__c, Requested_Date__c
FROM Case
WHERE Account.Name = 'Bethany Hills Family Pantry'
ORDER BY LastModifiedDate DESC
LIMIT 1
```

**Talking Points.**
- "**Total time on the dashboard: under 4 minutes.** Compare with last Monday's 90-minute Excel rebuild."
- "Carla still solves the same problem — making sure Thursday's distribution has enough protein — but she does it in the platform, in real time, with everyone else's data automatically reflected."
- Closing for Janet: "*Three pains, retired, on the NPSP you already own.* Carla — 90 minutes every Monday, gone. Devon — transcription work and Tuesday no-show hunts, gone. **Total staff time saved: a conservative 6 hours a week, or roughly a quarter of an FTE you can redirect to mission work.**"

---

## Closing (read aloud, ~90 sec)

> "Three pains. One platform. Zero new licenses. Carla, you walk in Monday and the dashboard you'd have built in Excel is already there — including a 600-pound protein shortage you'd have spent 90 minutes discovering. Devon, the partner request transcription cycle is gone, and your Tuesday no-show outreach went from a three-hour spreadsheet hunt to a four-click triage with the email template pre-loaded. Janet — *to your standard*: every minute we showed today maps to a specific job that used to consume a specific staff person. The conservative arithmetic is six hours of staff time back per week, on the platform you've been paying for the whole time. **No new license. No migration. No Tableau. Just NPSP doing what NPSP can do.** Questions?"

---

## Data Seed Requirements

Platform: NPSP

### Account (Organization)
- Centro Latino de Hillsboro | Hillsboro, OR | Monthly_Allotment_Lb__c=4200 | (Maria's partner agency)
- Bethany Hills Family Pantry | Beaverton, OR | Monthly_Allotment_Lb__c=3600 | Allotment_Protein_Lb__c=700
- Mercado de la Familia — North Portland | Portland, OR | Monthly_Allotment_Lb__c=2800
- Forest Grove United Methodist Pantry | Forest Grove, OR | Monthly_Allotment_Lb__c=2100

### Contact
- Maria Castillo | maria.castillo@demo.partner | Title=Pantry Coordinator | AccountId=Centro Latino de Hillsboro
- Jordan Mendez | jordan.mendez@demo.volunteer | Volunteer_Status__c=Active
- Marcus Halloran | marcus.halloran@demo.volunteer | Volunteer_Status__c=Active | Quarterly_NoShow_Count__c=3

### User
- alias: criv | Carla Rivera | carla.rivera@demo.riverside | System Administrator | TZ America/Los_Angeles
- alias: dpark | Devon Park | devon.park@demo.riverside | Standard User | TZ America/Los_Angeles
- alias: mcast | Maria Castillo | maria.castillo@demo.partner.riverside | Customer Community Plus User | ContactId=Maria Castillo
- alias: jmend | Jordan Mendez | jordan.mendez@demo.volunteer.riverside | Customer Community User | ContactId=Jordan Mendez

### Case (RecordType: Partner_Request)
- PR-00184 | Origin=Portal | Status=Submitted | Account=Centro Latino de Hillsboro | Total_Requested_Lb__c=900 | Truck_Route__c=Route 3 — Hillsboro/Forest Grove | Warehouse_Pull_List__c=Wed Pull List | CreatedDate=Monday 09:00
  Empty fields: (none — fully populated at seed because Tuesday-morning view in step 5 shows the routed values; routing fields populated by Flow during step-3 submission)
- PR-00179 | Origin=Portal | Status=Submitted | Account=Bethany Hills Family Pantry | Requested_Protein_Lb__c=250 | Requested_Date__c=Thursday this week
  Empty fields: (none — step 12 demonstrates Carla *editing* Requested_Date__c, not filling it from blank)

### Case (RecordType: Volunteer_NoShow)
- Subject "No-show: Marcus Halloran — Thursday 5pm Bethany" | Origin=Auto-Created | Status=New | ContactId=Marcus Halloran | Volunteer_Shift__c=shift-marcus-thursday | OwnerId=Devon Park
  Empty fields: (none — Case is fully populated at seed; step 9 shows Devon *reading* the populated Case, not filling it in live)

### Volunteer_Shift_Assignment__c
- Jordan Mendez — Saturday 9am Mobile Distribution | Shift_Location__c=Mobile Distribution — Cornelius | Status__c=Confirmed
- Jordan Mendez — Tuesday 2pm Warehouse Sort | Status__c=Confirmed
- Jordan Mendez — Thursday 5pm Bethany Pantry | Status__c=Confirmed
- Marcus Halloran — Thursday 5pm Bethany Pantry (last week) | Status__c=No-Show

### Dashboard / Report
- Dashboard `Distribution_Plan_Weekly` | Folder: Operations Dashboards | Running User: Carla Rivera | Tiles per click-path step 5 / 10 / 11
- Report `Protein_Shortage_This_Week` | ReportType: Cases with Account

---

## Personas

### Carla Rivera — Operations Director
- **Age:** 47
- **Motivation:** Walks in Monday morning. Wants one screen, no Excel rebuild.
- **Pain quote:** "I want to walk in Monday morning, look at one screen, and know if I'm short on protein for Thursday."
- **Salesforce alias:** criv | **TZ:** America/Los_Angeles | **Profile:** System Administrator

### Devon Park — Volunteer & Partner Manager
- **Age:** 35
- **Motivation:** Stop being a transcription robot. Get Tuesdays back from no-show outreach.
- **Pain quote:** "I want to stop being a transcription robot."
- **Salesforce alias:** dpark | **TZ:** America/Los_Angeles | **Profile:** Standard User

### Maria Castillo — Pantry Coordinator, Centro Latino de Hillsboro
- **Age:** 41
- **Motivation:** Get her food allotment filled without a 5-day email chain.
- **Salesforce alias:** mcast | **TZ:** America/Los_Angeles | **Profile:** Customer Community Plus User
- **Drives the wow moment:** her 9am Monday submission lands on Carla's Tuesday dashboard, mapped to a route, with no human transcription.

### Jordan Mendez — Volunteer
- **Age:** 28
- **Motivation:** Reschedule a shift without emailing the volunteer coordinator on a Saturday morning.
- **Salesforce alias:** jmend | **TZ:** America/Los_Angeles | **Profile:** Customer Community User

### Janet Whitfield — Board Chair (audience only, NOT in users[])
- **Age:** 62
- **Concern:** "We already have software that doesn't get used."
- **Audit standard:** every demo step must tie to a specific staff person's time saved. Feature breadth is not interesting.

---

## Presenter Cheat Sheet

**Target: 30 min — 12 steps × ~130 sec + 3.5 min opening / closing buffer = 1,800 seconds total**

| Step | Title | POV | Time budget (sec) | Wow? |
|---|---|---|---|---|
| 1 | Opening — set three pains | narrative | 90 | — |
| 2 | Maria signs in to partner portal | end_user | 90 | — |
| 3 | Maria submits her food request | end_user | 120 | watch_this for REQ-001 |
| 4 | Devon's queue: request landed itself | end_user | 90 | — |
| 5 | Tuesday: Carla dashboard already routed | end_user | 150 | **WOW — REQ-001 moment** |
| 6 | Same portal, Jordan's view | end_user | 90 | — |
| 7 | Jordan reschedules herself | end_user | 90 | watch_this for REQ-002 |
| 8 | Devon queue auto-fills no-show Case | end_user | 90 | **WOW — REQ-002 moment** |
| 9 | Devon opens no-show Case | end_user | 120 | narration for REQ-002 |
| 10 | Carla Monday dashboard, cold open | end_user | 90 | **WOW — REQ-003 moment** |
| 11 | Drill volunteer slots + route map | end_user | 90 | narration for REQ-003 |
| 12 | Carla closes protein gap inline | end_user | 110 | resolution |
| Total | | | **1,320 sec (22 min)** | |
| Opening + Closing | | | **210 sec (3.5 min)** | |
| Q&A buffer | | | **270 sec (4.5 min)** | |
| **Grand total** | | | **1,800 sec (30 min)** | |

**Three key talking points to memorize:**
1. "Maria submitted at 9am Monday. By Tuesday morning her request was on Carla's dashboard, routed. **No human transcribed anything in between.**" *(REQ-001 wow)*
2. "**3-hour Tuesday spreadsheet hunt → 4-click triage.** That's Devon's Tuesdays back, every week." *(REQ-002 wow)*
3. "**90 minutes every Monday → 30 seconds.** 78 hours of Carla's time back per year. On the NPSP you already pay for." *(REQ-003 wow)*

**Persona quick reference:**
- Carla = criv (System Admin) | Devon = dpark (Standard) | Maria = mcast (Customer Community Plus) | Jordan = jmend (Customer Community)
- Janet is in the room as the skeptic — she does NOT have a Salesforce account.

---

## Teardown

Run as System Administrator. Targets only `@demo.` email domains and `[E2E_TEST]`-prefixed records.

```apex
// Riverside Food Network demo teardown — targets only @demo. domains and [E2E_TEST] records
List<String> demoEmails = new List<String>{
    'maria.castillo@demo.partner',
    'jordan.mendez@demo.volunteer',
    'marcus.halloran@demo.volunteer',
    'carla.rivera@demo.riverside',
    'devon.park@demo.riverside'
};

// Clean up [E2E_TEST]-prefixed records that sf-demo-validate may have created
delete [SELECT Id FROM Task WHERE Subject LIKE '%[E2E_TEST]%'];
delete [SELECT Id FROM Case  WHERE Subject LIKE '%[E2E_TEST]%'];

// Reverse-dependency teardown of the demo records
delete [SELECT Id FROM Case
        WHERE RecordType.DeveloperName = 'Volunteer_NoShow'
          AND Contact.Email IN :demoEmails];
delete [SELECT Id FROM Case
        WHERE RecordType.DeveloperName = 'Partner_Request'
          AND Account.Name IN ('Centro Latino de Hillsboro',
                               'Bethany Hills Family Pantry',
                               'Mercado de la Familia — North Portland',
                               'Forest Grove United Methodist Pantry')];
delete [SELECT Id FROM Volunteer_Shift_Assignment__c
        WHERE Volunteer__r.Email IN :demoEmails];
delete [SELECT Id FROM User
        WHERE Email IN :demoEmails AND IsActive = true];
delete [SELECT Id FROM Contact
        WHERE Email IN :demoEmails];
delete [SELECT Id FROM Account
        WHERE Name IN ('Centro Latino de Hillsboro',
                       'Bethany Hills Family Pantry',
                       'Mercado de la Familia — North Portland',
                       'Forest Grove United Methodist Pantry')];

System.debug('Riverside Food Network demo teardown complete — @demo. domains cleaned');
```
