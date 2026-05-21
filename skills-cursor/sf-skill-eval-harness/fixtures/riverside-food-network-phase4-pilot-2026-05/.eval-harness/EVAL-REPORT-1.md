# EVAL-REPORT-1 — Phase 4 Pilot (Riverside Food Network demoscript)

**Iteration:** 1
**Evaluator:** fresh-context subagent (sf-skill-eval-harness)
**Verdict:** **SHIP**
**Quality:** 95/100 (95.0%)
**Hard-fail breaches:** none

---

## 1. Verdict

**SHIP.** All four hard-fail dimensions clear their floors with substantial margin. Schema validation passes (6/6 contracts + link integrity). Independent reconstructions of coverage matrix and POV ratio match the implementer's claims with zero divergence. All 3 wow moments pass Janet's "staff time saved" audience test with quantified time arithmetic (78 hrs/yr Carla; Devon's Tuesdays back; 5-10 day → next-morning lead time). Two minor blemishes flagged (cheat-sheet step-sum arithmetic error; REQ-001 narration_beat sequencing) but neither breaches a floor or AC.

---

## 2. Four-Dimension Scorecard

### Requirement_Coverage_And_Depth — 24/25 (floor 18) PASS

**Evidence quoted from artifacts:**
- All 3 `must_demo: true` requirements have `demonstration_quality: "primary"` in `requirement-coverage.json`:
  - `"requirement_id": "REQ-001", "covered_by_steps": ["step-2", "step-3", "step-4", "step-5"]`
  - `"requirement_id": "REQ-002", "covered_by_steps": ["step-6", "step-7", "step-8", "step-9"]`
  - `"requirement_id": "REQ-003", "covered_by_steps": ["step-5", "step-10", "step-11", "step-12"]`
- Each requirement's `covered_by_steps` length (4) meets or exceeds the matching `value_moments[].min_steps: 4`.
- `uncovered_requirements: []`.
- Sum of covered-by-steps across the 3 must_demos sits inside the 9-12 standard tier band.

**-1 deduction:** `value-moments.json` REQ-002 entry declares `"end_user_pov_steps": 3, "admin_pov_steps": 1` — but the actual click-path has zero admin steps for REQ-002 (steps 6-9 are all `pov: end_user`). The value-moments planning estimate doesn't match the click-path reality. Internal inconsistency, not a coverage drop.

### Wow_Moment_Delivery — 23/25 (floor 12) PASS

**Evidence quoted from artifacts:**
- All 3 deliveries in `wow-moment-delivery.json` have all four beats populated:
  - REQ-001: pain=step-1, watch=step-3, moment=step-5, narration=step-6
  - REQ-002: pain=step-1, watch=step-7, moment=step-8, narration=step-9
  - REQ-003: pain=step-1, watch=step-10, moment=step-10, narration=step-11
- Beat ordering verified by indices: `0 < 2 ≤ 4 < 5`, `0 < 6 ≤ 7 < 8`, `0 < 9 ≤ 9 < 10`. All three pass AC-18.
- Each delivery quotes Janet-grade, time-quantified narration: REQ-003 narration `"That red Protein tile told Carla in three seconds what used to take her 90 minutes to discover ... 78 hours of Carla's time a year. Janet — that is the staff time saved you came to see."`

**-2 deduction:** REQ-001's `narration_beat` is anchored at step-6 (`"Same portal, different user. This is the volunteer side..."`). The narration text in the JSON describes the Tuesday-morning routing reveal — content that visually lands in step-5, not step-6. Step-6 is the volunteer pivot, not the Carla-Tuesday narration. A presenter following the JSON beat-mapping verbatim would deliver the narration over the volunteer-portal screen, weakening the moment. Minor but real sequencing defect.

### End_User_POV_Ratio — 25/25 (floor 12) PASS

**Evidence — independent re-tag from step descriptions only:**

| Step | Description (truncated) | My re-tag | Implementer tag |
|---|---|---|---|
| 1 | "Opening narrative — set the three pains" | narrative | narrative |
| 2 | "Maria... signs into the Riverside Partner Portal" | end_user | end_user |
| 3 | "Maria clicks 'Request Distribution.' The portal opens..." | end_user | end_user |
| 4 | "Devon's NPSP Lightning Console... 'Inbound Partner Requests' list view" | end_user | end_user |
| 5 | "Carla's Distribution Plan dashboard..." | end_user | end_user |
| 6 | "Jordan Mendez (volunteer)... logs into the Volunteer side" | end_user | end_user |
| 7 | "Jordan clicks Reschedule on her Saturday shift" | end_user | end_user |
| 8 | "back to Devon... open Case is already in his queue" | end_user | end_user |
| 9 | "Devon opens the no-show Case" | end_user | end_user |
| 10 | "Carla. Monday morning. We open her Distribution Plan dashboard cold" | end_user | end_user |
| 11 | "Carla clicks the 'Unfilled Volunteer Slots' tile" | end_user | end_user |
| 12 | "Carla clicks the red Protein tile" | end_user | end_user |

- **Re-computed ratio (mine):** 11 end_user / 0 admin / 0 mixed / 1 narrative.
- Among non-narrative (11 steps): 100% end_user, 0% admin.
- Implementer's claimed ratio: identical. **Zero divergence.**
- Far above the 60% end_user floor; far below the 20% admin ceiling.
- `grep '/lightning/setup/'` against `click-path.json` and `demoscript.md`: zero hits (AC-19 + S-4 pass).

### Click_Path_Fidelity_And_Data_Contract — 23/25 (floor 13) PASS

**Evidence quoted from artifacts:**
- Schema validator output: `OK: 6 contract(s) valid, link integrity OK`.
- UI labels are real Salesforce surfaces: `"Request Distribution"` CTA, `"Inbound Partner Requests"` list view (`filterName=Inbound_Partner_Requests`), `"Distribution Plan — This Week"` dashboard, `"Volunteer No-Shows"` list view, NPSP toast pattern `div.toastMessage:has-text(...)`.
- NPSP-only object names used throughout (`Account` with `npe01__SYSTEMIsIndividual__c`, `Contact`, `Case` with `RecordType.DeveloperName='Partner_Request'|'Volunteer_NoShow'`, `Volunteer_Shift_Assignment__c`). `grep` for NPC objects (`PersonAccount|GiftTransaction|ApplicationForm|JobPositionShift|ProgramEnrollment`) returns zero hits across demoscript and all six contracts (AC-24 PASS).
- Realistic Oregon partner names: `Centro Latino de Hillsboro`, `Bethany Hills Family Pantry`, `Mercado de la Familia — North Portland`, `Forest Grove United Methodist Pantry`. The Maria-anchored Latino community pantry is honored. Zero placeholder regex matches.
- Teardown targets `@demo.` domains only (AC-27 pass): `delete [SELECT Id FROM Account WHERE Name IN ('Centro Latino de Hillsboro', ...)`.

**-1 deduction:** Cheat-sheet arithmetic error. Per-step time budgets sum to 1,220 sec (90+90+120+90+150+90+90+90+120+90+90+110), but the cheat-sheet declares `"Total | | | 1,320 sec (22 min)"`. The grand-total of 1,800 sec still reconciles because Q&A buffer (270) + opening/closing (210) absorbs the gap, but the steps-row arithmetic is off by exactly 100 seconds. AC-29 grand-total still passes; line-item total is wrong.

**-1 deduction:** REQ-001 narration_beat sequencing (already counted under Wow_Moment_Delivery). Treating the same defect under both dimensions would double-charge — keeping the deduction here for the click-path-side observation only: the click-path step-5 talking-points block carries the Tuesday-morning narration, but the wow-moment-delivery JSON points narration_beat at step-6. The talking-points text and the JSON beat-mapping diverge.

---

## 3. Test Rubric

| Test | Result | Evidence |
|---|---|---|
| Unit (U-1 to U-7) | **PASS** | `validate-contracts --strict`: `OK: 6 contract(s) valid, link integrity OK`. Demoscript YAML frontmatter parses; required keys present (`demo_duration_minutes: 30`, `demo_duration_tier: standard`, `target_step_runtime_seconds: 130`, `users[]` with 4 personas). |
| Integration (I-1 to I-8) | **PASS** | Set equality on `requirement_id` between `requirements.json` (3 must_demo) and `value-moments.json` (3 entries) and `wow-moment-delivery.json` (3 deliveries). All step-id FKs resolve. Per-requirement `covered_by_steps` length ≥ `min_steps`. POV ratio 100%/0% (within 60%/20% policy). Beat ordering valid for all 3 deliveries. |
| Smoke (S-1 to S-6) | **PASS** | S-1: 4-phase narrative reconstructable (pain step-1 → struggle step 2,4 → wow steps 5/8/10 → resolution steps 9/12). S-2: at least 2 distinct staff-time framings ("90 minutes every Monday → 30 seconds; 78 hrs/yr Carla", "3-hour Tuesday → 4-click triage", "transcription robot dies"). S-3: zero placeholder name matches. S-4: zero `/lightning/setup/` URLs. S-5: every persona alias used in steps appears in `users[]`; Janet does not. S-6: REQ-001 wow_moment description contains both "Monday" and "Tuesday" + "Truck Route 3" mapping artifact. |

---

## 4. Independent Reconstruction Findings

### Reconstruction A — Coverage matrix (from notes.md + demoscript prose only)

| Requirement | My reconstructed coverage | Implementer's claim | Diff |
|---|---|---|---|
| REQ-001 (Partner Portal) | step-2, step-3, step-4, step-5 | step-2, step-3, step-4, step-5 | 0 |
| REQ-002 (Volunteer + No-Show) | step-6, step-7, step-8, step-9 | step-6, step-7, step-8, step-9 | 0 |
| REQ-003 (Distribution Dashboard) | step-5, step-10, step-11, step-12 | step-5, step-10, step-11, step-12 | 0 |

Step-5 plausibly serves both REQ-001 (truck-route routing arrival) and REQ-003 (Carla's dashboard view). The implementer claims step-5 against both — defensible because the screen literally shows both stories simultaneously. **Zero divergence.**

### Reconstruction B — POV ratio (from step descriptions only)

My computation matches implementer's exactly: 11 end_user / 0 admin / 0 mixed / 1 narrative → 100% end_user, 0% admin among non-narrative. **Zero divergence; no SPEC-DEFECT signal.**

---

## 5. Faithfulness Findings (notes.md → requirements.json)

- **Source quote spot-checks:**
  - REQ-001 quote (line 17): notes line 17 reads `The "wow" is supposed to be: a partner submits a request at 9am Monday...` — verified verbatim.
  - REQ-002 quote (line 23): notes line 23 reads `They want volunteers to sign up via the same portal as partners (different user license)...` — verified verbatim.
  - REQ-003 quote (line 30): notes line 30 reads `"I want to walk in Monday morning, look at one screen, and know if I'm short on protein for Thursday."` — verified verbatim.
  - REQ-004 quote: matches notes line 35.
  - REQ-005 quote: matches notes line 55.
- **No requirement was hallucinated.** All 5 requirements trace to notes content.
- **No must_demo requirement was dropped.** All three pain-attributed use cases from notes (Partner Portal, Volunteer Self-Service, Distribution Dashboard) became must_demo:true. Donor Receipt and Tableau correctly marked must_demo:false per notes' explicit framing.
- **Devon's "transcription robot" pain quote** (notes line 18) is folded into REQ-001's `summary` field, not its `source_quote` field. Acceptable — the wow-callout quote takes the source-quote slot per the planner's rules in AC-2 (a). The transcription-robot quote then surfaces in `value-moments.json` as `persona_pain_quote: "I want to stop being a transcription robot."` — its proper home.

**Verdict on faithfulness:** Clean. No drops, no hallucinations.

---

## 6. Wow-Moment Audience-Test Findings (Janet's bar)

| Wow | Janet test framing in talking points | Pass? |
|---|---|---|
| REQ-001 | Step 3: `"That round-trip used to take 5 to 10 days. We just did it in 90 seconds. That's a Devon time saved moment"`. Step 5: `"That's hours back in Devon's week. Every week."` | **PASS** — quantified time, named staff, no feature breadth. |
| REQ-002 | Step 8: `"the 15-20% no-show rate translated into 'Devon's Tuesdays back.'"`. Step 9: `"3-hour Tuesday → 4-click triage. ... That is the 90 minutes — sorry, the *3 hours* — Devon got back this Tuesday."` | **PASS** — quoted-from-discovery numbers, Devon-named outcome. |
| REQ-003 | Step 10: `"That red tile told Carla in three seconds what used to take her 90 minutes to find. ... 78 hours of Carla's time back per year. That is the staff time saved you came to see."` | **PASS** — strongest framing in the demo; ties directly to Carla's exact 90-minute notes quote. |

All three wows pass Janet's bar with explicit time-arithmetic. None resort to "look how pretty this is" generic ROI handwaving.

---

## 7. Data Fidelity Findings

- **Oregon-flavored realistic names** (AC-23): all four partner agencies (Centro Latino de Hillsboro / Bethany Hills Family Pantry / Mercado de la Familia — North Portland / Forest Grove United Methodist Pantry) are plausible Oregon nonprofits with real Oregon addresses (zip codes 97123, 97006, 97217, 97116 are all valid Oregon zips). Personas (Maria Castillo, Jordan Mendez, Marcus Halloran, Carla Rivera, Devon Park) read as realistic. The Maria-anchored Latino community pantry is explicitly honored ("Centro Latino de Hillsboro").
- **NPSP-only object compliance** (AC-24): zero NPC-only object names anywhere. `grep -E 'PersonAccount|GiftTransaction|ApplicationForm|JobPositionShift|ProgramEnrollment'` against demoscript.md and all 6 JSON files returns zero matches.
- **No orphan UI references** (AC-21): every record name appearing in click-path step descriptions has a matching `data-requirements.json` record. `Mercado de la Familia` and `Forest Grove United Methodist` appear only in `referenced_by_steps: ["step-5"]` for the dashboard "Partner Requests count: 7" tile background — defensible (they populate the counter without being individually narrated).
- **No orphan records** (AC-22): every record entry has non-empty `referenced_by_steps[]` and every referenced step exists in click-path.

---

## 8. What Self-Evaluation Would Have Missed

I'm being honest here: this is a clean run. Two real defects emerged that the implementer's IMPL-NOTES did not surface:

1. **REQ-001 narration_beat is mis-anchored.** The wow-moment-delivery JSON places `narration_beat` at step-6, but the narration text describes the Tuesday-morning routing reveal — content that visually lands in step-5. Step-6 is the persona pivot to Jordan. A presenter who follows the JSON literally would deliver the narration during the volunteer-portal screen transition, weakening the moment. The demoscript step-5 talking-points block already carries this narration, so the visual reading works — but the JSON contract itself is misaligned. Self-evaluation tends to miss this kind of "the prose is right but the contract pointer is wrong" defect because the demoscript reads correctly end-to-end.

2. **Cheat-sheet arithmetic error.** Per-step time budgets sum to 1,220 sec, but the cheat sheet's `Total` row claims 1,320 sec — off by 100 seconds. The grand total still lands at 1,800 because the Q&A buffer absorbs the gap, but the line-item total is wrong. The implementer's IMPL-NOTES claim "Janet's audience test honored" — true — but did not recheck the cheat-sheet arithmetic.

3. **value-moments.json REQ-002 internal inconsistency.** The value-moment declares `end_user_pov_steps: 3, admin_pov_steps: 1`, but the actual REQ-002 click-path coverage (steps 6-9) is 4× end_user / 0× admin. The planning estimate doesn't match the delivered click-path. Self-evaluation would not catch this without the side-by-side reconstruction the harness forces.

None of the three breach hard-fail floors. The first is the most important — a presenter following the JSON beat-mapping verbatim would underdeliver the REQ-001 wow.

---

## 9. Adjudication

### Planner's distribution-dashboard ruling

The planner ruled REQ-003 (Distribution Dashboard) `must_demo: true`. Verified: `requirements.json.requirements[2]` is REQ-003 with `must_demo: true`, fully built out across steps 5/10/11/12 with primary coverage and a 4-beat wow delivery. **Honored.**

### Implementer's flagged AC-2 / AC-11 tension

The implementer flagged a SPEC tension: AC-2 read strictly as "every qualifying bullet → exactly one must_demo requirement" would force ≥5 must_demo requirements, which against the schema floor of `min_steps: 4` and AC-11's 9-12 step ceiling is mathematically infeasible (5 × 4 = 20 > 12). The implementer resolved by interpreting AC-2 at use-case granularity (matching AC-4's enumeration of three named use cases), consolidating multiple qualifying bullets within a use case into a single requirement.

**My adjudication:** the implementer's resolution is correct. AC-4 explicitly enumerates "the following three pain-quoted use cases each produce a `must_demo: true` requirement" — that is the binding test, and it implies use-case-level granularity. AC-2's strict per-bullet reading is not internally consistent with AC-4's per-use-case enumeration nor with AC-11's step-band ceiling against the schema's min_steps floor. The implementer chose the only interpretation under which the SPEC is self-consistent. **Not a SPEC-DEFECT — surface for spec-author awareness.** A future SPEC iteration could clarify AC-2 to say "each use case in the notes' 'What they want to show' subsections that has at least one of (pain quote / current-state cost / wow callout) produces exactly one must_demo requirement" — the per-use-case wording — to close the ambiguity.

---

## 10. Critical Gaps

None. All four hard-fail floors clear with margin (24/18, 23/12, 25/12, 23/13). All schema validations pass. Reconstructions match. No SPEC-DEFECT signal.

---

## 11. Remediation

Verdict is **SHIP**, no remediation file written. The three defects above are below the bar to require an iteration — they're "polish-pass" observations, not gap-closers.

For documentation only: if this were ITERATE, the gaps to surface would be:
- REQ-001 narration_beat is anchored at step-6 but its narration content describes step-5's screen.
- Cheat-sheet steps-row total claims 1,320 sec but actual sum is 1,220 sec.
- value-moments.json REQ-002 `admin_pov_steps: 1` does not match the click-path's zero admin steps for that requirement.

---

## 12. Confidence

**High.** I verified every implementer claim against the artifacts:
- Schema validation output reproduced directly via the harness CLI.
- POV re-tag done from step descriptions only, in fresh context, with zero reference to the implementer's `pov` tags.
- Coverage matrix rebuilt from notes + demoscript prose, then compared to `requirement-coverage.json`.
- Source quotes spot-checked against `notes.md` line numbers — all verbatim.
- Beat ordering verified by computing step indices in click-path.
- Janet test verified via grep for time-arithmetic substrings.
- Setup-URL prohibition verified via grep.
- NPC object prohibition verified via grep.

I did not have to take any IMPL-NOTES claim on faith — every claim was independently verifiable from the artifacts.
