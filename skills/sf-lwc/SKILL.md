---
name: sf-lwc
description: >
  Lightning Web Components with PICKLES methodology and 165-point scoring.
  TRIGGER when: user creates/edits LWC components, touches lwc/**/*.js, .html,
  .css, .js-meta.xml files, or asks about wire service, SLDS, or Jest LWC tests;
  also phrases like "create a component", "add an LWC", "build a Lightning component",
  "wire this to Apex".
  DO NOT TRIGGER when: Apex classes (use sf-apex), Aura components, or Visualforce.
license: MIT
metadata:
  version: "2.1.0"
  author: "Jag Valaiyapathy"
  scoring: "165 points across 8 categories (SLDS 2 + Dark Mode compliant)"
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "165-pt rubric in references/scoring-and-testing.md (8 categories: SLDS Class Usage, Accessibility, Dark Mode Readiness, SLDS Migration, Styling Hooks, Component Structure, Performance, PICKLES Compliance), mapped onto the 4-dimension default rubric from skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  lwc_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 15
      description: "Component renders correctly and works as specified. Maps to Component Structure (15) + actual functional behavior. The component must render without console errors, fire its declared events, and respond to its declared @api properties."
      automatic_hard_fail_rules:
        - "Any @track on a primitive value (deprecated since LWC API 35; use plain field reactivity instead)"
        - "Any direct DOM manipulation that bypasses the LWC reactivity model (e.g., document.querySelector for component-internal state)"
        - "Any infinite re-render loop (e.g., setting @track inside a getter, mutating a prop directly)"
    - name: Robustness
      max: 25
      hard_fail_below: 12
      description: "Component is accessible and survives bad input. Maps to Accessibility (25). Keyboard navigation works, ARIA labels present, screen reader announces correctly, alt-text on images. Real users include disabled users."
      automatic_hard_fail_rules:
        - "Any interactive element (button, link, input) without a visible label, aria-label, or aria-labelledby"
        - "Any image element without alt text (alt='' explicitly is OK for decorative; missing alt is hard-fail)"
        - "Any custom interactive widget (clickable div) without role + tabindex + keyboard handler"
        - "Any color-only conveying information without redundant text/icon (color-blind users excluded)"
    - name: Fit
      max: 25
      hard_fail_below: 10
      description: "Component matches SLDS 2 + Dark Mode + PICKLES conventions. Maps to SLDS Class Usage (25) + SLDS Migration (20) + Styling Hooks (20) + Dark Mode Readiness (25) + PICKLES Compliance (25). The largest mapped category — Fit captures the soul of LWC quality."
      automatic_hard_fail_rules:
        - "Any hardcoded color value (#hex, rgb(), named colors) in component CSS instead of --slds-g-color-* tokens"
        - "Any deprecated SLDS 1 utility class or token (slds-text-color_default, --lwc-color-text-default, etc.)"
        - "Any @import of a stylesheet outside the component bundle (LWC bundles are self-contained)"
        - "Any base component reimplemented from scratch (lightning-button, lightning-card, lightning-record-form etc. exist for a reason)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Component renders efficiently and respects platform limits. Maps to Performance (10) + responsive rendering. No unnecessary re-renders, lazy load with lwc:if where appropriate, debounce rapid user input, cache expensive computed values."
      automatic_hard_fail_rules:
        - "Any !important rule in component CSS (signals SLDS hook bypass, breaks dark mode and theming)"
        - "Any synchronous network call inside a getter or render path (blocks UI; use @wire or onConnect)"
        - "Any debounce-missing rapid-input handler (search-as-you-type without debounce; fires N requests for N keystrokes)"
  test_rubric:
    unit:
      required: true
      criteria: "Jest test bundle exists. Covers @api property setters, public methods, dispatched events, and primary user interactions. ≥80% coverage of the component's public surface."
    integration:
      required: true
      criteria: "Component deploys to a connected org and appears in Lightning App Builder without errors. Required attributes resolve. Renders to a real page without console errors."
    smoke:
      required: true
      criteria: "Primary user interaction completes end-to-end (e.g., for a 'donor signup' component: filling all fields and clicking Submit dispatches the expected event with the correct payload)."
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://developer.salesforce.com/docs/platform/lwc/guide/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/component-library/overview/components
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/lwc
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_lwc.htm
---

# sf-lwc: Lightning Web Components Development

Expert frontend engineer specializing in Lightning Web Components for Salesforce. Generate production-ready LWC components using the **PICKLES Framework** for architecture, with proper data binding, Apex/GraphQL integration, event handling, SLDS 2 styling, and comprehensive Jest tests.

## Core Responsibilities

1. **Component Scaffolding**: Generate complete LWC bundles (JS, HTML, CSS, meta.xml)
2. **PICKLES Architecture**: Apply structured design methodology for robust components
3. **Wire Service Patterns**: Implement @wire decorators for data fetching (Apex & GraphQL)
4. **Apex/GraphQL Integration**: Connect LWC to backend with @AuraEnabled and GraphQL
5. **Event Handling**: Component communication (CustomEvent, LMS, pubsub)
6. **Lifecycle Management**: Proper use of connectedCallback, renderedCallback, etc.
7. **Jest Testing**: Generate comprehensive unit tests with advanced patterns
8. **Accessibility**: WCAG compliance with ARIA attributes, focus management
9. **Dark Mode**: SLDS 2 compliant styling with global styling hooks
10. **Performance**: Lazy loading, virtual scrolling, debouncing, efficient rendering

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Component patterns** | [references/component-patterns.md](references/component-patterns.md) | Wire, GraphQL, Modal, Navigation, TypeScript |
| **LMS guide** | [references/lms-guide.md](references/lms-guide.md) | Lightning Message Service deep dive |
| **Jest testing** | [references/jest-testing.md](references/jest-testing.md) | Advanced testing patterns |
| **Accessibility** | [references/accessibility-guide.md](references/accessibility-guide.md) | WCAG compliance, ARIA, focus management |
| **Performance** | [references/performance-guide.md](references/performance-guide.md) | Dark mode migration, lazy loading, optimization |
| **Scoring & testing** | [references/scoring-and-testing.md](references/scoring-and-testing.md) | 165-point SLDS 2 scoring, dark mode checklist, Jest patterns |
| **Advanced features** | [references/advanced-features.md](references/advanced-features.md) | Flow Screen integration, TypeScript, Dashboards, Agentforce |
| **State management** | [references/state-management.md](references/state-management.md) | @track, Singleton Store, @lwc/state |
| **Template anti-patterns** | [references/template-anti-patterns.md](references/template-anti-patterns.md) | LLM template mistakes |
| **Async notifications** | [references/async-notification-patterns.md](references/async-notification-patterns.md) | Platform Events + empApi |
| **Flow integration** | [references/flow-integration-guide.md](references/flow-integration-guide.md) | Flow-LWC communication |

---

## Eval Harness Wrap (Stage B)

When `eval_harness.enabled: true` (set in frontmatter above), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md) — a separate skill that owns the orchestration of planner / implementer / evaluator subagents and grades the generated LWC bundle in fresh context.

**This is Stage B of the harness rollout** (per `content/specs/skill-eval-harness-SPEC.md` §14). Stage A wrapped the demo orchestrator's artifact-producing phases. Stage B extends to the implementation skills those phases delegate to. When sf-demo-validate's Phase 5 (or another wrapped skill) invokes this skill to generate an LWC, the inner harness fires *inside* the outer harness — nested adversarial evaluation.

### Why this matters for LWC specifically

The most common LWC failure modes in production aren't compile errors — they're:
- A11y regressions (interactive widget without keyboard support, image without alt-text)
- Hardcoded colors that break Dark Mode after the org enables it
- Deprecated SLDS 1 tokens that look fine today and silently break in a future release
- Reimplementing a base component poorly instead of using `lightning-*`

These slip past self-evaluation because the component "works" in basic visual testing. They get caught by adversarial evaluation that runs the SLDS migration probe, the a11y probe, and the hardcoded-color probe deterministically.

### How the harness composes with this skill

| What | Owned by |
|---|---|
| 165-pt scoring rubric (8 categories) | This skill (`references/scoring-and-testing.md`) |
| 4-dimension SPEC default rubric mapping (Correctness / Robustness / Fit / Performance) | This skill's frontmatter `lwc_dimensions` block |
| PICKLES architecture methodology, SLDS 2 patterns, Dark Mode compliance | This skill (existing references) |
| Three-agent loop control (SHIP / ITERATE / SPEC-DEFECT verdicts, hard-fail floors, replan budget) | sf-skill-eval-harness |
| Subagent prompts (planner / implementer / evaluator) | sf-skill-eval-harness/prompts/ |
| Append-only TRACE.md primary debugging loop | sf-skill-eval-harness |

### Critical evaluator checks for LWC artifacts

The evaluator runs four deterministic verifications:

1. **A11y probe** — grep template files for interactive elements without aria-label / aria-labelledby; grep for `<img>` without `alt`; grep for `<div onclick=>` without `role` + `tabindex`. Each pattern = Robustness -1; persistent absence = Robustness hard-fail.
2. **SLDS hardcoded-color probe** — grep CSS for `#[0-9a-fA-F]{3,6}`, `rgb(`, named CSS colors. Any hit = Fit automatic hard-fail (Dark Mode breaker).
3. **SLDS deprecation probe** — grep for SLDS 1 utility class names (`slds-text-color_default`, etc.) and deprecated CSS variables (`--lwc-*` instead of `--slds-g-*`). Any hit = Fit automatic hard-fail.
4. **Reactivity model probe** — grep JS for `@track` on primitives (deprecated), direct `document.querySelector` on component-internal DOM (bypasses reactivity), `!important` in CSS (signals SLDS hook bypass). Each pattern = Correctness or Performance hard-fail per the specific rule.

### Disabling the harness

Set `eval_harness.enabled: false` in this skill's frontmatter (or remove the `eval_harness:` block entirely). The PICKLES methodology runs as before with no harness wrap.

See [the harness skill's SKILL.md](../../skills-cursor/sf-skill-eval-harness/SKILL.md) for the full orchestration playbook.

---

## PICKLES Framework (Architecture Methodology)

```
┌─────────────────────────────────────────────────────────────────────┐
│                     PICKLES FRAMEWORK                                │
├─────────────────────────────────────────────────────────────────────┤
│  P → Prototype    │  Validate ideas with wireframes & mock data    │
│  I → Integrate    │  Choose data source (LDS, Apex, GraphQL, API)  │
│  C → Composition  │  Structure component hierarchy & communication │
│  K → Kinetics     │  Handle user interactions & event flow         │
│  L → Libraries    │  Leverage platform APIs & base components      │
│  E → Execution    │  Optimize performance & lifecycle hooks        │
│  S → Security     │  Enforce permissions, FLS, and data protection │
└─────────────────────────────────────────────────────────────────────┘
```

| Principle | Key Actions |
|-----------|-------------|
| **P - Prototype** | Wireframes, mock data, stakeholder review, separation of concerns |
| **I - Integrate** | LDS for single records, Apex for complex queries, GraphQL for related data |
| **C - Composition** | `@api` for parent→child, CustomEvent for child→parent, LMS for cross-DOM |
| **K - Kinetics** | Debounce search (300ms), disable during submit, keyboard navigation |
| **L - Libraries** | Use `lightning/*` modules, base components, avoid reinventing |
| **E - Execution** | Lazy load with `lwc:if`, cache computed values, avoid infinite loops |
| **S - Security** | `WITH SECURITY_ENFORCED`, input validation, FLS/CRUD checks |

**For detailed PICKLES implementation patterns, see [references/component-patterns.md](references/component-patterns.md)**

---

## Subagent Delegation

LWC work is one of the strongest fits for subagent delegation in this repo because most multi-component features build N independent bundles from N independent specs. Apply the policy in [`sf-subagent-orchestration`](../sf-subagent-orchestration/SKILL.md):

| PICKLES phase | Mode | Why |
|---|---|---|
| **P - Prototype** (wireframes, mock data, stakeholder dialog) | **Parent** | Decision-laden + user-facing |
| **I - Integrate** (data source choice: LDS / Apex / GraphQL) | **Parent** | Architectural call that constrains every later phase |
| **C - Composition** (3+ independent component bundles) | `generalPurpose` subagents in **parallel** | One bundle per agent; parent integrates the composed view |
| **C - Composition** (1-2 components or tightly coupled parent+child) | **Parent** | Subagent overhead not worth it |
| **K - Kinetics**, **L - Libraries**, **S - Security** policy decisions | **Parent** | Cross-cutting; needs full picture |
| **E - Execution** (Jest test authoring across N components) | `generalPurpose` subagents in parallel | One test file per component, parent runs the suite |
| **Deployment + Jest run** (`sf project deploy start`, `sfdx force:lightning:lwc:test:run`) | `shell` subagent | Verbose CLI output stays out of parent context |

**Default rule**: when the user asks for "build me 3+ LWCs" / "build the homepage components" / "scaffold the donor portal LWCs", fire one `generalPurpose` subagent per component in a **single tool-call message**. Each subagent receives: the component spec, the brand tokens / SLDS 2 styling hooks, the data source choice from Phase I, and the 165-point scoring rubric as acceptance criteria. Each returns paths + self-scored result. The parent never re-reads the generated bundles unless integration requires it.

For the canonical worked example of this pattern across 6 LWCs in parallel, see the `sf-nonprofit-experience-cloud-build` Phase 3 delegation note.

---

## Key Component Patterns

### Wire vs Imperative Apex Calls

| Aspect | Wire (@wire) | Imperative Calls |
|--------|--------------|------------------|
| **Execution** | Automatic / Reactive | Manual / Programmatic |
| **DML** | Read-Only | Insert/Update/Delete |
| **Data Updates** | Auto on param change | Manual refresh |
| **Caching** | Built-in | None |

**Quick Decision**: Use `@wire` for read-only display with auto-refresh. Use imperative for user actions, DML, or when you need control over timing.

### Data Source Decision Tree

| Scenario | Recommended Approach |
|----------|---------------------|
| Single record by ID | Lightning Data Service (`getRecord`) |
| Simple record CRUD | `lightning-record-form` / `lightning-record-edit-form` |
| Complex queries | Apex with `@AuraEnabled(cacheable=true)` |
| Related records | GraphQL wire adapter |
| Real-time updates | Platform Events / **Pub/Sub API** (empApi for LWC) |
| External data | Named Credentials + Apex callout |

### Communication Patterns

| Pattern | Direction | Use Case |
|---------|-----------|----------|
| `@api` properties | Parent → Child | Pass data down |
| Custom Events | Child → Parent | Bubble actions up |
| Lightning Message Service | Any → Any | Cross-DOM communication |
| Pub/Sub | Sibling → Sibling | Same page, no hierarchy |

**Decision Tree**: Same parent? → Events up, `@api` down. Different DOM trees? → LMS. LWC ↔ Aura/VF? → LMS.

### Lifecycle Hook Guidance

| Hook | When to Use | Avoid |
|------|-------------|-------|
| `constructor()` | Initialize properties | DOM access (not ready) |
| `connectedCallback()` | Subscribe to events, fetch data | Heavy processing |
| `renderedCallback()` | DOM-dependent logic | Infinite loops, property changes |
| `disconnectedCallback()` | Cleanup subscriptions/listeners | Async operations |

---

## SLDS 2 Validation & Dark Mode

> See [references/scoring-and-testing.md](references/scoring-and-testing.md) for the full 165-point scoring breakdown, dark mode checklist, styling hooks reference, and Jest testing patterns.

**Quick summary**: 8 categories, 165 total points. 150+ Production-ready | 125+ Good | 100+ Functional | <75 Needs work. Dark mode requires CSS variables only (`--slds-g-color-*`), no hardcoded colors.

---

## Accessibility

WCAG compliance is mandatory for all components.

| Requirement | Implementation |
|-------------|----------------|
| **Labels** | `label` on inputs, `aria-label` on icons |
| **Keyboard** | Enter/Space triggers, Tab navigation |
| **Focus** | Visible indicator, logical order, focus traps in modals |
| **Live Regions** | `aria-live="polite"` for dynamic content |
| **Contrast** | 4.5:1 minimum for text |

**For comprehensive guide, see [references/accessibility-guide.md](references/accessibility-guide.md)**

---

## Metadata Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Account Dashboard</masterLabel>
    <description>SLDS 2 compliant account dashboard with dark mode support</description>
    <targets>
        <target>lightning__RecordPage</target>
        <target>lightning__AppPage</target>
        <target>lightning__HomePage</target>
        <target>lightning__FlowScreen</target>
        <target>lightningCommunity__Page</target>
        <target>lightning__Dashboard</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects><object>Account</object></objects>
            <property name="title" type="String" default="Dashboard"/>
            <property name="maxRecords" type="Integer" default="10"/>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

---

## Flow Screen & Advanced Features

> See [references/advanced-features.md](references/advanced-features.md) for Flow Screen integration (FlowAttributeChangeEvent, FlowNavigationFinishEvent), TypeScript support (API 66.0 GA), LWC in Dashboards (Beta), and Agentforce discoverability.

**Flow Screen quick reference**: `@api` inputs → `FlowAttributeChangeEvent` outputs → `FlowNavigationFinishEvent` for navigation. See also [references/flow-integration-guide.md](references/flow-integration-guide.md).

---

## Form Building Context

LWC is the **only form-building option with Jest unit testing**. For forms requiring automated test coverage or CI/CD validation, prefer LWC over Screen Flows or Dynamic Forms.

**Complexity spectrum**: Dynamic Forms < Screen Flow < OmniStudio < Screen Flow + LWC < Full LWC

Choose the simplest tool that meets requirements — don't default to LWC when Screen Flow suffices. See [sf-flow/references/form-building-guide.md](../sf-flow/references/form-building-guide.md) for the 5-tool comparison and decision tree.

---

## CLI Commands

| Command | Purpose |
|---------|---------|
| `sf template generate lightning component --type lwc` | Create new LWC |
| `sf template generate flexipage --name MyPage --template DefaultAppPage` | Generate FlexiPage metadata |
| `sf force lightning lwc test run` | Run Jest tests |
| `sf force lightning lwc test run --watch` | Watch mode |
| `sf project deploy start -m LightningComponentBundle` | Deploy LWC |

```bash
# Generate new component
sf template generate lightning component \
  --name accountDashboard \
  --type lwc \
  --output-dir force-app/main/default/lwc

# Run tests with coverage
sf force lightning lwc test run -- --coverage

# Specific component tests
sf force lightning lwc test run --spec force-app/main/default/lwc/accountList/__tests__
```

---

## Cross-Skill Integration

| Skill | Use Case |
|-------|----------|
| sf-apex | Generate Apex controllers (`@AuraEnabled`, `@InvocableMethod`) |
| sf-flow | Embed components in Flow Screens, pass data to/from Flow |
| sf-testing | Generate Jest tests |
| sf-deploy | Deploy components |
| sf-metadata | Create message channels |

---

## Dependencies

**Required**: Target org with LWC support (API 45.0+), `sf` CLI authenticated
**For Testing**: Node.js 18+, Jest (`@salesforce/sfdx-lwc-jest`)
**For SLDS Validation**: `@salesforce-ux/slds-linter` (optional)

---

## External References

- [PICKLES Framework (Salesforce Ben)](https://www.salesforceben.com/the-ideal-framework-for-architecting-salesforce-lightning-web-components/)
- [LWC Recipes (GitHub)](https://github.com/trailheadapps/lwc-recipes)
- [SLDS 2 Transition Guide](https://www.lightningdesignsystem.com/2e1ef8501/p/8184ad-transition-to-slds-2)
- [James Simone - Advanced Jest Testing](https://www.jamessimone.net/blog/joys-of-apex/advanced-lwc-jest-testing/)
