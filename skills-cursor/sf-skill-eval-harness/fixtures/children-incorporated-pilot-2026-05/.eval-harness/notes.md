# Discovery notes — Children Incorporated demo

Tailored demo story mapped to Nonprofit Cloud, Experience Cloud, and Marketing Cloud Account Engagement (MCAE).

## 1. Child & Sponsorship Workflow (Nonprofit Cloud)

Story: Walk through the full lifecycle of a child and sponsorship using Nonprofit Cloud's Program Management and Recurring Gifts.

- Enroll a Child: Create a new child record tied to an affiliated site (use a custom object Site__c). Show site-specific fields (country, site coordinator, program level) on the Site object. Child record should include fields for current school year, favorite subject and hobbies/interests.
- Complete a Sponsorship: Show a donor selecting an available child → creating a Recurring Gift (monthly) → auto-linking to the child record. Emphasize the 1:1 donor-to-child relationship.
- Cancellation: Demonstrate closing a Recurring Gift with a reason code, triggering a task for the program team.
- Substitution/Transfer: Show how a donor is re-linked to a new child when the original child leaves the program — this directly addresses their pain point of easy transfers when a child leaves.

## 2. Automation of Child Correspondence (Nonprofit Cloud + Flow + Experience Cloud)

- Correspondence Tracking Object: Show a custom (or configured) correspondence record linked to each child — tracking letters and photos with a status picklist: In-House → In Process → Ready to Send.
- Automated Coordinator Notifications: Use a Flow to auto-notify site coordinators when a correspondence item is overdue or missing (e.g., letter not received 30 days before due date). Show the notification landing in their Experience Cloud portal.
- Dashboard View: A list view or report showing all items by status across sites — so staff can see at a glance what's in-house, in process, or ready for donors.
- Site Volunteer Portal (Experience Cloud): Show coordinators logging in, seeing letters due, submitting new letters and photos directly. The submitted letters should be approved before they can be shared via Experience Cloud to the Sponsor.
- Sponsor Portal (Experience Cloud): Show a sponsor logging in to see their current sponsorship and the letter that is from their child. The Sponsor portal should also show a history of their recurring gift transactions.

## 3. Donor Notes & Financial Detail (Nonprofit Cloud)

Story: Steve Mitchell specifically called out bequests and audit-readiness.

- Rich Notes on Contact/Donor Record: Show a donor record with detailed Notes or a custom "Donor Development" related list — capturing bequest intentions, capacity ratings, communication preferences, and relationship history.
- Restricted vs. Unrestricted Funds: Demonstrate General Accounting Units (GAUs) in NPSP/Nonprofit Cloud to tag gifts as restricted or unrestricted — directly supporting their audit requirements and monthly close process.
- Financial Rollups: Show soft credit rollups, gift summaries, and how the monthly close totals (per site + child-specific gifts) can be surfaced on a report.
- Sponsorship Support Details: Highlight that paid-through dates and rates are editable, addressing their explicit requirement.

## 4. Content Input & Marketing Access (Experience Cloud + MCAE)

Story: Rachel Luginbuhl (Marketing Director) needs direct access to letters and photos — no more separate downloads.

- Content Upload via Experience Cloud: Show a site coordinator uploading a child's letter and photo through the volunteer portal → content saves directly to the child's Salesforce record as Salesforce Files.
- Rachel's Access: Show Rachel logging into Salesforce (or a staff Experience Cloud page) and accessing the child's Files tab — filtering by content type, date, or site — without needing a manual download/export.
- MCAE Integration: Show how approved photos and content can be tagged and used to populate marketing emails or nurture journeys in MCAE — e.g., a "meet your sponsored child" email to a new donor that pulls in the child's photo and bio automatically.
- Donor-Facing Portal: Show donors logging into the Sponsorship Portal to see the child's letters and progress reports — addressing their stated desire for portal visibility.

## Decisions captured in conversation (2026-05-21)

- Recurring Gift home: NPC native (Gift Commitment → Gift Commitment Schedule → Gift Transaction).
- Site object: `Site__c` (custom).
- Demo scope priority: Section 1 at full depth (must_demo: true). Sections 2-4 are aspirational coverage (must_demo: false).
- Phase 5 fix scope: full autonomy to enable + configure NPC Recurring Gifts in cool stuff if missing.
