# EVAL-REPORT-2 — Children Incorporated Sponsorship Lifecycle Demo

**Iteration:** 2
**Date:** 2026-05-21
**Org:** cool stuff (`storm-b8c8ef44ac58ea.my.salesforce.com`, OrgId `00Dg8000005IqLTEA0`)
**Evaluator context:** fresh subagent — has NOT read EVAL-REPORT-1.md, EVAL-FEEDBACK.md, or TRACE.md

---

## 1. Verdict

**SHIP**

- 4-dimension total: **89 / 100 (89.0%)** — exceeds quality_pct_floor=80
- 10-category prorated rubric (sf-demo-validate native): see §2 — all 10 base categories applicable to this nonprofit-only demo, no cross-cloud add-ons
- All hard-fail floors met: Correctness 23/15, Robustness 22/12, Fit 23/10, Performance 21/12
- All test rubric categories pass: unit, integration, smoke
- Two independent reconstructions (coverage matrix, POV ratio) — zero divergence from declared contracts

---

## 2. Quality scorecard — 200-pt 10-category rubric (evidence-quoted)

Mapping the SPEC's 10 base sf-demo-validate categories to evidence in `cool stuff`:

| # | Category | Score | Evidence (quoted from artifact / org / live measurement) |
|---|---|---|---|
| 1 | Platform prerequisites | 19/20 | Recurring Gifts feature enabled — `GiftCommitment`, `GiftCommitmentSchedule`, `GiftTransaction` queryable. Org Description: `Connected: true`, `Api Version: 66.0`, `Instance Url: https://storm-b8c8ef44ac58ea.my.salesforce.com`. |
| 2 | Custom metadata | 20/20 | `Site__c` (`Country__c`, `Program_Level__c`, `Site_Coordinator__c`) and `Child__c` (`FirstName__c`, `LastName__c`, `Year__c`, `School__c`, `FavoriteSubject__c`, `Hobbies__c`, `Site__c`, `Status__c`) deployed and populated. Daniel record: `FirstName__c: Daniel, Year__c: 3, School__c: Mwanza Primary, Site__r.Name: Helping Schools Kenya, Status__c: Available`. |
| 3 | Seed data | 19/20 | `Helping Schools Kenya` (`Country: Kenya, Program_Level: Primary`), Daniel + Sarah both present at that site, Margaret Hartwell is a `IsPersonAccount: true` with `PersonEmail: margaret.hartwell@example.com`. Aisha (`IsActive: true, TimeZoneSidKey: Africa/Nairobi`) + Joseph users present. Daniel is demo-pristine: `COUNT(GiftCommitment WHERE Sponsored_Child = Daniel AND Status='Active') = 0`. |
| 4 | Permissions | 18/20 | `CI_Donor_Engagement_Specialist` assigned to Joseph, `CI_Site_Coordinator` assigned to Aisha (PermissionSetAssignment query). FLS on `Display_Status__c`: both perm sets `PermissionsRead: true`. No Profile edits. End-user `runAs` simulation deferred per IMPL-NOTES — acknowledged informational gap. |
| 5 | Automations | 19/20 | Flow `CI_GiftCommitment_Cancel_Routes_Task` `Status: Active, VersionNumber: 1, MasterLabel: "CI - Gift Commitment Cancel Routes Task"`. Test `cancel_routes_task_to_kenya_queue` Pass — task lands on `Helping_Schools_Kenya_Queue` after closing commitment with `Cancel_Reason__c='Donor Financial Hardship'`. |
| 6 | Visual UI | 18/20 | Quick actions deployed: `Child__c.Sponsor_This_Child` (id 09Dg8000002qStVEAU), `GiftCommitment.Transfer_Sponsorship` (id 09Dg8000002qStWEAU). `Display_Status__c` added to GiftTransactions related list on both `Gift Commitment Layout` and `Gift Commitment Schedule Layout` (Layout Metadata query confirms). |
| 7 | Experience Cloud | n/a | Not in scope (REQ-008/009/017 are `must_demo: false`). |
| 8 | End-to-end simulation | 17/20 | Apex Test Run 707g800000GsZ48: 6/6 Pass — sponsor_creates_three_records_from_one_save (838ms), transfer_repoints_commitment_and_preserves_history (1641ms), cancel_routes_task_to_kenya_queue (2013ms), 3 bulk tests pass. Live N=5: deltaSOQL=3, deltaDML=4. Live duplicate: SECOND_CALL alreadySponsored=true, SAME_ID=true. Live formula: 12/12 future-dated unpaid txns return Display_Status='Scheduled'. |
| 9 | Product-specific (NPC Recurring Gifts) | 18/20 | `GiftCommitment` uses standard `ScheduleType='Recurring', RecurrenceType='OpenEnded', NextTransactionAmount, NextTransactionDate, ExpectedTotalCmtAmount`. `GiftCommitmentSchedule` uses standard `TransactionPeriod='Monthly', TransactionInterval=12, Type='CreateTransactions'`. `GiftTransaction.Status='Unpaid'` (platform-standard). |
| 10 | Coverage + scope discipline | 19/20 | requirement-coverage.json matches reconstruction exactly; `must_demo: true` requirements REQ-001-004 covered by primary steps; REQ-005-017 explicitly out-of-scope and untouched (no Correspondence__c, no MCAE, no portal). |

**Prorated 10-cat total (excluding §7 Experience Cloud): 167 / 180 = 92.8%** → exceeds 80% (E2E-7 satisfied).

---

## 3. 4-dimension rollup

| Dimension | Score | Floor | Pass? | Evidence |
|---|---|---|---|---|
| **Correctness** | 23/25 | 15 | YES | Live duplicate test confirms one-not-two active commitments after re-invocation; `transfer_repoints_commitment_and_preserves_history` Pass shows `aged_out=true`, `Prior_Sponsor_Note__c.contains('Daniel')`, ≥12 new GiftTransactions on new commitment, ≥1 within 32 days. Display_Status formula returns `'Scheduled'` for 12/12 future-dated unpaid rows — click-path `expected_visible: ["Scheduled"]` is now truthful at runtime. |
| **Robustness** | 22/25 | 12 | YES | Live duplicate-prevention: `commitmentId=6gcg80000000jd3AAA` returned identically on first + second call, `alreadySponsored=true`, `ACTIVE_AFTER_SECOND=1`. Mixed-batch test (`dups=1, new=1`) Pass, deltaSOQL≤4 deltaDML≤5. Empty-state on Transfer when no Available children + end-user FLS `runAs` simulation: deferred per IMPL-NOTES (acknowledged informational, not blocking). |
| **Fit** | 23/25 | 10 | YES | All three NPC objects use platform-standard field values (no custom Recurring Donation lookalike). Cancellation automation is Flow (`CI_GiftCommitment_Cancel_Routes_Task` Active), not Apex trigger. Permissions via PermissionSet only (`CI_Donor_Engagement_Specialist`, `CI_Site_Coordinator`); no Profile edits. `Display_Status__c` is a Text formula with `description: "Demo-friendly status surface. Shows \"Scheduled\" for future-dated Unpaid transactions...Backing record value of Status is unchanged"` — surfaces UI without disturbing platform `Status`. |
| **Performance** | 21/25 | 12 | YES | Live N=5 anonymous Apex (outside `Test.startTest()` window): `LIVE_BULK5\|deltaSOQL=3\|deltaDML=4` — constant in N, vs. old N+1 baseline of 20 SOQL / 40 DML. Test `sponsor_bulk_5_requests_uses_constant_soql_and_dml` asserts `soqlDelta <= 4` and `dmlDelta <= 5` (Pass). Caveat: `CI_TransferSponsorshipAction.transfer()` still does `for (Request req : requests) { responses.add(transferOne(req)); }` with multiple SOQL + DML inside `transferOne` — not bulkified. For demo N=1 this is benign; flagged but not blocking. |

**Total: 89 / 100 (89.0%)** — exceeds 80% floor.
**No hard-fail breaches.**

---

## 4. Test rubric

| Category | Result | Evidence |
|---|---|---|
| Unit | **PASS** | `validate-contracts --strict` returns `OK: 6 contract(s) valid, link integrity OK`. Schema validation tests in harness already passing per SPEC §4.1. |
| Integration | **PASS** | IT-1 (org connect: Connected), IT-2 (NPC objects queryable), IT-3 (Site__c + Child__c fields deployed), IT-4 (7 seed records present), IT-5 (Helping_Schools_Kenya_Queue + Aisha membership: 1 GroupMember row), IT-6 (Cancel Reason picklist contains "Donor Financial Hardship"), IT-7 (both quick actions present), IT-8 (Flow Active), IT-9 (PermissionSetAssignments confirmed). |
| Smoke / E2E | **PASS** | Apex Test Run 707g800000GsZ48: **6/6 tests Pass** (100% pass rate, 9914ms total). Live anonymous Apex confirms N=5 bulk-safety deltaSOQL=3 deltaDML=4, duplicate-prevention SAME_ID=true ACTIVE_AFTER_SECOND=1, formula field returns `Scheduled` for 12/12 future-dated unpaid txns. |

---

## 5. Independent reconstruction findings

### Reconstruction A — Coverage matrix (rebuilt from requirements.json + click-path.json)

| Req | My reconstruction | Declared in requirement-coverage.json | Match? |
|---|---|---|---|
| REQ-001 | step-2, step-3 | `["step-2", "step-3"]` | YES |
| REQ-002 | step-4, step-5, step-6 | `["step-4", "step-5", "step-6"]` | YES |
| REQ-003 | step-8, step-9 | `["step-8", "step-9"]` | YES |
| REQ-004 | step-11, step-12, step-13 | `["step-11", "step-12", "step-13"]` | YES |

**Divergence: 0** → no SPEC-DEFECT trigger.

### Reconstruction B — POV ratio (re-tagged from click-path.json descriptions)

| Step | My re-tag | Declared | Match? |
|---|---|---|---|
| step-1 | narrative | narrative | YES |
| step-2 | end_user | end_user | YES |
| step-3 | end_user | end_user | YES |
| step-4 | end_user | end_user | YES |
| step-5 | end_user | end_user | YES |
| step-6 | end_user | end_user | YES |
| step-7 | narrative | narrative | YES |
| step-8 | end_user | end_user | YES |
| step-9 | end_user | end_user | YES |
| step-10 | narrative | narrative | YES |
| step-11 | end_user | end_user | YES |
| step-12 | end_user | end_user | YES |
| step-13 | end_user | end_user | YES |
| step-14 | admin | admin | YES |
| step-15 | narrative | narrative | YES |

**Computed ratio: 10/15 end_user (66.7%), 1/15 admin (6.7%), 4/15 narrative (26.7%).**

Compared to value-moments.json `duration_budget`:
- end_user_pov_min_pct=60 → **66.7% PASS**
- admin_setup_max_pct=20 → **6.7% PASS**
- narrative_transitions_pct=20 → 26.7% (slightly over but a soft target — narration-heavy openings/closings are normal)

**Divergence from declared POV: 0/15 (0.0%)** → no SPEC-DEFECT trigger (well below 5% threshold).

---

## 6. What self-evaluation would have missed

I came in with no prior evaluator context. Here's what I checked independently and what survived:

1. **Bulk-safety claim verified live, not just in test class.** The IMPL-NOTES claim of `deltaSOQL=3 deltaDML=4` for N=5 was reproduced in anonymous Apex *outside* the `Test.startTest/stopTest` window: `LIVE_BULK5|deltaSOQL=3|deltaDML=4`. This rules out the test-window-counter-reset measurement artifact the implementer correctly flagged.
2. **Duplicate prevention verified in live data, not just unit test.** Two back-to-back `CI_SponsorChildAction.sponsor` calls with the same `(donor, child)` returned `SAME_ID=true` and `ACTIVE_AFTER_SECOND=1`. The Response shape was correctly extended (alreadySponsored, message) without breaking the existing `commitmentId / scheduleId / transactionCount` contract.
3. **Display_Status formula deployed and works on real records.** Created a test commitment, queried 12 future-dated unpaid txns, all 12 returned `Display_Status__c='Scheduled'`. The formula matches IMPL-NOTES verbatim including `formulaTreatBlanksAs: BlankAsZero` and the description string. FLS is granted on both `CI_Donor_Engagement_Specialist` and `CI_Site_Coordinator` perm sets.
4. **Page layouts updated.** Both `Gift Commitment Layout` and `Gift Commitment Schedule Layout` have `Display_Status__c` in their `GiftTransactions` related list column set per Tooling API Layout Metadata.

**Surprises / things that survived skeptical scrutiny:**
- **CI_TransferSponsorshipAction is NOT bulkified.** Lines 630-636 of the deployed source still loop: `for (Request req : requests) { responses.add(transferOne(req)); }`. Each `transferOne` does ~5 SOQL and ~4 DML. For N=1 (the only realistic invocation path from the Transfer Sponsorship quick action) this is fine. But the IMPL-NOTES summary "bulk-safe + duplicate-guarded" only applies to `CI_SponsorChildAction`. The implementer's gap-1 narrative is precisely scoped to sponsor and doesn't claim transfer is bulkified. Not blocking — flagged in §3 Performance evidence.
- **`existingByPair` over-fetches.** The duplicate-guard query uses `donor IN :donorIds AND child IN :childIds`, which fetches the cross-product, not the exact pair set. The implementer self-disclosed this in IMPL-NOTES "Honest limitations" — for screen-flow N=1 this is two rows max, harmless. The disclosure is accurate.

**What the implementer claims that I confirmed:**
- 6 tests pass: confirmed via `sf apex test run` (Test Run Id 707g800000GsZ48, 100% pass rate)
- Constant SOQL/DML in N: confirmed via independent live Apex measurement
- Duplicate returns same Id, no new records: confirmed via independent live test
- Daniel demo-pristine: confirmed via SOQL count = 0 active commitments
- All 6 contract files validate: confirmed via `validate-contracts --strict`

**Nothing the implementer claims got wrong.** The IMPL-NOTES is honest about its limitations (transfer-not-bulkified, runAs deferred, over-fetch trade-off).

---

## 7. Critical gaps

**None.** All four hard-fail floors met:
- Correctness 23 ≥ 15
- Robustness 22 ≥ 12
- Fit 23 ≥ 10
- Performance 21 ≥ 12

---

## 8. Remediation

Not applicable (verdict = SHIP). Below the bar of remediation but worth recording for the planner if this demo expands:

- **Optional polish:** bulkify `CI_TransferSponsorshipAction.transfer()` if a future use case ever calls it with N>1 (migration loaders, agent batch actions). Today's screen-flow path is N=1.
- **Optional polish:** end-user `runAs(Aisha)` / `runAs(Joseph)` test methods to confirm FLS in the actual presenter context, not just admin context. Would catch a future Profile/PermSet drift before a live demo.

These are explicitly outside the iteration-2 feedback scope and the SPEC's gating ACs — recorded so they don't get lost.

---

## Appendix — Live evidence captures

```
$ sf org display --target-org "cool stuff"
Connected, Api Version 66.0, OrgId 00Dg8000005IqLTEA0

$ sf apex test run --class-names CI_SponsorChildAction_BulkTest CI_SponsorshipActions_Test
Test Run Id 707g800000GsZ48: 6/6 Pass (100%, 9914ms)
  CI_SponsorChildAction_BulkTest.sponsor_bulk_5_requests_uses_constant_soql_and_dml             Pass 2883ms
  CI_SponsorChildAction_BulkTest.sponsor_duplicate_donor_child_returns_existing_no_new_records  Pass 1007ms
  CI_SponsorChildAction_BulkTest.sponsor_mixed_batch_some_dup_some_new                          Pass 1532ms
  CI_SponsorshipActions_Test.cancel_routes_task_to_kenya_queue                                  Pass 2013ms
  CI_SponsorshipActions_Test.sponsor_creates_three_records_from_one_save                        Pass  838ms
  CI_SponsorshipActions_Test.transfer_repoints_commitment_and_preserves_history                 Pass 1641ms

$ sf apex run --file /tmp/bulk_verify.apex   # live, outside Test.startTest window
USER_DEBUG | LIVE_BULK5 | deltaSOQL=3 | deltaDML=4

$ sf apex run --file /tmp/dup_verify.apex
USER_DEBUG | FIRST_CALL  | commitmentId=6gcg80000000jd3AAA | alreadySponsored=false
USER_DEBUG | ACTIVE_AFTER_FIRST=1
USER_DEBUG | SECOND_CALL | commitmentId=6gcg80000000jd3AAA | alreadySponsored=true
USER_DEBUG | ACTIVE_AFTER_SECOND=1
USER_DEBUG | SAME_ID=true

$ sf apex run --file /tmp/disp_status_check.apex
USER_DEBUG | SCHEDULED_COUNT=12 | TOTAL=12  (formula returns 'Scheduled' on all 12 future-dated unpaid txns)

$ python3 -m scripts.cli validate-contracts --harness-dir /tmp/children-incorporated-demo/.eval-harness --strict
OK: 6 contract(s) valid, link integrity OK

Machine verdict (4-dim, /tmp/score input):
{ "verdict": "SHIP", "quality_total": 89, "quality_max": 100, "quality_pct": 89.0, "hard_fail_breaches": [] }
```
