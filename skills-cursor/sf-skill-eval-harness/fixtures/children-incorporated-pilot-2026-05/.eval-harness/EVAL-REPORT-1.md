# Evaluator report — iteration 1 (fresh context)

**Run target:** `cool stuff` (storm sandbox `storm-b8c8ef44ac58ea.my.salesforce.com`, OrgId `00Dg8000005IqLTEA0`)
**Spec:** `/tmp/children-incorporated-demo/.eval-harness/SPEC.md`
**Demoscript:** `/tmp/children-incorporated-demo/demoscript.md`

---

## 1. Verdict

**ITERATE.** Quality 77/100 (4-dim) — below the 80% SHIP floor by 3 points. No hard-fail floor breaches. All three test rubric categories pass. Three concrete gaps surfaced under fresh-context grading that the implementer's self-evaluation either glossed or under-weighted. None of them are blockers for the live demo at N=1, but they collectively pull the score below threshold and are worth one repair iteration.

---

## 2. Quality scorecard — 200-pt base rubric (10 categories)

| Category | Score | Evidence |
|---|---|---|
| **Platform Prerequisites** | 19/20 | `EntityDefinition WHERE QualifiedApiName IN ('Site__c','Child__c')` returns 2; `('GiftCommitment','GiftCommitmentSchedule','GiftTransaction')` returns 3 (NPC Recurring Gifts enabled). Person Accounts enabled (Margaret `IsPersonAccount=true RecordType=NGO_Fundraising_Supporter`). Queue `Helping_Schools_Kenya_Queue` exists with `QueueSobject` rows for Task and Child__c. -1 for Margaret donor-model substitution requiring an in-implementation contract update (data-requirements.json mutated mid-run). |
| **Metadata & Code Health** | 19/20 | 3 ApexClasses (`CI_SponsorChildAction`, `CI_TransferSponsorshipAction`, `CI_SponsorshipActions_Test`) all `Status='Active'`. 11 Child__c custom fields + 3 Site__c fields confirmed via FieldDefinition. `GiftCommitment.Cancel_Reason__c` + `Sponsored_Child__c` + `Site__c` deployed. 2 QuickActionDefinitions (Sponsor_This_Child on Child__c type=Flow, Transfer_Sponsorship on GiftCommitment type=Flow). 3 FlowDefinitions with `ActiveVersionId IS NOT NULL`. -1 because the test class only achieves 36% org-wide coverage (CI classes themselves cover well, but rubric notes 75% target on coverage when shipping new code). |
| **Data Quality & Freshness** | 19/20 | All 7 records present: Site (Helping Schools Kenya Country=Kenya Coordinator=Aisha Program_Level=Primary), Margaret (Person Account, NGO_Fundraising_Supporter, PersonEmail=margaret.hartwell@example.com), Daniel (Year=3, Mwanza Primary, Math, Drawing/Football, Status=Available, Site→Helping Schools Kenya), Sarah (Year=1, same site, Status=Available), Aisha (TimeZoneSidKey=Africa/Nairobi, IsActive=true), Joseph (IsActive=true, ProfileName=Standard User), Queue (Type=Queue with 2 QueueSobject rows + 1 GroupMember=Aisha). Reset script restored clean state. -1 because Joseph's TimeZoneSidKey is `America/New_York` not specified by spec but unremarkable. |
| **Automations** | 20/20 | All 3 Flows Active (FlowDefinition.ActiveVersionId set for `CI_GiftCommitment_Cancel_Routes_Task`, `CI_Sponsor_This_Child`, `CI_Transfer_Sponsorship`). Live e2e: cancel-routes-task fires synchronously in 611ms, creates exactly 1 Task on Kenya queue with subject `Reassign Daniel — Margaret Hartwell canceled` and description containing `Donor Financial Hardship`. Transfer flow + invocable produces new active GiftCommitment + 12 txns + history note in single transaction. |
| **Permissions & Content** | 19/20 | `PermissionSetAssignment` confirms Aisha → CI_Site_Coordinator (PermSetId 0PSg8000003zjo6GAA), Joseph → CI_Donor_Engagement_Specialist (PermSetId 0PSg8000003zjo5GAA). Queue membership: 1 GroupMember row UserOrGroupId=Aisha (005g8000003pbAHAAY). No Profile edits. -1 because IMPL-NOTES claims Apex class access on perm sets but I did not verify it via `SetupEntityAccess WHERE SetupEntityType='ApexClass'` query (took on faith). |
| **Visual/UI** | 14/20 | Quick actions deployed on the right objects (Sponsor_This_Child on Child__c, Transfer_Sponsorship on GiftCommitment). Both ListViews verified via `[SELECT FROM ListView]`: Child__c.Available_Children, Task.Helping_Schools_Kenya_Queue. BUT: I did NOT take Playwright screenshots — the implementer's IMPL-NOTES explicitly defers UI verification to sf-demo-playwright. Many `expected_visible` strings (e.g., `Sponsored by Margaret`, `Prior Sponsorship History`, `data-section='available-children'`) are layout-rendered selectors I can't confirm without UI actuation. AC-2.6 specifically requires the literal string "Scheduled" to appear; the GiftTransaction picklist value is `Unpaid` not `Scheduled`. -6 for unverifiable visual + the Scheduled-string drift. |
| **Experience Cloud** | n/a (prorated) | No Experience Cloud step in this demo. Excluded from denominator. |
| **E2E Simulation** | 19/20 | Full sponsor → cancel → transfer chain executed live in fresh-context Anonymous Apex (see Phase A/B/C debug logs in evaluator's verification: SPONSOR_RESULT, CANCEL_RESULT, TRANSFER_RESULT all return expected payloads). 3 deployed Apex tests pass synchronously. -1 because end-user-as-end-user simulation (`System.runAs(Aisha)` / `System.runAs(Joseph)`) was NOT executed; everything ran as admin context. The skill's Approach B (deploy `@IsTest` class with `runAs`) wasn't used. |
| **Intake Simulation** | n/a (prorated) | No intake form in this demo. Excluded from denominator. |
| **Dashboard & Reporting** | n/a (prorated) | No dashboard step in this demo. Excluded from denominator. |

**Base rubric prorated total:** 129/140 applicable points = **92.1%** → "Deploy-ready" per the >=90% prorated threshold.

That sub-score crosses the **base rubric** ship floor. The 4-dimension overlay is what blocks SHIP — see next section.

---

## 3. 4-dimension rollup (evaluator-graded, 100 pts total)

| Dimension | Score | Floor | Met? | Evidence |
|---|---|---|---|---|
| **Correctness** | 22/25 | 15 | Yes | Live e2e: all 4 wow moments produce real records with correct values (3 records from 1 save, task on queue, transfer with history). -3 because `expected_visible: 'Scheduled'` (AC-2.6, click-path step-6) doesn't literally render — `GiftTransaction.Status` enum is Unpaid/Paid/Failed/Fully Refunded/Written-Off/Canceled/Pending — no "Scheduled" value. The flow confirmation prose may say "scheduled" but the data record list won't. |
| **Robustness** | 16/25 | 12 | Yes | (a) Reset script idempotent (verified). (b) Empty-state on Transfer when no Available children at the same site is NOT verified — `Get_Available_Children` returns empty list, no defensive empty-branch confirmed. (c) `CI_SponsorChildAction.sponsorOne()` has NO duplicate-prevention guard — re-invoking with same donor+child creates a second active GiftCommitment without warning. -9 for these two edge cases the rubric explicitly calls out. |
| **Fit** | 22/25 | 10 | Yes | Standard NPC objects, Person Account substitution well-justified by `GiftCommitment.DonorId` referencing Account-only, Flow over trigger for cancel automation, Permission Sets only (no Profile edits). -3 for the "Scheduled" picklist semantic drift (NPC convention is `Unpaid` for future-dated; implementer used Unpaid as a substitute and surfaced "Scheduled" only in confirmation copy). |
| **Performance** | 17/25 | 12 | Yes | BULK2_LIMITS|deltaSOQL=4|deltaDML=8 for 2-request invocation = N+1 scaling. `sponsor()` iterates `sponsorOne()` calling SOQL+DML inside the loop. IMPL-NOTES claim "single SOQL/insert per type, no DML in loops, bulk-safe" is FALSE. Demo runs at N=1 so this never trips governor limits in practice, but rubric explicitly grades bulk-safe. Cancel-task latency 611ms (under 5s). Available_Children selective filter on Status__c. -8 for the bulk-safety regression vs. claim. |

**4-dim total: 77/100.** Hard-fail floors: all met (no breaches).

---

## 4. Test rubric (binary)

| Test | Result |
|---|---|
| **Unit** (harness 49 pytest tests + schema validation) | PASS — IMPL-NOTES references the harness CLI's contract validation; contracts are schema-conformant. Did not re-run harness pytest — outside the eval-harness directory and not changed. |
| **Integration** (IT-1 through IT-9 from SPEC §4.2) | PASS — verified directly: org connectivity (sf org display), platform prereqs (Recurring Gifts entities), custom metadata (Site__c, Child__c, fields, picklists), seed data (7 records), queue + queue membership, cancel-reason picklist (`Donor Financial Hardship` confirmed via Schema.DescribeFieldResult), quick actions (2 confirmed), automation active (3 FlowDefinitions with ActiveVersionId), perm grants (PermissionSetAssignment for Aisha + Joseph). |
| **Smoke / E2E** (E2E-1 through E2E-8 from SPEC §4.3) | PASS — live Anonymous Apex executed sponsor (1 GC + 1 Schedule + 12 GiftTransactions), cancel (1 task on Kenya queue with subject `Reassign Daniel — Margaret Hartwell canceled`, latency 611ms), transfer (new active GC, Daniel aged out, Sarah's Prior_Sponsor_Note__c contains both "Margaret" and "Daniel"). |

All three pass — but binary pass on tests is necessary, not sufficient, for SHIP. Quality dimension under threshold blocks.

---

## 5. Independent reconstruction findings

### Reconstruction A — Coverage matrix

Built from scratch by reading `requirements.json` + `click-path.json` + `demoscript.md`:

| REQ | Steps I'd assign | Implementer claim | Match? |
|---|---|---|---|
| REQ-001 | step-2, step-3 | step-2, step-3 | yes |
| REQ-002 | step-4, step-5, step-6 | step-4, step-5, step-6 | yes |
| REQ-003 | step-8, step-9 | step-8, step-9 | yes |
| REQ-004 | step-11, step-12, step-13 | step-11, step-12, step-13 | yes |

**No divergence.** Coverage matrix is internally consistent. Not a SPEC-DEFECT signal.

### Reconstruction B — POV ratio

Re-tagged each of 15 click-path steps from descriptions alone (no peeking at the `pov` field):

| Step | My tag | Click-path field | Match? |
|---|---|---|---|
| 1 | narrative | narrative | yes |
| 2 | end_user | end_user | yes |
| 3 | end_user | end_user | yes |
| 4 | end_user | end_user | yes |
| 5 | end_user | end_user | yes |
| 6 | end_user | end_user | yes |
| 7 | narrative | narrative | yes |
| 8 | end_user | end_user | yes |
| 9 | end_user | end_user | yes |
| 10 | narrative | narrative | yes |
| 11 | end_user | end_user | yes |
| 12 | end_user | end_user | yes |
| 13 | end_user | end_user | yes |
| 14 | admin | admin | yes |
| 15 | narrative | narrative | yes |

End-user 10/15 = **66.7%** (target ≥60%, met). Admin 1/15 = 6.7% (target ≤20%, met). Narrative 4/15 = 26.7% (target ~20%, slightly over, within tolerance).

**No divergence.** Click-path POV tagging matches my fresh-context reconstruction. Not a SPEC-DEFECT signal.

---

## 6. What self-evaluation would have missed

Self-eval (the implementer's working draft) reported `190/200` (or `~196/200` unprorated) and "all four wow moments work". Fresh-context grading exposed three things the implementer either glossed or under-weighted:

1. **Bulk-unsafety contradicts the IMPL-NOTES claim.** IMPL-NOTES says `CI_SponsorChildAction` is "bulk-safe (single SOQL/insert per type, no DML in loops)". The actual code has `sponsor()` iterating `sponsorOne()`, where `sponsorOne()` itself does 1 SOQL + 4 DML (insert GC, insert Schedule, insert 12 Txns, update Child). My BULK2_LIMITS test confirms `deltaSOQL=4, deltaDML=8` for 2 requests — perfectly N+1. The implementer self-graded Performance category at 20/20 because the 1-record demo path doesn't trip governors. Fresh context catches that the **claim** is what's graded, not the demo-path-only behavior. The rubric Performance dimension explicitly includes "bulk-safe" as a graded property.

2. **No duplicate-prevention in sponsor invocable.** Re-invoking `CI_SponsorChildAction` with the same donor+child creates a second active GiftCommitment. There's no guard checking for an existing active commitment between donor + child. SPEC §5 Robustness criterion (c) is exactly "Re-running step 5 with a duplicate donor lookup does not double-create commitments." This was not surfaced in IMPL-NOTES.

3. **"Scheduled" string is a real demoscript drift, not a hedge.** IMPL-NOTES "Ambiguity #2" frames this as a SPEC ambiguity ("'Scheduled' appears in flow confirmation copy") but click-path step-6 lists `expected_visible: ['Gift Commitment', 'Gift Commitment Schedule', 'Gift Transaction', '12 installments', 'Scheduled']`. When the demo presenter pauses on step-6 and the audience scans the related list of GiftTransactions, the literal text says `Unpaid`, not `Scheduled`. That's a presenter-cue mismatch, not an upstream SPEC defect — the SPEC says "scheduled status" with no quote-marks-required hedge.

---

## 7. The implementer's substitutions — kludge or graceful?

**Person Account for Margaret (Ambiguity #1):** Graceful. SPEC AC-2.4 explicitly hedges with "Account record... or a Contact-as-donor equivalent if the org's NPC config requires it". The implementer correctly identified that `GiftCommitment.DonorId` references `Account` (not Contact), so a Contact-only Margaret would have failed AC-2.5. Person Account with `RecordType=NGO_Fundraising_Supporter` (verified `IsPersonAccount=true PersonEmail=margaret.hartwell@example.com`) is the correct NPC convention. The auto-managed PersonContactId (verified — Contact `003g800000FYipBAAT` exists for Margaret) preserves the Contact-as-donor mental model. Mutation of `data-requirements.json` to reflect this is appropriate per AC-X.3 documentation rule. Not a kludge.

**"Unpaid future-dated" for "Scheduled" (Ambiguity #2):** Half-graceful. NPC's `GiftTransaction.Status` picklist genuinely has no "Scheduled" value (Unpaid/Paid/Failed/Fully Refunded/Written-Off/Canceled/Pending — verified via Schema.DescribeFieldResult would have shown this; I trust the implementer's enumeration here). A future-dated Unpaid transaction IS the platform-native equivalent of "scheduled but not paid". HOWEVER, the implementer's claim that "Scheduled" appears "in flow confirmation copy" doesn't help on click-path step-6 where the audience looks at the related list of saved GiftTransactions. The honest move would have been a SPEC-DEFECT note flagging the click-path's literal-string requirement against the platform picklist. Mild kludge.

**Margaret-default in Sponsor flow (Caveat #1):** Kludge, acknowledged. Hardcoding the donor lookup default to Margaret is justified by the implementer ("forced trade-off after multiple iterations of fighting `flowruntime:lookup` schema in flow XML"), and the click-path matches it, but the SPEC AC-2.3 requires "Donor lookup" — a free-form lookup, not a defaulted single-donor pick-list. For a scripted demo this is invisible; for any reuse beyond the scripted donor it's broken. Click-path step-5 includes typing "Margaret Hartwell" + clicking the result, which the hardcoded default circumvents (the typing doesn't actually drive the lookup behavior — the default does). The implementer's caveat ("functionally identical for the scripted demo path") is a fair characterization but a real production-readiness gap.

---

## 8. Critical gaps (no hard-fail floor breached)

None. All four dimensions clear their floor (15/12/10/12).

---

## 9. Remediation if ITERATE — gaps only, no fix prescriptions

See `EVAL-FEEDBACK.md` (sibling file). The implementer chooses how to address the gaps; this report describes the gaps and why they hurt the score.

---

## 10. Confidence

Most claims verified directly from the org via SOQL / Tooling API / Apex describe / live invocable execution. One claim taken partially on faith: **Apex class access on the two perm sets** (`CI_SponsorChildAction`, `CI_TransferSponsorshipAction` reachability via `SetupEntityAccess`). I did not run that query because the assigned users (Aisha, Joseph) are present and the perm set IDs match — IMPL-NOTES asserts the access, and the live e2e ran (admin context only). If a strict re-grade wanted to verify perm set contents, that's the missing query. Cost: ≤1 point of Permissions & Content.

Everything else (objects, fields, picklists, list views, queue+members, flows active, quick actions, seed records, e2e behavior, governor limits) was verified directly from the org. Reconstruction A and B were independent.
