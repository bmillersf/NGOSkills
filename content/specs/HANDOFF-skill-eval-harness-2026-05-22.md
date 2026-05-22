# Handoff — sf-skill-eval-harness rollout
**Date written:** 2026-05-22
**Branch:** `learn/skill-self-improvements-2026-05` (NOT pushed; all 26 commits are local)
**Working repo:** `/Users/brianmiller/Cursor/Skills/NGOSkills`
**Read this whole document before doing anything.**

---

## TL;DR

Adversarial eval harness for Salesforce skills. Three-agent loop (planner → implementer → evaluator) running in fresh subagent contexts, gated by hard-fail floors, with structured handoffs. **34 of ~47 skills are wrapped. 4 real LLM-driven pilots passed SPEC §8 success metrics 4/4. Roughly 13 skills remain.**

The thing the harness fundamentally does: catches the failure mode where a producing agent self-rates ~196/200 but a fresh-context evaluator finds real bugs. Proven across 4 pilots in different domains (validation, authoring, Apex, LWC).

---

## 1. Where everything lives

```
~/Cursor/Skills/NGOSkills/                                  ← canonical repo
├── content/specs/
│   ├── skill-eval-harness-SPEC.md                          ← SPEC v7 (authoritative)
│   └── HANDOFF-skill-eval-harness-2026-05-22.md            ← THIS DOC
├── skills-cursor/sf-skill-eval-harness/                    ← THE HARNESS SKILL
│   ├── SKILL.md                                            ← orchestration playbook
│   ├── prompts/{planner,implementer,evaluator}.md          ← subagent prompts
│   ├── schemas/*.schema.json                               ← 6 cross-phase contracts
│   ├── scripts/{contracts,rubric,trace,harness,cli}.py     ← Python primitives
│   ├── tests/                                              ← 49 pytest tests, 0.34s
│   ├── fixtures/
│   │   ├── simple-volunteer-demo/                          ← deterministic regression fixture
│   │   ├── children-incorporated-pilot-2026-05/            ← Phase 6 LLM pilot
│   │   ├── riverside-food-network-phase4-pilot-2026-05/    ← Phase 4 LLM pilot
│   │   ├── phase5-walkthrough-2026-05/                     ← Phase 5 deterministic
│   │   ├── sf-apex-stage-b-pilot-2026-05/                  ← Stage B Apex pilot
│   │   └── sf-lwc-stage-b-pilot-2026-05/                   ← Stage B LWC pilot
│   ├── README.md                                           ← invocation guide
│   └── SAMPLE-RUN.md                                       ← deterministic walkthrough
└── skills/<wrapped-skill>/SKILL.md                         ← 33 wrapped consumer skills

~/.cursor/skills/sf-skill-eval-harness                      ← symlink (auto-managed by sync-skills.sh)
~/.claude/skills/sf-skill-eval-harness                      ← symlink (auto via dir-level link)
```

**Test suite location:** `skills-cursor/sf-skill-eval-harness/`. Run with:
```bash
cd ~/Cursor/Skills/NGOSkills/skills-cursor/sf-skill-eval-harness && \
  .venv/bin/python -m pytest tests/ -q
```
Expected: `49 passed in <1s`. If this isn't green, stop and investigate before doing anything else.

---

## 2. Current state — what's wrapped

**34 wrapped skills** (eval_harness.enabled: true in frontmatter). Listing alphabetically:

```
sf-ai-agentforce              sf-ai-agentforce-persona      sf-ai-agentforce-testing
sf-ai-agentscript             sf-apex                       sf-backup-datamask
sf-data                       sf-debug                      sf-demo-author
sf-demo-data                  sf-demo-playwright            sf-demo-validate
sf-deploy                     sf-devops-center              sf-experience-cloud
sf-flow                       sf-identity-sso               sf-integration
sf-lwc                        sf-metadata                   sf-mulesoft
sf-nonprofit-cloud            sf-nonprofit-demo-data        sf-nonprofit-experience-cloud
sf-nonprofit-fundraising      sf-nonprofit-npsp             sf-permissions
sf-revenue-cloud              sf-shield-event-monitoring    sf-skill-eval-harness
sf-slack                      sf-soql                       sf-tableau                    sf-testing
```

(That's the harness skill itself + 33 consumers. The harness skill counts because its SKILL.md is the orchestration playbook.)

**Real LLM-driven pilot results (4 runs, 4/4 SPEC §8 yes):**

| Pilot | Skill | Type | Result | Iterations | Self-eval gaps caught |
|---|---|---|---|---|---|
| Children Inc | sf-demo-validate (Phase 6) | Validation | ITERATE 77 → SHIP 89 | 2 | 3 (N+1 bulk, no dup-prevent, "Scheduled" string drift) |
| Riverside | sf-demo-author (Phase 4) | Authoring | SHIP 95 (calibration miss caught → tightened rubric) | 1 | 3 (narration anchored to wrong step, arithmetic, POV count) |
| sf-apex Stage B | sf-apex | Apex code-gen | SHIP 93 | 1 | Clean code; rules calibrated correctly negative-direction |
| sf-lwc Stage B | sf-lwc | LWC code-gen | SHIP 94 | 1 | 2 minor (test name collapse, display:contents a11y edge) |

---

## 3. Remaining work

### 3a. Mechanical wraps (rubric exists, needs wiring) — ~3-5 min each

| Skill | Rubric | Categories |
|---|---|---|
| sf-connected-apps | 120pt | Security 30 / OAuth Config 25 / Metadata 20 / Best Practices 20 / Scopes 15 / Documentation 10 |
| sf-industry-health | 150pt | Regulatory 25 / Data Model 25 / Clinical Workflow 25 / FHIR 20 / UX 20 / PHI 20 / Testing 15 |
| sf-industry-commoncore-omniscript | 120pt | (categories not yet extracted) |
| sf-industry-commoncore-integration-procedure | 110pt | (categories not yet extracted) |
| sf-industry-commoncore-datamapper | 100pt | Design & Naming 20 / Field Mapping 25 / Data Integrity 25 / Performance 15 / Documentation 15 |
| sf-industry-commoncore-flexcard | 130pt | Design & Layout 25 / Data Binding 20 / Actions & Navigation 20 / Styling 20 / (3 more) |
| sf-industry-commoncore-callable-apex | 120pt | (categories not yet extracted) |

### 3b. Rubric authoring + wrap — ~10-15 min each

| Skill | What it needs |
|---|---|
| sf-nonprofit-grants | Has weighted-criterion rubric (1-5 × weight%) — needs translation to point-based 4-dim shape |
| sf-nonprofit-experience-cloud-build | UI/UX rubric to author from scratch (mine reference website, design tokens, LWC purposefulness, brand fidelity) |
| sf-nonprofit-experience-cloud-ux | UI/UX rubric to author from scratch (visual design, journey flows, accessibility, donor empathy) |
| sf-nonprofit-program-case | Rubric extraction from existing workflow narrative (it's there, just not in tree format) |

### 3c. Deferred (do not wrap yet)

- **sf-ui-autonomous** (170pt rubric exists). Skill is in "bootstrap — library awaiting first captured flows" status. Wrap when at least one captured flow exists in `library/library.json` to grade against.
- **sf-diagram-mermaid** (80pt) and **sf-diagram-nanobananapro** (80pt). These are visual-output skills; harness wrap value is unclear because the output is for humans not deterministic. Skip unless user requests.

---

## 4. The wrapping pattern (how to do mechanical wraps fast)

Every wrapped skill follows the same template. Two edits to `skills/<skill>/SKILL.md`:

### Edit 1 — Add eval_harness frontmatter block

Insert after `upstream_release_notes:` block but BEFORE the closing `---`:

```yaml
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "<N>-pt rubric inline (or in references/<file>) (<categories>), mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  <skill>_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: <12-18>
      description: "<what this dim grades, mapped from existing rubric categories>"
      automatic_hard_fail_rules:
        - "<concrete deterministic check>"
        - "<another concrete deterministic check>"
    - name: Robustness
      max: 25
      hard_fail_below: <12-18>
      description: "..."
      automatic_hard_fail_rules: [...]
    - name: Fit
      max: 25
      hard_fail_below: <10-12>
      description: "..."
      automatic_hard_fail_rules: [...]
    - name: Performance
      max: 25
      hard_fail_below: <10-15>
      description: "..."
      automatic_hard_fail_rules: [...]
  test_rubric:
    unit:
      required: true
      criteria: "<what unit testing means for this artifact type>"
    integration:
      required: true
      criteria: "<what integration testing means>"
    smoke:
      required: true
      criteria: "<what end-to-end testing means>"
```

### Edit 2 — Add "Eval Harness Wrap" body section

Insert immediately after the H1 + intro paragraph, before the first `## Section`:

```markdown
## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). Three subagents (planner / implementer / evaluator) loop against the <N>-pt rubric in fresh context. <One-sentence highlight: heaviest hard-fail floor + why>. Disable with `eval_harness.enabled: false`.

---
```

For higher-stakes skills, expand the body section to ~30 lines with composition table + per-skill probe descriptions. See `sf-apex/SKILL.md` or `sf-lwc/SKILL.md` for the longer pattern.

### Validation after each wrap (mandatory)

```bash
REPO=/Users/brianmiller/Cursor/Skills/NGOSkills
PY=$REPO/skills-cursor/sf-skill-eval-harness/.venv/bin/python

# Frontmatter sanity
/opt/homebrew/bin/python3 -c "
import re
text = open('$REPO/skills/<SKILL>/SKILL.md').read()
fm = re.match(r'^---\n(.*?)\n---\n', text, re.S).group(1)
assert 'eval_harness:' in fm
assert text.count('hard_fail_below:') == 4
assert '## Eval Harness Wrap' in text
print('OK')
"

# Test suite (must stay 49/49)
cd $REPO/skills-cursor/sf-skill-eval-harness && $PY -m pytest tests/ -q
```

If the file already has a `metadata:` block in frontmatter and the existing skill HAS NO scoring declaration (e.g., sf-deploy, sf-permissions before I authored rubrics), insert a new `metadata: scoring: ...` block alongside `eval_harness:`. See commit `506f867` for the pattern.

---

## 5. The 4-dimension SPEC default mapping

Every skill maps its existing N-category rubric onto the SPEC §5.1 4-dimension shape:

| SPEC dimension | Typical hard-fail floor | What goes here |
|---|---|---|
| **Correctness** | 15 (or 18 if life-or-death) | Does the artifact do what it claims? Bulk safety, schema validity, semantic accuracy. |
| **Robustness** | 12 (or 15-18 if security-bearing) | Does it survive bad input + edge cases + concurrent execution? Error handling, retries, security boundaries. |
| **Fit** | 10 (sometimes 12-15) | Pattern adherence, naming conventions, framework idioms, no-duplication-of-existing-platform. |
| **Performance** | 12 (or 15 if measured) | Governor limits, scale-tested with measured evidence, async patterns where heavy. |

**Pick the floor by asking: what's the worst that happens if this dimension breaches?** Catastrophic = 18. Demo-killer = 15. User confusion = 12. Polish = 10.

Heavily security-flavored skills get higher Robustness floors (sf-experience-cloud Robustness=15, sf-shield Robustness=18, sf-permissions Robustness=18, sf-identity-sso Robustness=18). Backup/recovery skills get higher Correctness floors (sf-backup-datamask Correctness=18, untested backups aren't backups).

---

## 6. Hard-won conventions (do not violate)

1. **Never push.** All 26 commits are local on `learn/skill-self-improvements-2026-05`. Per CLAUDE.md global policy, push is user-initiated only.
2. **Never modify the 2 unrelated pre-existing dirty files** (`refresh-report.md`, `skills-cursor/babysit/SKILL.md`). They were dirty when I started; leave them.
3. **Don't auto-trigger sync-skills.sh after every wrap.** Run `~/Cursor/Skills/NGOSkills/scripts/sync-skills.sh --check` only when you're done with a session and want to verify drift=0.
4. **Don't author rubrics without a clear basis** in the skill's existing methodology. If a skill has no scoring section anywhere — not in SKILL.md, not in references/ — surface to user before inventing one. (Exceptions Brian explicitly approved: sf-deploy and sf-permissions, both pass-fail by nature.)
5. **Don't run live LLM-driven pilots without user approval.** Each pilot burns ~30-45 min of subagent time + an org if Phase 5/6 are exercised. The 4 existing pilots are sufficient evidence; don't add more without need.
6. **Test calibration discipline:** if you author a new rubric, the hard-fail floor for each dimension should be derived from "what's catastrophic in this domain," not arbitrarily set at 12-15.
7. **49/49 tests must stay green** after every commit. If a frontmatter edit breaks YAML parsing, the harness's own pytest suite will catch it via `test_contracts.py`. Verify before committing.

---

## 7. Open calibration questions (worth knowing about)

These are surfaced in the pilot fixture READMEs as future work:

- **Lex-aware bulkification probe (sf-apex Stage B):** the deterministic regex CLI probe could false-positive on string literals containing DML keywords like `'GiftCommitment insert failed: '`. Would need a small parser update to `scripts/contracts.py` or a new `scripts/apex_static_analysis.py`. Currently mitigated by evaluator subagent doing a manual pass — fine for LLM-driven runs, weak for purely-mechanical CI use.

- **Positive-detection pilots (Stage B both):** sf-apex and sf-lwc rules are validated as not-firing-on-clean-code. They have NOT been validated as firing-on-broken-code. Worth a deliberate-failure pilot per skill: take an existing fixture, deliberately introduce one violation per probe, confirm each rule trips.

- **Wow_Moment_Delivery hard-fail rules** (committed in `814aaf7`): added after Riverside Phase 4 evaluator soft-graded a real beat-step mismatch. Three new automatic_hard_fail_rules in `prompts/evaluator.md` and SPEC §16. Have NOT been re-tested against Riverside fixture. If you re-run that fixture, expected new verdict on iter 1 = ITERATE, not SHIP.

- **Stage A + Stage B composition** never tested live. We don't know what happens when sf-demo-validate's Phase 5 fix logic delegates to sf-apex (now wrapped) inside a real loop. Theory: nested adversarial eval. Reality: untested.

---

## 8. SPEC + skill content quick reference

**SPEC §1-5:** the 5 guiding principles, three-agent architecture, subagent contracts, rubric structure (4-dim default + binary test rubric).

**SPEC §6:** loop control. 3 iterations max. 1 re-plan per loop. Hard-fail breaches always escalate to user (per §6.3).

**SPEC §8:** pilot success metrics. 4 questions. ≥3 yes → keep. Currently 4/4 yes across 4 runs.

**SPEC §14:** rollout roadmap. Stage A (orchestrator phases) = done. Stage B (implementation skills) = ~22/N done.

**SPEC §16:** per-phase rubrics for sf-demo-orchestrate's 7 phases. Phases 4, 5, 6, 7 wrapped. Phases 1, 2, 3 still orchestrator-internal (need dedicated skills before they can be wrapped — see §17).

**SPEC §17:** cross-phase JSON contracts (requirements.json, value-moments.json, click-path.json, requirement-coverage.json, wow-moment-delivery.json, data-requirements.json). Schemas in `skills-cursor/sf-skill-eval-harness/schemas/`.

**SPEC §19:** the shallow-demo fix. Phase 3 → 4 depth + user-value contract.

**SPEC §20:** universal coverage + opt-in via SKILL.md frontmatter.

**SPEC §21:** non-collision with gsd / superpowers / gstack. Hard non-overrides documented.

**SPEC §22:** authoritative ownership + artifact link map.

---

## 9. Recommended next session opening

```
Read these in order:
1. content/specs/HANDOFF-skill-eval-harness-2026-05-22.md (this doc)
2. content/specs/skill-eval-harness-SPEC.md (the SPEC, esp §5.1, §14, §20)
3. skills-cursor/sf-skill-eval-harness/SKILL.md (orchestration playbook)
4. One existing wrap as a pattern reference, e.g. skills/sf-apex/SKILL.md

Then verify:
- cd ~/Cursor/Skills/NGOSkills/skills-cursor/sf-skill-eval-harness
- .venv/bin/python -m pytest tests/ -q  (expect 49 passed)

Then pick next task:
- Easiest: mechanical wrap on sf-connected-apps (rubric extracted in §3a above)
- Highest-leverage: rubric authoring for sf-nonprofit-experience-cloud-build OR -ux
- Highest-data-value: positive-detection pilot on sf-apex Stage B (verify rules
  fire on actual N+1 code by mutating sf-apex-stage-b-pilot-2026-05 fixture)

Stop conditions during the next run:
- Test suite drops below 49/49
- Any commit you'd be making touches files outside skills/ or skills-cursor/
- Context approaches 60% — checkpoint commit and stop, leave clean state
```

---

## 10. Three things I would have done if I had more context

1. **Wrap the 7 mechanical-wrap skills in §3a.** Each is ~3 min. Total ~25 min including commits + test runs. Same pattern as Batches 1-5.
2. **Author the sf-nonprofit-program-case rubric** (it's there in narrative form, just needs extraction into the standard table format).
3. **Run the positive-detection sf-apex pilot.** Mutate the Stage B fixture's `CI_SponsorChildAction.cls` to put a SOQL inside a for-loop, re-spawn the evaluator subagent, verify it returns ITERATE with a Correctness hard-fail breach. ~30 min. Most-information-per-minute remaining work.

---

## 11. Tasks left in the system

```
#32 [in_progress] Wrap remaining Batch 5 skills (nonprofit + industry + OmniStudio)
#33 [in_progress] Author rubrics for 6 skipped skills + wrap them
```

These are still useful labels. Future session can mark them completed as it finishes the work in §3a-3b above.

---

## 12. Branch hygiene before pushing

When user is ready to push:

```bash
cd ~/Cursor/Skills/NGOSkills
git log --oneline c2f7c56^..HEAD          # 26 commits expected (or more if you wrapped more)
git status --short                         # should show only the 2 pre-existing dirty files
git push origin learn/skill-self-improvements-2026-05
```

The 2 pre-existing dirty files (`refresh-report.md`, `skills-cursor/babysit/SKILL.md`) are NOT mine and shouldn't be in the push.

If consolidating commits before push, the harness work cleanly groups into ~5 logical units:
- SPEC commits (c2f7c56 through b0e1078) — keep separate, they're the design history
- Pilot scaffolding (190a46b, 42bbd88, b188a8a) — squash to one
- Each LLM-driven pilot evidence (26fdf27, 814aaf7, 4384b92, 6d7194a) — keep separate, they're real data
- Each batch (4f4f0ab, aedc29c, 9736a7f, 2d27058, 0debc67, 506f867, 8a49c59) — squash by stage if desired

---

## End of handoff
