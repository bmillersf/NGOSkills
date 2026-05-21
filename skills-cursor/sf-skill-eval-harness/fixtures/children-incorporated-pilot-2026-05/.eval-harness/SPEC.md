# SPEC — Children Incorporated Sponsorship Lifecycle Demo Validation

**Target skill:** `sf-demo-validate`
**Org:** `cool stuff` (storm sandbox: `storm-b8c8ef44ac58ea.my.salesforce.com`)
**Demoscript:** `/tmp/children-incorporated-demo/demoscript.md`
**Duration:** 30 minutes (NPC, 4 must_demo requirements as the demo's spine)

---

## 1. Goal

Prove that the connected `cool stuff` org can run the 15-step Children Incorporated sponsorship-lifecycle demoscript end-to-end as written, with all four `must_demo: true` requirements (REQ-001 through REQ-004) demonstrably working from a presenter's seat at presenter cue moments — no "imagine this" gaps, no errors, no missing data.

---

## 2. Acceptance Criteria (falsifiable)

Every AC below has a yes/no test. Subjective phrasing is forbidden.

### REQ-001 — Aisha enrolls Daniel; Site context one-saves into a sponsorship-ready record

- **AC-1.1** The custom object `Site__c` exists in the org with at minimum these fields: `Country__c`, `Site_Coordinator__c` (User lookup), `Program_Level__c` (picklist including value `Primary`).
- **AC-1.2** The custom object `Child__c` exists in the org with at minimum these fields: `FirstName__c`, `LastName__c`, `Year__c` (Number), `School__c`, `FavoriteSubject__c`, `Hobbies__c`, `Site__c` (Lookup to `Site__c`), `Status__c` (picklist including value `Available`).
- **AC-1.3** A `Site__c` record with `Name = "Helping Schools Kenya"`, `Country__c = "Kenya"`, `Program_Level__c = "Primary"`, and `Site_Coordinator__c` pointing to user Aisha Mwangi exists in the org.
- **AC-1.4** User `Aisha Mwangi` exists, is `IsActive = true`, has `TimeZoneSidKey = Africa/Nairobi`, and is assigned a profile or permission set that grants Create on `Child__c` and Read on `Site__c`.
- **AC-1.5** A "New Child" creation path exists that Aisha can reach in ≤2 clicks from a Children app or `Child__c` object home (button labelled `New` on the standard list view is acceptable). Step 2 of the click path must execute without selector errors against the live org.
- **AC-1.6** When a `Child__c` record is saved with `Site__c` = the Helping Schools Kenya record, the related Site panel (or compact related list) on the saved record renders the values `Kenya`, `Aisha`, and `Primary` without a page reload — i.e., the demoscript's "after Save, the panel is populated from one save" claim is verifiable in the UI.

### REQ-002 — Joseph creates Margaret's Gift Commitment; three records appear from one save

- **AC-2.1** Standard NPC objects `GiftCommitment`, `GiftCommitmentSchedule`, and `GiftTransaction` are accessible in the org (Recurring Gifts feature is enabled and licensed).
- **AC-2.2** A list view named (or filterable as) `Available Children` exists on `Child__c` filtering for `Status__c = "Available"`, and Daniel's record appears in it before step 5 of the demoscript runs.
- **AC-2.3** A quick action or button labelled `Sponsor This Child` (or API name `Sponsor_This_Child`) is available on the `Child__c` record page; clicking it opens a form with at minimum: Donor lookup, Amount (numeric), Frequency, Start Date, and a child reference that auto-populates from the source record.
- **AC-2.4** The Account record `Margaret Hartwell` (RecordType.DeveloperName matching a Household/Person variant available in the org, or a Contact-as-donor equivalent if the org's NPC config requires it) exists with a populated email and is selectable from the Donor lookup in the Sponsor This Child action.
- **AC-2.5** Saving the Sponsor This Child action with Donor = Margaret Hartwell, Amount = $40, Frequency = Monthly, Start Date = today, Sponsored Child = Daniel must produce, atomically and visible without a manual refresh: (a) one `GiftCommitment` linking Margaret to Daniel with status active and amount = 40; (b) a `GiftCommitmentSchedule` with at least 12 monthly installment records; (c) at least one `GiftTransaction` record in scheduled status with a due date on the 1st of the next calendar month. All three are queryable via SOQL immediately post-save.
- **AC-2.6** The post-save layout (`Step 6` of the click path) renders all three record types in one screen — verifiable via the `expected_visible` strings: `Gift Commitment`, `Gift Commitment Schedule`, `Gift Transaction`, `12 installments`, `Scheduled`.

### REQ-003 — Joseph cancels Margaret's commitment with reason; task lands on Aisha's queue

- **AC-3.1** The `GiftCommitment` object exposes a Cancel/Close action accessible from the record page; the cancel reason picklist on `GiftCommitment` includes the literal value `Donor Financial Hardship`.
- **AC-3.2** A queue named `Helping Schools Kenya Queue` exists, has `Type = Queue`, supports the `Task` sObject, and includes Aisha Mwangi as a queue member.
- **AC-3.3** A list view on `Task` filterable as `Helping_Schools_Kenya_Queue` (URL-resolvable per click-path step 9) returns rows owned by that queue.
- **AC-3.4** Closing Margaret's `GiftCommitment` with `Cancel Reason = Donor Financial Hardship` causes a `Task` to be created within ≤5 seconds, owned by the Helping Schools Kenya Queue, with subject containing the substring `Reassign Daniel`, body or related field referencing `Margaret`, and a value carrying `Donor Financial Hardship`. Verifiable via SOQL `WHERE OwnerId = :queueId`.
- **AC-3.5** The automation that creates the task (Flow, Apex trigger, or Process) is in `Active` status in the org; if Flow, its API name is recorded in `IMPL-NOTES.md`.

### REQ-004 — Joseph transfers Margaret's sponsorship to Sarah; history preserved on both child records

- **AC-4.1** A `Child__c` record `Sarah K`, `Year__c = 1`, `Site__c` = Helping Schools Kenya, `Status__c = Available` exists in the org before step 11 runs.
- **AC-4.2** A quick action, button, or LWC component labelled `Transfer Sponsorship` (API name `Transfer_Sponsorship`) is available on the closed `GiftCommitment` record page for Margaret.
- **AC-4.3** Clicking Transfer Sponsorship presents a list of `Child__c` records filtered to `Site__c = Margaret's prior child's site` AND `Status__c = Available`. Sarah appears in that list. The list is visible in the UI (verifiable via the `data-section='available-children'` selector or the `expected_visible` strings `Sarah`, `Helping Schools Kenya`).
- **AC-4.4** Confirming the transfer with Sarah selected results in: (a) a new active `GiftCommitment` linking Margaret to Sarah with the same $40/month terms; (b) Daniel's `Child__c` record carrying a sponsored-from / sponsored-to date range and an aged-out indicator (verifiable via field values or a related Sponsorship History record); (c) Sarah's `Child__c` record showing a `Prior Sponsorship History`-equivalent related list or section that references Margaret's prior commitment to Daniel. All three changes are queryable via SOQL post-confirm.
- **AC-4.5** Margaret's giving cadence does not pause: post-transfer, there is at least one scheduled or active `GiftTransaction` with a due date ≤32 days in the future on the new commitment.

### Cross-cutting acceptance criteria

- **AC-X.1** Every step in `click-path.json` (steps 1–15) executes against the live `cool stuff` org without selector / URL / permission errors when run by the indicated POV user (Aisha for steps 2–3, 9; Joseph for steps 4–6, 8, 11–13; admin POV for step 14; narrative steps 1, 7, 10, 15 require no UI interaction). Selector failures are AC failures.
- **AC-X.2** Every record listed in `data-requirements.json` exists in the org with all `required_fields` populated. Missing records or missing required fields are AC failures.
- **AC-X.3** Phase 5 fix actions taken by `sf-demo-validate` are recorded in `IMPL-NOTES.md` with: (a) the deploy command(s) executed, (b) the metadata or data created/updated, (c) the post-fix re-validation result. Undocumented fixes are AC failures.
- **AC-X.4** The `sf-demo-validate` Phase 4 report is produced and lists per-step pass/fail; final Phase 7 summary is produced and includes prorated score and threshold verdict (Deploy-ready / Review / Blocked).
- **AC-X.5** Demoscript step 14 (admin POV setup glance, ≤30s) succeeds: the GiftCommitment Cancel Reason picklist values are visible in Object Manager and the Transfer Sponsorship Flow appears in Setup → Flows.

---

## 3. Out of scope (the implementer MUST NOT do these)

- Touch any artifact for `must_demo: false` requirements (REQ-005 through REQ-017 — correspondence object, MCAE integration, sponsor/volunteer Experience Cloud portals, GAUs, donor-development notes, soft credit rollups, paid-through editing, file-tab filters). Do **not** create Correspondence__c, set up MCAE journeys, build portal pages, or seed any record outside `data-requirements.json`. Sections 2-4 of the discovery notes are aspirational, not gating.
- Auto-push to remote git (no `git push` whatsoever).
- Modify any Profile directly. Permission Sets only.
- Delete any production-looking record. Inserts, updates, and metadata deploys are allowed; deletes are limited to the explicit teardown rows referenced in `data-requirements.json` cleanup, and only when the record is unambiguously demo-seeded.
- Alter `.planning/` files anywhere on disk (gsd-owned).
- Modify the six upstream-locked contracts in `/tmp/children-incorporated-demo/.eval-harness/` (`requirements.json`, `value-moments.json`, `requirement-coverage.json`, `wow-moment-delivery.json`, `data-requirements.json`, `click-path.json`).
- Hardcode Salesforce IDs in any deployed metadata or seed script. Use SOQL lookups or external IDs.
- Deploy without `--dry-run` first.
- Skip Phase 5 self-repair by reporting failures and stopping. The demoscript explicitly grants Phase 5 freedom to enable NPC Recurring Gifts, deploy `Site__c` and `Child__c`, build the Helping Schools Kenya queue, and seed the 7 demo records — this is in scope.
- Exceed 3 fix iterations on a single failing step (per sf-demo-validate guardrail).

---

## 4. Test plan

Tests group into three categories. Unit tests are already covered by the harness's existing 49 pytest tests in `skills-cursor/sf-skill-eval-harness/tests/`; do not duplicate them — reference and rely.

### 4.1 Unit (already covered by harness; reference only)

- `test_schema_validation_*` — confirms `requirements.json`, `value-moments.json`, `data-requirements.json`, `click-path.json`, `requirement-coverage.json`, `wow-moment-delivery.json` all conform to their JSON schemas.
- `test_rubric_scoring_math` — confirms prorated 200-point math is correct for nonprofit-only demos (no add-ons).
- `test_loop_decide` and `test_hard_fail_floor` — confirm hard-fail floors and loop verdicts compute correctly.

The implementer MUST run `python3 scripts/cli.py validate-contracts --harness-dir /tmp/children-incorporated-demo/.eval-harness --strict` before claiming completion. Schema failure is an AC failure.

### 4.2 Integration (must be authored / executed against `cool stuff`)

Each integration test is named, has a clear pass/fail signal, and writes evidence to `IMPL-NOTES.md`.

- **IT-1 — Org connectivity** — `sf org display --target-org "cool stuff"` succeeds; `My Domain`, `Instance URL`, `OrgId` captured.
- **IT-2 — Platform prerequisites** — Recurring Gifts (NPC) feature is enabled; `GiftCommitment`, `GiftCommitmentSchedule`, `GiftTransaction` are queryable via Tooling API or `sf data query`.
- **IT-3 — Custom metadata exists** — SOQL/Tooling query confirms `Site__c` and `Child__c` objects with the fields enumerated in AC-1.1 / AC-1.2 deployed and accessible.
- **IT-4 — Seed data present** — `sf data query` confirms each row in `data-requirements.json` exists with required fields populated. One sub-test per record (7 sub-tests).
- **IT-5 — Queue + queue membership** — SOQL on `Group` and `GroupMember` confirms `Helping Schools Kenya Queue` exists, `Type = Queue`, supports Task, includes Aisha.
- **IT-6 — Cancel reason picklist** — Tooling API query on `GiftCommitment` Cancel Reason picklist returns `Donor Financial Hardship`.
- **IT-7 — Quick actions / page actions** — `Sponsor This Child` exists on `Child__c`; `Transfer Sponsorship` exists on `GiftCommitment`. Verifiable via Metadata API list of QuickActions or Lightning Page components.
- **IT-8 — Automation active** — Flow, trigger, or process that creates the cancellation task is `Active`. Recorded by API name in `IMPL-NOTES.md`.
- **IT-9 — Permission grants per persona** — Aisha can Create `Child__c`; Joseph can Create `GiftCommitment`, run `Sponsor_This_Child` and `Transfer_Sponsorship`. Verified via PermissionSetAssignment + ObjectPermissions SOQL.

Any IT failure that can be self-repaired by Phase 5 (deploy missing metadata, seed missing data, activate the flow, assign perms) MUST be repaired and re-validated; otherwise it's an AC failure.

### 4.3 Smoke / e2e (must execute the demoscript end-to-end)

- **E2E-1 — Step-by-step execution** — Each of the 15 click-path steps runs against the live org as the indicated POV user without errors. Selectors resolve. URLs return 200. `expected_visible` strings appear on-screen. Step failures are AC failures.
- **E2E-2 — REQ-001 wow moment** — After running steps 2–3 as Aisha, querying `Child__c WHERE FirstName__c = 'Daniel'` returns one record whose `Site__c` lookup resolves to the Helping Schools Kenya site with the three site fields populated. The post-save UI shows `Helping Schools Kenya`, `Kenya`, `Aisha`, `Primary` without a manual refresh.
- **E2E-3 — REQ-002 wow moment (3-from-1-save)** — After running steps 5–6 as Joseph, SOQL confirms exactly one new `GiftCommitment`, ≥12 `GiftCommitmentSchedule` rows linked to it, and ≥1 `GiftTransaction` in scheduled status linked to it — created within a single transaction window (compare CreatedDate timestamps within ≤5s spread).
- **E2E-4 — REQ-003 same-day routing** — After step 8 closes Margaret's commitment, SOQL `WHERE OwnerId = :kenyaQueueId AND Subject LIKE '%Reassign Daniel%'` returns ≥1 Task within 5 seconds, with `Donor Financial Hardship` reachable on the task or its related fields.
- **E2E-5 — REQ-004 transfer integrity** — After steps 11–13, SOQL confirms (a) new active `GiftCommitment` Margaret→Sarah at $40/month; (b) Daniel's record carries a sponsored-date-range and aged-out indicator; (c) Sarah's record carries a prior-history reference. Margaret's prior commitment to Daniel is `Closed`, not deleted.
- **E2E-6 — Continuity check (no giving gap)** — Post-transfer SOQL confirms ≥1 active or scheduled `GiftTransaction` for Margaret on the new commitment with due date within the next 32 days.
- **E2E-7 — Prorated 200-pt rubric ≥ 80%** — sf-demo-validate Phase 7 summary reports a prorated score ≥ 160/200 across the 10 base categories applicable to this nonprofit demo (no cross-cloud add-ons). Add-on categories (Sales / Service / Marketing / etc.) are not assessed and do not enter the denominator. Score < 160/200 is an AC failure.
- **E2E-8 — Coverage matrix** — sf-demo-validate's coverage assessment matches `requirement-coverage.json`: REQ-001 → step-2/3, REQ-002 → step-4/5/6, REQ-003 → step-8/9, REQ-004 → step-11/12/13. Mismatches are AC failures.

### Test execution evidence (mandatory)

The implementer's `IMPL-NOTES.md` MUST include, for each AC and each integration / e2e test: pass/fail, the SOQL or CLI command run, the evidence (count, ID, screenshot path, or error). Documentation alone (e.g. "deployed Site__c") is not evidence; a query result or post-deploy verification is.

---

## 5. Rubric weights for this run (4-dimension shape, 100 pts total, evaluator-graded)

The harness wraps `sf-demo-validate`'s native 200-pt 10-category rubric (graded inside the implementer's Phase 4/7 report and reflected in E2E-7 above). Above that, the evaluator independently grades these four cross-cutting dimensions, 25 pts each, **with hard-fail floors per the sf-demo-validate frontmatter**:

| Dimension | Points | Hard-fail floor | What's graded |
|---|---|---|---|
| **Correctness** | 25 | **15** | Does the demo do what the script claims at every wow moment? Specifically: (a) all four `must_demo: true` ACs pass; (b) the three-records-from-one-save in REQ-002 produces real `GiftCommitment` + `GiftCommitmentSchedule` + `GiftTransaction` records (not stubs / not promises); (c) Aisha's queue task in REQ-003 is real and routable, not a manually-inserted demo record; (d) the transfer in REQ-004 actually re-points the commitment with history preserved on both child records. |
| **Robustness** | 25 | **12** | Edge cases the live demo will hit. Specifically: (a) Transfer Sponsorship invoked when no `Available` children exist at the same site behaves predictably (graceful empty state, not an unhandled exception); (b) Cancel without a queue assignment does not silently swallow the task; (c) Re-running step 5 with a duplicate donor lookup does not double-create commitments; (d) the demo data resets cleanly via the teardown step. |
| **Fit** | 25 | **10** | Native NPC convention adherence. Specifically: (a) standard `GiftCommitment` / `GiftCommitmentSchedule` / `GiftTransaction` object names + relationships are used (not custom Recurring Donation lookalikes); (b) `Site__c` and `Child__c` follow NPC field naming conventions and Person Account / Household record-type conventions where applicable; (c) the cancellation automation uses Flow over Apex trigger when both work; (d) permissions are delivered via Permission Sets (never Profile edits). |
| **Performance** | 25 | **12** | Governor-limit and runtime hygiene. Specifically: (a) the GiftCommitment-save automation that produces 12+ schedule rows + the first transaction is bulk-safe (single transaction, no SOQL inside loops); (b) the Available Children list view does not require a full-table scan to render Daniel quickly (selective filter on `Status__c`); (c) the Task creation Flow on cancel does not fan out N+1 queries per related record; (d) the Transfer Sponsorship action completes in the UI in ≤3 seconds against the storm sandbox. |

Hard-fail rule: a score below the floor in **any** dimension blocks SHIP regardless of total. Per `sf-demo-validate.eval_harness.hard_fail_dimensions`, Correctness and Robustness floors are non-negotiable and never get autonomous retries — the loop escalates.

The evaluator does not see this rubric inside the implementer's prompt — the implementer fits to ACs only. Weights here are for evaluator grading and harness loop control.

---

## Provenance + harness mechanics

- This SPEC was produced by the planner subagent in fresh context. It does not see the implementer's working memory or any prior evaluator report.
- On a re-plan triggered by `SPEC-DEFECT.md`, this file is rewritten end-to-end against the defect notes — the prior implementer's code is NOT a reference.
- The 6 upstream contract files in `.eval-harness/` are immutable for this run.
- Harness loop config (from `sf-demo-validate.eval_harness`): `max_iterations: 3`, `improvement_threshold_points: 5`, `per_loop_replan_budget: 1`, `quality_pct_floor: 80`.
