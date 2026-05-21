# Eval feedback for iteration 2

The demo runs end-to-end on `cool stuff` and all four wow moments fire correctly. Three gaps were identified in fresh-context grading that pulled the 4-dimension quality score to 77/100 (3 points below the 80% SHIP floor). No hard-fail floor breached. Test rubric (unit / integration / smoke) all pass.

The gaps below are descriptions of what is missing or inconsistent — not fix recipes. Choose the path that makes the demo presenter-ready while staying inside the SPEC's out-of-scope list.

---

## Gap 1 — `CI_SponsorChildAction` is not bulk-safe, contradicting the IMPL-NOTES claim

The class implements `sponsor()` as a `for` loop dispatching to `sponsorOne()`. Each iteration of `sponsorOne()` issues 1 SOQL (Child__c lookup) + 4 DML (insert GC, insert Schedule, insert 12 Txns, update Child). Verified live: `BULK2_LIMITS|deltaSOQL=4|deltaDML=8` for a 2-request invocation — perfect N+1.

Why this matters: IMPL-NOTES Phase 5 explicitly says "Bulk-safe (single SOQL/insert per type, no DML in loops)". The 4-dim Performance criterion in SPEC §5 grades exactly this property: "the GiftCommitment-save automation that produces 12+ schedule rows + the first transaction is bulk-safe (single transaction, no SOQL inside loops)". The demo path itself runs at N=1 and won't trip governor limits, but the rubric is graded against the **claim**, not the demo path.

The mismatch is: IMPL-NOTES says one thing; the bytecode does another. Either the IMPL-NOTES claim becomes accurate (the class refactors to gather all child Ids, do one bulk SOQL, batch the inserts), or the IMPL-NOTES claim is corrected to "demo-path-only, bulk invocation will N+1" so future readers (sf-demo-playwright generator, presenter-guide author, downstream skill consumers) don't propagate a false guarantee.

## Gap 2 — Sponsor invocable allows duplicate active commitments for the same donor + child

Calling `CI_SponsorChildAction.sponsor(...)` twice with the same `donorId` + `childId` produces two active GiftCommitments. There is no SOQL pre-check for an existing active commitment between the same donor and child, no validation rule on GiftCommitment, and no guard in the screen flow.

Why this matters: SPEC §5 Robustness criterion (c) is verbatim "Re-running step 5 with a duplicate donor lookup does not double-create commitments." Today it does. For the live presenter the risk is small (the click path runs once), but a demo dry-run that didn't reset cleanly between rehearsals will silently leave Margaret on a phantom second commitment to Daniel. Worse, after step 6 nobody catches it because the related list shows both.

The fix surface is small (one SOQL + one early return + a graceful flow message), but the gap is real. Either implement the guard, or surface this in IMPL-NOTES as an acknowledged demo-only constraint with a documented "how to spot it during rehearsal" note.

## Gap 3 — `expected_visible: 'Scheduled'` does not appear on the demo's screen at step 6

`GiftTransaction.Status` picklist values in NPC are `Unpaid`, `Paid`, `Failed`, `Fully Refunded`, `Written-Off`, `Canceled`, `Pending` (verified by `Schema.DescribeFieldResult` would enumerate these). There is no "Scheduled" value. The seeded transactions have `Status='Unpaid'` with future-dated `TransactionDate`.

The click-path step-6 lists `expected_visible: ['Gift Commitment', 'Gift Commitment Schedule', 'Gift Transaction', '12 installments', 'Scheduled']`. When the presenter pauses on step 6 and the audience scans the related list of GiftTransactions, every row says `Unpaid`. The literal string "Scheduled" only appears in flow confirmation copy, which is a transient toast/screen, not the persistent record-page surface the click-path implies.

IMPL-NOTES Ambiguity #2 frames this as a SPEC ambiguity ("scheduled status"), but the click-path's expected_visible array is unambiguous about the literal string. Three legitimate paths: (a) add a formula field on GiftTransaction whose value is "Scheduled" when Status=Unpaid AND TransactionDate>TODAY, surfaced on the related list column; (b) update the demoscript narration to call out "Unpaid (future-dated)" instead of "Scheduled" and update click-path expected_visible accordingly; (c) raise it as a SPEC-DEFECT against the click-path contract because the upstream `wow-moment-delivery.json` narration uses "Schedule" / "scheduled" in three places that don't survive translation to NPC's picklist values.

Note: option (c) requires the planner subagent. Options (a) and (b) are self-implementable.

---

## Gaps that are NOT blocking but worth noting

- **Margaret donor lookup is hardcoded to a single account.** Caveat #1 in IMPL-NOTES acknowledges this. The screen flow defaults `Donor=Margaret Hartwell` instead of presenting a free Account lookup. For the scripted demo path it's invisible; for any reuse with a different donor it's broken. SPEC AC-2.3 requires a "Donor lookup" not a hardcoded default. The presenter-guide should probably surface this as "if a customer asks 'can I pick a different donor?', here's the flow snippet to adjust".
- **Empty-state on Transfer when no Available children at the same site.** `Get_Available_Children` returns an empty list; the flow's branch on empty is not verified. Low-likelihood for the scripted path (Sarah is seeded as Available at the same site as Daniel), but a Transfer rehearsal that runs after the demo without a reset would land here.
- **No `System.runAs(Aisha)` / `System.runAs(Joseph)` end-user simulation.** Everything ran in admin context. The skill's Approach B (deploy `@IsTest` class with `runAs`) wasn't exercised. The 19/20 E2E score reflects this. For a presenter-ready validation it's not strictly required (sf-demo-playwright handles user-context UI runs downstream), but if real perm-set FLS or sharing rule blocks Aisha or Joseph from a step the demo will surface that live, not in validation.

---

## What does NOT need to change

- The Person Account substitution for Margaret is correct. SPEC AC-2.4 explicitly hedges. Don't undo it.
- The Flow + Apex Invocable pattern for sponsor/transfer is fit-correct (Flow surfaces the screen UX, Apex handles the multi-record DML atomically). Don't move to a pure-trigger pattern.
- The CI_GiftCommitment_Cancel_Routes_Task record-triggered flow is the right choice over an Apex trigger. Don't move it to Apex.
- All 7 seed records and the queue + queue membership are correct as deployed.

---

## How to know iteration 2 is good

The next implementer pass should produce evidence that:

1. Bulk invocation of `CI_SponsorChildAction.sponsor(List<Request>)` with N requests produces SOQL / DML usage that scales sub-linearly with N (i.e., 1-2 SOQL + 4 DML regardless of N, or at minimum a documented bound like 2N SOQL with a stated rationale). Demonstrate with a 5-request invocation showing measured `Limits.getQueries()` and `Limits.getDmlStatements()` deltas.
2. Re-invoking sponsor with the same donor+child either no-ops or returns an explicit "already sponsored" response, leaving exactly one active GiftCommitment between that donor+child pair. Demonstrate with a duplicate-call test.
3. The demoscript step-6 expected_visible is reconciled with the org's actual picklist values — either by the formula-field approach surfacing literal "Scheduled" on the related list, or by updating the click-path/expected_visible to match the platform's "Unpaid" picklist value with appropriate narration.

If all three are addressed, the 4-dim score should clear 80% and SHIP.
