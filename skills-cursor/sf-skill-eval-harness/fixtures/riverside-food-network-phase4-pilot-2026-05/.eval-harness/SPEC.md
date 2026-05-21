# SPEC.md — Phase 4 Demoscript Authoring (Riverside Food Network)

**Target skill:** `sf-demo-author` (sf-demo-orchestrate Phase 4)
**Source notes:** `/tmp/phase4-pilot/notes.md`
**Org platform:** NPSP (no migration to NPC)
**Demo duration:** 30 minutes (`standard` tier — 9-12 steps, 2-3 visual steps)
**Audience:** Carla (Operations Director), Devon (Volunteer & Partner Manager), Janet (Board Chair, skeptic)

---

## 1. Goal statement

Produce a `demoscript.md` plus all six cross-phase contract files for a 30-minute, NPSP-based, end-user-led demo for Riverside Food Network that visibly retires the Monday-morning Excel rebuild and the partner-request transcription work, in front of a board chair who needs to see staff time saved — not feature breadth.

---

## 2. Acceptance criteria

All ACs are falsifiable via JSON schema validation, file-presence checks, independent prose-rebuild against `notes.md`, or simple counting against the contract files.

### 2.1 Notes intake → `requirements.json` (drives every downstream contract)

- **AC-1.** `requirements.json` validates against `requirements.schema.json` and lists `source_notes: "/tmp/phase4-pilot/notes.md"`.
- **AC-2.** Every bullet in the notes' "What they want to show" subsections that has at least one of (a) an attributed pain quote, (b) a concrete current-state cost (minutes / days / no-show rate), or (c) an explicit "wow" callout produces exactly one requirement with `must_demo: true` and a non-empty `source_quote` + `source_line` pointing at `/tmp/phase4-pilot/notes.md`.
- **AC-3.** Bullets explicitly flagged "lower priority", "aspirational", "shelved", or "out of scope" produce requirements with `must_demo: false` (or are omitted entirely if redundant). The Donor Receipt Automation block MUST NOT appear with `must_demo: true`. The Tableau / advanced analytics line MUST NOT appear as a `must_demo: true` requirement.
- **AC-4.** At minimum, the following three pain-quoted use cases each produce a `must_demo: true` requirement (test: grep `requirements.json` for the substring of each source quote):
  1. Partner Agency Portal (Devon's "transcription robot" quote, request-to-route mapping wow)
  2. Volunteer Shift Self-Service (no-show case auto-creation, 15-20% no-show rate context)
  3. Distribution Planning Dashboard (Carla's "walk in Monday morning, look at one screen" quote, 90-minute Excel rebuild as pain)
- **AC-5.** No requirement has an empty `source_quote` field. No requirement cites a quote that does not appear verbatim in `notes.md`.

### 2.2 Story / persona depth → `value-moments.json`

- **AC-6.** `value-moments.json` validates against `value-moments.schema.json`. `duration_minutes: 30`. `duration_budget.end_user_pov_min_pct >= 60`. `duration_budget.admin_setup_max_pct <= 20`.
- **AC-7.** Every `must_demo: true` requirement from `requirements.json` has exactly one matching entry in `value_moments[]` keyed by `requirement_id`. No drops. No duplicates.
- **AC-8.** Each `value_moments[]` entry has all of: non-empty `persona` (one of Carla / Devon / Maria / Jordan — NOT Janet, who is audience not actor), non-empty `persona_pain_quote` drawn verbatim from `notes.md` (or marked `synthesized: true` with rationale), non-empty `persona_outcome`, populated `wow_moment` object with all four sub-fields (`description`, `why_audience_leans_forward`, `presenter_cue`, `estimated_duration_seconds`), `anti_demo[]` with at least one entry, and `min_steps >= 3` summing with `end_user_pov_steps + admin_pov_steps <= min_steps`.
- **AC-9.** For the Partner Agency Portal value moment, the `wow_moment.description` references the Monday-9am-submit → Tuesday-morning-on-Carla's-dashboard mapping (the explicit wow from the notes). A reviewer rebuilding from notes alone would arrive at the same wow.
- **AC-10.** Across all `value_moments[]`, the `anti_demo[]` lists collectively contain (a) "do not show Setup" or equivalent, and (b) at least one beneficiary-of-Janet's-skepticism guard (e.g., "do not show feature breadth without staff-time-saved framing").
- **AC-11.** Sum of `min_steps` across all `value_moments[]` falls within the 30-minute / `standard` tier band (9-12 total steps) — not below (loses story), not above (overruns slot).

### 2.3 Click path + coverage + wow delivery → `click-path.json`, `requirement-coverage.json`, `wow-moment-delivery.json`

- **AC-12.** All three files validate against their schemas. `click-path.json.steps[]` length is between 9 and 12 inclusive (standard tier band).
- **AC-13.** Every step has a non-empty `pov` field, valued `end_user` | `admin` | `mixed` | `narrative`. End-user share among non-narrative steps is `>= 60%`; admin share is `<= 20%`.
- **AC-14.** For every `must_demo: true` requirement, `requirement-coverage.json.coverage[]` contains an entry with `requirement_id` matching, `covered_by_steps[]` non-empty, `demonstration_quality` one of `primary` | `incidental`, AND at least one `primary` per requirement. `uncovered_requirements[]` is empty (or has explicit `rationale_for_uncovered` non-null per item).
- **AC-15.** For every `must_demo: true` requirement, the count of `covered_by_steps[]` for that requirement in `requirement-coverage.json` is `>= min_steps` from the matching `value_moments[]` entry. (Depth check.)
- **AC-16.** Each step ID referenced in `requirement-coverage.json.coverage[].covered_by_steps[]` exists in `click-path.json.steps[].id` (FK integrity).
- **AC-17.** `wow-moment-delivery.json.deliveries[]` has one entry per `value_moments[]` entry. Each delivery has all four narrative beats populated (`pain_context_beat`, `watch_this_cue`, `moment_step`, `narration_beat`), each pointing at a step ID that exists in `click-path.json`.
- **AC-18.** For every delivery, the four beats appear in `click-path.json` step order: `pain_context_beat.step` index < `watch_this_cue.step` index <= `moment_step` index < `narration_beat.step` index. (No backward beats; `watch_this` may be the same step as `moment` or precede it but never follow.)
- **AC-19.** No click-path step references a Setup-screen URL pattern (`/lightning/setup/`), and no step is tagged `pov: admin` while pointing at a partner-portal or volunteer-portal end-user URL (consistency check against Janet's anti-demo).

### 2.4 Data fidelity → `data-requirements.json`

- **AC-20.** `data-requirements.json` validates against `data-requirements.schema.json`.
- **AC-21.** Every record referenced (by Name, label, or ID placeholder) anywhere in `click-path.json.steps[].actions[]` or `expected_visible[]` has a corresponding entry in `data-requirements.json.records[]` with object, required_fields, and `referenced_by_steps[]` containing that step's ID. (No orphaned UI references.)
- **AC-22.** Conversely, every `records[].id` in `data-requirements.json` has a non-empty `referenced_by_steps[]` and each referenced step ID exists in `click-path.json`. (No unused records.)
- **AC-23.** Partner agency names, donor names, volunteer names, and beneficiary names in `data-requirements.json.records[].required_fields` are realistic Oregon-flavored names. NO placeholders matching the patterns: `Test (Company|User|Account|Org) [A-Z0-9]`, `Sample \w+`, `Demo \w+ \d+`, `Foo`, `Bar`, `Acme` (unless Acme is a real Oregon partner). Fictional partner agencies should be plausibly Oregon (Spanish/Latino community names are explicitly invited per the notes' Maria persona).
- **AC-24.** NPSP object API names are used (e.g., `Account` with `npe01__SYSTEMIsIndividual__c`, `Opportunity`, `npe03__Recurring_Donation__c`, `Contact`, `Case`). NO NPC-only object names (`PersonAccount`, `Gift`, `GiftTransaction`, `ApplicationForm`, `JobPositionShift`, `ProgramEnrollment`) appear in `data-requirements.json` or in click-path step descriptions.

### 2.5 demoscript.md packaging

- **AC-25.** `demoscript.md` exists at `/tmp/phase4-pilot/demoscript.md`. Its YAML frontmatter contains `demo_duration_minutes: 30`, `demo_duration_tier: standard`, `target_step_runtime_seconds` numeric, and `users[]` listing every persona who appears as an actor (Carla, Devon, Maria, Jordan — Janet is audience, not in `users[]`).
- **AC-26.** Every persona alias used in any step's narration or actions appears in the `users[]` frontmatter array.
- **AC-27.** A `## Teardown` section exists with Anonymous Apex that targets only `@demo.` email domains (the file MUST contain the literal substring `@demo.` in the teardown).
- **AC-28.** A `## Data Seed Requirements` section exists that mirrors the records in `data-requirements.json` (every record id from the JSON appears as a bullet under a `### <Object>` heading in the markdown).
- **AC-29.** A presenter cheat sheet section exists and includes the runtime banner string matching the regex `Target:\s*30\s*min` and per-step time budgets summing to within ±10% of `30 * 60 = 1800` seconds.

### 2.6 Narrative coherence (read end-to-end)

- **AC-30.** When the click-path is read in step order, an independent reviewer (the evaluator subagent, in fresh context) can identify exactly: (a) the pain / status quo step(s), (b) the struggle / current-state cost step(s), (c) the wow moment step(s), and (d) the resolution / "and now Janet sees the time saved" step(s) — and the four phases appear in that order. Falsifiable via prose-rebuild: evaluator writes the four-phase mapping; if any phase is empty or out of order, AC fails.
- **AC-31.** At least one click-path step is tagged with explicit "staff time saved" framing in its talking points or narration (board-chair-Janet test). Falsifiable via grep for substrings like `time saved`, `90 minutes`, `Tuesdays back`, `transcription` in the demoscript talking-point blocks.

---

## 3. Out-of-scope (the implementer MUST NOT do)

1. **Do not propose migrating to Nonprofit Cloud (NPC).** The notes explicitly say "Org is on NPSP, not migrating." Any mention of NPC objects, NPC migration, or "you'd get this for free in NPC" is an automatic SPEC violation.
2. **Do not include the Donor Receipt Automation as `must_demo: true`.** The notes flag it as lower priority and aspirational. It MAY appear with `must_demo: false` for completeness, or be omitted entirely.
3. **Do not include Tableau / advanced analytics as a `must_demo: true` requirement.** The notes explicitly shelve this ("Tableau later", "Out of scope: Tableau / advanced analytics").
4. **Do not use Setup screens in the click path.** No `/lightning/setup/` URLs; no `pov: admin` steps that walk through configuration UI. Janet has zero patience for admin views (her stated anti-demo).
5. **Do not use placeholder names** like "Test Company A", "Sample Org", "Acme Corp" (unless Acme is verifiably a real Oregon partner agency), "Demo User 1". Names must be realistic and Oregon-flavored. The Maria persona is anchored as a Latino community center pantry lead — honor that specificity.
6. **Do not invent requirements not present in `notes.md`.** If an AC requires an artifact field that isn't in the notes, the implementer must surface it (mark `synthesized: true` in `value-moments.json` for any pain quote not drawn verbatim from notes) — not silently fabricate.
7. **Do not propose any new license or product purchase.** Notes explicitly bar this ("Anything requiring a new license or product purchase" is out of scope).
8. **Do not write `demoscript.md` or any contract file outside `/tmp/phase4-pilot/`.** All artifacts land in that directory or its `.eval-harness/` subdirectory.
9. **Do not modify `/tmp/phase4-pilot/notes.md`.** Read-only.
10. **Do not commit or push anything.** No git operations.

---

## 4. Test plan

### 4.1 Unit tests — schema + structural validation

- **U-1.** `requirements.json` validates against `requirements.schema.json` (jsonschema CLI).
- **U-2.** `value-moments.json` validates against `value-moments.schema.json`.
- **U-3.** `click-path.json` validates against `click-path.schema.json`.
- **U-4.** `requirement-coverage.json` validates against `requirement-coverage.schema.json`.
- **U-5.** `wow-moment-delivery.json` validates against `wow-moment-delivery.schema.json`.
- **U-6.** `data-requirements.json` validates against `data-requirements.schema.json`.
- **U-7.** `demoscript.md` YAML frontmatter parses; required keys (`demo_duration_minutes`, `demo_duration_tier`, `target_step_runtime_seconds`, `users`) are present and well-typed.

### 4.2 Integration tests — cross-file FK + coverage integrity

- **I-1.** Every `must_demo: true` requirement in `requirements.json` has exactly one corresponding entry in `value-moments.json.value_moments[]` (set equality on `requirement_id`).
- **I-2.** Every `value_moments[].requirement_id` has exactly one corresponding entry in `wow-moment-delivery.json.deliveries[]` (set equality).
- **I-3.** Every step ID referenced in `requirement-coverage.json.coverage[].covered_by_steps[]`, `wow-moment-delivery.json` (all four beats), and `data-requirements.json.records[].referenced_by_steps[]` exists in `click-path.json.steps[].id` (referential integrity).
- **I-4.** Every `must_demo: true` requirement has `>= 1` entry in `requirement-coverage.json.coverage[]` with `demonstration_quality: "primary"`.
- **I-5.** Per-requirement step count: for each `must_demo: true` requirement, `len(coverage[].covered_by_steps) >= value_moments[].min_steps`.
- **I-6.** No orphan records: every `data-requirements.json.records[].id` is referenced by at least one click-path step. No orphan UI references: every record name/label appearing in `click-path.json.steps[].actions[]` or `expected_visible[]` has a backing record entry in `data-requirements.json`.
- **I-7.** POV ratio computed mechanically: `count(steps[pov=end_user]) / count(steps[pov in {end_user, admin, mixed}]) >= 0.60` and `count(steps[pov=admin]) / count(steps[pov in {end_user, admin, mixed}]) <= 0.20`.
- **I-8.** Beat ordering: for each delivery in `wow-moment-delivery.json`, the click-path step indices satisfy `pain_context_beat.step_index < watch_this_cue.step_index <= moment_step.step_index < narration_beat.step_index`.

### 4.3 Smoke / e2e — narrative coherence + audience-fit

- **S-1.** End-to-end narrative reconstruction. Evaluator subagent reads `click-path.json` in step order (with no other context) and writes a four-phase outline (lead-in pain → struggle → wow → resolution). Test passes iff each phase is non-empty and the phases appear in the click-path in that order. (Falsifiable: any phase missing or out of order = fail.)
- **S-2.** Board-chair-Janet test. Grep `demoscript.md` (talking-point blocks + narration) for at least one occurrence of explicit staff-time-saved language tied to the source notes' specifics: `90 minutes`, `Tuesdays`, `transcription`, `time saved`, `back her morning`, or equivalent. Test passes iff at least two distinct staff-time-saved framings appear, each tied to a real notes pain point (not generic ROI handwaving).
- **S-3.** Realistic-name spot check. Sample 100% of `data-requirements.json.records[].required_fields.Name` (and `FirstName`/`LastName` where present) and confirm no name matches the placeholder regex from AC-23. (Falsifiable: any match = fail.)
- **S-4.** Anti-demo enforcement. Grep `click-path.json.steps[].url_pattern` for `/lightning/setup/`. Test passes iff zero matches.
- **S-5.** Persona-actor consistency. Every persona alias appearing in any `click-path.json.steps[].description` or talking-point text appears in `demoscript.md` `users[]` frontmatter. Janet does NOT appear in `users[]`. (Falsifiable.)
- **S-6.** Wow-moment leaning-forward test. For the Partner Agency Portal value moment, `value_moments[].wow_moment.description` mentions both "Monday" and either "Tuesday" / "next morning" / "by tomorrow" AND mentions a route/truck/warehouse mapping artifact (the wow concretely from the notes). Falsifiable via substring check.

---

## 5. Rubric weights for this run

The rubric is graded by the evaluator against the four hard-fail Phase 4 dimensions declared in `sf-demo-author/SKILL.md` frontmatter `phase4_dimensions:`:

- **Requirement_Coverage_And_Depth** (max 25, hard-fail floor 18)
- **Wow_Moment_Delivery** (max 25, hard-fail floor 12)
- **End_User_POV_Ratio** (max 25, hard-fail floor 12)
- **Click_Path_Fidelity_And_Data_Contract** (max 25, hard-fail floor 13)

The 150-pt internal rubric in the same SKILL.md (Story clarity / Persona realism / Click path precision / Prerequisite completeness / Validate-readiness / Talking point quality) maps onto these four dimensions and is graded as a secondary view; the four hard-fail dimensions are authoritative for SHIP / ITERATE / SPEC-DEFECT verdict per the harness contract.

The implementer does NOT see weights or floors. The ACs above are what the implementer builds against.
