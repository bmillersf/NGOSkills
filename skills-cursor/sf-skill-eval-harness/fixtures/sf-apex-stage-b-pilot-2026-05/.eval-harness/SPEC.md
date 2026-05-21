# SPEC — Sponsorship Apex Invocable Class

## 1. Goal

Generate a single Apex `.cls` artifact (plus its companion test class `.cls`) implementing a Flow-invocable sponsorship action that, for each request, idempotently creates one GiftCommitment, twelve monthly GiftCommitmentSchedule rows, one initial GiftTransaction, and updates `Child__c.Status__c` to `Sponsored` — under governor limits at N=200.

## 2. Acceptance criteria (falsifiable)

### Functional

- **AC-1:** The class is annotated with `@InvocableMethod` and exposes a single static method that accepts `List<Request>` and returns `List<Response>`.
- **AC-2:** The `Request` inner class declares `@InvocableVariable` fields named `donorId` (Id), `childId` (Id), `monthlyAmount` (Decimal), `startDate` (Date).
- **AC-3:** The `Response` inner class declares `@InvocableVariable` fields including (at minimum) `isSuccess` (Boolean), `giftCommitmentId` (Id), `alreadySponsored` (Boolean), and an error field (e.g. `errorMessage` String).
- **AC-4:** For each successful, non-duplicate request, exactly one `GiftCommitment` record is created linking `donorId` to `childId` with `monthlyAmount` and a start date equal to `startDate`.
- **AC-5:** For each successful, non-duplicate request, exactly twelve `GiftCommitmentSchedule` records are created, one per month, anchored at `startDate`.
- **AC-6:** For each successful, non-duplicate request, exactly one `GiftTransaction` record is created with status `Unpaid` and a date equal to `startDate`.
- **AC-7:** For each successful, non-duplicate request, the corresponding `Child__c.Status__c` is updated to `Sponsored`.
- **AC-8:** The returned `List<Response>` has exactly one entry per input `Request`, in the same order.
- **AC-9:** When a request's `donorId + childId` pair already has an active `GiftCommitment`, the response for that request has `alreadySponsored = true` and **no** new GiftCommitment, no new schedules, no new transaction, and no Child status update is created/performed for that pair. Calling the action twice for the same pair therefore produces exactly one GiftCommitment in the org.

### Non-functional — bulk safety (the core probe)

- **AC-10:** No `SOQL` query (`[SELECT ...]` or `Database.query(...)`) appears textually inside any `for` or `while` loop body in the production class.
- **AC-11:** No DML statement (`insert`, `update`, `upsert`, `delete`, `Database.insert/update/upsert/delete`) appears textually inside any `for` or `while` loop body in the production class.
- **AC-12:** No callout (`HttpRequest`, `Http.send`, `Database.executeBatch` from inside iteration) appears inside any `for`/`while` loop body.
- **AC-13:** At N=200 input requests (none duplicates), measured `Limits.getQueries()` delta between `Test.startTest()` and `Test.stopTest()` is ≤ 5.
- **AC-14:** At N=200 input requests (none duplicates), measured `Limits.getDmlStatements()` delta between `Test.startTest()` and `Test.stopTest()` is ≤ 6.
- **AC-15:** A bulk invocation at N=200 completes inside `Test.startTest()/stopTest()` without throwing `LimitException` and without exceeding any governor limit.

### Non-functional — security

- **AC-16:** The production class is declared `with sharing` (literal token `with sharing` appears on the class declaration).
- **AC-17:** Every SOQL query in the production class includes `WITH USER_MODE` (or `WITH SECURITY_ENFORCED`) — no unqualified `SELECT` statements.
- **AC-18:** Every variable interpolated into a SOQL `WHERE` clause is supplied via a bind variable (`:varName`), not by string concatenation. No `'... WHERE Id = \'' + something + '\''` patterns.
- **AC-19:** No empty `catch` block (a catch with no body or only a comment) appears in the production class.

### Non-functional — testing

- **AC-20:** A companion test class exists in the same artifact set, annotated `@IsTest`.
- **AC-21:** The test class contains at least one positive test method (happy path: single request → 1 GiftCommitment + 12 schedules + 1 transaction + Child status updated, asserted via `Assert.*`).
- **AC-22:** The test class contains at least one negative test method (e.g. invalid input, duplicate sponsorship, or missing required field) that asserts the expected error / `alreadySponsored=true` behavior.
- **AC-23:** The test class contains at least one bulk test method that invokes the action with ≥ 251 requests inside `Test.startTest()/stopTest()` and asserts (a) all responses returned, (b) `Limits.getQueries()` delta ≤ 5 (per AC-13), (c) `Limits.getDmlStatements()` delta ≤ 6 (per AC-14).
- **AC-24:** The test class uses the `Assert` class (Spring '21+) — `Assert.areEqual`, `Assert.isTrue`, etc. — rather than only legacy `System.assertEquals`.
- **AC-25:** Apex test execution against the production class returns ≥ 90% line coverage when run via the standard `sf apex test run` smoke step.

### Documentation

- **AC-26:** The production class has an ApexDoc block on the class declaration and on the public invocable method (description, params, return).

## 3. Out of scope (the implementer MUST NOT)

- Deploy any artifact to an org. Output is `.cls` source only.
- Author Flow XML, screen flow definitions, or any `.flow-meta.xml`.
- Resolve Person Account vs Contact ambiguity for `donorId` — treat `donorId` as opaque and pass it through.
- Modify any file outside the artifact set (no edits to existing org metadata, no edits to `notes.md` or this SPEC).
- Add `@future`, `Queueable`, `Schedulable`, or `Batch` wrappers — the action is synchronous-from-Flow.
- Introduce external dependencies / packages / namespaces beyond standard Apex.

## 4. Test plan

### Unit

- **U-1 — Bulkification grep test:** Static scan of the production `.cls` file. Pattern `for\s*\([^)]*\)\s*\{[^}]*\[SELECT` and `while\s*\([^)]*\)\s*\{[^}]*\[SELECT` MUST return zero matches. Same for `insert`, `update`, `upsert`, `delete` inside `for`/`while` blocks. Same for `Database.query` and `Http.send`. Validates AC-10, AC-11, AC-12.
- **U-2 — Security grep test:** Pattern `\[SELECT\b[^]]*\]` MUST always co-occur with `WITH USER_MODE` or `WITH SECURITY_ENFORCED`. Pattern `class\s+\w+` (the production class) MUST be preceded by `with sharing`. Pattern `'\s*\+\s*\w+\s*\+\s*'` inside SOQL string contexts MUST return zero matches. Validates AC-16, AC-17, AC-18.
- **U-3 — Empty-catch grep test:** Pattern `catch\s*\([^)]+\)\s*\{\s*(?://[^\n]*)?\s*\}` MUST return zero matches. Validates AC-19.
- **U-4 — Annotation presence test:** Production class contains `@InvocableMethod` exactly once on a single static method; `Request` and `Response` inner classes each contain `@InvocableVariable` annotations on the required fields. Validates AC-1, AC-2, AC-3.
- **U-5 — Test class shape test:** Companion test class is annotated `@IsTest`, contains at least one method matching positive/negative/bulk shape (per AC-21/22/23), references `Assert.` at least once. Validates AC-20, AC-21, AC-22, AC-23, AC-24.
- **U-6 — Coverage assertion test:** When the test class is compiled and executed, the production class line coverage ≥ 90%. Validates AC-25.

### Integration

- **I-1 — Compile validity:** Both `.cls` files parse cleanly as Apex (syntactically valid: balanced braces, valid annotations, valid type references). The artifact is deployable in principle (no compile-blocking errors a deploy `--dry-run` would reject for syntax). Validates the artifact is syntactically Apex.
- **I-2 — Functional simulation (single request):** Run the positive test method. Assert exactly 1 GiftCommitment, 12 GiftCommitmentSchedule rows, 1 GiftTransaction, and `Child__c.Status__c = 'Sponsored'` for the sponsored child. Validates AC-4, AC-5, AC-6, AC-7, AC-8.
- **I-3 — Duplicate prevention simulation:** Invoke the action twice with the same `donorId + childId`. Assert second response has `alreadySponsored = true`, total GiftCommitment count for that pair == 1, total GiftCommitmentSchedule for that pair == 12 (not 24), Child status flipped only once. Validates AC-9.

### Smoke / e2e (the Children Inc N+1 detector)

- **S-1 — Bulk governor-limit probe:** The bulk test method (per AC-23) runs N=200 requests inside `Test.startTest()/stopTest()`. Capture `Limits.getQueries()` and `Limits.getDmlStatements()` deltas. Assert delta SOQL ≤ 5 and delta DML ≤ 6, and that no `LimitException` was thrown. Validates AC-13, AC-14, AC-15.
- **S-2 — Sub-linear scaling probe:** Run the bulk method at N=10 and N=200 (or the harness simulates this via static analysis of the bulkification structure). The SOQL/DML counts MUST be effectively constant across N — i.e. the same code path produces the same query count regardless of input size. Confirms the class is genuinely bulkified, not just lucky at N=200.

## 5. Rubric weights for this run

Scoring is delegated to the target skill. See `sf-apex` SKILL.md frontmatter `eval_harness.apex_dimensions` block:

- **Correctness** — 25 pts, hard-fail < 15
- **Robustness** — 25 pts, hard-fail < 12
- **Fit** — 25 pts, hard-fail < 10
- **Performance** — 25 pts, hard-fail < 15

Plus the binary `test_rubric` (unit + integration + smoke — all required, no partial credit).

The evaluator owns the rubric. ACs in §2 are testable claims about the artifact and are NOT a re-statement of rubric weights.
