---
name: sf-integration
description: >
  Salesforce integration architecture with 120-point scoring.
  TRIGGER when: user sets up Named Credentials, External Services, REST/SOAP
  callouts, Platform Events, CDC, or touches .namedCredential-meta.xml files;
  also phrases like "integrate with [external system]", "REST callout to [API]",
  "set up a platform event", "send data to [external system]".
  This skill owns Named Credentials, External Credentials, External Services,
  callouts, and async/event integration patterns.
  DO NOT TRIGGER when: pure OAuth / Connected App configuration happens first
  (use sf-connected-apps) — that is usually a prerequisite before Named Credentials
  are wired up here; Apex-only logic with no external callout (use sf-apex); or
  data import/export (use sf-data).
license: MIT
metadata:
  version: "1.2.0"
  author: "Jag Valaiyapathy"
  scoring: "120 points across 6 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.named_credentials_about.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/integrations
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_integration.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric in references/scoring-rubric.md (6 categories: Security 30, Error Handling 25, Bulkification 20, Architecture 20, Best Practices 15, Documentation 10), mapped onto the 4-dimension default rubric from skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  integration_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 15
      description: "Integration is bulk-safe and uses correct patterns. Maps to Bulkification (20) + Architecture (20). No callouts in loops, async pattern (Queueable / Future / @InvocableMethod) for callouts triggered by DML."
      automatic_hard_fail_rules:
        - "Any HTTP callout inside a for/while loop"
        - "Any callout from a trigger context without async wrapper (Salesforce blocks this at compile)"
        - "Any synchronous callout chain >5 calls per transaction (callout limit risk)"
    - name: Robustness
      max: 25
      hard_fail_below: 15
      description: "Integration handles transient errors + bad input. Maps to Error Handling (25). Heaviest hard-fail floor — integration failures cascade across systems. Retry logic, timeout handling, idempotency, dead-letter queue."
      automatic_hard_fail_rules:
        - "Any callout without timeout configured (default 10s may be wrong for the endpoint)"
        - "Any HTTP error response code (4xx/5xx) treated as success (status code not checked)"
        - "Any Platform Event publisher with no error handler (events lost silently on failure)"
        - "Any retry logic with no exponential backoff (retry storm risk)"
    - name: Fit
      max: 25
      hard_fail_below: 15
      description: "Integration uses Salesforce-native patterns. Maps to Security (30) — heaviest category in the rubric. Named Credentials only (NEVER hardcoded URLs/tokens), External Credentials for OAuth, no inline auth headers."
      automatic_hard_fail_rules:
        - "Any HTTP request with hardcoded URL (use Named Credential)"
        - "Any HTTP request with hardcoded auth token, API key, or password"
        - "Any callout to an external endpoint not registered in Remote Site Settings or Named Credentials"
        - "Any unencrypted credential stored in custom setting / custom metadata"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Integration scales + is documented. Maps to Best Practices (15) + Documentation (10). Composite API for chained calls, batch async patterns, ApexDoc on public surface."
      automatic_hard_fail_rules:
        - "Any sequence of >3 dependent callouts that doesn't use Composite API (latency multiplier)"
  test_rubric:
    unit:
      required: true
      criteria: "Apex test class uses Test.setMock for HTTP callouts. Covers happy path, error path, retry path, timeout."
    integration:
      required: true
      criteria: "Named Credential resolves and authentication succeeds against the target endpoint (verified via Anonymous Apex test callout)."
    smoke:
      required: true
      criteria: "End-to-end roundtrip: trigger event → external system receives payload → response processed correctly."
---

# sf-integration: Salesforce Integration Patterns Expert

Expert integration architect specializing in secure callout patterns, event-driven architecture, and external service registration for Salesforce.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). Three subagents (planner / implementer / evaluator) loop against the 120-pt rubric in fresh context. Robustness AND Fit floors are 15 (highest in any wrapped skill so far) — integration failures cascade across systems and hardcoded credentials are catastrophic. Disable with `eval_harness.enabled: false`.

---

## Core Responsibilities

1. **Named Credential Generation**: OAuth 2.0, JWT Bearer, Certificate, or Custom authentication
2. **External Credential Generation**: Modern External Credentials (API 61+) with Named Principals
3. **External Service Registration**: Generate ExternalServiceRegistration from OpenAPI/Swagger specs
4. **REST/SOAP Callout Patterns**: Sync and async implementations ([details](references/callout-patterns.md))
5. **Platform Events & CDC**: Event definitions, publishers, subscribers ([details](references/event-patterns.md))
6. **Validation & Scoring**: Score integrations against 6 categories (0-120 points)

## Key Insights

| Insight | Details |
|---------|---------|
| **Named Credential Architecture** | Legacy (pre-API 61) vs External Credentials (API 61+) — check org API version first |
| **Callouts in Triggers** | Synchronous callouts NOT allowed — use async (Queueable, @future) |
| **Governor Limits** | 100 callouts per transaction, 120s timeout max — batch callouts, use async |
| **External Services** | Auto-generates Apex from OpenAPI specs — requires Named Credential for auth |

---

## Named Credential Architecture (API 61+)

| Feature | Legacy Named Credential | External Credential (API 61+) |
|---------|------------------------|------------------------------|
| **API Version** | Pre-API 61 | API 61+ (Spring '24+) |
| **Principal Concept** | Single principal | Named + Per-User Principal |
| **OAuth Support** | Basic OAuth 2.0 | Full OAuth 2.0 + PKCE, JWT |
| **Recommendation** | Legacy orgs only | **Use for all new development** |

---

## Workflow (5-Phase Pattern)

### Phase 1: Requirements Gathering

**Ask the user** to gather: integration type (outbound REST/SOAP, inbound, event-driven), auth method (OAuth 2.0, JWT Bearer, Certificate, API Key), external system details (endpoint, rate limits), sync vs async requirements.

### Phase 2: Template Selection

| Integration Need | Template | Location |
|-----------------|----------|----------|
| Named Credentials | `oauth-client-credentials.namedCredential-meta.xml` | `assets/named-credentials/` |
| External Credentials | `oauth-external-credential.externalCredential-meta.xml` | `assets/external-credentials/` |
| External Services | `openapi-registration.externalServiceRegistration-meta.xml` | `assets/external-services/` |
| REST Callouts | `rest-sync-callout.cls`, `rest-queueable-callout.cls` | `assets/callouts/` |
| SOAP Callouts | `soap-callout-service.cls` | `assets/soap/` |
| Platform Events | `platform-event-definition.object-meta.xml` | `assets/platform-events/` |
| CDC Subscribers | `cdc-subscriber-trigger.trigger` | `assets/cdc/` |

### Phase 3: Generation & Validation

```
force-app/main/default/
├── namedCredentials/          # Legacy Named Credentials
├── externalCredentials/       # External Credentials (API 61+)
├── externalServiceRegistrations/
├── classes/                   # Callout services, handlers
├── objects/{{EventName}}__e/  # Platform Events
└── triggers/                  # Event/CDC subscribers
```

### Phase 4: Deployment (CRITICAL ORDER)

1. Named Credentials / External Credentials FIRST
2. External Service Registrations (depends on Named Credentials)
3. Apex classes (callout services, handlers)
4. Platform Events / CDC configuration
5. Triggers (depends on events being deployed)

Use the **sf-deploy** skill

### Phase 5: Testing & Verification

1. **Named Credential**: Setup → Named Credentials → Test Connection
2. **External Service**: Invoke generated Apex methods
3. **Callout**: Anonymous Apex or test class with `Test.setMock()`
4. **Events**: Publish and verify subscriber execution

---

## Named Credentials

| Auth Type | Use Case | Template |
|-----------|----------|----------|
| **OAuth 2.0 Client Credentials** | Server-to-server | `oauth-client-credentials.namedCredential-meta.xml` |
| **OAuth 2.0 JWT Bearer** | CI/CD, backend | `oauth-jwt-bearer.namedCredential-meta.xml` |
| **Certificate (Mutual TLS)** | High-security | `certificate-auth.namedCredential-meta.xml` |
| **Custom (API Key/Basic)** | Simple APIs | `custom-auth.namedCredential-meta.xml` |

Templates in `assets/named-credentials/`. **NEVER hardcode credentials.**

---

## External Services (OpenAPI/Swagger)

**Process**: Obtain OpenAPI spec → Create Named Credential → Register External Service → Salesforce auto-generates `ExternalService.{{ServiceName}}` Apex classes.

```apex
ExternalService.Stripe stripe = new ExternalService.Stripe();
ExternalService.Stripe_createCustomer_Request req = new ExternalService.Stripe_createCustomer_Request();
req.email = 'customer@example.com';
ExternalService.Stripe_createCustomer_Response resp = stripe.createCustomer(req);
```

---

## Callout Patterns

> See [references/callout-patterns.md](references/callout-patterns.md) for complete REST and SOAP implementations.

| Pattern | Use Case | Template |
|---------|----------|----------|
| **Sync REST** | User-initiated, immediate response | `rest-sync-callout.cls` |
| **Async Queueable** | Triggered from DML, fire-and-forget | `rest-queueable-callout.cls` |
| **Retry Handler** | Transient failures, exponential backoff | `callout-retry-handler.cls` |
| **SOAP (WSDL2Apex)** | WSDL-based services | `soap-callout-service.cls` |

**Key rules**: Use Named Credentials (`callout:{{NC}}/path`), set timeout (`req.setTimeout(120000)`), handle 4xx/5xx status codes.

---

## Event-Driven Patterns

> See [references/event-patterns.md](references/event-patterns.md) for complete Platform Event and CDC implementations.
> See [references/event-driven-architecture-guide.md](references/event-driven-architecture-guide.md) for EDA patterns, Pub/Sub API, Event Relays, and monitoring.

**Platform Events**: Standard Volume (~2K events/hour, 3-day retention) or High Volume (millions/day, 24-hour retention). Publish via `EventBus.publish()`, subscribe via triggers. Use `PublishAfterCommit` (default) to ensure events only fire on successful transactions. Use `PublishImmediately` only when the event must fire regardless of transaction outcome.

**Change Data Capture (CDC)**: Enable via Setup → Integrations → CDC. Channel: `{{Object}}ChangeEvent`. Change types: CREATE, UPDATE, DELETE, UNDELETE.

**Pub/Sub API** (recommended for external consumers): gRPC-based subscription to Platform Events and CDC. Replaces legacy Streaming API.

> ⚠️ **PushTopic, Generic Streaming Events, and legacy Streaming API are deprecated** — they no longer receive new investments. Migrate to **Pub/Sub API** for external consumers or **empApi** for LWC subscribers.

> ⚠️ **For high-volume outbound, use middleware + Platform Events.** Do NOT use async Apex directly — it consumes shared daily limits (250K). Let middleware (MuleSoft, custom Pub/Sub consumer) handle delivery, retries, and enrichment.

---

## Scoring System (120 Points)

> See [references/scoring-rubric.md](references/scoring-rubric.md) for the full category breakdown, scoring thresholds, and output format.

**Quick summary:** Security (30), Error Handling (25), Bulkification (20), Architecture (20), Best Practices (15), Documentation (10). Score 108+ = Excellent. Score <54 = BLOCK.

---

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Hardcoded credentials | Security vulnerability | Use Named Credentials |
| Sync callout in trigger | `CalloutException` | Use Queueable |
| No timeout specified | Default 10s too short | `req.setTimeout(120000)` |
| No retry logic | Transient failures | Exponential backoff |
| 100+ callouts per txn | Governor limit | Batch + async |
| No logging | Can't debug production | Log requests/responses |

---

## CLI Commands & Helper Scripts

> See [references/cli-reference.md](references/cli-reference.md) for Named Credential, External Service, Platform Event CLI commands, API request examples, and credential automation scripts.

---

## Cross-Skill Integration

| To Skill | When to Use |
|----------|-------------|
| sf-connected-apps | OAuth Connected App for Named Credential |
| sf-apex | Custom callout service beyond templates |
| sf-metadata | Query existing Named Credentials |
| sf-deploy | Deploy to org |
| sf-ai-agentscript | Agent action using External Service |
| sf-flow | HTTP Callout Flow for agent |

**Agentforce Integration Flow**: sf-integration → Named Credential + External Service → sf-flow → HTTP Callout wrapper → sf-ai-agentscript → `flow://` target → sf-deploy

---

## Additional Resources

- [Callout Patterns](references/callout-patterns.md) — REST and SOAP implementations
- [Event Patterns](references/event-patterns.md) — Platform Events and CDC
- [Event-Driven Architecture Guide](references/event-driven-architecture-guide.md) — EDA patterns, Pub/Sub API, Event Relays, monitoring
- [Messaging API v2](references/messaging-api-v2.md) — MIAW custom client architecture (Agentforce external chat)
- [Scoring Rubric](references/scoring-rubric.md) — 120-point scoring details
- [CLI Reference](references/cli-reference.md) — CLI commands and helper scripts

---

## Notes & Dependencies

- **API Version**: 62.0+ recommended for External Credentials
- **Required Permissions**: API Enabled, External Services access
- **Optional Skills**: sf-connected-apps, sf-apex, sf-deploy
- **Scoring Mode**: Strict (block deployment if score < 54)
