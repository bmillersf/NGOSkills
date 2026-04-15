---
name: sf-demo-author
description: >
  Demo script authoring from raw notes. Transforms discovery notes,
  meeting transcripts, or bullet-point requirements into a fully structured
  demoscript.md with narrative story arc, persona profiles, and a verbatim
  click-by-click path ready for sf-demo-validate.
  TRIGGER when: user provides notes, a meeting transcript, or requirements
  and asks to generate a demo script, demo story, demo narrative, click path,
  or demoscript.md. Also triggers when user says "write a demo from these notes",
  "create a demo script", or "author the demo".
  DO NOT TRIGGER when: validating an existing demoscript (use sf-demo-validate),
  seeding demo data (use sf-nonprofit-demo-data), generating Playwright tests
  (use sf-demo-playwright), or writing Apex/LWC code (use sf-apex, sf-lwc).
license: MIT
metadata:
  version: "2.0.0"
  author: "Brian Miller"
  scoring: "150 points across 6 categories"
---

# sf-demo-author: Demo Script Authoring from Raw Notes

Expert demo narrative architect. Transforms raw discovery notes, meeting transcripts, and requirements into a production-ready `demoscript.md` with a compelling story arc, fully fleshed personas, and a verbatim click-by-click path that `sf-demo-validate` can run against and a presenter can follow without guesswork.

## Core Responsibilities

1. **Notes Intake**: Parse raw notes, transcripts, bullet lists, or free-form requirements
2. **Story Architecture**: Build a narrative arc -- problem, journey, resolution -- that resonates with the audience
3. **Persona Creation**: Define named, realistic personas with roles, motivations, and what they care about
4. **Click Path Generation**: Produce verbatim, step-by-step UI actions (which app, tab, button, field, value)
5. **Prerequisite Derivation**: Infer and list all metadata, data, permissions, and config the demo depends on
6. **Demoscript Output**: Emit a fully-formed `demoscript.md` compatible with `sf-demo-validate`
7. **Talking Points**: Embed presenter talking points tied to the business narrative at each step

---

## Scoring Rubric (150 points)

| Category | Points | What's Evaluated |
|---|---|---|
| Story clarity | 25 | Problem → journey → resolution arc is coherent and compelling |
| Persona realism | 25 | Named personas with specific roles, motivations, and relevant context |
| Click path precision | 35 | Every action is verbatim -- specific app, tab, button, field, and value |
| Prerequisite completeness | 25 | All objects, data, permissions, and config inferred and listed |
| Validate-readiness | 25 | Output passes sf-demo-validate's format spec without modification |
| Talking point quality | 15 | Talking points are tied to business value, not UI description |

**Thresholds**: ✅ 120+ (Ship it) | ⚠️ 90–119 (Review before use) | ❌ <90 (Rework required)

---

## Document Map

| Need | Document | Description |
|---|---|---|
| **Story framework** | [references/story-framework.md](references/story-framework.md) | Narrative arc patterns, emotional hooks, nonprofit-specific story structures |
| **Persona templates** | [references/persona-templates.md](references/persona-templates.md) | Nonprofit role archetypes: donor, volunteer, program staff, fundraiser, admin |
| **Click path guide** | [references/click-path-guide.md](references/click-path-guide.md) | Rules for writing verbatim, unambiguous click paths |
| **Output template** | [assets/demoscript-template.md](assets/demoscript-template.md) | Blank demoscript.md to populate |

---

## Workflow (6-Phase Pattern)

### Phase 0: Org Connect + Baseline

Before authoring anything, connect to the target Salesforce org and scan what already exists.

**Step 1 — Verify org connection**:
```bash
sf org display --target-org <alias> --json
```
If no alias was provided, ask: *"Which org should I connect to? I need to see what's already there before writing the demo script."*

**Step 2 — Run baseline scan** (all commands in parallel):
```bash
sf org list metadata-types --target-org <alias> --json
sf package installed list --target-org <alias> --json
sf sobject list --sobject-type all --target-org <alias> --json
sf data query --query "SELECT Id, Name, UrlPathPrefix, Status FROM Site WHERE Status = 'Active'" --target-org <alias> --json
```

**Step 3 — Record the baseline** in your working context:
- Installed packages (NPC, NPSP, V4S, OFM, PMM, etc.)
- Existing custom objects and fields
- Active Experience Cloud sites
- Whether Person Accounts are enabled
- Whether Agentforce, Data Cloud, or OmniStudio are provisioned

This baseline feeds every downstream phase — you must have it before making any recommendations.

---

### Phase 0.5: Product Recommendation Plan

After notes intake (Phase 1) and before story architecture (Phase 2), present a **product recommendation** for user approval.

**Switch to plan mode** and present a structured recommendation:

```
## Recommended Products for This Demo

### Already enabled in the org
- [x] Nonprofit Cloud (NPC) — Person Accounts, Gift Transaction detected
- [x] Experience Cloud — active site "BTH_Portal" found

### Recommended based on discovery notes (user must approve)
- [ ] Agentforce — audience mentioned AI; setup effort: ~2 hours
- [ ] Data Cloud — donor 360 view requested; setup effort: ~4 hours

### Not recommended for this demo
- OmniStudio — no guided form requirement in notes
- Marketing Cloud — no email journey requirement
```

**Wait for the user to approve or reject each product.** Only generate demoscript steps, metadata, or configuration for approved products.

---

### Phase 1: Notes Intake and Classification

Read all provided notes and extract:

**Audience signals**:
- Who is in the room? (C-suite, IT, program staff, fundraisers, volunteers)
- What does the audience care about most? (efficiency, impact, donor experience, volunteer management)
- What pain points were mentioned?

**Platform signals**:
- Which Salesforce products are involved? (NPC, NPSP, Agentforce, Data Cloud, Experience Cloud, OmniStudio)
- Org type? (scratch, sandbox, production)
- Any specific features, apps, or objects mentioned?

**Use case signals**:
- What is the core process being demonstrated? (volunteer intake, gift entry, program enrollment, grant management)
- What is the "wow moment" -- the thing that should make the audience lean forward?
- What outcome proves success?

**Output of Phase 1**: A structured intake summary listing audience, platform, use case, wow moment, and gaps. If gaps exist, ask the user to fill them before proceeding.

---

### Phase 2: Story Architecture

Build the narrative arc following the framework from [references/story-framework.md](references/story-framework.md).

**Structure**:
```
SITUATION  → The world before the demo (the problem or status quo)
CHALLENGE  → What happens that demands a response
JOURNEY    → The process the persona goes through using Salesforce
RESOLUTION → The outcome -- what changed, what's possible now
```

**Nonprofit-specific story hooks**:
- Connect the technology to mission impact ("every minute saved on admin is a minute spent with kids")
- Show the person behind the data (a volunteer named James, not "User 1")
- Make the before/after tangible (3-day manual process vs. 10 minutes)

Write a 2–3 sentence story summary that the presenter can say as an opening before step 1. This goes in the demoscript frontmatter as `story_summary`.

---

### Phase 3: Persona Definition

Create **named, specific personas** for every role in the demo. Each persona should feel like a real person, not a job title.

**Persona card format**:
```
Name: Maria Santos
Role: Volunteer Coordinator, By The Hand Club
Age: 34
Motivation: Wants to match the right volunteers with the right kids fast
Pain: Currently emails spreadsheets back and forth; misses shift gaps until the day before
Salesforce user: volunteer-coordinator (alias: maria)
Email: maria@demo.org
Timezone: America/Chicago
Permission sets: BTH_Volunteer_Coordinator
```

Define at minimum:
- The **presenter persona** (the person driving the demo in Salesforce)
- Any **secondary personas** whose data or records appear (volunteers, donors, clients)
- The **beneficiary** (the child, client, or cause that gives the story its "why")

Personas feed directly into the demoscript's `users[]` frontmatter **and** the data that `sf-nonprofit-demo-data` will seed. Every persona with a Salesforce user alias MUST appear in both the `users[]` YAML array and in a persona card.

---

### Phase 4: Click Path + Demoscript Generation

Translate the story and use case into numbered demo steps following the [demoscript format spec](references/click-path-guide.md).

**Click path rules** (see [references/click-path-guide.md](references/click-path-guide.md)):
1. Every action must be **verbatim** -- "Click the App Launcher (grid icon, top left), type 'Volunteer Hub', click the result" not "open the app"
2. Every expected outcome must describe **exactly what the user sees** -- specific field values, record names, list counts. Never write "shows the page" or "the record appears" -- name the actual field and value.
3. Use `<!-- type: -->` tags on every step to enable precise validation
4. Add `<!-- visual: true -->` to the 3–4 most visually compelling steps (the wow moments) — **always** pair with `<!-- visual_path: /lightning/... -->` on the line immediately after
5. Include explicit `**Check**` SOQL block on every `type: data` and `type: automation` step
6. Talking points must reference **business value**, not UI description

**Step density**: Aim for 6–12 steps. Too few loses the story; too many loses the audience.

---

## Output Format

Emit the complete `demoscript.md` using the format spec from [assets/demoscript-template.md](assets/demoscript-template.md), followed by:

1. **Persona cards** (formatted as a separate `## Personas` section after the teardown)
2. **Data requirements** (formatted as a `## Data Seed Requirements` section listing what `sf-nonprofit-demo-data` needs to generate — use this structured format):
   ```
   ## Data Seed Requirements
   Platform: NPC | NPSP

   ### Person Accounts / Contacts
   - James Okafor | Email: james.okafor@demo.volunteer | Role: Volunteer applicant
   - Maria Santos  | Email: maria@demo.org             | Role: Coordinator (User alias: maria)

   ### ApplicationForms
   - James Okafor: Status=Submitted, CreatedDate=TODAY-2, Description=tutoring background

   ### JobPositionShifts
   - 3 shifts, StartDate=TODAY+7 through TODAY+21, RemainingCapacity=5, Location=Community Kitchen

   ### Users (configure existing or create)
   - alias: maria | TimeZoneSidKey: America/Chicago | ContactId: → Maria Santos Person Account
   - alias: jamie | TimeZoneSidKey: America/Chicago | ContactId: → James Okafor Person Account
   ```
3. **Story summary** (1 paragraph the presenter reads as the opening)
4. **Presenter cheat sheet** (a 1-page summary: personas at a glance, step titles in order, 3 key talking points)

### Teardown Section (required)

Always generate a `## Teardown` section with Anonymous Apex that deletes all seeded records in reverse dependency order, targeting only `@demo.` email domains. Also include cleanup for `[E2E_TEST]`-prefixed records created by `sf-demo-validate` during validation runs:

```apex
// Demo teardown — targets only @demo. domains
List<String> demoEmails = new List<String>{ '[all persona emails]' };
delete [SELECT Id FROM Task WHERE Subject LIKE '%[E2E_TEST]%'];
delete [SELECT Id FROM JobPositionAssignment WHERE Volunteer__r.PersonEmail IN :demoEmails];
delete [SELECT Id FROM Applicant__c WHERE ApplicationForm__r.Account.PersonEmail IN :demoEmails];
delete [SELECT Id FROM Applicant__c WHERE Email__c = 'e2e.test@example.com'];
delete [SELECT Id FROM ApplicationForm WHERE Account.PersonEmail IN :demoEmails];
delete [SELECT Id FROM ApplicationForm WHERE Name LIKE '%[E2E_TEST]%'];
delete [SELECT Id FROM Account WHERE IsPersonAccount = true AND PersonEmail IN :demoEmails];
System.debug('Teardown complete');
```

### NPC Platform Prerequisites (required for NPC demos)

Always include in the `## Prerequisites` section for NPC orgs:
- Person Accounts enabled
- `ApplicationForm` record type with DeveloperName `NPC_Programs` is active
- `Volunteer_Review` queue exists
- `Description__c` field exists on `ApplicationForm`
- Provisioner script `scripts/apex/provision-demo-member.apex` exists in local project

---

## Quality Checks Before Output

Run through every item — this is the Phase 1.5 checklist that `sf-demo-validate` will score the output against:

- [ ] Can a presenter who wasn't in the discovery call follow this click path without asking questions?
- [ ] Does every step tie back to the story arc?
- [ ] Are all persona names used consistently (never "the user")?
- [ ] Does the wow moment have `<!-- visual: true -->` AND `<!-- visual_path: /lightning/... -->` AND a strong `**Talking Points**` block?
- [ ] Does every `**Expected**` block name a specific field value or record — not "shows the page"?
- [ ] Does every `type: data` step have a `**Check**` SOQL block?
- [ ] Does the YAML frontmatter include `users[]` with every persona alias?
- [ ] Does the `## Prerequisites` section cover NPC platform requirements (Person Accounts, RT, queue, custom fields)?
- [ ] Does the `## Teardown` section exist and target only `@demo.` email domains?
- [ ] Does the `## Data Seed Requirements` section have enough detail for `sf-nonprofit-demo-data` to generate all records without asking questions?
- [ ] Are all User aliases in steps present in `users[]` frontmatter?

If any check fails, fix before emitting.
