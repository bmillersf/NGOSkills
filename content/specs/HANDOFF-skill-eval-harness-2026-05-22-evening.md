# Handoff — sf-skill-eval-harness rollout (evening update)
**Date written:** 2026-05-22 (evening, supersedes morning + afternoon handoffs)
**Branch:** `learn/skill-self-improvements-2026-05` (still NOT pushed; 45 commits local)
**Working repo:** `/Users/brianmiller/Cursor/Skills/NGOSkills`

---

## TL;DR (evening update)

This session closed out four more wraps the afternoon handoff had documented as deferred-for-good-reason — turns out three of those reasons were overly conservative.

**80 skills now wrapped (up from 76 at afternoon close, 47 at morning open).** All 5 remaining unwrapped skills are genuine non-fits, not deferrals.

| Marker | Open | Close |
|---|---|---|
| Wrapped skills | 76 | **80** |
| Commits since baseline c2f7c56^ | 42 | **45** |
| Tests | 49/49 | **49/49** green throughout |
| Working tree | 2 pre-existing dirty | **2 pre-existing dirty** |

---

## 1. Where everything lives — unchanged

Same as morning + afternoon handoffs §1. Test suite at `skills-cursor/sf-skill-eval-harness/tests/` — 49 passing.

---

## 2. Newly wrapped this evening (4 skills)

### From the afternoon §3b "deferred per §3c" bucket — 2 wraps

The morning handoff §3c flagged the diagram skills as "harness wrap value unclear because output is for humans not deterministic." Re-reading the rubrics, that reasoning was overly conservative — diagrams that misrepresent the system (wrong cardinality, hallucinated entities) are real, gradeable defects.

- **sf-diagram-mermaid** (80pt, 5 cat: Accuracy 20 / Clarity 20 / Completeness 15 / Styling 15 / Best Practices 10) — extracted from existing scoring section. Correctness floor at 14: diagrams that misrepresent the system encode the wrong mental model. Hard-fails on Mermaid syntax errors, hallucinated entities, missing required steps, wrong diagram type, internal API names exposed as node labels, demo-storytelling mode without paired talking track.

- **sf-diagram-nanobananapro** (80pt, 5 cat: Source Faithfulness 25 / Brand Fidelity 20 / Prompt Quality 15 / Workflow Hygiene 10 / Output Hygiene 10) — categories authored from scratch (frontmatter declared the 80pt total but no inline breakdown). Correctness floor at 14: hallucinated objects + wrong relationship cardinality on a rendered ERD encode the wrong mental model. Hard-fails on invented entities, wrong cardinality, fields that don't exist on the source object, hardcoded colors ignoring cloud auto-detection, draft skipped (straight to 4K), /edit workflow bypassed for wholesale regeneration.

### From the afternoon §3a "doesn't fit" bucket — 2 wraps

Both flagged as not-artifact-producing in the afternoon handoff. Re-examination showed they DO produce graded artifacts.

- **sf-ui-fallback-playwright** (120pt, 7 cat: Auth hygiene 15 / CLI-exhaustion check 20 / Selector resilience 25 / Self-heal logic 20 / Screenshot coverage 15 / Library organization 15 / Safety rails 10) — extracted from existing rubric (line 273 of the SKILL.md). Robustness floor at 18: Playwright fallbacks run authenticated UI automation; auth leaks + unconfirmed prod writes are the dominant catastrophic failure modes. Hard-fails on CLI-exhaustion check undocumented, selector-ladder violations (>20% raw xpath), passwords in config, storageState committed to git, prod writes without --write + typed confirmation, silent timeout passes (no self-heal), library path divergence, missing screenshots after state changes.

- **sf-ai-agentforce-observability** (100pt, 4 cat: STDM Query Correctness 30 / Auth + Storage Hygiene 25 / Analysis + Debug Quality 25 / Cost + Volume Discipline 20) — newly authored. Two heavy floors: Correctness 16 (wrong DMO / wrong join / SSDM-version-too-old produces empty or misleading results) and Robustness 16 (telemetry data includes prompt content + tool inputs + customer queries; weak auth or unencrypted Parquet leaks regulated data). Hard-fails on CRM SOQL in Data Cloud SQL context, SSDM <v1.124, JWT credentials inlined, Parquet not gitignored, Pandas on >100k rows when Polars is the pattern, debug claims without event_id citation, multi-million-row sync queries (must be async).

### One Edit-bug caught + fixed mid-session

The sf-ai-agentforce-observability wrap initially broke YAML parsing — my Edit accidentally pulled the closing `---` frontmatter delimiter into the replacement content. The afternoon handoff's YAML-parse validation pattern caught it immediately. Fix was a single Edit to restore the delimiter. Tests stayed green throughout.

This is the second instance of the same Edit pattern (afternoon's sf-service-cloud was the first). Both had a structurally similar trigger: replacing content that ended with `---` and accidentally absorbing the delimiter into the new block. **Future wraps on skills with `<!-- comments -->` between frontmatter and `# Heading` are at higher risk** because the body comments make it harder to spot the missing delimiter visually.

---

## 3. Remaining unwrapped — 5 skills, all genuine non-fits

| Skill | Reason for not wrapping |
|---|---|
| `sf-docs` | Pure retrieval — no producer/evaluator gap (per SPEC §3 non-goals: "Not for skills that don't ship artifacts") |
| `sf-demo-orchestrate` | Orchestrator-internal — its 7 phases wrap individually per SPEC §16; the orchestrator wraps recursively via the wrapped phase skills |
| `sf-subagent-orchestration` | Policy/routing skill — not artifact-producing (defines when to spawn subagents) |
| `sf-industry-commoncore-omnistudio-analyze` | Read-only dependency analysis — no artifact, just navigation across existing OmniStudio metadata |
| `sf-ui-autonomous` | "bootstrap — library awaiting first captured flow" status (per morning §3c). `library/library.json` flows array confirmed still empty as of evening. Wrap when at least one flow exists to grade against. |

Don't wrap any of these without specific reason. Each one's "non-fit" classification is durable — they describe categories the SPEC explicitly excluded or skill states that don't yet have artifacts.

---

## 4. Validation pattern (still the right one)

```bash
REPO=/Users/brianmiller/Cursor/Skills/NGOSkills
/opt/homebrew/bin/python3 -c "
import re, yaml
text = open('\$REPO/skills/<SKILL>/SKILL.md').read()
fm_match = re.match(r'^---\n(.*?)\n---\n', text, re.S)
assert fm_match, 'frontmatter not parseable'
parsed = yaml.safe_load(fm_match.group(1))
assert 'eval_harness' in parsed
assert parsed['eval_harness']['enabled'] == True
dims_keys = [k for k in parsed['eval_harness'] if k.endswith('_dimensions') and k != 'hard_fail_dimensions']
assert len(dims_keys) == 1
assert len(parsed['eval_harness'][dims_keys[0]]) == 4
assert text.count('hard_fail_below:') == 4
assert '## Eval Harness Wrap' in text
print('OK')
"
cd \$REPO/skills-cursor/sf-skill-eval-harness && .venv/bin/python -m pytest tests/ -q
```

This catches the closing-delimiter Edit bug because YAML parsing fails immediately on an unclosed frontmatter.

---

## 5. The two pre-existing dirty files (still untouched)

`refresh-report.md` and `skills-cursor/babysit/SKILL.md` were dirty before any of this work began. They're still dirty. Per morning §6.2: leave them.

---

## 6. Branch + commit summary

45 commits on `learn/skill-self-improvements-2026-05` since `c2f7c56^`. Three new this evening:

- `78c462e` — wrap diagram pair (Mermaid + Nano Banana Pro)
- `ec6fa28` — wrap reactive Playwright fallback + Agentforce observability
- (this commit) — evening handoff doc

Per morning + afternoon handoffs: never push without user approval. The 45 commits are pushable as a single feature branch when the user is ready.

---

## 7. What's left worth doing (if context returns)

The remaining work is now genuinely small. Two items:

1. **Run the positive-detection sf-apex pilot.** Mutate the Stage B fixture's `CI_SponsorChildAction.cls` to introduce a SOQL inside a for-loop, re-spawn the evaluator subagent, verify it returns ITERATE with a Correctness hard-fail breach. ~30 min. Highest data value remaining — validates that the harness rules fire in the positive direction (not just that they don't false-positive on clean code).

2. **Wrap sf-ui-autonomous when its library has a flow.** Requires user signal — at least one captured flow in `library/library.json`. Until then, no audience to grade against.

The full rollout is otherwise complete. 80 of ~85 active skills wrapped, with the 5 unwrapped each documented as genuine non-fit. All 49 harness tests green.

---

## End of evening handoff
