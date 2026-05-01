# Skill-Authoring Subagent Brief Template

Every Phase 1–3 subagent that authors new SKILL.md files receives this brief. Copy the template, fill the placeholders, and pass it as the subagent's prompt.

---

## Template

> **Goal:** Author the following N SKILL.md files in `/Users/brianmiller/Cursor/Skills/NGOSkills/skills/<skill-name>/SKILL.md` (one per skill), following the authoring conventions in [`skills-cursor/sf-skill-maintenance/SKILL.md`](../skills-cursor/sf-skill-maintenance/SKILL.md) exactly.
>
> **Skills to author:**
>
> - `<skill-name-1>` — <one-line purpose>
> - `<skill-name-2>` — <one-line purpose>
> - `<skill-name-3>` — <one-line purpose>
>
> **References (read before authoring):**
>
> 1. [`skills/sf-datacloud/SKILL.md`](../skills/sf-datacloud/SKILL.md) — house style reference for an orchestrator skill
> 2. [`skills/sf-datacloud-connect/SKILL.md`](../skills/sf-datacloud-connect/SKILL.md) — house style for a phase/sub-skill
> 3. [`references/industry-precheck.md`](./industry-precheck.md) — mandatory Phase 0 block for every generic cloud skill
> 4. [`skills-cursor/sf-skill-maintenance/SKILL.md`](../skills-cursor/sf-skill-maintenance/SKILL.md) — frontmatter contract + required sections
>
> **Required frontmatter fields (non-negotiable):**
>
> ```yaml
> name: <skill-name>
> description: >
>   <one-sentence>
>   TRIGGER when: <at least 3 scenarios, comma-separated; include example user phrases in quotes>
>   DO NOT TRIGGER when: <enumerate every related/overlapping skill by name; no "etc.">
> license: MIT
> compatibility: "<license/edition/plugin prereqs>"
> metadata:
>   version: "1.0.0"
>   author: "NGOSkills"
> release_pinned: "Spring '26"
> docs_last_verified: 2026-05-01
> upstream_refs:
>   - url: <authoritative help.salesforce.com or developer.salesforce.com URL>
>     anchor: ""
>     sha256: ""
>     importance: authoritative
>   - url: <second authoritative URL>
>     anchor: ""
>     sha256: ""
>     importance: authoritative
> upstream_release_notes:
>   - release: "Spring '26"
>     url: <release-notes URL for this domain>
> ```
>
> **Required sections (in order):**
>
> 1. When this skill owns the task (with delegation table)
> 2. **Phase 0: Industry pre-check** — link to `references/industry-precheck.md` and restate the deferral rule. (Skip ONLY for industry-specific skills; mark skipped with justification.)
> 3. Required context to gather first
> 4. Workflow phases (numbered)
> 5. Scoring rubric (100–165 pts; match neighbour scale)
> 6. Anti-patterns (min 5)
> 7. Common failure modes + remediation (3–5)
> 8. CLI / metadata cheat sheet (if applicable)
>
> **Constraints:**
>
> - Every generic cloud skill MUST include the industry pre-check as Phase 0. No exceptions.
> - `DO NOT TRIGGER when:` clauses must enumerate EVERY overlapping skill by exact name. No "etc.", no "related skills."
> - `upstream_refs` MUST be 2–5 authoritative URLs from `help.salesforce.com`, `developer.salesforce.com`, or `architect.salesforce.com`. No blogs, no Trailhead modules older than 1 year.
> - `release_pinned: "Spring '26"` and `docs_last_verified: 2026-05-01` on every skill.
> - Do NOT author README or CLAUDE.md edits — the parent will handle those as an atomic batch after merging all skills in this phase.
> - Do NOT modify existing skills in `skills/` — additive only.
> - Do NOT push anything. Commit locally if you work in a worktree; otherwise stage and return diff.
>
> **Return format:**
>
> 1. List of absolute paths to new SKILL.md files
> 2. Summary of which skills triggered the industry pre-check requirement
> 3. Any concerns about trigger-phrase overlap with existing skills (run audit-triggers.sh mentally — flag collisions)
> 4. Any authoritative doc URLs you could not verify via WebFetch (mark `docs_last_verified` anyway if urls are canonical Salesforce domains)
>
> **Done criteria:**
>
> - All N SKILL.md files exist at their canonical paths
> - Each parses as valid YAML frontmatter
> - Each passes the "required sections" checklist
> - `./scripts/refresh-skills.sh <skill-1> <skill-2> ... --offline` exits 0 (frontmatter valid)
> - `./scripts/audit-triggers.sh` overlap count did not increase beyond acceptable known-benign overlaps

---

## Severity gates for reviewers

When reviewing subagent output:

- Missing `Phase 0: Industry pre-check` in a generic skill → **reject**, send back for rewrite
- `DO NOT TRIGGER when:` contains "etc." or omits a sibling skill → **reject**
- `upstream_refs` empty or pointing at a blog → **reject**
- Scoring rubric scale mismatch (e.g., 50pt on a core platform skill) → **reject**
- Anti-patterns fewer than 5 → request expansion but OK to merge if substance is strong

Trivial fixes (wording, minor category renaming) can be merged with a follow-up edit commit.
