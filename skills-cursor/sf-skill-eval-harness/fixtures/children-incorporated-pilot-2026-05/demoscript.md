---
title: Children Incorporated — Sponsorship Lifecycle Demo
org_alias: cool stuff
org_type: nonprofit-cloud
duration_minutes: 30
required_features:
  - Nonprofit Cloud Program Management (Program, ProgramEnrollment)
  - Nonprofit Cloud Recurring Gifts (GiftCommitment, GiftCommitmentSchedule, GiftTransaction)
  - Custom object Site__c
  - Custom object for Child (or repurposed Contact w/ child fields)
required_packages: []
---

# Demoscript — Children Incorporated Sponsorship Lifecycle

## Story arc

Aisha enrolls Daniel in Kenya. Joseph in HQ matches Daniel to Margaret in 90 seconds. Three years later, Margaret cancels (financial hardship); Aisha gets the task same-day in Kenya. Six months later, Daniel ages out — Joseph re-links Margaret to Sarah in two clicks. Margaret's giving never pauses. The system did the dance that used to take three days.

## Personas in the demo

| Name | Role | Logged in via |
|---|---|---|
| Aisha | Site Coordinator, Helping Schools Kenya | Internal Salesforce |
| Joseph | Donor Engagement Specialist, Children Inc HQ | Internal Salesforce |
| Margaret (Sponsor) | Sponsor (depicted as a record, not a logged-in user in this demo) | — |
| Daniel (Child) | Original sponsored child | — |
| Sarah (Child) | Replacement child after Daniel ages out | — |

## Prerequisites

- 1 Site__c record: "Helping Schools Kenya" (Country=Kenya, Coordinator=Aisha, Program Level=Primary)
- 2 Child records (custom object or Contact-as-Child): Daniel (NEW — to be created in step-2), Sarah (pre-existing for transfer story)
- 1 Donor record (Account or Contact): Margaret Hartwell, with email
- 1 Gift Commitment to be created in step 5 (NEW)
- Cancel reason picklist on GiftCommitment includes "Donor Financial Hardship"
- Transfer Sponsorship Quick Action / Flow on GiftCommitment object

---

## Demo Steps

### Step 1 — narrative (intro)
Pov: narrative
"Children Incorporated runs sponsorships across 23 countries. Today we're following one sponsorship from enrollment to transfer — the lifecycle their team asked us to optimize."

### Step 2 — Aisha enrolls Daniel (REQ-001)
Pov: end_user
**Aisha (Kenya)** logs in and clicks the Children app → New Child button.
- Fills: First Name = Daniel, Year = 3, School = Mwanza Primary, Favorite Subject = Math, Hobbies = Drawing, Football
- Selects Site = "Helping Schools Kenya"

### Step 3 — Save → record refreshes (REQ-001 wow moment)
Pov: end_user
The new Daniel record renders with the Site__c related panel populated: country (Kenya), site coordinator (Aisha), program level (Primary). All from one save.
**Presenter cue:** *"Pause on the related Site. Note — this all came from one save."*

### Step 4 — Joseph sees Daniel as available (REQ-002 setup)
Pov: end_user
**Joseph (HQ)** opens the Available Children list view. Daniel appears at the top. He clicks into Daniel's record.

### Step 5 — Joseph creates Margaret's Gift Commitment (REQ-002)
Pov: end_user
On Daniel's record, Joseph clicks "Sponsor This Child" quick action.
- Donor = Margaret Hartwell (lookup)
- Amount = $40
- Frequency = Monthly
- Start Date = today
- Sponsored Child = Daniel (auto-populated)

### Step 6 — Save → three records appear (REQ-002 wow moment)
Pov: end_user
The save returns to a unified view that shows:
1. The Gift Commitment for Margaret → Daniel ($40/month, active)
2. The Gift Commitment Schedule with the next 12 monthly installments
3. The first Gift Transaction (status: scheduled, due 1st of next month)

**Presenter cue:** *"Watch all three records — commitment, schedule, first transaction. One save."*

### Step 7 — narrative (3-year jump)
Pov: narrative
"Three years go by. Margaret has given $1,440 to Daniel's education. Then her job changes. She emails to cancel."

### Step 8 — Joseph cancels Margaret's Commitment (REQ-003)
Pov: end_user
Joseph navigates to Margaret's Gift Commitment → clicks Close → picks Reason = "Donor Financial Hardship" → Save.

### Step 9 — Cut to Aisha's queue (REQ-003 wow moment)
Pov: end_user
Cut to Aisha's view in Salesforce (Tasks list view, Helping Schools Kenya queue). The new task is already there: "Reassign Daniel — Margaret canceled (Donor Financial Hardship)."

**Presenter cue:** *"Cut to Aisha's queue. Two seconds, the task is there."*

### Step 10 — narrative (6-month jump, Daniel ages out)
Pov: narrative
"Six months later, Daniel finishes Year 6 and ages out of the primary program. Margaret has paused giving but called back wanting to sponsor again. Today this would be a 3-day round trip across systems and time zones."

### Step 11 — Joseph initiates the transfer (REQ-004)
Pov: end_user
On Margaret's closed Gift Commitment, Joseph clicks "Transfer Sponsorship" quick action.

### Step 12 — Pick a new child (REQ-004 wow moment)
Pov: end_user
A list of available children at the same site (Helping Schools Kenya) appears, ranked by sponsorship age and need. Sarah (7, Year 1) is at the top.

Joseph picks Sarah → confirms transfer.

### Step 13 — Result: re-linked, history preserved (REQ-004 wow moment continued)
Pov: end_user
The new Gift Commitment is for Margaret → Sarah, $40/month, active. Daniel's record now shows: "Sponsored by Margaret Sept 2024–May 2026 (aged out)". Sarah's record shows the new sponsor + a related "Prior Sponsorship History" section.

**Presenter cue:** *"Two clicks. History on both records. Margaret's giving never pauses."*

### Step 14 — Setup glance (admin POV, deliberate)
Pov: admin
Brief Setup detour: show the GiftCommitment object's Cancel Reason picklist values + the Transfer Sponsorship Flow's high-level diagram (no expanded internals). 30 seconds max.

### Step 15 — narrative (close)
Pov: narrative
"Aisha enrolls in 2 minutes, not 2 days. Joseph matches in 90 seconds, not 20. Cancellations route same-day. Transfers — the #1 ask — are 2 clicks. The lifecycle works."

## Teardown
- Reset Daniel's record to NEW status
- Cancel test Gift Commitment for Margaret → Sarah
- Clear test Tasks from Aisha's queue
