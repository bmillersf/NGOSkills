---
name: sf-testing
description: >
  Apex test execution, coverage analysis, and test-fix loops with 120-point scoring.
  TRIGGER when: user runs Apex tests, checks code coverage, fixes failing tests,
  or touches *Test.cls / *_Test.cls files; also phrases like "run my Apex tests",
  "my test failed", "increase coverage to 90%", "why did this test break".
  DO NOT TRIGGER when: writing Apex production code (use sf-apex), Agentforce agent
  testing (use sf-ai-agentforce-testing), or Jest/LWC tests (use sf-lwc).
license: MIT
metadata:
  version: "1.1.0"
  author: "Jag Valaiyapathy"
  scoring: "120 points across 6 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_testing_apex.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/testing
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_apex_test.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric inline (6 categories: Test Coverage 25, Assertion Quality 25, Bulk Testing 20, Test Data 20, Isolation 15, Documentation 15), mapped onto the 4-dimension default rubric from skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  testing_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 15
      description: "Tests assert what they claim. Maps to Assertion Quality (25). Every test method must have at least one assertion that proves the production code did what it said. Tests with no Asserts pass meaningless conditions."
      automatic_hard_fail_rules:
        - "Any @isTest method with no Assert.* / System.assertEquals / System.assertNotEquals calls (test that asserts nothing)"
        - "Any test that asserts only on System exceptions thrown (testing that bad input throws, but not testing the happy path)"
        - "Any try/catch that swallows the assertion (catch (Exception e) { return; } — test passes by hiding failures)"
    - name: Robustness
      max: 25
      hard_fail_below: 12
      description: "Tests cover bulk + edge cases + isolation. Maps to Bulk Testing (20) + Isolation (15). 200+ record bulk path tested. Tests don't depend on org state (use Test Data Factory). Each test is independent."
      automatic_hard_fail_rules:
        - "Any class with public methods callable in bulk that has no 200+ record bulk test method"
        - "Any test using SeeAllData=true on a class touching production data (test isolation broken; passes locally, fails in CI)"
        - "Any test depending on a hardcoded record Id (00*) that won't exist in scratch orgs"
    - name: Fit
      max: 25
      hard_fail_below: 10
      description: "Tests use platform conventions + Test Data Factory. Maps to Test Data (20) + Documentation (15). Test data created via factory class, ApexDoc on test methods explains the scenario."
      automatic_hard_fail_rules:
        - "Any test creating records inline (insert new Account(Name='Test')) instead of via Test Data Factory (causes drift across tests)"
        - "Any test class without ApexDoc on @testSetup or test methods (future maintainer can't tell what's being tested)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Tests achieve coverage and run efficiently. Maps to Test Coverage (25). 90%+ coverage on the production class under test (Salesforce floor is 75%; production-grade is 90%). Tests don't time out or exceed governor limits."
      automatic_hard_fail_rules:
        - "Any production class with <75% coverage (Salesforce will block deploy)"
        - "Any test that takes >30 seconds to run (test inefficiency or missing Test.startTest/stopTest boundaries)"
  test_rubric:
    unit:
      required: true
      criteria: "Test methods cover positive, negative, AND bulk scenarios. Each test has a clear assertion. ≥90% coverage on the class under test."
    integration:
      required: true
      criteria: "Test class deploys to a connected org and runs to completion. sf apex run test --tests <ClassName> returns Outcome=Pass."
    smoke:
      required: true
      criteria: "Bulk test (200+ records) passes without governor limit errors. Test runs within Salesforce's 10-minute synchronous test cap."
---

# sf-testing: Salesforce Test Execution & Coverage Analysis

Expert testing engineer specializing in Apex test execution, code coverage analysis, mock frameworks, and agentic test-fix loops. Execute tests, analyze failures, and automatically fix issues.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). Three subagents (planner / implementer / evaluator) loop against the 120-pt rubric in fresh context.

**Why test code needs the harness:** the most damaging test failures are tests that pass but don't prove anything. Empty assertions, silenced exceptions, hardcoded record Ids that vanish in scratch orgs, missing 200+ record bulk paths. These pass deploy and CI but mask production bugs that ship to customers. Self-eval doesn't catch them — the test reports "Pass". Adversarial eval reads the test class and grades whether the assertions are meaningful.

**Composition:** rubric inline below (120 pts, 6 categories). Frontmatter `testing_dimensions` block maps onto 4 SPEC dimensions with hard-fail floors. Tests-with-no-assertions is automatic Correctness hard-fail.

**Disabling:** set `eval_harness.enabled: false` in frontmatter.

---

## Core Responsibilities

1. **Test Execution**: Run Apex tests via `sf apex run test` with coverage analysis
2. **Coverage Analysis**: Parse coverage reports, identify untested code paths
3. **Failure Analysis**: Parse test failures, identify root causes, suggest fixes
4. **Agentic Test-Fix Loop**: Automatically fix failing tests and re-run until passing
5. **Test Generation**: Create test classes using sf-apex patterns
6. **Bulk Testing**: Validate with 251+ records for governor limit safety

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Test patterns** | [references/test-patterns.md](references/test-patterns.md) | Basic, bulk, mock callout, and data factory patterns |
| **Test-fix loop** | [references/test-fix-loop.md](references/test-fix-loop.md) | Agentic loop implementation & failure decision tree |
| **Best practices** | [references/testing-best-practices.md](references/testing-best-practices.md) | General testing guidelines |
| **CLI commands** | [references/cli-commands.md](references/cli-commands.md) | SF CLI test commands |
| **Mocking** | [references/mocking-patterns.md](references/mocking-patterns.md) | Mocking vs Stubbing, DML mocking, HttpCalloutMock |
| **Performance** | [references/performance-optimization.md](references/performance-optimization.md) | Fast tests, reduce execution time |

---

## Workflow (5-Phase Pattern)

### Phase 1: Test Discovery

**Ask the user** to gather:
- Test scope (single class, all tests, specific test suite)
- Target org alias
- Coverage threshold requirement (default: 75%, recommended: 90%)
- Whether to enable agentic fix loop

**Then**:
1. Check existing tests: `Glob: **/*Test*.cls`, `Glob: **/*_Test.cls`
2. Check for Test Data Factories: `Glob: **/*TestDataFactory*.cls`

### Phase 2: Test Execution

**Run Single Test Class**:
```bash
sf apex run test --class-names MyClassTest --code-coverage --result-format json --output-dir test-results --target-org [alias]
```

**Run All Tests**:
```bash
sf apex run test --test-level RunLocalTests --code-coverage --result-format json --output-dir test-results --target-org [alias]
```

**Run Specific Methods**:
```bash
sf apex run test --tests MyClassTest.testMethod1 --tests MyClassTest.testMethod2 --code-coverage --result-format json --target-org [alias]
```

**Run Test Suite / All Tests (Concise)**:
```bash
sf apex run test --suite-names MySuite --code-coverage --result-format json --target-org [alias]
sf apex run test --test-level RunLocalTests --code-coverage --result-format json --concise --target-org [alias]
```

### Phase 3: Results Analysis

Parse `test-results/test-run-id.json` and report:

```
📊 TEST EXECUTION RESULTS
════════════════════════════════════════════════════════════════

SUMMARY
───────────────────────────────────────────────────────────────
✅ Passed:    42    ❌ Failed:    3    📈 Coverage: 78.5%

FAILED TESTS
───────────────────────────────────────────────────────────────
❌ AccountServiceTest.testBulkInsert
   Line 45: System.AssertException: Assertion Failed

COVERAGE BY CLASS
───────────────────────────────────────────────────────────────
Class                   Lines  Covered  Uncovered   %
AccountService          150    142      8           94.7% ✅
OpportunityTrigger      45     28       17          62.2% ⚠️
ContactHelper           30     15       15          50.0% ❌
```

### Phase 4: Agentic Test-Fix Loop

> See [references/test-fix-loop.md](references/test-fix-loop.md) for the full implementation flow and failure analysis decision tree.

When tests fail, the agentic loop: parses failures → reads source → identifies root cause → invokes sf-apex to fix → re-runs (max 3 attempts). Key error types: AssertException, NullPointerException, DmlException, LimitException, QueryException.

### Cross-Skill: Flow Testing (GA)

Flow tests are GA and run alongside Apex tests. **Authoring schema and verified examples** for `.flowtest-meta.xml` live in **[sf-flow/references/flow-test-authoring.md](../sf-flow/references/flow-test-authoring.md)** — read it before hand-writing a flow test. Files live at `force-app/main/default/flowtests/<Flow>_<Test>.flowtest-meta.xml`; the fastest authoring path is Setup → Flow → Debug → Convert to Test → `sf project retrieve start --metadata FlowTest:<Flow>.<Test>`.

```bash
# Legacy single-runner
sf flow run test --tests FlowTest1,FlowTest2 --target-org [alias] --json
sf flow run test --target-org [alias] --json
sf flow get test --test-run-id <id> --target-org [alias] --json

# Unified Apex + Flow runner (preferred for CI, CLI v2.107+)
sf logic run test --tests "FlowTesting.<flow-test-name>" --target-org [alias] --json
sf logic run test --test-category Flow --test-level RunAllTestsInOrg --code-coverage --synchronous --target-org [alias]
sf logic get test --test-run-id <id> --target-org [alias] --json
```

**Key flags:**
- `--tests` (`-t`) — for `sf flow run test`, comma-separated test names; for `sf logic run test`, prefix with `FlowTesting.`
- `--test-category Flow` / `--test-category Apex` — repeatable; omit both to run everything
- `--code-coverage` — works for flow tests (same flag as Apex)
- `--synchronous` (`-y`) — default is async; pair with `--wait` for blocking runs
- `--json` — structured output

### Phase 5: Coverage Improvement

**If coverage < threshold**:
1. `sf apex run test --class-names MyClassTest --code-coverage --detailed-coverage --result-format json` to identify uncovered lines
2. Use sf-apex to generate test methods targeting those lines
3. Use the **sf-data** skill: "Create 251 [ObjectName] records for bulk testing"
4. Re-run and verify

---

## Best Practices (120-Point Scoring)

| Category | Points | Key Rules |
|----------|--------|-----------|
| **Test Coverage** | 25 | 90%+ class coverage; all public methods tested; edge cases covered |
| **Assertion Quality** | 25 | Assert class used; meaningful messages; positive AND negative tests |
| **Bulk Testing** | 20 | Test with 251+ records; verify no SOQL/DML in loops under load |
| **Test Data** | 20 | Test Data Factory used; no hardcoded IDs; @TestSetup for efficiency |
| **Isolation** | 15 | SeeAllData=false; no org dependencies; mock external callouts |
| **Documentation** | 15 | Test method names describe scenario; comments for complex setup |

**Thresholds**: 108+ Excellent | 96+ Good | 84+ Acceptable | 72+ Below standard | <72 BLOCKED

---

## Test Patterns & Templates

> See [references/test-patterns.md](references/test-patterns.md) for full Apex code examples of all 4 patterns.

| Pattern | Template | Use Case |
|---------|----------|----------|
| Basic Test Class | `assets/basic-test.cls` | Given-When-Then with @TestSetup, positive + negative |
| Bulk Test (251+) | `assets/bulk-test.cls` | Cross 200-record batch boundary, governor limit check |
| Mock Callout | `assets/mock-callout-test.cls` | HttpCalloutMock for external API testing |
| Test Data Factory | `assets/test-data-factory.cls` | Reusable data creation with convenience insert |

Additional templates: `assets/dml-mock.cls` (35x faster tests), `assets/stub-provider-example.cls` (dynamic behavior)

---

## Testing Guardrails (MANDATORY)

**BEFORE running tests, verify:**

| Check | Command | Why |
|-------|---------|-----|
| Org authenticated | `sf org display --target-org [alias]` | Tests need valid org connection |
| Classes deployed | `sf project deploy report --target-org [alias]` | Can't test undeployed code |
| Test data exists | Check @TestSetup or TestDataFactory | Tests need data to operate on |

**NEVER do these:**

| Anti-Pattern | Problem | Correct Pattern |
|--------------|---------|-----------------|
| `@IsTest(SeeAllData=true)` | Tests depend on org data, break in clean orgs | Always `SeeAllData=false` (default) |
| Hardcoded Record IDs | IDs differ between orgs | Query or create in test |
| No assertions | Tests pass without validating anything | Assert every expected outcome |
| Single record tests only | Misses bulk trigger issues | Always test with 200+ records |
| `Test.startTest()` without `Test.stopTest()` | Async code won't execute | Always pair start/stop |

---

## CLI Command Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `sf apex run test` | Run tests | See Phase 2 examples |
| `sf apex get test` | Get async test status | `--test-run-id 707xx...` |
| `sf apex list log` | List debug logs | `--target-org alias` |
| `sf apex tail log` | Stream logs real-time | `--target-org alias` |

**Key flags**: `--code-coverage`, `--detailed-coverage`, `--result-format json`, `--output-dir`, `--test-level RunLocalTests`, `--concise`, `--poll-interval <seconds>` (v2.116.6+)

### Spring '26 Apex Test Annotations

| Annotation | Purpose | Example |
|------------|---------|---------|
| `@isTest(testFor=ClassName.class)` | Explicit test-to-source linking — ties test class to production class for coverage tracking | `@isTest(testFor=AccountService.class)` |
| `@isTest(isCritical=true)` | Marks tests that always run, even in `RunRelevantTests` mode — use for smoke tests and critical paths | `@isTest(isCritical=true)` |

```apex
// Spring '26: Link test to source class
@isTest(testFor=AccountService.class)
private class AccountServiceTest {

    // Spring '26: Always run this test, even in RunRelevantTests mode
    @isTest(isCritical=true)
    static void testCriticalPath() {
        // ...
    }
}
```

---

## Common Test Failures & Fixes

| Failure | Likely Cause | Fix |
|---------|--------------|-----|
| `MIXED_DML_OPERATION` | User + non-setup object in same txn | Use `System.runAs()` or separate transactions |
| `CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY` | Trigger or flow error | Check trigger logic with debug logs |
| `REQUIRED_FIELD_MISSING` | Test data incomplete | Add required fields to TestDataFactory |
| `DUPLICATE_VALUE` | Unique field conflict | Use dynamic values or delete existing |
| `FIELD_CUSTOM_VALIDATION_EXCEPTION` | Validation rule fired | Meet validation criteria in test data |
| `UNABLE_TO_LOCK_ROW` | Record lock conflict | Use `FOR UPDATE` or retry logic |

---

## Cross-Skill Integration

| Skill | When to Use | Example |
|-------|-------------|---------|
| sf-apex | Generate test classes, fix failing code | Use the **sf-apex** skill: "Create test class for LeadService" |
| sf-data | Create bulk test data (251+ records) | Use the **sf-data** skill: "Create 251 Leads for bulk testing" |
| sf-deploy | Deploy test classes to org | Use the **sf-deploy** skill: "Deploy tests to sandbox" |
| sf-debug | Analyze failures with debug logs | Use the **sf-debug** skill: "Analyze test failure logs" |

---

## Dependencies

**Required**: Target org with `sf` CLI authenticated
**Recommended**: sf-apex (auto-fix), sf-data (bulk test data), sf-debug (log analysis)
