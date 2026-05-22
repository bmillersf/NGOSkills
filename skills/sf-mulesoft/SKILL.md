---
name: sf-mulesoft
description: >
  MuleSoft Anypoint Platform, MuleSoft for Flow, and DataWeave integration
  architecture with 140-point scoring.
  TRIGGER when: user designs or implements Anypoint Platform projects,
  RAML/OAS API specs, Mule applications, Mule flows, DataWeave 2.x
  transformations, API Manager policies, Exchange assets, Runtime Manager
  deployments, MuleSoft for Flow (low-code connector in SF Flow Builder),
  MuleSoft Composer flows, or Anypoint Studio projects; or says "build a
  Mule app", "publish API to Exchange", "DataWeave transform", "RAML
  design-first", "MuleSoft for Flow action", "Anypoint Studio project",
  "MuleSoft Composer flow", "API Manager policy", "Runtime Fabric deploy".
  DO NOT TRIGGER when: user wants Salesforce-side Named Credentials,
  External Services, Apex HTTP callouts, Platform Events, CDC, or Pub/Sub
  API subscription (use sf-integration); OAuth / Connected App / JWT
  Bearer configuration on the Salesforce side (use sf-connected-apps);
  pure Apex code without a Mule app (use sf-apex); native SF Flow with no
  MuleSoft connector (use sf-flow); data import/export via sf CLI (use
  sf-data); OmniStudio Integration Procedures (use
  sf-industry-commoncore-integration-procedure — that is an OmniStudio
  server-side orchestrator, not a Mule app).
license: MIT
compatibility: "Requires MuleSoft Anypoint Platform subscription; MuleSoft for Flow requires Salesforce + MuleSoft entitlement"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "140 points across 7 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-04
upstream_refs:
  - url: https://docs.mulesoft.com
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.platform_events_mulesoft.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://docs.mulesoft.com/mulesoft-composer/
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_mulesoft.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "140-pt rubric inline (7 categories: API Design 20, Mule Implementation 25, DataWeave Quality 20, Policies + Security 20, Testing 20, Deployment + Ops 20, Boundary Respect 15), mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  mulesoft_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Mule app + DataWeave correct. Maps to Mule Implementation (25) + DataWeave Quality (20)."
      automatic_hard_fail_rules:
        - "Any DataWeave script with mutable state (impure functions break test reproducibility)"
        - "Any error handler catching generic exception type without specific handlers (silent failure cascade)"
        - "Any Mule flow using Java where DataWeave would suffice (unmaintainable, test-resistant)"
    - name: Robustness
      max: 25
      hard_fail_below: 14
      description: "Policies + security applied. Maps to Policies + Security (20) + Testing (20). OAuth/Client ID Enforcement, rate limit, secrets in Secure Properties."
      automatic_hard_fail_rules:
        - "Any API without OAuth or Client ID Enforcement (open endpoint)"
        - "Any secret in plain config file (must be in Secure Properties or vault)"
        - "Any API without rate limit policy (DDoS risk)"
    - name: Fit
      max: 25
      hard_fail_below: 10
      description: "Spec-first + boundary respect. Maps to API Design (20) + Boundary Respect (15) — most-failed category. Don't re-implement Salesforce-side concerns inside Mule."
      automatic_hard_fail_rules:
        - "Any duplicate Named-Credential / OAuth logic in Mule when sf-integration / sf-connected-apps owns it"
        - "Any API built without RAML/OAS spec drafted first (no contract for consumers)"
    - name: Performance
      max: 25
      hard_fail_below: 14
      description: "Deployment + ops correct. Maps to Deployment + Ops (20). CloudHub 2.0 / Fabric chosen correctly, per-env params, alerts + log retention."
      automatic_hard_fail_rules:
        - "Any deploy without per-env config (prod creds in dev YAML)"
        - "Any API without alerts on error rate / latency"
  test_rubric:
    unit:
      required: true
      criteria: "MUnit coverage ≥ 80%. DataWeave fixture-based tests."
    integration:
      required: true
      criteria: "Integration test against real connector (not just mocked)."
    smoke:
      required: true
      criteria: "End-to-end API call from external consumer through Mule to Salesforce returns expected payload."
---

# sf-mulesoft: MuleSoft Anypoint + MuleSoft for Flow + DataWeave

Owns everything that runs on **Anypoint Platform** or extends Salesforce via a MuleSoft runtime: Mule applications, flows, DataWeave transforms, API specifications (RAML / OAS), Exchange assets, API Manager policies, Runtime Manager / CloudHub 2.0 / Runtime Fabric deployments, MuleSoft Composer (low-code iPaaS), and MuleSoft for Flow (low-code Mule connector inside Salesforce Flow Builder).

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). Three subagents grade against the 140-pt rubric in fresh context. Boundary Respect is the most-failed category in the rubric — Mule engineers commonly re-implement Salesforce-side concerns inside Mule, fragmenting ownership. Hard-fail rule prevents duplicate Named-Credential logic. Disable with `eval_harness.enabled: false`.

---

## When This Skill Owns the Task

Use `sf-mulesoft` when the work involves:

- **Anypoint Studio** projects (Mule 4.x applications)
- **API specs** in RAML 1.0 or OAS 3.x (design-first API)
- **DataWeave 2.x** transformations
- **Mule flows, subflows, error handlers, batch jobs, scheduler**
- **API Manager** policies (OAuth 2.0, Client ID Enforcement, Rate Limiting, JWT Validation, Threat Protection)
- **Exchange** asset publishing + versioning + fragments
- **Runtime Manager / CloudHub 2.0 / Runtime Fabric / Hybrid** deployment
- **MuleSoft Composer** (non-developer iPaaS) flows
- **MuleSoft for Flow** — low-code Mule connector surfaced inside Salesforce Flow Builder
- **Connectors**: Salesforce, Salesforce Platform Events, Database, HTTP, SAP, Workday, NetSuite, etc.
- **Accelerators**: MuleSoft Accelerator for Salesforce, for Financial Services, for Healthcare

---

## Phase 0: sf-integration Boundary (NOT an Industry Pre-Check)

**MuleSoft is platform-adjacent middleware, not a Salesforce cloud.** This skill therefore does **not** run the industry pre-check at `references/industry-precheck.md`. Instead, it has a hard boundary with `sf-integration` that must be respected before any work begins.

### Who owns what

| Surface | Skill | Examples |
|---|---|---|
| **Salesforce-side integration configuration** | `sf-integration` | Named Credential, External Credential, External Service registration, Apex HTTP callout, Platform Event publish/subscribe, Change Data Capture, Pub/Sub API gRPC subscriber, `EventBus.publish()`, trigger-based CDC consumer |
| **OAuth / Connected App (Salesforce side)** | `sf-connected-apps` | Connected App definition, JWT Bearer, OAuth 2.0 Client Credentials, token lifetime |
| **MuleSoft side of the same integration** | `sf-mulesoft` (this skill) | Mule application, Mule flow, DataWeave, RAML/OAS spec, API Manager policy, Exchange publish, Runtime Manager deploy, CloudHub 2.0, MuleSoft Composer, MuleSoft for Flow connector |
| **OmniStudio Integration Procedure** | `sf-industry-commoncore-integration-procedure` | Server-side orchestration inside OmniStudio — **not** a Mule app |

### Routing rules

1. If the artifact is a `.xml` Mule config, a `.dwl` DataWeave file, a `.raml` or `.yaml` OAS spec, or an Anypoint Studio project → this skill owns it.
2. If the artifact is a Named Credential, External Credential, External Service Registration, Apex class with `HttpCallout`, Platform Event object, or Pub/Sub subscriber → route to `sf-integration`.
3. If the task spans both sides (the common case — e.g., "publish Salesforce Platform Event and consume in MuleSoft"):
   - `sf-integration` owns the Platform Event definition + `EventBus.publish()` pattern.
   - This skill owns the MuleSoft Platform Events connector subscription + downstream Mule flow.
   - Both skills should be invoked **sequentially**; do not silently absorb the other side.
4. If the user says "integrate with [external system]" without naming MuleSoft, default to `sf-integration` and only route here if the user confirms a MuleSoft runtime.
5. **MuleSoft for Flow** is the blurriest boundary: it is a low-code Mule connector surfaced inside Salesforce Flow. This skill owns it because the underlying runtime is Mule; but when the work is predominantly SF Flow design, collaborate with `sf-flow`.

Print a boundary handoff on routing, e.g.:

```
This request has two sides: Platform Event publish (sf-integration) and Mule subscriber
flow (sf-mulesoft). Routing the publish side to sf-integration first; returning here to
build the Mule subscription + DataWeave transform + downstream HTTP consumer.
```

---

## Required Context to Gather First

Ask for or infer:

- Anypoint Platform edition: Titanium, Gold, Silver; CloudHub 1.0 vs **CloudHub 2.0** (strongly prefer 2.0 for new work) vs Runtime Fabric vs Hybrid
- Runtime version: Mule 4.4 LTS, Mule 4.6, Mule 4.9, **Mule 4.11 (current)** — see `docs.mulesoft.com/mule-runtime/latest/`
- Design-first or code-first? (RAML / OAS **first** is the house recommendation)
- Target connector(s): Salesforce (which variant — REST, Bulk, Composite, Platform Events, Pub/Sub), external system, DB, SaaS
- MuleSoft for Flow enabled? (requires Salesforce + MuleSoft entitlement)
- MuleSoft Composer vs Anypoint Studio? (Composer is no-code iPaaS for business users; Studio is the developer IDE)
- API Manager policies required (OAuth, rate limit, mTLS)?
- Exchange asset strategy: System API / Process API / Experience API layers (3-layer API-led)?
- Deployment target + non-prod / prod promotion model
- Existing accelerators installed?

---

## Workflow Phases

### Phase 1: API Design (API-led connectivity)

1. Decide API tier — **System**, **Process**, or **Experience**. Do not collapse layers arbitrarily.
2. Draft the spec in **RAML 1.0** (MuleSoft native) or **OAS 3.x** (if required by external consumer tooling).
3. Use Exchange fragments for shared types (dataTypes, libraries, security schemes).
4. Mock the API in Exchange / Anypoint Design Center before implementation.
5. Review with consumers; iterate on the spec, not the implementation.

### Phase 2: Mule Application Implementation

1. Scaffold from spec via **APIkit** in Anypoint Studio (`APIkit Router` + auto-generated flows).
2. Configure connector(s): Salesforce Connector for CRM calls, Salesforce Platform Events Connector for event subscription, DB Connector for database, HTTP Requester for outbound.
3. Implement flows:
   - Main flow (entry point: HTTP Listener / scheduler / event subscriber)
   - Subflows for reusable logic
   - Error handler — `on-error-propagate` vs `on-error-continue`, with specific `when` clauses
4. **DataWeave 2.x** transforms: always prefer DataWeave over Java for transformation. Keep scripts in `.dwl` files under `src/main/resources/dwl/`, not inline, once they exceed ~10 lines.
5. Parameterise everything via `config.yaml` + property placeholders (`${env.endpoint}`).

### Phase 3: Unit + Integration Testing

1. **MUnit** test suite per flow. Mock external dependencies.
2. Assert DataWeave transforms with fixture input + expected output.
3. Coverage gate ≥ 80% for flows and DataWeave.
4. Integration test in sandbox/CI environment with real connector targets.

### Phase 4: API Manager + Policies

1. Auto-discover the deployed app to API Manager.
2. Apply policies: **OAuth 2.0 Access Token Enforcement** (or Client ID Enforcement for machine-to-machine), **Rate Limiting** (SLA-tier-based), **JSON Threat Protection**, **HTTP Caching**, **CORS** if browser-consumed.
3. Configure SLA tiers if multi-tenant consumers.
4. Publish API portal in Exchange for consumers.

### Phase 5: Deployment

1. Package: `mvn clean package` produces `.jar`.
2. Deploy target:
   - **CloudHub 2.0** (preferred): via Runtime Manager or `anypoint-cli runtime-mgr cloudhub-application`.
     (Anypoint CLI is officially versioned as **Anypoint CLI 3.x**.)
   - **Runtime Fabric**: for customer-managed Kubernetes.
   - **Hybrid / on-prem**: for data-locality requirements.
3. Parameterise per environment via Runtime Manager secure properties.
4. Configure Alerts: CPU, memory, unhandled errors, queue depth.

### Phase 6: MuleSoft for Flow / MuleSoft Composer (low-code)

1. **MuleSoft for Flow**: publish a Mule API to Exchange with the "Invocable from Flow" flag. It surfaces in Salesforce Flow Builder as a Mule action. Mapping inputs/outputs happens in Flow Builder; the Mule runtime executes.
2. **MuleSoft Composer**: non-developer iPaaS. Good for business-led simple sync (e.g., "new Salesforce Account → create NetSuite Customer"). Not a Mule application — no DataWeave, no custom Java, no API Manager policies. Know when to graduate from Composer to Anypoint Studio.

### Phase 7: Observability + Lifecycle

1. **Anypoint Monitoring**: dashboards, alerts, log search.
2. **Titanium Visualizer**: dependency graph across APIs + Exchange assets.
3. Versioning: semver on API specs; major bump only on breaking change.
4. Deprecation: mark old versions in Exchange; communicate sunset date.
5. Decommission: tear down runtime, archive from Exchange, close API Manager instance.

---

## Scoring Rubric

Total: **140 points across 7 categories.** Any category below its pass threshold fails the whole review.

```
Score: XX/140
├─ API Design (spec-first): XX/20          (pass >= 14) RAML/OAS drafted first; fragments reused; Exchange published; mocked before build
├─ Mule Implementation: XX/25              (pass >= 18) APIkit scaffolded; correct connectors; error handlers specific; no Java where DataWeave suffices
├─ DataWeave Quality: XX/20                (pass >= 14) Scripts in .dwl files; pure functions; no mutable state; null-safe; tested
├─ Policies + Security: XX/20              (pass >= 14) OAuth / Client ID Enforcement applied; rate limit tuned; secrets in Secure Properties; mTLS where required
├─ Testing (MUnit + integration): XX/20    (pass >= 14) MUnit coverage >= 80%; integration test against real connector; fixture-based DataWeave tests
├─ Deployment + Ops: XX/20                 (pass >= 14) CloudHub 2.0 / Fabric chosen correctly; per-env params; alerts configured; log retention set
└─ Boundary Respect: XX/15                 (pass >= 10) SF-side work delegated to sf-integration / sf-connected-apps; no duplicate Named-Credential logic; Composer vs Studio chosen correctly
```

Passing score: **100/140 with every category at pass threshold.** Boundary Respect is the category most often failed — MuleSoft engineers commonly re-implement Salesforce-side concerns inside Mule, fragmenting ownership.

---

## Anti-Patterns

- **Code-first Mule apps with no RAML/OAS spec.** Breaks consumer contracts, prevents mocking, blocks API Manager auto-discovery. Always spec-first.
- **Inline DataWeave longer than 10 lines.** Unreadable, untestable, un-diffable. Move to `.dwl` files.
- **Collapsing System / Process / Experience API layers.** Short-term shortcut, long-term re-write. API-led connectivity exists because the layers have different change cadences.
- **Using Java transformers when DataWeave can do it.** DataWeave is the platform's first-class language; Java transformers are a tax on maintainability and testability.
- **No error handling, or a single catch-all `on-error-continue`.** Swallows errors, hides contract violations. Handle per error type (e.g., `HTTP:TIMEOUT`, `DB:CONNECTIVITY`, `SALESFORCE:INVALID_SESSION`).
- **Hardcoded secrets or endpoints in the Mule XML.** Use Secure Properties files encrypted with the Mule key, parameterised per environment.
- **Putting API Manager policies inside the Mule flow (via manual checks).** Policies belong in API Manager so they can be updated without redeploying the app.
- **Running net-new apps on CloudHub 1.0 in 2026.** CloudHub 2.0 is GA with Kubernetes-native runtime, better scaling, and shared VPC. Greenfield → 2.0.
- **Duplicating Named Credential / Connected App logic inside Mule.** SF side owns OAuth bootstrap; Mule consumes it. Duplicating fragments ownership and creates secret sprawl.
- **Using MuleSoft Composer for a workflow that needs DataWeave, custom connectors, or API Manager policies.** Composer is excellent for simple business-user flows; graduate to Anypoint Studio when complexity arrives.
- **Exposing an internal System API directly to an external consumer.** System APIs are unstable by design (they follow the source system). Put a Process or Experience API in front.
- **Letting a Mule app own what a Salesforce Pub/Sub subscriber could do.** If the use case is purely "Salesforce Platform Event → internal Apex handler", stay on Pub/Sub API inside SF; don't route through Mule just because Mule exists.

---

## Common Failure Modes + Remediation

| Symptom | Root Cause | Fix |
|---|---|---|
| Mule Salesforce connector "INVALID_SESSION_ID" | Access token expired; connection refresh not configured | Use OAuth JWT Bearer connection provider; enable reconnection strategy `reconnect-forever` with backoff |
| Platform Event subscriber misses events after redeploy | Replay ID not persisted; default `latest` resets on restart | Use Object Store v2 with a named store; persist replay ID; on restart read before subscribing |
| DataWeave `NullPointerException` | Missing field, no null-safety in transform | Use `default` operator: `payload.field default ""`; or `valueOr`; lint transforms |
| API Manager policy not enforced | Auto-discovery not configured, or app deployed without API instance binding | Add `api.id` + `api.instance.uri` properties; redeploy; verify from API Manager dashboard |
| CloudHub 2.0 app OOM on scaling event | Wrong replica size; memory limit too tight | Resize replica; set Mule JVM heap via `-XX:MaxRAMPercentage` not fixed `-Xmx` |
| MuleSoft for Flow action not appearing in Flow Builder | API not published with invocable flag; or user lacks permission | Re-publish to Exchange with "Invocable from Flow" checked; assign the MuleSoft Integration user permission set |
| Composer flow hits execution limit | Business-grade limits exceeded | Migrate to Anypoint Studio / Mule app; keep Composer for low-volume flows |

---

## Cheat Sheet — Anypoint Platform Objects

| Concern | Artifact | Where it lives |
|---|---|---|
| API spec | `.raml` or `.yaml` OAS | Design Center → Exchange |
| Shared types / libraries | RAML fragments | Exchange |
| Mule app | `.xml` + `.dwl` + `pom.xml` | Anypoint Studio project |
| Transformation | DataWeave `.dwl` | `src/main/resources/dwl/` |
| Policies | Policy definitions | API Manager |
| Deployment runtime | CloudHub 2.0 / Fabric / Hybrid | Runtime Manager |
| Monitoring | Dashboards + alerts | Anypoint Monitoring |
| Secrets | Secure Properties (encrypted) | `src/main/resources/*-secure.yaml` |
| Tests | MUnit XMLs | `src/test/munit/` |
| Connector catalog | Salesforce / DB / HTTP / SAP / etc. | Exchange → add dependency to `pom.xml` |
| Low-code iPaaS | MuleSoft Composer flows | Composer (no-code UI) |
| SF-Flow-invocable Mule action | Exchange-published API with invocable flag | Salesforce Flow Builder → Mule action element |
| Agentforce-invocable Mule action | **MuleSoft for Agentforce** — APIs exposed as agent actions | Agentforce → Mule action |
| AI-assisted Mule build | **Einstein for MuleSoft** — natural-language flow/DataWeave generation | Anypoint Code Builder / Studio |
| Low-code cloud IDE | **Anypoint Code Builder** (VS Code-based) — alternative to Anypoint Studio | Browser + VS Code |
| Edge API gateway | **Flex Gateway** — lightweight runtime-independent gateway | Customer-managed edge |
| MCP-exposed APIs | **MuleSoft MCP Support** — expose Exchange APIs as MCP tools for agents | Exchange + MCP endpoint |

---

## Cross-Skill Integration

| To Skill | When to Use |
|---|---|
| `sf-integration` | Salesforce-side Named Credential, External Service, Platform Event, CDC, Pub/Sub API — always before or alongside Mule work |
| `sf-connected-apps` | OAuth / JWT / Client Credentials Connected App that Mule uses to auth into Salesforce |
| `sf-flow` | When MuleSoft for Flow is invoked inside a SF Flow; design partnership |
| `sf-apex` | Custom callable Apex that consumes MuleSoft API response |
| `sf-data` | Data loads via MuleSoft vs Salesforce Bulk API decision |
| `sf-deploy` | CI/CD for the Salesforce side of a MuleSoft-integrated workstream |
| `sf-industry-commoncore-integration-procedure` | OmniStudio IP is NOT a Mule app — clarify the boundary if the user conflates them |

---

## Additional Resources

- [MuleSoft documentation](https://docs.mulesoft.com)
- [MuleSoft for Flow (Salesforce Help)](https://help.salesforce.com/s/articleView?id=sf.platform_events_mulesoft.htm)
- [MuleSoft Composer docs](https://docs.mulesoft.com/mulesoft-composer/) (note: `mulesoft-composer/latest/` returns 404 as of 2026-05-04; Composer content may be consolidating under "MuleSoft for Flow: Integration")
- [sf-integration boundary](../sf-integration/SKILL.md) (load-bearing cross-skill dependency)
