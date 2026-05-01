---
name: sf-skill-learning
description: >-
  Continuous, local-only self-learning contract for sf-* skills. Defines when
  the agent is allowed to edit a SKILL.md after using it (anti-patterns,
  failure modes, cheat sheets only), what must never be auto-edited
  (methodology, routing, metadata), redaction rules, and the learn(...) commit
  convention. Read before authoring or reviewing any auto-generated learning.
  TRIGGER when: user asks how skill self-learning works, how to review
  captured learnings, how to push local learnings to the repo, or when the
  agent is about to record a learning from a completed skill invocation.
  DO NOT TRIGGER when: authoring a brand-new skill (use sf-skill-maintenance),
  running the weekly upstream-refs auto-refresh (use refresh-skills.sh), or
  making a methodology change (human-authored, not auto-learning).
license: MIT
compatibility: "Local-only. No push. Writes to the canonical SKILL.md in ~/Cursor/Skills/NGOSkills/skills/<name>/."
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "N/A"
docs_last_verified: 2026-05-01
upstream_refs: []
upstream_release_notes: []
---

# sf-skill-learning — Continuous Local Self-Learning

Defines how the agent auto-improves sf-* skills from real usage. The full contract lives in [`~/.claude/CLAUDE.md`](../../.cursor/rules/agent-autonomy.mdc) under **Section 4. Continuous Skill Learning** — this meta-skill is the discoverable reference.

## The one-sentence rule

After using an sf-* skill, if a generalizable, redacted, non-methodology lesson emerged, the agent edits the SKILL.md's safe sections (≤3 bullets), commits locally with a `learn(...)` prefix, and never pushes.

## Decision flow

```
used a skill → was there a generalizable lesson?
  ├── NO           → do nothing
  └── YES
       ↓
    is it client-specific (org names, customer data, specific IDs)?
       ├── YES  → stays in conversation memory, do not touch SKILL.md
       └── NO
            ↓
         does it already exist in the skill? (grep first)
            ├── YES  → merge/consolidate with existing bullet (not duplicate)
            └── NO
                 ↓
              which section? (allowed list below)
                 ├── Anti-patterns / Failure modes / Cheat sheet  → edit + commit
                 └── Anything else                                 → refuse; surface to user
```

## Allowed sections (auto-editable)

| Section | OK to edit | Rationale |
|---|---|---|
| Anti-patterns | yes | Cumulative institutional memory — real mistakes beat theoretical ones |
| Common failure modes + remediation | yes | Captures symptom → root cause → fix from live incidents |
| Cheat sheet (CLI commands, object names, error messages) | yes | Factual additions, easily verified |

## Never auto-editable

- YAML frontmatter (every field)
- Scoring rubric
- Workflow phases (numbered)
- Required context / Industry pre-check sections
- Delegation tables
- TRIGGER when: / DO NOT TRIGGER when: clauses

Those are human-authored judgment calls. Auto-editing them would slowly drift the routing and methodology contract.

## Redaction — mandatory before the edit lands

**Strip from every learning:**
- Org usernames, My Domain names, sandbox URLs
- Customer / company names
- Salesforce record IDs (15 or 18 char)
- Specific emails, phone numbers
- Industry namespaces that tie to one tenant (e.g., `FSC__MyClient*`, `npsp__AcmeCorp*`)
- Numeric values that look like customer KPIs

**Keep:**
- Standard object API names (Account, Contact, Case, Opportunity, Gift_Transaction__c, etc.)
- Framework / pattern choices (TriggerHandler, OmniScript element types, RecordEditForm)
- Scoring-rubric category names (as learning signal, not methodology edits)
- Error messages with IDs scrubbed

## Guardrails

- **≤3 new bullets per skill per session** — prevents a bad session from polluting a skill
- **Merge-over-append** — replace or consolidate a similar bullet instead of duplicating
- **Single-skill scope** — each `learn(...)` commit touches exactly one SKILL.md
- **Never push** — pushing is always user-initiated

## Branch safety net

Before committing, the agent runs `git branch --show-current`:

| Branch | Action |
|---|---|
| `main` | Commit directly |
| Feature branch (not scratch-like) | Commit to feature branch — learning merges when branch merges |
| `learn/*`, `wip/*`, `scratch/*`, `throwaway/*` | Stash to `~/.claude/skills-learnings-pending/<skill>-<YYYYMMDD-HHMMSS>.md`, flush on next `main` invocation |
| Working tree dirty on the target SKILL.md | Stash to pending; tell user *"learning captured to pending/, commit your in-flight edits and I'll flush on next use"* |

Pending files are plain markdown with the proposed diff so the user can review or manually apply if they want.

## Commit convention

```
learn(<skill-name>): <one-line summary>
```

Examples:

```
learn(sf-apex): add governor-limit anti-pattern for bulk Account triggers
learn(sf-industry-fsc): note household merge requires ACR cleanup first
learn(sf-datacloud-segment): capture audience refresh lag after DMO schema change
learn(sf-demo-validate): Omni-Channel capacity check fails silently on inactive queues
```

The `learn(` prefix is load-bearing for:
- `git log --grep="^learn("` — full learning history
- `git log --grep="^learn(" --since="1 week ago"` — weekly summary
- Bulk-squash before pushing: `git rebase -i` + mark all `learn(...)` commits as `squash`

## Your review flow

```bash
cd ~/Cursor/Skills/NGOSkills

# See all pending learnings (since last push)
git log --grep="^learn(" origin/main..HEAD --oneline

# Review a specific learning
git show <commit-sha>

# Review everything since yesterday
git log --grep="^learn(" --since="yesterday" --stat

# Revert a bad auto-learning
git revert <commit-sha>

# Push when ready
git push    # or run: scripts/push-learnings.sh for a guided flow
```

## Relationship to other systems

- **Auto-refresh cron** (Sunday 03:00, Layer 2 weekly): touches only `refresh-report.md` + frontmatter `sha256` fields. **No overlap** with learning system's allowed sections.
- **Release-cut handoff** (event-driven, Layer 4): produces a review list of skills touched by a new Salesforce release. After a major release, learnings captured against the old release may become outdated — review + prune before upgrading `release_pinned`.
- **Memory system** (`~/.claude/projects/.../memory/`): project-scoped, for user preferences and project context. Learning system is **skill-scoped** — the lesson follows the skill across every project you use it in.

## Anti-patterns for this meta-skill

- **Auto-editing methodology sections** because "the user said so" — if they want a methodology change, they author it explicitly; the agent does not auto-draft rubric edits
- **Committing a learning before checking for duplicates** — always grep the SKILL.md first
- **Committing without redaction** — a single leaked customer name in a commit message is harder to scrub than never writing it
- **Pushing learnings proactively** — push is always user-initiated
- **Recording trivial lessons** — "I used sf-apex successfully" is not a learning; noise degrades the skill
- **Multi-skill commits** — one `learn(...)` commit per SKILL.md; mixing makes review and revert harder

## Scoring rubric

Not applicable — this is a meta-skill. Its "output" is the conformance of actual auto-learning commits to the rules above. Review via the commit log and `git diff` at your own cadence.
