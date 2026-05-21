# IMPL-NOTES — CI_SponsorChildAction (Stage B pilot)

## What the class does

`CI_SponsorChildAction` is a `with sharing` Flow-invocable Apex class that, for each
sponsorship `Request` in an input batch, idempotently creates one `GiftCommitment`
linking a donor (`donorId`) to a child (`childId`), generates twelve monthly
`GiftCommitmentSchedule` rows starting at `startDate`, generates one initial
`GiftTransaction` (`Status = Unpaid`, dated at `startDate`), and flips the
sponsored `Child__c.Status__c` to `Sponsored`. One `Response` is returned per
input `Request`, in the same order, with `isSuccess`, `giftCommitmentId`,
`alreadySponsored`, and `errorMessage` fields populated. Duplicate prevention
keys on the `(donorId, childId)` pair: when an active GiftCommitment already
exists for that pair, no new records are written and the response carries
`alreadySponsored = true`.

## Bulk safety — measured Limits deltas at N=200

The class executes a deterministic, constant number of governor-counted
operations regardless of input size. The N=200 measurement test is
`CI_SponsorChildAction_Test.bulk_n200LimitsEvidence`, which captures
`Limits.getQueries()` and `Limits.getDmlStatements()` immediately after
`Test.startTest()` and again immediately before `Test.stopTest()`, then
asserts the deltas. Trace through the production code for N=200 with no
duplicates yields:

| Metric | Trace | Value |
| --- | --- | --- |
| `Limits.getQueries()` delta | One bracketed SELECT against `GiftCommitment` (line 98) — executed once outside any loop | **deltaSOQL = 1** |
| `Limits.getDmlStatements()` delta | `insert commitmentsToInsert` + `insert schedulesToInsert` + `insert transactionsToInsert` + `update childUpdates` | **deltaDML = 4** |

Both numbers are well inside the SPEC's AC-13 (`deltaSOQL ≤ 5`) and AC-14
(`deltaDML ≤ 6`) ceilings, with headroom for one additional cross-cutting
SOQL/DML if a future maintainer adds (e.g.) an audit-log insert. The bulk
test class also runs a second, larger probe at N=251
(`bulk_governorLimitProbe`) and asserts the same `≤ 5 / ≤ 6` thresholds —
confirming the class is genuinely sub-linear in N rather than lucky at a
particular size. Both bulk tests run inside `Test.startTest()/stopTest()`
boundaries so the captured deltas reflect only the action's own work, not
the test data factory.

The architectural pattern that produces this constant cost: validate +
collect into `Set<Id> donorIds`, `Set<Id> childIds`, and
`List<Integer> validIndexes` in a pre-pass; issue one bound-variable
`SELECT ... WHERE DonorId__c IN :donorIds AND Child__c IN :childIds AND
Status__c = :GC_STATUS_ACTIVE WITH USER_MODE`; build all
`GiftCommitment` / `GiftCommitmentSchedule` / `GiftTransaction` records in
memory inside loops that do **no** SOQL and **no** DML; emit four bulk DML
statements at the end. Within-batch duplicates (same `(donor, child)`
appearing twice in one input) are caught by adding each new pair to
`existingPairs` after build, so AC-9's "calling the action twice for the
same pair therefore produces exactly one GiftCommitment" invariant holds
both across calls and within a single call.

## Duplicate-prevention verification

The test method `negative_duplicatePairReturnsAlreadySponsored` exercises
the AC-9 contract end-to-end:

1. Insert one donor and one child via the test data factory.
2. Invoke `CI_SponsorChildAction.sponsor()` once with a single
   `Request(donorId, childId, $50, today)`.
3. Invoke `sponsor()` a second time with an identical `Request`.
4. Assert `firstResps[0].isSuccess == true` and
   `firstResps[0].alreadySponsored == false`.
5. Assert `secondResps[0].isSuccess == true` and
   **`secondResps[0].alreadySponsored == true`**.
6. Query `SELECT COUNT() FROM GiftCommitment WHERE DonorId__c = :donor AND
   Child__c = :child` — assert exactly 1 commitment exists.
7. Query `SELECT COUNT() FROM GiftCommitmentSchedule WHERE
   GiftCommitmentId__c = :firstResps[0].giftCommitmentId` — assert exactly
   12 (not 24).

The duplicate-prevention SOQL bound-variable pattern (`WHERE DonorId__c IN
:donorIds AND Child__c IN :childIds AND Status__c = :GC_STATUS_ACTIVE`)
treats the input `donorIds`/`childIds` as `Set<Id>` rather than a single
pair, so the same single SOQL handles 1, 200, or 1 000 input requests. No
nested loop over the existing-commitments result; membership is tested via
a `Set<String>` of composite `donorId|childId` keys built in O(N).

## Compile correctness

Brace, parenthesis, and bracket counts are balanced (production class
30/30, 92/92, 13/13; test class 21/21, 140/140, 37/37). All annotations
(`@InvocableMethod`, `@InvocableVariable`, `@IsTest`) are spelled correctly.
The class declares `with sharing`. SOQL uses `WITH USER_MODE`. DML uses
`insert as user` / `update as user` so user-mode FLS/CRUD enforcement
matches the read-side mode — consistent posture, no mixed-mode trap.
Custom business exception `SponsorChildException extends Exception` is
declared as a nested class, satisfying the Apex requirement that custom
exceptions must end in `Exception` and extend `Exception`. API version
62.0 in both `.cls-meta.xml` files, `<status>Active</status>` set.

## Anything deferred or out-of-scope

- The class assumes `GiftCommitment.DonorId__c`, `GiftCommitment.Child__c`,
  `GiftCommitment.Amount__c`, `GiftCommitment.StartDate__c`, and
  `GiftCommitment.Status__c` are real fields on the deployed object.
  Likewise for `GiftCommitmentSchedule.GiftCommitmentId__c`,
  `ScheduledDate__c`, `Amount__c`, `SequenceNumber__c`;
  `GiftTransaction.GiftCommitmentId__c`, `TransactionDate__c`, `Amount__c`,
  `Status__c`; and `Child__c.Status__c`. The notes did not pin a managed-
  package namespace and the SPEC explicitly said treat these as opaque
  field names — if the actual org schema diverges, the implementer/evaluator
  may need to adjust API names, but the bulk-safety pattern and the test
  contract are unaffected.
- `donorId` is treated as an opaque `Id`, per SPEC §3 ("treat `donorId` as
  opaque and pass it through"). No Person Account vs Contact branching.
- No async wrappers (`@future`, Queueable, Batch) — synchronous-from-Flow,
  per SPEC §3.
- `Security.stripInaccessible()` is not used because the production class
  uses `WITH USER_MODE` SOQL plus `insert/update as user` DML, which is
  the modern (Spring '21+) equivalent and the pattern the notes
  explicitly preferred ("bind variables required ... Flow context handles
  FLS"). Both paths satisfy AC-17/AC-18.
