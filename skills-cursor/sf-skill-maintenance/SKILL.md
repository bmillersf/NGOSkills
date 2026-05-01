---
name: sf-skill-maintenance
description: >
  Skill authoring conventions and auto-refresh workflow for the NGOSkills repo.
  TRIGGER when: user authors a new skill, edits an existing SKILL.md, updates
  the refresh/audit scripts, responds to a refresh PR, runs a Salesforce release
  handoff, or asks "how do skills stay current?" / "how do I add upstream_refs?"
  / "what are the skill authoring rules?".
  DO NOT TRIGGER when: user is doing Salesforce work in a specific domain
  (route to the matching sf-* skill), or asking about sync-skills.sh symlink
  behaviour only (that lives in the README, not here).
license: MIT
compatibility: "Applies to every sf-* and skills-cursor/* skill in this repo"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs: []
---

# sf-skill-maintenance

The canonical reference for:

1. Authoring a new skill (frontmatter contract, required sections, scoring)
2. Keeping skills current against Salesforce release notes (Layers 1–4 auto-refresh)
3. Responding to a refresh PR (review checklist)
4. Handling a Salesforce release-cut event (release handoff playbook)

Skills that change behaviour (TRIGGER clauses, scoring rubrics, workflow phases) are **human-authored judgment calls** and must never be auto-edited. Skills that reflect Salesforce capability (CLI flags, object names, URLs, feature GA status) **can** be auto-refreshed via Layer 2 PRs because they are factual and reviewable.

---

## 1. Authoring a new skill

### 1.1 Required frontmatter

Every `SKILL.md` MUST have this YAML block at the top. Fields without sample values are required; others are typed.

```yaml
---
name: sf-<domain-or-function>
description: >
  One-sentence summary of what the skill owns.
  TRIGGER when: <comma-separated scenarios that activate this skill>
  DO NOT TRIGGER when: <scenarios that look related but route elsewhere,
  each with the owning skill named in parentheses>
license: MIT
compatibility: "<license/edition/plugin prereqs>"
metadata:
  version: "1.0.0"
  author: "<name>"
release_pinned: "Spring '26"          # Salesforce core release this skill was written against
docs_last_verified: 2026-05-01        # YYYY-MM-DD of last manual verification
upstream_refs:                         # authoritative doc URLs this skill mirrors
  - url: https://help.salesforce.com/s/articleView?id=sf.<topic>.htm
    anchor: ""                         # optional #section anchor
    sha256: ""                         # populated by refresh-skills-auto.sh
    importance: authoritative           # authoritative | supplemental
  - url: https://developer.salesforce.com/docs/atlas.en-us.<guide>/...
    anchor: ""
    sha256: ""
    importance: authoritative
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_<topic>.htm
---
```

Missing `upstream_refs` or `docs_last_verified` is a **hard gate** — `sync-skills.sh --check` will flag it.

### 1.2 Required sections in the body

In this order:

1. **When this skill owns the task** — positive scope, with a delegation table to related skills for every scope boundary.
2. **Phase 0: Industry pre-check** — mandatory for every generic cloud skill (Sales/Service/Marketing/Revenue/Tableau/MuleSoft/Slack/Experience/Reports/Lightning App Builder). Link to [`references/industry-precheck.md`](../../references/industry-precheck.md). Industry-specific, AI, Data Cloud, OmniStudio, and trust/ops skills **skip** this phase.
3. **Required context to gather first** — org edition, license, feature flags, namespaces, prerequisite CLI plugins.
4. **Workflow phases** — numbered, in execution order.
5. **Scoring rubric** — 100–165 points total; 5–10 categories; each category has a pass/fail threshold. Match scale of neighbouring skills (core platform skills: ~150; orchestrators: 130; phase skills: 100–120; stubs: 50).
6. **Anti-patterns** — at minimum 5 bullets covering the most common mistakes.
7. **Common failure modes + remediation** — 3–5 entries with symptom → root cause → fix.
8. **CLI / metadata cheat sheet** — if applicable.

### 1.3 Industry-first precedence rule

**Every generic cloud skill** must run the [industry pre-check](../../references/industry-precheck.md) as Phase 0 before any other work. If an industry package is installed AND the user's request touches industry-owned objects, halt and forward. The generic skill never silently overrides an industry data model.

Industry skills (`sf-industry-*`, `sf-nonprofit-*`, `sf-field-service`, `sf-revenue-cloud` when CPQ/RCA detected) do **not** run the pre-check — they are the pre-check's destination.

### 1.4 Post-authoring checklist

After saving a new `SKILL.md`:

1. `./scripts/sync-skills.sh --fix` — creates per-skill symlinks, flags drift
2. `./scripts/sync-skills.sh --check` — verifies drift = 0
3. `./scripts/audit-triggers.sh` — verifies no unintended trigger-phrase collisions
4. `./scripts/refresh-skills.sh <new-skill-name> --offline` — verifies frontmatter parses
5. Update `README.md` skill-listing section (atomic with the new SKILL.md — not a follow-up commit)
6. Update `CLAUDE.md` Option 1 routing table (keep byte-identical to README skill rows)
7. Commit with message: `skill: add sf-<name> — <one-line purpose> (Spring '26)`

Skipping step 5 or 6 is treated as a bug. The three sources (SKILL.md, README.md, CLAUDE.md) must stay synchronised or the routing breaks.

---

## 2. Auto-refresh: how skills stay current

Four layers, each with a different risk profile.

### Layer 1 — Passive staleness banner (always on)

Every skill's `docs_last_verified` date is compared to today on every invocation. If older than 60 days, the runtime emits a one-line warning:

```
⚠ sf-<skill> verified 72d ago against Spring '26. Run ./scripts/refresh-skills.sh sf-<skill> to rescan.
```

No content changes; just visibility.

### Layer 2 — Scheduled diff scan (opt-in)

Weekly cron (macOS launchd + GitHub Action, both in `scripts/refresh-skills.sh`).

For every skill, for every entry in `upstream_refs`:

1. Fetch the URL via `sf-docs` (which handles JS-heavy Salesforce help pages)
2. Canonicalise: strip nav/footer, collapse whitespace
3. sha256 the canonical content
4. Compare to stored `sha256` in frontmatter
5. If different, record the diff in `refresh-report.md`

`refresh-report.md` is a review-only output. No SKILL.md is modified by Layer 2 directly.

### Layer 3 — Subagent-driven PR generation (opt-in, still human-reviewed)

`refresh-skills-auto.sh` runs after Layer 2 detects drift:

1. For each affected skill, spawn a Claude Code subagent with:
   - Current `SKILL.md`
   - Diff between stored and current upstream content
   - Severity classifier instructions
2. Subagent proposes:
   - **Trivial** (URL repair, new CLI flag, typo in error message) → direct edit
   - **Additive** (new feature GA'd, new command in a family) → direct edit, flag `auto-merge-eligible`
   - **Behavior-change** (API deprecation, default changed, limit reduced) → edit + `requires-human-review`
   - **Methodology** (scoring rubric, workflow phases, anti-patterns) → **refuses to edit**; only bumps `docs_last_verified`
3. Opens a branch `refresh/<skill-name>-YYYYMMDD` and a PR via `gh pr create`
4. **Never auto-merges** by default. `auto-merge-eligible` label is advisory.

Layer 3 auto-merge is a separate opt-in flag (`--auto-merge-trivial`) on the cron job, disabled by default. Enable only after reviewing 4+ weeks of PRs and confirming classifier accuracy.

### Layer 4 — Release-cut handoff (event-driven)

`release-handoff.sh` runs when Salesforce publishes a new release notes TOC (~6 weeks before GA):

1. Fetch the release notes TOC URL
2. Extract every section heading and map it to a domain keyword set
3. Cross-reference against `TRIGGER when:` clauses in every skill
4. Produce a prioritised review list: *"These N skills touch areas with <Release> release notes."*
5. Each flagged skill gets a dedicated refresh subagent run (like Layer 3, but sourced from release notes, not hash drift)

This catches **net-new** objects/features that `upstream_refs` wouldn't point to yet.

---

## 3. Responding to a refresh PR (review checklist)

When you receive an auto-generated `refresh/<skill>-<date>` PR:

1. Read the severity label set by the generator (trivial / additive / behavior-change / methodology-refused)
2. Inspect the diff. Verify:
   - [ ] Only the sections appropriate to the severity class were touched
   - [ ] No scoring rubric / workflow phase / anti-pattern edits (those are human-only)
   - [ ] `docs_last_verified` bumped to today
   - [ ] `sha256` values in `upstream_refs` re-populated
   - [ ] `release_pinned` unchanged (unless PR is for a release bump)
3. If the skill has a CLI cheat sheet, spot-check 1–2 commands against current `sf --help` to confirm accuracy
4. Run `./scripts/audit-triggers.sh` before merge to confirm no new trigger collisions
5. Merge with the standard squash commit; do not keep the branch

Reject / close PRs that:

- Modify methodology sections despite the severity gate
- Propose removing anti-patterns (they are institutional memory; keep them)
- Change TRIGGER/DO NOT TRIGGER clauses (routing is a human-authored decision)

---

## 4. Release-cut handoff playbook

Every ~6 months (Spring / Summer / Winter Salesforce cycle):

1. Monitor the release notes TOC URL. When it publishes:
2. Run `./scripts/release-handoff.sh <release-name>` (e.g., `Summer '26`)
3. Review the prioritised list of affected skills
4. For each, decide:
   - **Auto-refresh sufficient** → let Layer 3 handle it on its next weekly run
   - **Needs structural rewrite** → human edit (new workflow phase, new anti-pattern, new scoring category)
   - **New skill needed** → new feature has no existing owner; author a new skill following section 1
5. Bump `release_pinned` on affected skills once verified against the new release
6. Update the release-cut log in `references/release-log.md`

---

## 5. Adding `upstream_refs` to an existing skill

For skills authored before auto-refresh was adopted, add refs incrementally:

1. Identify the authoritative Salesforce help / developer doc URL(s) the skill references implicitly
2. Add 1–5 entries under `upstream_refs:` in frontmatter
3. Mark them `importance: authoritative` (primary source of truth) or `supplemental` (supporting reference)
4. Leave `sha256: ""` — it will be populated by the first `refresh-skills-auto.sh` run
5. Set `docs_last_verified` to today

Fewer, higher-quality refs are better than many weak ones. Three authoritative URLs is a good target per skill.

---

## 6. Anti-patterns

- **Never hand-edit `sha256` values.** They are derived from refetched content; manual edits will cause false drift reports.
- **Never point `upstream_refs` at third-party blogs.** Only `help.salesforce.com`, `developer.salesforce.com`, or `architect.salesforce.com` URLs.
- **Never skip the README + CLAUDE.md routing-table updates** when adding a skill. Drift between the three breaks Cursor's auto-routing.
- **Never auto-merge a PR that touches scoring rubrics.** Scoring is a human-authored judgment call, not a doc mirror.
- **Never use `release_pinned: latest`.** Always a specific release (e.g., `Spring '26`) so refresh tooling can detect misalignment.

---

## 7. Scoring rubric for this skill

Not applicable — this is a meta-skill, not a domain skill. Its "output" is the conformance of other skills to the rules defined here. Conformance is enforced by `sync-skills.sh --check` and `audit-triggers.sh`, not a rubric.
