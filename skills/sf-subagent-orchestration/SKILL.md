---
name: sf-subagent-orchestration
description: >
  Subagent delegation policy for long-running Salesforce work. Defines when to
  spawn parallel or sequential subagents to keep the parent agent's context
  fresh and prevent context-window exhaustion during multi-phase Salesforce
  builds. TRIGGER when: a Salesforce task spans multiple phases (discovery +
  build + deploy), involves heavy file/web exploration before implementation,
  requires building several independent units (multiple LWCs, multiple Apex
  classes, multiple flows) that can be implemented in parallel, or includes
  long-running deployment / verification loops. Other sf-* skills reference
  this skill from their phase descriptions to standardize delegation. DO NOT
  TRIGGER when: the user asks a single narrow question, the task fits in one
  short turn, or no other sf-* skill is active.
license: MIT
metadata:
  version: "1.0.0"
  author: "Brian Miller"
  companion_skills:
    - sf-demo-orchestrate
    - sf-nonprofit-experience-cloud-build
    - sf-nonprofit-experience-cloud
    - sf-apex
    - sf-lwc
    - sf-deploy
---

# sf-subagent-orchestration: Subagent Delegation Policy

Long Salesforce builds (Experience Cloud sites, end-to-end demo pipelines, multi-component features) regularly exceed the parent agent's working context. Subagents are the answer: each gets a fresh context window, returns a compact summary, and frees the parent to keep coordinating.

This skill defines **when** to delegate, **which subagent type** to use, and **what contract** to pass — so delegation is consistent across every `sf-*` skill in this repo.

## Lifecycle map: where subagents fit

Almost every multi-phase Salesforce skill in this repo follows roughly the same arc. Map each phase to the right execution mode:

| Phase | Mode | Why |
|-------|------|-----|
| **Discovery** (read website, scan org metadata, list components, gather schema) | Subagent — `explore` | Read-heavy; returns a digest, not raw bytes |
| **Planning / decisions** | Parent | Trade-offs need full context |
| **Independent implementation** (multiple LWCs, classes, flows that don't depend on each other) | Subagents — `generalPurpose` in parallel | One unit per agent; coordinator integrates |
| **Sequential implementation** (one component depends on another's output) | Parent | Dependency means context must persist |
| **Deployment + long CLI loops** (deploy, watch, publish, verify) | Subagent — `shell` | Verbose output never enters parent |
| **Final integration / wire-up** | Parent | Needs the whole picture |
| **Verification / acceptance loop** | Subagent — `shell` | Repetitive curl + sf data query checks |

**Default rule of thumb:** if the work is *generative + parallelizable* or *exploration-heavy + summary-returnable*, delegate. If it's *coordination + decisions*, keep it in the parent.

## When to delegate (decision checklist)

Before doing any non-trivial unit of work in the parent, ask:

```
Delegation Check:
- [ ] Will this read more than ~3 large files / pages of output?
- [ ] Are there 3+ independent units I could build in parallel?
- [ ] Will the output of this step be a multi-minute log I don't need verbatim?
- [ ] Is this exploration where only the conclusion matters?
- [ ] Could the parent's context fill up before the user's goal is done?
```

Two or more "yes" → delegate.

## Subagent type selection

Cursor's `Task` tool supports several subagent types. Pick by phase:

| Subagent type | Use for | Notes |
|---------------|---------|-------|
| `explore` | Brand-mining external sites, surveying org metadata, listing components, schema inspection, finding existing patterns | Readonly — safe default for any "go look at X and tell me Y" |
| `generalPurpose` | Building one LWC, one Apex class, one Flow, one demo data set in isolation | Use for parallel units with clear specs |
| `shell` | `sf project deploy start`, `sf community publish`, `sf data query`, `curl` verification loops, anything with verbose CLI output | Keeps deploy logs out of parent context |
| **Parent** (no Task) | Planning, integrating outputs, final approval, decisions | Default when context isn't a concern |

## The standard subagent contract

Every Task subagent invocation should pass a prompt with these four sections so the subagent has everything it needs *and* knows exactly what to return.

```
## Mission
[One paragraph: what to build / discover / verify]

## Context (everything the subagent needs)
- Repo path: <absolute path>
- Reference files: <list>
- Specs / acceptance criteria: <bulleted>
- Branding tokens / API version / org alias: <as applicable>

## Constraints
- Do NOT modify <unrelated areas>
- Use <library / convention> only
- Stay within <directory>

## Return
A single message back to the parent containing:
1. Summary of what was done (3-6 bullets)
2. List of files created / modified (paths only)
3. Any blockers or open questions
4. Suggested next step for the parent
```

This contract is what keeps the parent's context lean — the subagent's working memory is discarded; only the structured return survives.

## Parallel delegation pattern

For N independent units, fire all subagents in **a single tool-call message** so they run concurrently:

```
[single message containing N Task tool calls, each with subagent_type: generalPurpose]
- Build LWC: donorPortalHeader (spec: ...)
- Build LWC: donorHeroBanner (spec: ...)
- Build LWC: givingOpportunitiesGrid (spec: ...)
- Build LWC: bishopQuoteBanner (spec: ...)
- Build LWC: upcomingEvents (spec: ...)
```

Wait for all to return, then the parent integrates.

**Don't fire dependent units in parallel** — if Component B imports from Component A, build A first (parent or sequential subagent), then B.

## Long-running deployments

For `sf project deploy start` and `sf community publish` cycles:

- Delegate to a `shell` subagent with `run_in_background: true` if the parent has other work to do meanwhile
- Otherwise let the subagent block — its long output is captured in the subagent's context, not the parent's
- Subagent returns: success/fail, deploy ID, key error lines (not the full log)

## Anti-patterns to avoid

| Don't | Do instead |
|-------|-----------|
| Delegate decisions to subagents | Keep planning in parent; subagents execute, parent decides |
| Fire one subagent at a time when N could parallel | Single message, N Task calls |
| Pass the whole transcript as context | Pass only the spec + reference paths the subagent will read |
| Let a subagent "explore freely" | Always include explicit acceptance criteria and a Return section |
| Re-read files in the parent that a subagent already digested | Trust the subagent's summary; only re-fetch if integration requires it |
| Use `generalPurpose` for read-only inspection | Use `explore` (readonly is faster + safer) |
| Use a subagent for a 30-second task | Just do it inline; subagent overhead isn't worth it |

## How other skills should reference this skill

Each multi-phase `sf-*` skill should annotate its phases with one line each, e.g.:

```markdown
### Phase 1 — Brand-mine the reference website
**Delegation**: spawn an `explore` subagent per sf-subagent-orchestration with mission
"Visit <url>, return palette + fonts + IA + asset URLs as structured summary."

### Phase 3 — Build the LWCs
**Delegation**: fire one `generalPurpose` subagent per LWC in a single message,
following the parallel delegation pattern in sf-subagent-orchestration.

### Phase 4 — Deploy and publish
**Delegation**: `shell` subagent per sf-subagent-orchestration to run the
deploy + publish + verify loop and return a status summary.
```

This keeps the policy in one place and each domain skill stays focused on its own subject matter.

## Example: full Experience Cloud build, fully orchestrated

For a typical "build me a donor portal modeled after orgwebsite.org" request, the parent's tool-call timeline looks like:

```
T0  Parent: receive request, read sf-nonprofit-experience-cloud-build SKILL
T1  Subagent (explore):  brand-mine the reference website -> returns palette/fonts/IA/assets
T2  Parent: design system decisions; write theme customCSS + brandingSet
T3  Subagents (generalPurpose ×6, parallel): build 6 homepage LWCs from specs
T4  Subagents (generalPurpose ×2, parallel): build donationForm + donationThankYou
T5  Parent: compose home.json view, write routes + views metadata
T6  Subagent (shell): deploy components -> deploy ExperienceBundle -> publish -> verify with curl
T7  Parent: report results to user
```

Parent context stays focused on architecture, integration, and decisions. Heavy lifting happens in subagents whose contexts are discarded after they return.

## Additional resources

For Experience Cloud-specific phase delegation: see `sf-nonprofit-experience-cloud-build`
For end-to-end demo pipeline orchestration (a different orchestration use case): see `sf-demo-orchestrate`
