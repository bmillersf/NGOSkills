# Demo Story Framework

## The Core Arc

Every compelling demo follows a 4-beat structure:

```
SITUATION → CHALLENGE → JOURNEY → RESOLUTION
```

| Beat | Purpose | Duration in Demo |
|---|---|---|
| **Situation** | Establish the world before -- the status quo, the persona, what's at stake | Opening 30 seconds (verbal, before step 1) |
| **Challenge** | The specific problem or event that kicks off the demo | Step 1–2 |
| **Journey** | The process through Salesforce -- each step shows capability | Steps 3–N |
| **Resolution** | The outcome -- what changed, what's possible, what the persona feels | Final step + closing verbal |

---

## Nonprofit-Specific Story Patterns

### Pattern 1: The Volunteer Story
**Use for**: Volunteer management, Experience Cloud portals, intake workflows

```
SITUATION: [Org] is growing its volunteer program but coordinators are drowning in emails and spreadsheets.
CHALLENGE: A new volunteer [Name] applies online -- but without a system, it falls through the cracks.
JOURNEY: [Name]'s application flows into Salesforce automatically. The coordinator reviews, approves, assigns a shift.
RESOLUTION: [Name] shows up day one, matched to the right role. The coordinator handled 10 applications that morning.
```

### Pattern 2: The Donor Journey
**Use for**: Fundraising, gift entry, donor portals, recurring giving

```
SITUATION: [Org]'s major gift officer spends hours pulling together donor history before every call.
CHALLENGE: A longtime donor [Name] calls unexpectedly -- the officer needs the full picture in 30 seconds.
JOURNEY: One search. Complete giving history, last contact, soft credits, open pledge -- all on one screen.
RESOLUTION: The call goes well. [Name] upgrades their gift. The relationship deepened because the data was there.
```

### Pattern 3: The Program Enrollment Story
**Use for**: Program management, case management, client intake

```
SITUATION: Kids are waiting weeks to get enrolled in programs because intake is manual and fragmented.
CHALLENGE: A new family [Name] walks in. Three different staff members would normally need to coordinate.
JOURNEY: One intake form captures everything. Automatic eligibility check. Enrollment triggered. Staff notified.
RESOLUTION: The family is enrolled same day. Staff spent 10 minutes, not 3 days.
```

### Pattern 4: The Grant Story
**Use for**: Grant management, reporting, compliance

```
SITUATION: Grant reports are due at the end of the quarter. The development team is manually pulling data from 4 systems.
CHALLENGE: The program officer needs outcomes data that lives in a completely different system.
JOURNEY: All program data flows into Salesforce. The report builds itself from live data.
RESOLUTION: 3-hour report generation becomes 15 minutes. Accuracy improves. Funder relationship strengthens.
```

### Pattern 5: The Impact Story (Agentforce)
**Use for**: Agentforce, AI features, automation

```
SITUATION: [Org] receives 200+ inquiries a month. Staff spend hours answering the same questions.
CHALLENGE: After hours, a prospective volunteer asks about upcoming shifts. There's no one to answer.
JOURNEY: The Agentforce agent responds instantly -- personalized, accurate, available 24/7.
RESOLUTION: Staff focus on high-value conversations. Volunteers get answers when they need them.
```

---

## Emotional Hooks for Nonprofit Audiences

These phrases connect technology to mission. Weave them into talking points:

- "Every minute saved on admin is a minute spent with kids"
- "The data tells us who needs help before they have to ask"
- "We're not automating relationships -- we're protecting them"
- "The coordinator went home on time for the first time this month"
- "This donor has given for 10 years. She deserved to be recognized by name"
- "That child got the right program because the right data was in the right place"

---

## Opening and Closing Lines

**Opening** (say before step 1):
> "Let me introduce you to [Persona]. [She/He/They] work at [Org] as a [role]. [One sentence on what they care about and what's hard today]. Let's walk through what a [typical day / critical moment] looks like with Salesforce."

**Closing** (say after final step):
> "[Persona] just [accomplished outcome] in [time]. Before Salesforce, that took [old time/process]. [One sentence on mission impact]. That's what this looks like in practice."

---

## Wow Moment Criteria

The wow moment is the step where the audience leans forward. It should be:
- **Unexpected**: something they didn't know Salesforce could do
- **Visual**: shows something on screen that's hard to argue with
- **Mission-connected**: directly ties back to the nonprofit's purpose
- **Concrete**: a specific number, name, or outcome -- not a general capability

Mark it with `<!-- visual: true -->` and give it the strongest `**Talking Points**` block in the script.

---

## Story Arc by Demo Duration

The 4-beat arc is the same shape at every duration, but the relative weight of each beat changes. Compress the arc to fit the slot — never stretch a 5-minute story to 30 minutes by repeating the same beat.

| Tier | Minutes | Beats to keep | Opening verbal | Closing verbal | Persona depth |
|---|---|---|---|---|---|
| Lightning | 5 | Challenge -> Resolution only (skip Situation setup) | 1 sentence ("Meet Maria. She has 30 seconds to find James's application.") | 1 sentence ("That used to take a week.") | 1 driver only |
| Short *(default)* | 15 | All 4 beats, condensed (Situation in 1 line) | 2-3 sentences | 1-2 sentences | 1-2 personas, name the driver + the beneficiary |
| Standard | 30 | Full 4-beat arc with breathing room | 3-4 sentences | 2-3 sentences | 2-3 personas, full persona cards introduced verbally |
| Extended | 45 | Full arc + an admin/setup view ("here's how this got configured in 5 minutes") | 3-4 sentences + persona intro | 2-3 sentences + roadmap teaser | 2-4 personas, optional handoff between two |
| Workshop | 60 | Full arc + multi-persona handoffs + Q&A pause cues every ~3 steps | 4 sentences + persona intro + agenda | 3 sentences + call to action + next-steps slide | 3-4 personas, explicit handoffs between roles |

### Rules for using this table

1. **Always keep Resolution.** No matter how short the slot, the audience needs to see the payoff. If you only have time for one beat, make it the Resolution.
2. **Skip Situation before you skip Challenge.** Setup is the most expendable beat; the inciting moment is what makes the demo a story instead of a feature tour.
3. **The opening and closing verbals are part of the runtime.** Budget them inside `demo_duration_minutes` — don't treat them as free.
4. **Don't add personas to fill time.** A 60-min demo with one persona is fine if the journey earns it. A 5-min demo with 3 personas will fail.
5. **Match the wow-moment count to the tier.** Lightning gets 1 wow moment. Workshop gets 3-4. The Phase 4 click path table in `click-path-guide.md` is the source of truth for visual-step counts.
