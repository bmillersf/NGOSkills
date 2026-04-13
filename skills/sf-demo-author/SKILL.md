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
  version: "1.0.0"
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

## Workflow (4-Phase Pattern)

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
```

Define at minimum:
- The **presenter persona** (the person driving the demo in Salesforce)
- Any **secondary personas** whose data or records appear (volunteers, donors, clients)
- The **beneficiary** (the child, client, or cause that gives the story its "why")

Personas feed directly into the demoscript's `users` frontmatter and the data that `sf-nonprofit-demo-data` will seed.

---

### Phase 4: Click Path + Demoscript Generation

Translate the story and use case into numbered demo steps following the [demoscript format spec](references/click-path-guide.md).

**Click path rules** (see [references/click-path-guide.md](references/click-path-guide.md)):
1. Every action must be **verbatim** -- "Click the App Launcher (grid icon, top left), type 'Volunteer Hub', click the result" not "open the app"
2. Every expected outcome must describe **exactly what the user sees** -- specific field values, record names, list counts
3. Use `<!-- type: -->` tags on every step to enable precise validation
4. Add `<!-- visual: true -->` to the 3–4 most visually compelling steps (the wow moments)
5. Include explicit `**Check**` SOQL or Apex on any data or automation step
6. Talking points must reference **business value**, not UI description

**Step density**: Aim for 6–12 steps. Too few loses the story; too many loses the audience.

---

## Output Format

Emit the complete `demoscript.md` using the format spec from [assets/demoscript-template.md](assets/demoscript-template.md), followed by:

1. **Persona cards** (formatted as a separate `## Personas` section after the teardown)
2. **Data requirements** (formatted as a `## Data Seed Requirements` section listing what `sf-nonprofit-demo-data` needs to generate)
3. **Story summary** (1 paragraph the presenter reads as the opening)
4. **Presenter cheat sheet** (a 1-page summary: personas at a glance, step titles in order, 3 key talking points)

---

## Quality Checks Before Output

Run mentally through:
- [ ] Can a presenter who wasn't in the discovery call follow this click path without asking questions?
- [ ] Does every step tie back to the story arc?
- [ ] Are all persona names used consistently (never "the user")?
- [ ] Does the wow moment have `<!-- visual: true -->` and a strong `**Talking Points**` block?
- [ ] Would `sf-demo-validate` be able to validate every step as written?
- [ ] Are all data prerequisites specific enough for `sf-nonprofit-demo-data` to seed?

If any check fails, fix before emitting.
