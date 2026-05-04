---
name: sf-ai-model-builder-trust-layer
description: >
  Einstein Trust Layer configuration and Model Builder (BYOM) — generative
  and embedding endpoints for Azure OpenAI, AWS Bedrock, Google Vertex, and
  other providers, plus toxicity detection, prompt defense, PII/PHI masking,
  zero-retention policy, Content Safety, and Audit Trail in Data Cloud.
  TRIGGER when: user configures the Einstein Trust Layer (masking rules,
  zero-retention, toxicity / prompt-injection defense, Content Safety,
  grounding-attribution, Audit Trail destination in Data Cloud); registers,
  edits, or swaps a generative or embedding model endpoint in Model Builder
  / Einstein Studio — Azure OpenAI, AWS Bedrock, Google Vertex, OpenAI
  direct, Anthropic direct, or any self-hosted model; authors a Model Card;
  says "bring our own model", "BYOM", "register a Bedrock model", "swap the
  default GPT model for Claude on Bedrock", "turn on PII masking", "enable
  zero retention", "where does the Trust Layer log prompts", "configure
  Content Safety", "audit every prompt in Data Cloud".
  DO NOT TRIGGER when: user is authoring a PromptTemplate (body, merge
  fields, variables, versioning, activation — use sf-ai-prompt-builder);
  configuring agents, topics, or actions (use sf-ai-agentforce); writing
  Agent Script `.agent` files (use sf-ai-agentscript); designing agent
  personas (use sf-ai-agentforce-persona); running agent tests
  (use sf-ai-agentforce-testing); analyzing session traces
  (use sf-ai-agentforce-observability); writing Apex that calls the
  Einstein Models API (use sf-apex); building LWCs that surface AI output
  (use sf-lwc); building Flows that invoke templates (use sf-flow);
  ingesting telemetry into Data Cloud beyond Audit Trail
  (use sf-datacloud-prepare); querying the Audit Trail DMO
  (use sf-datacloud-retrieve); HIPAA/PHI clinical masking policies
  (use sf-industry-health — this skill implements what that skill
  specifies); PCI / financial masking policies (use sf-industry-fsc
  — same relationship).
license: MIT
compatibility: "Einstein Generative AI add-on; Trust Layer enabled by default; Model Builder requires Einstein Studio license; BYOM requires provider-side account + credentials"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-04
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.einstein_trust_layer.htm
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.generative_ai_data_masking.htm
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.model_builder_overview.htm
    importance: authoritative
  - url: https://developer.salesforce.com/docs/einstein/genai/guide/byollm.html
    importance: authoritative
  - url: https://developer.salesforce.com/docs/ai/agentforce/guide/supported-models.html
    importance: authoritative
  - url: https://architect.salesforce.com/design/ai
    importance: supplemental
---

# sf-ai-model-builder-trust-layer

Owns the **model endpoint** and the **trust perimeter** around every generative AI call Salesforce makes. Everything that happens *before* the prompt reaches the model (masking, prompt defense, grounding attribution) and *after* the response comes back (toxicity scan, Content Safety, de-masking, Audit Trail logging, zero-retention enforcement) is configured here. Nothing about prompt *authoring* is configured here — that lives in `sf-ai-prompt-builder`.

---

## 1. When this skill owns the task

| Concern | Owner |
|---|---|
| Trust Layer masking rules, zero-retention, toxicity, prompt defense, Content Safety, grounding attribution, Audit Trail | **sf-ai-model-builder-trust-layer** (this skill) |
| Model Builder: registering generative / embedding endpoints (BYOM) for Azure OpenAI, Bedrock, Vertex, OpenAI, Anthropic | **this skill** |
| Model Cards (metadata describing the registered model) | **this skill** |
| PromptTemplate body, variables, versioning, activation, testing | sf-ai-prompt-builder |
| Agent topic/action config | sf-ai-agentforce |
| Agent Script `.agent` files | sf-ai-agentscript |
| Agent tests / coverage | sf-ai-agentforce-testing |
| STDM trace extraction & analysis | sf-ai-agentforce-observability |
| Apex wrappers over Einstein Models API / `ConnectApi.EinsteinLlm` | sf-apex |
| Flow / LWC invocations | sf-flow / sf-lwc |
| Data Cloud stream / DLO / DMO config (beyond the Audit Trail DMO) | sf-datacloud-prepare, sf-datacloud-harmonize |
| Querying Audit Trail DMO | sf-datacloud-retrieve |
| HIPAA/PHI policy definition (what to mask, retention policy) | sf-industry-health — this skill implements it |
| PCI / financial policy definition | sf-industry-fsc — this skill implements it |

---

## 2. Cross-cloud scope note

The Einstein Trust Layer and Model Builder are **platform-wide** capabilities, not industry-specific. A Sales Cloud email generation, a Service Cloud case summary, a Health Cloud clinical note, and a Nonprofit Cloud donor letter all pass through the **same** Trust Layer and can be routed to the **same** BYOM endpoint. This skill therefore **skips the generic Phase 0 industry pre-check** — there is no industry fork of the Trust Layer.

**Industry compliance is enforced via Trust Layer *settings*, not a separate product:**

- **HIPAA / PHI (sf-industry-health)** — enable masking for PHI patterns (MRN, DOB, clinical terms), enforce zero-retention on the model endpoint, route Audit Trail to a Data Cloud data space inside the HIPAA-compliant tenant.
- **FERPA (sf-industry-education)** — mask student identifiers, disable grounding in external models, pin a US-region endpoint.
- **PCI (sf-industry-fsc)** — block PAN/CVV patterns via Data Masking + block-list patterns, refuse non-zero-retention endpoints, require Audit Trail retention ≥ required years.
- **GLBA / financial privacy** — same pattern via sf-industry-fsc.
- **FedRAMP / government (sf-industry-public-sector)** — restrict to Government Cloud region endpoints; forbid BYOM to non-FedRAMP providers.

This skill provides the *mechanism*; the industry skill provides the *policy*. Never implement an industry policy by memory — always cross-reference the industry skill for the authoritative list of protected patterns.

---

## 3. Required context to gather first

Before changing any Trust Layer or Model Builder setting, confirm:

1. **License posture** — Einstein Generative AI add-on active; Einstein Studio license if registering BYOM; Data Cloud license if enabling Audit Trail (Audit Trail is a DMO).
2. **Current default model** — `Setup → Einstein → Einstein Setup → Model`. Record what it is before swapping.
3. **Data residency** — Org home region; provider region; regulatory region requirement (EU, US, Gov).
4. **Provider credentials (for BYOM)** — Azure OpenAI: endpoint URL + deployment name + key; AWS Bedrock: role ARN + region; Google Vertex: service account JSON + project + region.
5. **Named Credential** — BYOM requires a Named Credential with the provider's auth. Delegate creation to `sf-integration`; never hand-edit keys into Setup.
6. **Industry compliance requirement** — Read the relevant `sf-industry-*` skill first. Copy its masking pattern list verbatim; do not paraphrase.
7. **Audit Trail destination** — Data space in Data Cloud; retention period; downstream consumers.
8. **Change-control window** — Swapping the default model is a tenant-wide behavior change. Coordinate with Agentforce, Prompt Builder, and application owners.

---

## 4. Workflow phases

### Phase 1 — Audit the current Trust Layer baseline

`Setup → Einstein → Trust Layer` (or `Einstein Setup → Trust & Compliance`). Capture:

- Data Masking: ON/OFF, enabled pattern categories, custom patterns
- Zero-Retention Policy: enforced? (Einstein-managed endpoints: enforced by default; BYOM: depends on provider contract)
- Toxicity Detection: threshold
- Prompt Defense: injection-pattern blocking ON/OFF
- Grounding Attribution: ON/OFF
- Audit Trail: destination, retention, enabled event types

Export this baseline to a change-control record *before* editing. Every Trust Layer change affects every downstream template, agent, Flow, and LWC invocation.

### Phase 2 — Configure Data Masking

Masking replaces sensitive values with tokens *before* the prompt is sent to the model, then de-masks on the way back. It runs on both the prompt and the response.

| Pattern category | Masks |
|---|---|
| Person Name | First/last names detected by NER |
| Email | Email addresses |
| Phone | Phone numbers (E.164, US, EU) |
| Address | Street + postal patterns |
| SSN / National ID | US SSN, UK NI, EU national IDs |
| Credit Card | PAN by Luhn check |
| IP Address | IPv4/IPv6 |
| Date of Birth | DOB patterns |
| Custom | Regex + label you define |

**Rules:**

- Turn on **all** categories that apply to the data the templates will ground on.
- Add **custom patterns** for industry identifiers (MRN, patient ID, student ID, account number). Cross-reference `sf-industry-health` / `sf-industry-education` / `sf-industry-fsc` for the regex list.
- Prefer field-level masking tags (`Sensitive Data` on a field) over body-scanning where possible — it is deterministic and survives prompt edits.
- **Never** disable masking to "improve output quality." If masking breaks the output contract, fix the template, not the mask.

### Phase 3 — Enforce zero-retention

Zero-retention means the provider does not store prompts/responses server-side past the inference window.

- **Einstein-managed endpoints** (sfdc_ai__Default*) — zero-retention enforced by contract. No setting to toggle.
- **BYOM Azure OpenAI** — requires Azure's "Abuse Monitoring opt-out" approval; without it, Microsoft retains 30 days.
- **BYOM AWS Bedrock** — zero-retention by default for Bedrock inference; confirm for fine-tuned models.
- **BYOM Google Vertex** — zero-retention per Vertex data-governance settings; confirm per-model.
- **BYOM OpenAI direct / Anthropic direct** — depends on contract tier; verify in provider agreement.

Record the zero-retention posture on the Model Card so downstream skills can surface it.

### Phase 4 — Register a BYOM endpoint (Model Builder)

Use when the default Einstein models don't meet a requirement (regulated region, fine-tuned domain model, provider choice).

**Steps:**

1. Create a **Named Credential** (delegate to `sf-integration`) pointing at the provider.
2. `Setup → Einstein Studio → Model Builder → New Model`.
3. Choose provider. BYOLLM foundation-model providers currently supported: Amazon Bedrock, Azure OpenAI, OpenAI, Vertex AI (Google). Any other model (including Anthropic direct, IBM Granite, Databricks DBRX, or self-hosted open-source) must be registered via the **BYOLLM Open Connector** (OpenAI-API-compatible shim) rather than as a first-class provider.
4. Choose **Generative** or **Embedding**.
5. Fill the **Model Card**:
   - API name (e.g., `Acme_Bedrock_Claude45Sonnet`)
   - Provider, region, endpoint
   - Max tokens, context window, temperature default
   - Use-case description
   - Compliance posture (HIPAA / PCI / FedRAMP attestations)
   - Cost per 1K tokens (for internal chargeback)
6. **Test** with a sample prompt in the Model Builder test pane.
7. **Activate**. You can activate as Default or as a Named Option (referenced by model-aware templates or agents).

**Embedding endpoints** follow the same flow but are selected in Data Cloud vector-search config (delegate to `sf-datacloud-retrieve`) or in RAG grounding in templates.

### Phase 5 — Configure Content Safety & Prompt Defense

- **Toxicity Detection** — scans responses; threshold 0.0–1.0 (lower = more strict). Start at 0.5; tighten per user report.
- **Prompt Defense** — blocks common prompt-injection strings and instruction-overrides in user inputs.
- **Grounding Attribution** — appends source-field citations to the response where supported (Record Summary, Retriever-grounded templates).
- **Content Safety (Bedrock Guardrails, Azure Content Filters)** — provider-side filters. Enable on the provider and note in the Model Card.

### Phase 6 — Enable Audit Trail

Audit Trail logs every prompt, response, masking event, toxicity score, and grounding citation to a Data Cloud DMO (`Einstein_Audit_Event__dlm`).

1. `Setup → Einstein → Trust Layer → Audit Trail → Enable`.
2. Choose the target Data Space.
3. Choose event types (Prompt, Response, Masking, Feedback, Error).
4. Set retention period (industry-dictated).
5. Verify in Data Cloud that the DMO is populating (delegate queries to `sf-datacloud-retrieve`).

### Phase 7 — Change-control and rollback

Every Trust Layer or Model-Default change is a tenant-wide behavior change. Before activating:

- Announce in change-management.
- Run the Prompt Template Builder preview against each *production* template using the new model — delegate to `sf-ai-prompt-builder` for the test list.
- Run a sampling of agent tests — delegate to `sf-ai-agentforce-testing`.
- Have the prior Model Card ready for one-click revert.

---

## 5. Scoring rubric (130 points)

| Category | Points | Threshold |
|---|---|---|
| **Masking coverage** (all applicable pattern categories ON; industry patterns copied from the right sf-industry-* skill) | 25 | 18 |
| **Zero-retention verification** (posture recorded per endpoint; provider contract confirmed for BYOM) | 15 | 11 |
| **Model Card completeness** (provider, region, context window, compliance, cost all populated) | 15 | 11 |
| **Named Credential hygiene** (no inline keys; credential delegated to sf-integration; rotated per policy) | 15 | 10 |
| **Content Safety + Prompt Defense** (toxicity threshold set; prompt defense ON; provider-side filters ON where applicable) | 15 | 10 |
| **Audit Trail configured** (DMO populating; retention matches industry requirement; data space owner identified) | 15 | 10 |
| **Change-control evidence** (baseline exported; template + agent regression run before activate; rollback plan documented) | 15 | 11 |
| **Industry policy alignment** (cross-referenced sf-industry-health / -fsc / -education / -public-sector; no paraphrased policy) | 15 | 11 |

**Total: 130 pts; pass threshold: 92.**

---

## 6. Anti-patterns

1. **Disabling masking to "improve output."** If a masked token breaks the output, fix the template's output contract or add a custom de-masking rule — never turn masking off to unblock a demo.
2. **Hand-keying provider credentials into Setup.** BYOM credentials belong in a Named Credential. Inline keys leak via Setup Audit Trail and metadata exports.
3. **Swapping the default model without regression.** A new default changes token count, temperature sensitivity, refusal behavior, and latency. Run template + agent regression before activating.
4. **Trusting BYOM zero-retention by assumption.** Azure retains 30 days by default; Bedrock varies by model. Verify per-provider, per-model, in writing; note it on the Model Card.
5. **Paraphrasing industry masking rules.** PHI, PCI, and FERPA pattern lists are authoritative in the industry skills. Copy them verbatim. A dropped digit in a regex is a breach.
6. **Forgetting Audit Trail retention.** Compliance requires a specific retention period (e.g., HIPAA ≥ 6 years). Leaving the default (90 days) is a silent compliance failure.
7. **Registering an embedding model as generative (or vice-versa).** They have different Model Card schemas and different callers. Pick the right type at registration.
8. **Enabling grounding attribution without testing output format.** Citations append to responses and can break Field Generation templates that expect a single field value.
9. **Treating Content Safety as a substitute for prompt hygiene.** Toxicity filtering catches some abuse; it does not replace Prompt Defense, masking, or careful template authoring.

---

## 7. Common failure modes + remediation

| Symptom | Root cause | Fix |
|---|---|---|
| Masked token `<PERSON_NAME_1>` appears verbatim in output | De-masking failed because the token format was altered by the model | Lower temperature on the Model Card; tighten template output contract; re-test. |
| BYOM model returns 401 | Named Credential key rotated but not re-linked to Model Card | Re-select the Named Credential in the Model Card; save; re-activate. |
| Audit Trail DMO empty after enabling | Data Space permissions missing on the configured principal | Grant the Einstein Audit Principal write access to the data space (delegate to `sf-datacloud-harmonize`). |
| Toxicity filter blocking legitimate clinical terms | Default threshold too strict for clinical vocabulary | Raise threshold incrementally (0.5 → 0.7); add allow-list terms; cross-reference `sf-industry-health`. |
| Bedrock model latency spikes after swap | Region mismatch between Salesforce tenant and Bedrock endpoint | Repick the Bedrock region nearest the tenant; update Model Card `region`. |
| Prompt injection succeeds despite Prompt Defense ON | Pattern not covered by built-in defense; injection in grounded data | Add custom block-list patterns; sanitize grounding source; escalate if source is a DMO (delegate to `sf-datacloud-harmonize`). |
| Zero-retention audit flagged by compliance | Azure OpenAI abuse-monitoring opt-out not filed | File opt-out with Microsoft; until approved, deactivate the endpoint for regulated workloads. |

---

## 8. Cheat sheet

### 8.1 Trust Layer toggles (Setup path)

```
Setup → Einstein → Trust Layer
  ├─ Data Masking                      [enabled | per-pattern toggles | custom patterns]
  ├─ Toxicity Detection                [threshold: 0.0–1.0]
  ├─ Prompt Defense                    [on/off]
  ├─ Grounding Attribution             [on/off]
  ├─ Zero-Retention (informational)    [per-endpoint status]
  └─ Audit Trail
       ├─ Data Space                   [pick DC data space]
       ├─ Event Types                  [Prompt | Response | Masking | Feedback | Error]
       └─ Retention                    [days]
```

### 8.2 Model Card metadata (`Acme_Bedrock_Claude45Sonnet.genAiModelConfig-meta.xml`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GenAiModelConfig xmlns="http://soap.sforce.com/2006/04/metadata">
    <developerName>Acme_Bedrock_Claude45Sonnet</developerName>
    <masterLabel>Acme Bedrock Claude 4.5 Sonnet</masterLabel>
    <provider>AmazonBedrock</provider>
    <modelName>anthropic.claude-4-5-sonnet-20250101-v1:0</modelName>
    <region>us-east-1</region>
    <modelType>Generative</modelType>
    <namedCredential>Bedrock_Prod_NC</namedCredential>
    <contextWindow>200000</contextWindow>
    <maxOutputTokens>8192</maxOutputTokens>
    <defaultTemperature>0.2</defaultTemperature>
    <compliance>
        <hipaa>true</hipaa>
        <pci>false</pci>
        <fedRamp>false</fedRamp>
        <zeroRetention>true</zeroRetention>
    </compliance>
    <useCase>Clinical note summarization; case deflection.</useCase>
    <isActive>true</isActive>
</GenAiModelConfig>
```

### 8.3 Custom masking pattern (YAML excerpt)

```yaml
trustLayer:
  dataMasking:
    enabled: true
    builtInCategories:
      - PersonName
      - Email
      - Phone
      - Address
      - NationalId
      - CreditCard
      - IpAddress
      - DateOfBirth
    customPatterns:
      - label: MedicalRecordNumber
        regex: "MRN[-: ]?\\d{6,10}"
        maskAs: "<MRN>"
      - label: StudentId
        regex: "S\\d{8}"
        maskAs: "<STUDENT_ID>"
```

### 8.4 BYOM registration order

1. **Named Credential** (via `sf-integration`)
2. **Model Card** (this skill)
3. **Test** in Model Builder preview
4. **Activate** — as Default or as a Named Option
5. **Regression** — Prompt Builder (`sf-ai-prompt-builder`) + Agentforce (`sf-ai-agentforce-testing`)
6. **Audit Trail verify** — query DMO (`sf-datacloud-retrieve`)

### 8.5 Provider quick reference

Salesforce-managed standard configurations (`sfdc_ai__Default*` API names, all inside the Salesforce Trust Boundary when hosted on Bedrock; Azure OpenAI / OpenAI direct / Vertex routes traverse partner trust zones):

| Provider route | Current standard models (API-name stems) | Notes |
|---|---|---|
| Amazon Bedrock (inside Salesforce Trust Boundary) | Amazon Nova Lite / Pro; Anthropic Claude Haiku 4.5, Sonnet 4 / 4.5 / 4.6, Opus 4.5 / 4.6 (Beta) / 4.7 (Beta); NVIDIA Nemotron 3 Nano 30B (Beta) | Region-pinned; zero-retention default |
| Azure OpenAI / OpenAI (geo-aware) | GPT-4o, GPT-4o Mini, GPT-4.1, GPT-4.1 Mini, GPT-5, GPT-5 Mini, GPT-5.1, GPT-5.2, GPT-5.4, O3, O4 Mini | Azure requires abuse-monitoring opt-out for zero-retention; geo-aware models auto-route to nearest region matching Data 360 provisioning |
| Vertex AI (Google) | Gemini 2.5 Flash / Flash Lite / Pro; Gemini 3 Flash; Gemini 3 Pro (Beta, retiring 2026-04-23); Gemini 3.1 Flash Lite (Beta), Gemini 3.1 Pro (Beta) | Project + region pinned |
| Embeddings (Models API only) | `sfdc_ai__DefaultAzureOpenAITextEmbeddingAda_002`, `sfdc_ai__DefaultOpenAITextEmbeddingAda_002` | Generative-Embedding split enforced at registration |

**BYOLLM foundation providers:** Amazon Bedrock, Azure OpenAI, OpenAI, Vertex AI. All other models (Anthropic direct, IBM Granite, Databricks DBRX, custom in-house) must use the **BYOLLM Open Connector** (OpenAI-compatible spec; see Einstein AI Platform GitHub repo). BYOLLM consumes 30% fewer Einstein Requests than standard models. Deprecation reroutes handled automatically by Salesforce (e.g., Claude 3 Haiku → Claude Haiku 4.5; GPT 3.5 Turbo → GPT-4o Mini; Gemini 2.0 Flash → Gemini 2.5 Flash).

**Beta models:** display as `(Disabled)` until explicitly enabled in AI Models; run under Beta Services Terms; use sandbox/dev only.

### 8.6 Context-window cap under data masking

All models are capped at **65,536 tokens** total context (input + output) when Trust Layer data masking is ON. This supersedes the provider's native context window (e.g., Claude Sonnet 200K, Gemini Pro 1M). If a template truly needs the full provider window, masking must be disabled for that path — which requires a documented compliance exception; never do this silently. Record the effective context ceiling on the Model Card.
