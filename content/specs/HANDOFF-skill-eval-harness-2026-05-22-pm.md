# Handoff — sf-skill-eval-harness rollout (afternoon update)
**Date written:** 2026-05-22 (afternoon, supersedes morning handoff)
**Branch:** `learn/skill-self-improvements-2026-05` (still NOT pushed; 41 commits local)
**Working repo:** `/Users/brianmiller/Cursor/Skills/NGOSkills`
**Read this entire document before doing anything.** Morning handoff still valid for SPEC + methodology references; this doc just updates §2 and §3.

---

## TL;DR (afternoon update)

Morning context closed out the original 11-task punch list (mechanical wraps + rubric authoring) AND wrapped 18 additional skills that turned out to have inline scoring rubrics or required from-scratch rubrics. **76 skills now wrapped (up from 47 at handoff start), 41 commits, 49/49 tests still pass, working tree only the 2 pre-existing dirty files.**

The work that remains is small and intentional: 9 skills that genuinely don't fit the harness model (pure retrieval, orchestrator-internal, policy/router, visual-output-for-humans, telemetry-read).

---

## 1. Where everything lives

Same as morning handoff §1. No structural changes — just added eval_harness frontmatter to additional SKILL.md files.

**Test suite:**
```bash
cd ~/Cursor/Skills/NGOSkills/skills-cursor/sf-skill-eval-harness && \
  .venv/bin/python -m pytest tests/ -q
```
Expected: **49 passed in <1s**.

---

## 2. Current state — what's wrapped (76 of ~85 active skills)

### Newly wrapped this afternoon (29 skills)

**Original §3a punch list (7 skills, mechanical wraps):**
- sf-connected-apps, sf-industry-health, sf-industry-commoncore-omniscript,
  sf-industry-commoncore-integration-procedure, sf-industry-commoncore-datamapper,
  sf-industry-commoncore-flexcard, sf-industry-commoncore-callable-apex

**Original §3b punch list (4 skills, rubric authoring):**
- sf-nonprofit-grants (converted weighted-criterion → point-based)
- sf-nonprofit-experience-cloud-build (UI/UX rubric, 140pt)
- sf-nonprofit-experience-cloud-ux (UI/UX rubric, 100pt)
- sf-nonprofit-program-case (extracted from existing workflow narrative)

**Bonus discoveries — pre-existing inline rubrics (16 skills):**
- sf-industry-fsc (150pt), sf-sales-cloud (150pt orchestrator)
- sf-service-cloud (150pt orchestrator)
- sf-service-case, sf-service-omnichannel, sf-service-knowledge (120pt each)
- sf-sales-opportunity, sf-sales-forecasting, sf-sales-engagement (120pt each)
- sf-marketing-cloud-growth, sf-marketing-account-engagement (130pt each)
- sf-field-service (140pt)
- sf-flow-orchestration (130pt)
- sf-reports-dashboards, sf-lightning-app-builder (120pt each)
- sf-ai-prompt-builder, sf-ai-model-builder-trust-layer (130pt each)
- sf-industry-education (150pt), sf-industry-public-sector (150pt)
- sf-industry-manufacturing, sf-industry-consumer-goods, sf-industry-communications,
  sf-industry-media, sf-industry-energy (50pt each — router-style skills)

**Newly authored rubrics (Data Cloud family, 7 skills):**
- sf-datacloud orchestrator (120pt, 6 cat) — phase localization + readiness classification
- sf-datacloud-connect (100pt, 4 cat) — Robustness 18 (credentials are entry points)
- sf-datacloud-prepare (100pt, 4 cat) — DLO + stream design
- sf-datacloud-harmonize (120pt, 4 cat) — Robustness 18 (IR over/under-merge is a privacy disaster)
- sf-datacloud-segment (100pt, 4 cat) — consent + suppression hardfails
- sf-datacloud-act (100pt, 4 cat) — Robustness 18 (egress = compliance boundary)
- sf-datacloud-retrieve (100pt, 4 cat) — Data Cloud SQL vs CRM SOQL discipline

### Full wrapped list (76 skills) — alphabetical

```
sf-ai-agentforce              sf-ai-agentforce-persona      sf-ai-agentforce-testing
sf-ai-agentscript             sf-ai-model-builder-trust-layer
sf-ai-prompt-builder          sf-apex                       sf-backup-datamask
sf-connected-apps             sf-data                       sf-datacloud
sf-datacloud-act              sf-datacloud-connect          sf-datacloud-harmonize
sf-datacloud-prepare          sf-datacloud-retrieve         sf-datacloud-segment
sf-debug                      sf-demo-author                sf-demo-data
sf-demo-playwright            sf-demo-validate              sf-deploy
sf-devops-center              sf-experience-cloud           sf-field-service
sf-flow                       sf-flow-orchestration         sf-identity-sso
sf-industry-commoncore-callable-apex     sf-industry-commoncore-datamapper
sf-industry-commoncore-flexcard          sf-industry-commoncore-integration-procedure
sf-industry-commoncore-omniscript        sf-industry-communications
sf-industry-consumer-goods    sf-industry-education         sf-industry-energy
sf-industry-fsc               sf-industry-health            sf-industry-manufacturing
sf-industry-media             sf-industry-public-sector     sf-integration
sf-lightning-app-builder      sf-lwc                        sf-marketing-account-engagement
sf-marketing-cloud-growth     sf-metadata                   sf-mulesoft
sf-nonprofit-cloud            sf-nonprofit-demo-data        sf-nonprofit-experience-cloud
sf-nonprofit-experience-cloud-build      sf-nonprofit-experience-cloud-ux
sf-nonprofit-fundraising      sf-nonprofit-grants           sf-nonprofit-npsp
sf-nonprofit-program-case     sf-permissions                sf-reports-dashboards
sf-revenue-cloud              sf-sales-cloud                sf-sales-engagement
sf-sales-forecasting          sf-sales-opportunity          sf-service-case
sf-service-cloud              sf-service-knowledge          sf-service-omnichannel
sf-shield-event-monitoring    sf-skill-eval-harness         sf-slack
sf-soql                       sf-tableau                    sf-testing
```

(75 consumer skills + the harness skill itself = 76.)

### Pilot results (unchanged from morning) — 4/4 SPEC §8 yes

The 4 LLM-driven pilots are still the gold-standard evidence. No new pilots run this afternoon — just mechanical / authoring wraps. Pilots remain valid for the harness machinery itself.

---

## 3. Remaining work — only 9 unwrapped skills, all intentional

### 3a. Skills that don't fit the harness model (do NOT wrap)

| Skill | Reason for not wrapping |
|---|---|
| `sf-docs` | Pure retrieval — no producer/evaluator gap (per SPEC §3 non-goals) |
| `sf-demo-orchestrate` | Orchestrator-internal — its 7 phases are wrapped individually per SPEC §16; orchestrator wraps recursively via the wrapped phase skills |
| `sf-subagent-orchestration` | Policy/routing skill — not artifact-producing |
| `sf-industry-commoncore-omnistudio-analyze` | Read-only dependency analysis |
| `sf-ui-fallback-playwright` | Reactive UI-fallback helper — not artifact-producing |
| `sf-ai-agentforce-observability` | STDM telemetry-read |

### 3b. Skills deferred per morning handoff §3c

| Skill | Reason for deferral |
|---|---|
| `sf-ui-autonomous` | "bootstrap — library awaiting first captured flows" status. Wrap when at least one captured flow exists in `library/library.json` to grade against |
| `sf-diagram-mermaid` (80pt) | Visual-output-for-humans skill — harness wrap value unclear (output not deterministic) |
| `sf-diagram-nanobananapro` (80pt) | Same as above |

If the user wants to wrap any of these later: the diagram skills already have 80pt rubrics inline; sf-ui-autonomous has a 170pt rubric. The mechanics are the same as the wraps already done.

---

## 4. Validation pattern (use this on every wrap going forward)

The morning handoff's regex-based validation has a subtle issue — it doesn't catch malformed YAML where my Edit splits the frontmatter (one wrap this afternoon hit this exact bug). Use this stronger YAML-parse validation:

```bash
REPO=/Users/brianmiller/Cursor/Skills/NGOSkills
/opt/homebrew/bin/python3 -c "
import re, yaml
text = open('\$REPO/skills/<SKILL>/SKILL.md').read()
fm_match = re.match(r'^---\n(.*?)\n---\n', text, re.S)
assert fm_match, 'frontmatter not parseable'
parsed = yaml.safe_load(fm_match.group(1))
assert 'eval_harness' in parsed, 'no eval_harness key'
assert parsed['eval_harness']['enabled'] == True
dims_keys = [k for k in parsed['eval_harness'] if k.endswith('_dimensions') and k != 'hard_fail_dimensions']
assert len(dims_keys) == 1, f'expected 1 *_dimensions key, got {dims_keys}'
assert len(parsed['eval_harness'][dims_keys[0]]) == 4, 'expected 4 dimensions'
assert text.count('hard_fail_below:') == 4
assert '## Eval Harness Wrap' in text, 'wrap section missing'
print('OK')
"
cd \$REPO/skills-cursor/sf-skill-eval-harness && .venv/bin/python -m pytest tests/ -q
```

The `hard_fail_dimensions` is a flat list of dimension names (sibling of the `<skill>_dimensions` key); only the `<skill>_dimensions` is the actual schema. The validator now distinguishes them.

---

## 5. The two pre-existing dirty files (still don't touch)

`refresh-report.md` and `skills-cursor/babysit/SKILL.md` were dirty when the morning context started; they're still dirty now. Per morning handoff §6.2: leave them.

---

## 6. Branch hygiene before pushing

Same as morning handoff §12. 41 commits since `c2f7c56^`. Logical groups:
- Spec history (c2f7c56 through b0e1078) — 5 commits, keep separate
- Pilot scaffolding + LLM-driven pilots — 8 commits, keep separate (real data)
- Wrap batches (1-5, etc.) + new afternoon batches — squashable by domain if desired:
  - Service Cloud (orchestrator + trio) — 2 commits
  - Sales Cloud (FSC bonus + orchestrator + trio) — 2 commits
  - Marketing pair — 1 commit
  - Platform builder (FS + Flow Orch + Reports + LAB) — 1 commit
  - AI primitives — 1 commit
  - Industry batch — 1 commit
  - Data Cloud family — 1 commit
  - Original 11 punch-list — 4 commits (already squashed by morning context)

---

## 7. What's next (if context returns)

The remaining work is genuinely small. Three options if a future session wants to keep wrapping:

1. **Wrap the diagram skills anyway.** sf-diagram-mermaid + sf-diagram-nanobananapro both have 80pt rubrics inline. The "harness value unclear" reason was conservative — wrapping costs 10 min and adds a pre-render check on Mermaid syntax / nanobananapro prompt-quality, which has real value. Low risk.

2. **Wrap sf-ui-autonomous when its library has a flow.** This requires user signal (a captured flow in `library/library.json`) before the rubric can grade against anything.

3. **Run the positive-detection sf-apex pilot** (still in morning handoff §10 #3 as the highest-data-value remaining work). Mutate the Stage B fixture's `CI_SponsorChildAction.cls` to introduce a SOQL inside a for-loop, re-spawn the evaluator subagent, verify it returns ITERATE with a Correctness hard-fail breach. ~30 min, validates that the harness rules actually fire in the positive direction (not just that they don't false-positive on clean code).

Otherwise, the rollout is complete enough to push when the user is ready.

---

## End of afternoon handoff
