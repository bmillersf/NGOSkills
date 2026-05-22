---
name: sf-apex
description: >
  Generates and reviews Salesforce Apex code with 150-point scoring.
  TRIGGER when: user writes, reviews, or fixes Apex classes, triggers, test classes,
  batch/queueable/schedulable jobs, or touches .cls/.trigger files; also phrases like
  "write some Apex", "add a trigger to [object]", "my Apex broke — fix it",
  "refactor this class".
  DO NOT TRIGGER when: LWC JavaScript (use sf-lwc), Flow XML (use sf-flow),
  SOQL-only queries (use sf-soql), analyzing debug logs (use sf-debug),
  or non-Salesforce code.
license: MIT
metadata:
  version: "1.1.0"
  author: "Jag Valaiyapathy"
  scoring: "150 points across 8 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-04
upstream_refs:
  - url: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/apex
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_apex.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "150-pt rubric in this SKILL.md (Best Practices section), mapped onto the 4-dimension default rubric from skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  apex_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 15
      description: "Code does what it claims AND does it bulk-safely. Maps to the 150-pt rubric's Bulkification category (25 pts). A class that works at N=1 but is N+1 at N=200 is functionally broken — it shipped 70% of the spec and breaks at the first governor-limit boundary."
      automatic_hard_fail_rules:
        - "Any SOQL query inside a for/while loop"
        - "Any DML statement (insert/update/upsert/delete) inside a for/while loop"
        - "Any callout (HTTP, Database, etc) inside a for/while loop"
        - "Any IMPL-NOTES claim of 'bulk-safe' or 'no DML in loops' that contradicts the actual bytecode (this is the N+1 bulkification failure mode)"
    - name: Robustness
      max: 25
      hard_fail_below: 12
      description: "Code survives bad input and security boundaries. Maps to Security (25) + Error Handling (15) categories. WITH USER_MODE, bind variables, with sharing, Security.stripInaccessible(), specific exception types, no empty catch blocks, custom business exceptions where appropriate."
      automatic_hard_fail_rules:
        - "Any SOQL query without WITH USER_MODE or WITH SECURITY_ENFORCED on classes that handle user input"
        - "Any DML on user-input data without Security.stripInaccessible()"
        - "Any catch block with no body or only a comment (silent swallow)"
        - "Any class declared without 'with sharing' that operates on user-input records"
    - name: Fit
      max: 25
      hard_fail_below: 10
      description: "Code matches existing patterns + skill conventions. Maps to Architecture (20) + Clean Code (20) + Documentation (10). TAF triggers, Service/Domain/Selector layers, SOLID, dependency injection, meaningful names, ApexDoc on public surface."
    - name: Performance
      max: 25
      hard_fail_below: 15
      description: "Code respects governor limits AND has measured bulk evidence. Maps to Performance (10) + bulkification stress signal. Limits monitoring, async for heavy work, scope variables, cache expensive ops. The hard-fail floor at 15 is intentional: shipping Apex without measured bulk evidence (Limits.getQueries() / getDmlStatements() deltas at N=200) is the path that ships demos with Children-Inc-style N+1 bugs."
      automatic_hard_fail_rules:
        - "No bulk test (251+ records) for any class with @InvocableMethod, @future, or trigger handler logic"
        - "Any IMPL-NOTES performance claim without measured Limits delta evidence (e.g., 'bulk-safe at N=5' without showing deltaSOQL/deltaDML)"
  test_rubric:
    unit:
      required: true
      criteria: "90%+ code coverage. Test class with positive, negative, AND bulk test methods. Test Data Factory used (no inline record creation). Assert class (Spring '21+) preferred over System.assertEquals."
    integration:
      required: true
      criteria: "Apex test class deploys to a connected org and passes (sf apex test run --tests <ClassName> --result-format human returns Outcome=Pass)."
    smoke:
      required: true
      criteria: "Bulk invocation test at N=251+ records does not exceed governor limits. Limits.getQueries() and Limits.getDmlStatements() deltas measured and recorded in IMPL-NOTES.md. The N+1 bulkification failure mode is exactly what this smoke test exists to catch."
---

# sf-apex: Salesforce Apex Code Generation and Review

Expert Apex developer specializing in clean code, SOLID principles, and 2025 best practices. Generate production-ready, secure, performant, and maintainable Apex code.

## Core Responsibilities

1. **Code Generation**: Create Apex classes, triggers (TAF), tests, async jobs from requirements
2. **Code Review**: Analyze existing Apex for best practices violations with actionable fixes
3. **Validation & Scoring**: Score code against 8 categories (0-150 points)
4. **Deployment Integration**: Validate and deploy via sf-deploy skill

---

## Eval Harness Wrap (Stage B)

When `eval_harness.enabled: true` (set in frontmatter above), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md) — a separate skill that owns the orchestration of planner / implementer / evaluator subagents and grades the generated Apex code in fresh context.

**This is Stage B of the harness rollout.** Stage A wrapped the demo orchestrator's artifact-producing phases. Stage B extends to the implementation skills those phases delegate to. When Phase 5 (data seeding) or Phase 6 (validate + repair) invokes this skill to generate Apex, the inner harness fires *inside* the outer harness — nested adversarial evaluation that catches code-level defects before the outer evaluator sees them.

### Why this matters (the canonical N+1 failure mode)

A real pilot run had the implementer subagent invoke this skill to generate a sponsor-creation Apex action. The implementer self-reported "bulk-safe, no DML in loops". The class actually ran 4 SOQL + 8 DML for a 2-request invocation — perfect N+1. The outer harness evaluator caught it on iter-1 ITERATE.

**With Stage B wrapping in place**, this skill's own evaluator subagent would have caught the N+1 *before* the outer Phase 6 harness saw the code. The outer harness gets cleaner artifacts; iteration count drops; presenter-prep becomes faster. That's the nested-adversarial-eval payoff.

### How the harness composes with this skill

| What | Owned by |
|---|---|
| 150-pt scoring rubric (8 categories) | This skill ("Best Practices" section below) |
| 4-dimension SPEC default rubric mapping (Correctness / Robustness / Fit / Performance) | This skill's frontmatter `apex_dimensions` block |
| 5-phase implementer workflow (Requirements → Design → Generation → Tests → Deploy) | This skill ("Workflow" section below) |
| TAF, SOLID, 2025 best practices, async patterns, Trust Layer integration | This skill (existing references) |
| Three-agent loop control (SHIP / ITERATE / SPEC-DEFECT verdicts, hard-fail floors, replan budget) | sf-skill-eval-harness |
| Subagent prompts (planner / implementer / evaluator) | sf-skill-eval-harness/prompts/ |
| Append-only TRACE.md primary debugging loop | sf-skill-eval-harness |

### Critical evaluator checks for Apex artifacts

The evaluator runs four deterministic verifications:

1. **Bulkification probe** — grep the generated class for SOQL/DML/callout statements inside `for` or `while` loops. Any hit = Correctness automatic hard-fail. This is the canonical N+1 detector.
2. **Security boundary probe** — grep for SOQL without `WITH USER_MODE` / `WITH SECURITY_ENFORCED`, DML without `Security.stripInaccessible()`, classes without `with sharing`. Each pattern = Robustness -1; persistent absence on user-input handlers = Robustness hard-fail.
3. **Bulk smoke test probe** — execute a 251+ record invocation against the deployed test class. Capture `Limits.getQueries()` and `Limits.getDmlStatements()` deltas. If deltas scale linearly with N (vs constant), that's a Performance hard-fail regardless of whether the run succeeded — the class will trip governor limits at the next scale boundary.
4. **Test rubric live verification** — execute `sf apex test run --tests <ClassName>` and confirm Outcome=Pass with ≥90% coverage. Test rubric is binary: pass or fail.

### IMPL-NOTES claim verification (the N+1 lesson encoded)

Per the Performance dimension's `automatic_hard_fail_rules`, any IMPL-NOTES.md claim about bulk-safety, performance characteristics, or test coverage must be backed by measured evidence. Evaluator verifies claims by:

- Re-running the bulk invocation in `Test.startTest() / Test.stopTest()` boundaries and comparing measured Limits deltas to the implementer's claim
- Running `sf apex test run` and confirming the test class actually exists and passes
- Checking the deployed class via Tooling API to confirm what's actually in the org matches what IMPL-NOTES describes

Mismatch between claim and bytecode = automatic Performance OR Correctness hard-fail (depending on the claim).

### Disabling the harness

Set `eval_harness.enabled: false` in this skill's frontmatter (or remove the `eval_harness:` block entirely). The 5-phase workflow runs as before with no harness wrap.

See [the harness skill's SKILL.md](../../skills-cursor/sf-skill-eval-harness/SKILL.md) for the full orchestration playbook.

---

## Workflow (5-Phase Pattern)

### Phase 1: Requirements Gathering

**Delegation**: keep in **parent**. Requirements gathering is a user-facing dialog that needs full conversational context.

**Ask the user** to gather:
- Class type (Trigger, Service, Selector, Batch, Queueable, Test, Controller)
- Primary purpose (one sentence)
- Target object(s)
- Test requirements

**Then**:
1. Check existing code: `Glob: **/*.cls`, `Glob: **/*.trigger`
2. Check for existing Trigger Actions Framework setup: `Glob: **/*TriggerAction*.cls`
3. Create a task list

---

### Phase 2: Design & Template Selection

**Delegation**: keep in **parent**. Template + architecture decisions (Service vs Selector vs Trigger Action, sharing keyword, namespace strategy) are foundational and short — subagent overhead isn't worth it.

**Select template**:
| Class Type | Template |
|------------|----------|
| Trigger | `assets/trigger.trigger` |
| Trigger Action | `assets/trigger-action.cls` |
| Service | `assets/service.cls` |
| Selector | `assets/selector.cls` |
| Batch | `assets/batch.cls` |
| Queueable | `assets/queueable.cls` |
| Test | `assets/test-class.cls` |
| Test Data Factory | `assets/test-data-factory.cls` |
| Standard Class | `assets/apex-class.cls` |

**Template Path Resolution** (try in order):
1. **Marketplace folder**: `~/.claude/plugins/marketplaces/sf-skills/sf-apex/assets/[template]`
2. **Project folder**: `[project-root]/sf-apex/assets/[template]`

**Example**: `Read: ~/.claude/plugins/marketplaces/sf-skills/sf-apex/assets/apex-class.cls`

---

### Phase 3: Code Generation/Review

**Delegation**: when generating **3+ independent classes** (e.g. a Service + Selector + Domain trio, or N Trigger Actions), fire one `generalPurpose` subagent per class in a single tool-call message per the parallel pattern in `sf-subagent-orchestration`. Each subagent gets the template, naming conventions, target object, and the 150-point scoring rubric as acceptance criteria; each returns the generated `.cls` paths and its self-scored result. The parent integrates and runs the guardrail check below. For a single class, stay in the **parent**.

**For Generation**:
1. Create class file in `force-app/main/default/classes/`
2. Apply naming conventions (see [references/naming-conventions.md](references/naming-conventions.md))
3. Include ApexDoc comments
4. Create corresponding test class

**For Review**:
1. Read existing code
2. Run validation against best practices
3. Generate improvement report with specific fixes

**Run Validation**:
```
Score: XX/150 ⭐⭐⭐⭐ Rating
├─ Bulkification: XX/25
├─ Security: XX/25
├─ Testing: XX/25
├─ Architecture: XX/20
├─ Clean Code: XX/20
├─ Error Handling: XX/15
├─ Performance: XX/10
└─ Documentation: XX/10
```

---

### ⛔ GENERATION GUARDRAILS (MANDATORY)

**BEFORE generating ANY Apex code, Claude MUST verify no anti-patterns are introduced.**

If ANY of these patterns would be generated, **STOP and ask the user**:
> "I noticed [pattern]. This will cause [problem]. Should I:
> A) Refactor to use [correct pattern]
> B) Proceed anyway (not recommended)"

| Anti-Pattern | Detection | Impact |
|--------------|-----------|--------|
| SOQL inside loop | `for(...) { [SELECT...] }` | Governor limit failure (100 SOQL) |
| DML inside loop | `for(...) { insert/update }` | Governor limit failure (150 DML) |
| Missing sharing | `class X {` without keyword | Security violation |
| Hardcoded ID | 15/18-char ID literal | Deployment failure |
| Empty catch | `catch(e) { }` | Silent failures |
| String concatenation in SOQL | `'SELECT...WHERE Name = \'' + var` | SOQL injection |
| Test without assertions | `@IsTest` method with no `Assert.*` | False positive tests |

**DO NOT generate anti-patterns even if explicitly requested.** Ask user to confirm the exception with documented justification.

**See**: [references/security-guide.md](references/security-guide.md) for detailed security patterns
**See**: [references/anti-patterns.md](references/anti-patterns.md) for complete anti-pattern catalog

---

### Phase 4: Deployment

**Delegation**: hand off to `sf-deploy`, which itself delegates the long `sf project deploy start` loops to a `shell` subagent per `sf-subagent-orchestration`. Verbose deploy output never enters this skill's context.

**Step 1: Validation**
Use the **sf-deploy** skill: "Deploy classes at force-app/main/default/classes/ to [target-org] with --dry-run"

**Step 2: Deploy** (only if validation succeeds)
Use the **sf-deploy** skill: "Proceed with actual deployment to [target-org]"

**See**: [references/troubleshooting.md](references/troubleshooting.md#cross-skill-dependency-checklist) for deployment prerequisites

---

### Phase 5: Documentation & Testing Guidance

**Delegation**: keep in **parent**. The completion summary is short and synthesises results from prior phases — no benefit from a fresh subagent context.

**Completion Summary**:
```
✓ Apex Code Complete: [ClassName]
  Type: [type] | API: 65.0
  Location: force-app/main/default/classes/[ClassName].cls
  Test Class: [TestClassName].cls
  Validation: PASSED (Score: XX/150)

Next Steps: Run tests, verify behavior, monitor logs
```

---

## Best Practices (150-Point Scoring)

| Category | Points | Key Rules |
|----------|--------|-----------|
| **Bulkification** | 25 | NO SOQL/DML in loops; collect first, operate after; test 251+ records |
| **Security** | 25 | `WITH USER_MODE`; bind variables; `with sharing`; `Security.stripInaccessible()` |
| **Testing** | 25 | 90%+ coverage; Assert class; positive/negative/bulk tests; Test Data Factory |
| **Architecture** | 20 | TAF triggers; Service/Domain/Selector layers; SOLID; dependency injection |
| **Clean Code** | 20 | Meaningful names; self-documenting; no `!= false`; single responsibility |
| **Error Handling** | 15 | Specific before generic catch; no empty catch; custom business exceptions |
| **Performance** | 10 | Monitor with `Limits`; cache expensive ops; scope variables; async for heavy |
| **Documentation** | 10 | ApexDoc on classes/methods; meaningful params |

**Thresholds**: ✅ 90+ (Deploy) | ⚠️ 67-89 (Review) | ❌ <67 (Block - fix required)

**Deep Dives**:
- [references/bulkification-guide.md](references/bulkification-guide.md) - Governor limits, collection handling
- [references/security-guide.md](references/security-guide.md) - CRUD/FLS, sharing, injection prevention
- [references/testing-patterns.md](references/testing-patterns.md) - Exception types, mocking, coverage
- [references/patterns-deep-dive.md](references/patterns-deep-dive.md) - TAF, @InvocableMethod, async patterns

---

## Trigger Actions Framework (TAF)

### Quick Reference

**When to Use**: If TAF package is installed in target org (check: `sf package installed list`)

**Trigger Pattern** (one per object):
```apex
trigger AccountTrigger on Account (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    new MetadataTriggerHandler().run();
}
```

**Action Class** (one per behavior):
```apex
public class TA_Account_SetDefaults implements TriggerAction.BeforeInsert {
    public void beforeInsert(List<Account> newList) {
        for (Account acc : newList) {
            if (acc.Industry == null) {
                acc.Industry = 'Other';
            }
        }
    }
}
```

**⚠️ CRITICAL**: TAF triggers do NOTHING without `Trigger_Action__mdt` records! Each action class needs a corresponding Custom Metadata record.

**Installation**:
```bash
sf package install --package 04tKZ000000gUEFYA2 --target-org [alias] --wait 10
```

**Fallback**: If TAF is NOT installed, use standard trigger pattern (see [references/patterns-deep-dive.md](references/patterns-deep-dive.md#standard-trigger-pattern))

**See**: [references/patterns-deep-dive.md](references/patterns-deep-dive.md#trigger-actions-framework-taf) for complete TAF patterns and Custom Metadata setup

---

## Automation Density

| Object Density | Recommended Tool | Notes |
|---------------|-----------------|-------|
| **Low** (0-2 automations) | Flow (Record-Triggered) | Declarative, admin-maintainable |
| **Medium** (3-5) | Hybrid (Flow + Invocable Apex) | Flow orchestrates, Apex handles complexity |
| **High** (6+) | Apex (TAF) | Full control over execution order and limits |

> ⚠️ **One Entry Point Per Object**: Don't add a second trigger or record-triggered flow if one exists. Use Flow Trigger Explorer (Setup → Process Automation) to audit before adding automation.

**See**: [references/automation-density-guide.md](references/automation-density-guide.md) for framework details, hybrid patterns, CDC async, and coexistence management

---

## Async Decision Matrix

| Scenario | Use | Key Advantage | Daily Limit |
|----------|-----|---------------|-------------|
| Default async processing | **Queueable** (preferred) | Job ID, chaining, non-primitive types, delays up to 10 min, dedup signatures | 250K or 200× licenses |
| Process millions of records | Batch Apex | Chunked, off-peak, max 5 concurrent threads | Same pool |
| Modern batch alternative | **CursorStep** (`Database.Cursor`) | 2000-record chunks, higher throughput | N/A |
| Scheduled/recurring job | **Scheduled Flow** (preferred) or Schedulable | Flow = deployable metadata, packageable; Apex = 100 job limit | — |
| Post-job cleanup | Queueable Finalizer (`System.Finalizer`) | Runs regardless of success/failure | — |
| Long-running Lightning callouts | `Continuation` | 3 per txn, 3 parallel, doesn't count toward daily async | — |
| Legacy fire-and-forget | `@future` (legacy — prefer Queueable) | Simpler syntax only | Same pool |

> ⚠️ **Async doesn't solve horizontal scaling.** Finite threads + flow control + fair usage algorithm constrain throughput. Design for governor limits, not unlimited parallelism.

**See**: [references/patterns-deep-dive.md](references/patterns-deep-dive.md#async-patterns) for detailed async patterns

---

## Modern Apex Features (API 62.0)

- **Null coalescing**: `value ?? defaultValue`
- **Safe navigation**: `record?.Field__c`
- **User mode**: `WITH USER_MODE` in SOQL
- **Assert class**: `Assert.areEqual()`, `Assert.isTrue()`

**Breaking Change (API 62.0)**: Cannot modify Set while iterating - throws `System.FinalException`

**See**: [references/bulkification-guide.md](references/bulkification-guide.md#collection-handling-best-practices) for collection usage

---

## Flow Integration (@InvocableMethod)

Apex classes can be called from Flow using `@InvocableMethod`. This pattern enables complex business logic, DML, callouts, and integrations from declarative automation.

### Quick Pattern

```apex
public with sharing class RecordProcessor {

    @InvocableMethod(label='Process Record' category='Custom')
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            res.isSuccess = true;
            res.processedId = req.recordId;
            responses.add(res);
        }
        return responses;
    }

    public class Request {
        @InvocableVariable(label='Record ID' required=true)
        public Id recordId;
    }

    public class Response {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;
        @InvocableVariable(label='Processed ID')
        public Id processedId;
    }
}
```

**Template**: Use `assets/invocable-method.cls` for complete pattern

**See**:
- [references/patterns-deep-dive.md](references/patterns-deep-dive.md#flow-integration-invocablemethod) - Complete @InvocableMethod guide
- [references/flow-integration.md](references/flow-integration.md) - Advanced Flow-Apex patterns
- [references/triangle-pattern.md](references/triangle-pattern.md) - Flow-LWC-Apex triangle

---

## Testing Best Practices

### The 3 Test Types (PNB Pattern)

Every feature needs:
1. **Positive**: Happy path test
2. **Negative**: Error handling test
3. **Bulk**: 251+ records test

**Example**:
```apex
@IsTest
static void testPositive() {
    Account acc = new Account(Name = 'Test', Industry = 'Tech');
    insert acc;
    Assert.areEqual('Tech', [SELECT Industry FROM Account WHERE Id = :acc.Id].Industry);
}

@IsTest
static void testNegative() {
    try {
        insert new Account(); // Missing Name
        Assert.fail('Expected DmlException');
    } catch (DmlException e) {
        Assert.isTrue(e.getMessage().contains('REQUIRED_FIELD_MISSING'));
    }
}

@IsTest
static void testBulk() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 251; i++) {
        accounts.add(new Account(Name = 'Bulk ' + i));
    }
    insert accounts;
    Assert.areEqual(251, [SELECT COUNT() FROM Account]);
}
```

**See**:
- [references/testing-patterns.md](references/testing-patterns.md) - Exception types, mocking, Test Data Factory
- [references/testing-guide.md](references/testing-guide.md) - Complete testing reference

---

## Common Exception Types

When writing test classes, use these specific exception types:

| Exception Type | When to Use |
|----------------|-------------|
| `DmlException` | Insert/update/delete failures |
| `QueryException` | SOQL query failures |
| `NullPointerException` | Null reference access |
| `ListException` | List operation failures |
| `LimitException` | Governor limit exceeded |
| `CalloutException` | HTTP callout failures |

**Example**:
```apex
@IsTest
static void testExceptionHandling() {
    try {
        insert new Account(); // Missing required Name
        Assert.fail('Expected DmlException was not thrown');
    } catch (DmlException e) {
        Assert.isTrue(e.getMessage().contains('REQUIRED_FIELD_MISSING'),
            'Expected REQUIRED_FIELD_MISSING but got: ' + e.getMessage());
    }
}
```

**See**: [references/testing-patterns.md](references/testing-patterns.md#common-exception-types) for complete reference

---

## LSP-Based Validation (Auto-Fix Loop)

The sf-apex skill includes Language Server Protocol (LSP) integration for real-time syntax validation. This enables Claude to automatically detect and fix Apex syntax errors during code authoring.

### How It Works

1. **PostToolUse Hook**: After every Write/Edit operation on `.cls` or `.trigger` files, the LSP hook validates syntax
2. **Apex Language Server**: Uses Salesforce's official `apex-jorje-lsp.jar` (from VS Code extension)
3. **Auto-Fix Loop**: If errors are found, Claude receives diagnostics and auto-fixes them (max 3 attempts)
4. **Two-Layer Validation**:
   - **LSP Validation**: Fast syntax checking (~500ms)
   - **150-Point Validation**: Semantic analysis for best practices

### Prerequisites

For LSP validation to work, users must have:
- **VS Code Salesforce Extension Pack**: VS Code → Extensions → "Salesforce Extension Pack"
- **Java 11+**: https://adoptium.net/temurin/releases/

**Graceful Degradation**: If LSP is unavailable, validation silently skips - the skill continues to work with only 150-point semantic validation.

**See**: [references/troubleshooting.md](references/troubleshooting.md#lsp-based-validation-auto-fix-loop) for complete LSP guide

---

## Cross-Skill Integration

| Skill | When to Use | Example |
|-------|-------------|---------|
| sf-metadata | Discover object/fields before coding | Use the **sf-metadata** skill: "Describe Invoice__c" |
| sf-data | Generate 251+ test records after deploy | Use the **sf-data** skill: "Create 251 Accounts for bulk testing" |
| sf-deploy | Deploy to org - see Phase 4 | Use the **sf-deploy** skill: "Deploy to [org]" |
| sf-flow | Create Flow that calls your Apex | See @InvocableMethod section above |
| sf-lwc | Create LWC that calls your Apex | `@AuraEnabled` controller patterns |

---

## Reference Documentation

### Quick Guides (references/)
| Guide | Description |
|-------|-------------|
| [patterns-deep-dive.md](references/patterns-deep-dive.md) | TAF, @InvocableMethod, async patterns, service layer |
| [security-guide.md](references/security-guide.md) | CRUD/FLS, sharing, SOQL injection, guardrails |
| [bulkification-guide.md](references/bulkification-guide.md) | Governor limits, collections, monitoring |
| [testing-patterns.md](references/testing-patterns.md) | Exception types, mocking, Test Data Factory, coverage |
| [anti-patterns.md](references/anti-patterns.md) | Code smells, red flags, refactoring patterns |
| [troubleshooting.md](references/troubleshooting.md) | LSP validation, deployment errors, debug logs |

### Full Documentation (references/)
| Document | Description |
|----------|-------------|
| `best-practices.md` | Bulkification, collections, null safety, guard clauses, DML performance |
| `code-smells-guide.md` | Code smells detection and refactoring patterns |
| `design-patterns.md` | 12 patterns including Domain Class, Abstraction Levels |
| `trigger-actions-framework.md` | TAF setup and advanced patterns |
| `automation-density-guide.md` | Automation density framework, hybrid patterns, CDC async |
| `security-guide.md` | Complete CRUD/FLS and sharing reference |
| `testing-guide.md` | Complete test patterns and mocking |
| `naming-conventions.md` | Variable, method, class naming rules |
| `solid-principles.md` | SOLID principles for Apex |
| `code-review-checklist.md` | 150-point scoring criteria |
| `flow-integration.md` | Complete @InvocableMethod guide |
| `triangle-pattern.md` | Flow-LWC-Apex integration |
| `llm-anti-patterns.md` | **NEW**: Common LLM code generation mistakes (Java types, non-existent methods, Map patterns) |

**Path**: `~/.claude/plugins/marketplaces/sf-skills/sf-apex/references/`

---

## Dependencies

**All optional**: sf-deploy, sf-metadata, sf-data. Install: `/plugin install github:Jaganpro/sf-skills/[skill-name]`

---

## Notes

- **API Version**: 62.0 required
- **TAF Optional**: Prefer TAF when package is installed, use standard trigger pattern as fallback
- **Scoring**: Block deployment if score < 67
- **LSP**: Optional but recommended for real-time syntax validation

---

## License

MIT License.
Copyright (c) 2024-2025 Jag Valaiyapathy
