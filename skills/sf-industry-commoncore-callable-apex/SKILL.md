---
name: sf-industry-commoncore-callable-apex
description: >
  Salesforce Industries Common Core (OmniStudio/Vlocity) Apex callable generation and review with
  120-point scoring.
  TRIGGER when: user creates or reviews System.Callable classes, migrates
  `VlocityOpenInterface` / `VlocityOpenInterface2`, or builds Industries callable extensions used by
  OmniStudio, Integration Procedures, or DataRaptors; user asks for "Industries extension Apex",
  "custom callable for OmniStudio", or "build a System.Callable class for an IP/OmniScript".
  DO NOT TRIGGER when: generic non-Industries Apex (use sf-apex), generic Apex classes/triggers
  (use sf-apex), building Integration Procedures (use sf-industry-commoncore-integration-procedure),
  authoring OmniScripts (use sf-industry-commoncore-omniscript), configuring Data Mappers
  (use sf-industry-commoncore-datamapper), or analyzing namespace/dependency issues
  (use sf-industry-commoncore-omnistudio-analyze).
license: MIT
metadata:
  version: "1.0.0"
  author: "Shreyas Dhond"
  scoring: "120 points across 7 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://developer.salesforce.com/docs/platform/omnistudio/guide/os-ccore.html
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_interface_System_Callable.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/industries
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_omnistudio.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric (7 categories: Contract & Dispatch 20 / Input Validation 20 / Security 20 / Error Handling 15 / Bulkification & Limits 20 / Testing 15 / Documentation 10) — mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  callable_apex_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 15
      description: "Contract + dispatch correctness. Maps to Contract & Dispatch (20) + Input Validation (20). Explicit versioned action list, switch-on action with default-throws, args.get('inputMap') / args.get('options') extracted with null guards, return envelope shape consistent across actions."
      automatic_hard_fail_rules:
        - "Dynamic method invocation or reflection driven by user-supplied action string (security + maintainability hole)"
        - "Default switch case that returns silently or returns success=false without typed exception or error envelope"
        - "Input map keys accessed without containsKey / null check (NullPointerException on missing key)"
        - "Inconsistent response shape across actions (some return Map, some return String, some return Boolean — caller can't trust the contract)"
        - "VlocityOpenInterface migration that changes action string names — breaks existing IP / OmniScript callers"
    - name: Robustness
      max: 25
      hard_fail_below: 18
      description: "Security floor. Maps to Security (20). Heaviest robustness floor — Industries callables are entry points invoked from declarative components; weak CRUD/FLS handling propagates security holes across every consumer."
      automatic_hard_fail_rules:
        - "Class declared without 'with sharing' (defaults to inherited or without — silent record-access escalation)"
        - "DML on user-supplied SObjects without Security.stripInaccessible() or explicit FLS check"
        - "SOQL on objects without WITH USER_MODE / WITH SECURITY_ENFORCED when callable runs in user context"
        - "Empty catch block or exception swallowed (catch (Exception e) {}) — silent failure"
        - "global class without an exception path — implementer can't surface errors to caller"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Pattern adherence + documentation. Maps to Documentation (10) + portions of Contract & Dispatch. Thin call() that delegates, ApexDoc on class + actions, action names documented + versioned, both Callable and Open Interface delegate to identical private methods when dual-supported."
      automatic_hard_fail_rules:
        - "Business logic inside call() / invokeMethod() instead of delegating to private methods (untestable + violates SRP)"
        - "Missing ApexDoc on the class and on each action's private method"
        - "Action names not documented — caller has to read source to know what's supported"
        - "Dual Callable + Open Interface implementations with diverging logic instead of shared private methods"
        - "Generic class name (Industries_Helper, MyCallable) instead of action-domain-named (Industries_OrderCallable)"
    - name: Performance
      max: 25
      hard_fail_below: 14
      description: "Bulkification + testing. Maps to Bulkification & Limits (20) + Testing (15). No SOQL/DML in loops, list inputs handled in single transaction, positive/negative/contract/bulk tests present."
      automatic_hard_fail_rules:
        - "SOQL or DML inside a for loop on input collection (governor-limit failure on bulk caller)"
        - "Single-record assumption when input map's documented schema includes a list (silently drops everything past the first record)"
        - "Test class missing the unsupported-action negative test"
        - "Test class with no bulk test (single-record only) when the action accepts list inputs"
        - "Long-running synchronous work (>5s expected duration) without async / Queueable handoff"
  test_rubric:
    unit:
      required: true
      criteria: "Apex compiles. ApexDoc present on class + action methods. Action dispatch is switch-based, default-throws, no reflection. Input null/contains-key guards in place."
    integration:
      required: true
      criteria: "Class deploys to a connected org. Test class achieves ≥75% coverage on each action method. Positive, negative (unsupported action), contract (missing/invalid input), and bulk tests all green. Security.stripInaccessible / FLS checks fire correctly under restricted-profile runAs."
    smoke:
      required: true
      criteria: "Real Industries consumer (Integration Procedure / OmniScript / Vlocity Open Interface caller) invokes the class via its action string and receives the documented envelope shape. Bulk invocation with list inputs completes within governor + CPU budgets."
---

# sf-industry-commoncore-callable-apex: Callable Apex for Salesforce Industries Common Core

Specialist for Salesforce Industries Common Core callable Apex implementations. Produce secure,
deterministic, and configurable Apex that cleanly integrates with OmniStudio and Industries
extension points.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 120-pt rubric across 7 categories, mapped onto the 4-dim shape with Robustness floor at 18 — Industries callables are entry points called from declarative components; weak CRUD/FLS handling propagates security holes across every consumer. Hard-fail rules block reflection-based dispatch, without-sharing classes, swallowed exceptions, SOQL/DML in loops, and inconsistent response envelopes. Disable with `eval_harness.enabled: false`.

---

## Core Responsibilities

1. **Callable Generation**: Build `System.Callable` classes with safe action dispatch
2. **Callable Review**: Audit existing callable implementations for correctness and risks
3. **Validation & Scoring**: Evaluate against the 120-point rubric
4. **Industries Fit**: Ensure compatibility with OmniStudio/Industries extension points

---

## Workflow (4-Phase Pattern)

### Phase 1: Requirements Gathering

Ask for:
- Entry point (OmniScript, Integration Procedure, DataRaptor, or other Industries hook)
- Action names (strings passed into `call`)
- Input/output contract (required keys, types, and response shape)
- Data access needs (objects/fields, CRUD/FLS rules)
- Side effects (DML, callouts, async requirements)

Then:
1. Scan for existing callable classes: `Glob: **/*Callable*.cls`
2. Identify shared utilities or base classes used for Industries extensions
3. Create a task list

---

### Phase 2: Design & Contract Definition

**Define the callable contract**:
- Action list (explicit, versioned strings)
- Input schema (required keys + types)
- Output schema (consistent response envelope)

**Recommended response envelope**:
```
{
  "success": true|false,
  "data": {...},
  "errors": [ { "code": "...", "message": "..." } ]
}
```

**Action dispatch rules**:
- Use `switch on action`
- Default case throws a typed exception
- No dynamic method invocation or reflection

**VlocityOpenInterface / VlocityOpenInterface2 contract mapping**:

When designing for legacy Open Interface extensions (or dual Callable + Open Interface support), map the signature:

```
invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options)
```

| Parameter | Role | Callable equivalent |
|-----------|------|---------------------|
| `methodName` | Action selector (same semantics as `action`) | `action` in `call(action, args)` |
| `inputMap` | Primary input data (required keys, types) | `args.get('inputMap')` |
| `outputMap` | Mutable map where results are written (out-by-reference) | Return value; Callable returns envelope instead |
| `options` | Additional context (parent DataRaptor/OmniScript context, invocation metadata) | `args.get('options')` |

Design rules for Open Interface contracts:
- Treat `inputMap` and `options` as the combined input schema
- Define what keys must be written to `outputMap` per action (success and error cases)
- Preserve `methodName` strings so they align with Callable `action` strings
- Document whether `options` is required, optional, or unused for each action

---

### Phase 3: Implementation Pattern

**Vanilla System.Callable** (flat args, no Open Interface coupling):

```apex
public with sharing class Industries_OrderCallable implements System.Callable {
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'createOrder' {
                return createOrder(args != null ? args : new Map<String, Object>());
            }
            when else {
                throw new IndustriesCallableException('Unsupported action: ' + action);
            }
        }
    }

    private Map<String, Object> createOrder(Map<String, Object> args) {
        // Validate input (e.g. args.get('orderId')), run business logic, return response envelope
        return new Map<String, Object>{ 'success' => true };
    }
}
```

Use the vanilla pattern when callers pass flat args and no VlocityOpenInterface integration is required.

**Callable skeleton** (same inputs as VlocityOpenInterface):

Use `inputMap` and `options` keys in `args` when integrating with Open Interface or when callers pass that structure:

```apex
public with sharing class Industries_OrderCallable implements System.Callable {
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (args != null && args.containsKey('inputMap'))
            ? (Map<String, Object>) args.get('inputMap') : (args != null ? args : new Map<String, Object>());
        Map<String, Object> options  = (args != null && args.containsKey('options'))
            ? (Map<String, Object>) args.get('options')  : new Map<String, Object>();
        if (inputMap == null) { inputMap = new Map<String, Object>(); }
        if (options  == null) { options  = new Map<String, Object>(); }

        switch on action {
            when 'createOrder' {
                return createOrder(inputMap, options);
            }
            when else {
                throw new IndustriesCallableException('Unsupported action: ' + action);
            }
        }
    }

    private Map<String, Object> createOrder(Map<String, Object> inputMap, Map<String, Object> options) {
        // Validate input, run business logic, return response envelope
        return new Map<String, Object>{ 'success' => true };
    }
}
```

**Input format**: Callers pass `args` as `{ 'inputMap' => Map<String, Object>, 'options' => Map<String, Object> }`. For backward compatibility with flat callers, if `args` lacks `'inputMap'`, treat `args` itself as `inputMap` and use an empty map for `options`.

**Implementation rules**:
1. Keep `call()` thin; delegate to private methods or service classes
2. Validate and coerce input types early (null-safe)
3. Enforce CRUD/FLS and sharing (`with sharing`, `Security.stripInaccessible()`)
4. Bulkify when args include record collections
5. Use `WITH USER_MODE` for SOQL when appropriate

**VlocityOpenInterface / VlocityOpenInterface2 implementation**:

When implementing `omnistudio.VlocityOpenInterface` or `omnistudio.VlocityOpenInterface2`, use the signature:

```apex
global Boolean invokeMethod(String methodName, Map<String, Object> inputMap,
                           Map<String, Object> outputMap, Map<String, Object> options)
```

Open Interface skeleton:

```apex
global with sharing class Industries_OrderOpenInterface implements omnistudio.VlocityOpenInterface2 {
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap,
                                Map<String, Object> outputMap, Map<String, Object> options) {
        switch on methodName {
            when 'createOrder' {
                Map<String, Object> result = createOrder(inputMap, options);
                outputMap.putAll(result);
                return true;
            }
            when else {
                outputMap.put('success', false);
                outputMap.put('errors', new List<Map<String, Object>>{
                    new Map<String, Object>{ 'code' => 'UNSUPPORTED_ACTION', 'message' => 'Unsupported action: ' + methodName }
                });
                return false;
            }
        }
    }

    private Map<String, Object> createOrder(Map<String, Object> inputMap, Map<String, Object> options) {
        // Validate input, run business logic, return response envelope
        return new Map<String, Object>{ 'success' => true, 'data' => new Map<String, Object>() };
    }
}
```

Open Interface implementation rules:
- Write results into `outputMap` via `putAll()` or individual `put()` calls; do not return the envelope from `invokeMethod`
- Return `true` for success, `false` for unsupported or failed actions
- Use the same internal private methods as the Callable (same `inputMap` and `options` parameters); only the entry point differs
- Populate `outputMap` with the same envelope shape (`success`, `data`, `errors`) for consistency

Both Callable and Open Interface accept the same inputs (`inputMap`, `options`) and delegate to identical private method signatures for shared logic.

---

### Phase 4: Testing & Validation

Minimum tests:
- **Positive**: Supported action executes successfully
- **Negative**: Unsupported action throws expected exception
- **Contract**: Missing/invalid inputs return error envelope
- **Bulk**: Handles list inputs without hitting limits

**Example test class**:
```apex
@IsTest
private class Industries_OrderCallableTest {
    @IsTest
    static void testCreateOrder() {
        System.Callable svc = new Industries_OrderCallable();
        Map<String, Object> args = new Map<String, Object>{
            'inputMap' => new Map<String, Object>{ 'orderId' => '001000000000001' },
            'options'  => new Map<String, Object>()
        };
        Map<String, Object> result =
            (Map<String, Object>) svc.call('createOrder', args);
        Assert.isTrue((Boolean) result.get('success'));
    }

    @IsTest
    static void testUnsupportedAction() {
        try {
            System.Callable svc = new Industries_OrderCallable();
            svc.call('unknownAction', new Map<String, Object>());
            Assert.fail('Expected IndustriesCallableException');
        } catch (IndustriesCallableException e) {
            Assert.isTrue(e.getMessage().contains('Unsupported action'));
        }
    }
}
```

---

## Migration: VlocityOpenInterface to System.Callable

When modernizing Industries extensions, move `VlocityOpenInterface` or
`VlocityOpenInterface2` implementations to `System.Callable` and keep the
action contract stable. Use the Salesforce guidance as the source of truth.
[Salesforce Help](https://help.salesforce.com/s/articleView?id=ind.v_dev_t_callable_implementations_651821.htm&type=5)

**Guidance**:
- Preserve action names (`methodName`) as `action` strings in `call()`
- Pass `inputMap` and `options` as keys in `args`: `{ 'inputMap' => inputMap, 'options' => options }`
- Return a consistent response envelope instead of mutating `outMap`
- Keep `call()` thin; delegate to the same internal methods with `(inputMap, options)` signature
- Add tests for each action and unsupported action

**Example migration (pattern)**:
```apex
// BEFORE: VlocityOpenInterface2
global class OrderOpenInterface implements omnistudio.VlocityOpenInterface2 {
    global Boolean invokeMethod(String methodName, Map<String, Object> input,
                                Map<String, Object> output,
                                Map<String, Object> options) {
        if (methodName == 'createOrder') {
            output.putAll(createOrder(input, options));
            return true;
        }
        return false;
    }
}

// AFTER: System.Callable (same inputs: inputMap, options)
public with sharing class OrderCallable implements System.Callable {
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = args != null ? (Map<String, Object>) args.get('inputMap') : new Map<String, Object>();
        Map<String, Object> options  = args != null ? (Map<String, Object>) args.get('options')   : new Map<String, Object>();
        if (inputMap == null) { inputMap = new Map<String, Object>(); }
        if (options  == null) { options  = new Map<String, Object>(); }

        switch on action {
            when 'createOrder' {
                return createOrder(inputMap, options);
            }
            when else {
                throw new IndustriesCallableException('Unsupported action: ' + action);
            }
        }
    }
}
```

---

## Best Practices (120-Point Scoring)

| Category | Points | Key Rules |
|----------|--------|-----------|
| **Contract & Dispatch** | 20 | Explicit action list; `switch on`; versioned action strings |
| **Input Validation** | 20 | Required keys validated; types coerced safely; null guards |
| **Security** | 20 | `with sharing`; CRUD/FLS checks; `Security.stripInaccessible()` |
| **Error Handling** | 15 | Typed exceptions; consistent error envelope; no empty catch |
| **Bulkification & Limits** | 20 | No SOQL/DML in loops; supports list inputs |
| **Testing** | 15 | Positive/negative/contract/bulk tests |
| **Documentation** | 10 | ApexDoc for class and action methods |

**Thresholds**: ✅ 90+ (Ready) | ⚠️ 70-89 (Review) | ❌ <70 (Block)

---

## ⛔ Guardrails (Mandatory)

Stop and ask the user if any of these would be introduced:
- Dynamic method execution based on user input (no reflection)
- SOQL/DML inside loops
- `without sharing` on callable classes
- Silent failures (empty catch, swallowed exceptions)
- Inconsistent response shapes across actions

---

## Common Anti-Patterns

- `call()` contains business logic instead of delegating
- Action names are unversioned or not documented
- Input maps assumed to have keys without checks
- Mixed response types (sometimes Map, sometimes String)
- No tests for unsupported actions

---

## Cross-Skill Integration

| Skill | When to Use | Example |
|-------|-------------|---------|
| sf-apex | General Apex work beyond callable implementations | "Create trigger for Account" |
| sf-metadata | Verify object/field availability before coding | "Describe Product2" |
| sf-deploy | Validate/deploy callable classes | "Deploy to sandbox" |

---

## Reference Skill

Use the core Apex standards, testing patterns, and guardrails in:
- [skills/sf-apex/SKILL.md](../sf-apex/SKILL.md)

---

## Bundled Examples

- [examples/Test_QuoteByProductCallable/](examples/Test_QuoteByProductCallable/) — read-only query example with `WITH USER_MODE`
- [examples/Test_VlocityOpenInterfaceConversion/](examples/Test_VlocityOpenInterfaceConversion/) — migration from legacy `VlocityOpenInterface`
- [examples/Test_VlocityOpenInterface2Conversion/](examples/Test_VlocityOpenInterface2Conversion/) — migration from `VlocityOpenInterface2`

## Notes

- Prefer deterministic, side-effect-aware callable actions
- Keep action contracts stable; introduce new actions for breaking changes
- Avoid long-running work in synchronous callables; use async when needed

---
