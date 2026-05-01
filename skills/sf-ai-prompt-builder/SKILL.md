---
name: sf-ai-prompt-builder
description: >
  Salesforce Prompt Builder authoring — standalone PromptTemplate metadata and
  the Prompt Template Builder UI — for reusable AI prompts grounded in CRM
  data, Data Cloud DMOs, Flows, and Apex.
  TRIGGER when: user authors, versions, activates, or tests a PromptTemplate
  in Setup → Einstein → Prompt Builder (or Einstein Studio → Prompt Templates);
  edits a `.promptTemplate-meta.xml` / `genAiPromptTemplate` file; chooses a
  template type (Flex, Field Generation / Field Completion, Sales Email,
  Record Summary, Chat); adds merge fields, grounding to CRM fields, Data
  Cloud DMOs, Flows, or Apex; invokes a template from Flow, Apex
  (`ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate`), LWC, or an
  Agentforce action; says "build a prompt template", "generate a sales email
  template", "summarize this record with AI", "ground the prompt in Data
  Cloud", "field generation template for Case resolution", "version and
  activate this template", "test prompt in Prompt Builder".
  DO NOT TRIGGER when: user is configuring agents, topics, actions, or
  Agent-embedded Prompt Templates (use sf-ai-agentforce); writing Agent
  Script `.agent` files (use sf-ai-agentscript); designing agent personas
  (use sf-ai-agentforce-persona); writing agent tests (use
  sf-ai-agentforce-testing); debugging session traces (use
  sf-ai-agentforce-observability); configuring generative / embedding model
  endpoints, BYOM, Einstein Trust Layer masking, zero-retention, or Audit
  Trail (use sf-ai-model-builder-trust-layer); writing Apex invocation
  classes beyond the template call (use sf-apex); writing LWCs that surface
  templates (use sf-lwc); building Flows that invoke templates
  (use sf-flow); retrieving Data Cloud data for grounding
  (use sf-datacloud-retrieve); mapping DMOs that back grounding
  (use sf-datacloud-harmonize); enforcing HIPAA/PHI-specific Trust Layer
  configuration (use sf-industry-health); enforcing PCI / financial
  Trust Layer configuration (use sf-industry-fsc).
license: MIT
compatibility: "Einstein Generative AI enabled; Prompt Builder license; API v60.0+ for genAiPromptTemplate metadata"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.prompt_builder_overview.htm
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.prompt_builder_template_types.htm
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_genaipromttemplate.htm
    importance: authoritative
  - url: https://developer.salesforce.com/docs/einstein/genai/guide/prompt-templates.html
    importance: authoritative
  - url: https://architect.salesforce.com/design/ai
    importance: supplemental
---

# sf-ai-prompt-builder

Owns authoring, grounding, versioning, activation, testing, and invocation of **standalone Prompt Templates** — the reusable, policy-governed AI prompts that live under **Setup → Einstein → Prompt Builder** and serialize as `genAiPromptTemplate` metadata. Agent-embedded Prompt Templates (registered via `GenAiFunction` with `invocationTargetType: prompt`) are authored *here* and then consumed by `sf-ai-agentforce`.

---

## 1. When this skill owns the task

This skill owns the **template** — its body, its variables, its grounding, its versions, its activation state, and every test run in the Prompt Template Builder. It does not own the model that runs behind it, the trust guarantees around it, or the surface that invokes it.

| Concern | Owner |
|---|---|
| Template body, merge fields, grounding, versions, activation | **sf-ai-prompt-builder** (this skill) |
| Agent topic/action config that *invokes* a template | sf-ai-agentforce |
| Agent Script `.agent` file that references a template | sf-ai-agentscript |
| Agent tests that exercise a template through an agent | sf-ai-agentforce-testing |
| STDM / session traces showing template calls | sf-ai-agentforce-observability |
| Generative/embedding endpoint (BYOM), Trust Layer masking, zero-retention, Audit Trail | sf-ai-model-builder-trust-layer |
| Flow step that calls a template | sf-flow |
| Apex `ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate` wrapper class | sf-apex |
| LWC that renders template output | sf-lwc |
| Data Cloud DMO mapping that backs template grounding | sf-datacloud-harmonize |
| Data Cloud query (SQL, vector search) for grounding | sf-datacloud-retrieve |
| HIPAA/PHI-specific masking rules | sf-industry-health |
| PCI/financial-specific masking rules | sf-industry-fsc |

---

## 2. Cross-cloud scope note

Prompt Builder is **industry-agnostic**. A Sales email template, a Nonprofit gift-acknowledgement template, a Health Cloud care-summary template, and a Public Sector case-note template all use the same `genAiPromptTemplate` metadata and the same Prompt Template Builder UI. Accordingly, this skill **skips the generic Phase 0 industry pre-check** — there is no industry-specific Prompt Builder fork.

**However**, industry-specific compliance requirements (HIPAA PHI, FERPA student records, PCI cardholder data, GLBA financial records, government classified data) are enforced *one layer down*, at the **Einstein Trust Layer**:

- PHI/PII masking rules → configure in `sf-ai-model-builder-trust-layer`, cross-reference `sf-industry-health`
- PCI masking and retention → configure in `sf-ai-model-builder-trust-layer`, cross-reference `sf-industry-fsc`
- FERPA student data → configure in `sf-ai-model-builder-trust-layer`, cross-reference `sf-industry-education`

Authoring a template that pulls regulated data is never safe by virtue of the template alone. The template must run on a configured Trust Layer, and the grounding source (CRM field, DMO) must already be inside a compliance perimeter. Delegate the compliance configuration; do not attempt it here.

---

## 3. Required context to gather first

Before writing or editing a template, confirm:

1. **Template type** — Flex (free-form), Field Generation (populate a field), Sales Email, Record Summary, Chat/Service Replies, or Einstein Copilot/Agent prompt. Type is set at creation and cannot be changed.
2. **Primary object** — The SObject the template binds to (e.g., `Account`, `Contact`, `Case`, `Opportunity`, custom object, NPC `GiftTransaction`). Required for all types except pure-Flex with freeText-only inputs.
3. **Grounding sources** — CRM fields on the primary object, related-list fields, Data Cloud DMOs, Apex-invoked data, Flow-provided data, Static Resources.
4. **Invocation surface** — Flow, Apex, LWC, Agent action, standalone Prompt Builder test, or Einstein Copilot.
5. **License & permission set** — `Prompt Template Manager` or `Prompt Template User`; Einstein Generative AI add-on SKU.
6. **Target model** — Default Einstein-managed model, BYOM via Model Builder, or an Agentforce-supported model (see `sf-ai-model-builder-trust-layer` for endpoint choice).
7. **Trust Layer posture** — Masking enabled? Zero-retention required? Audit Trail destination? (Do not *configure* here; confirm before authoring.)
8. **API version** — `genAiPromptTemplate` requires v60.0+; set `package.xml` `<version>` accordingly.

---

## 4. Workflow phases

### Phase 1 — Choose template type and bind object

Pick from the catalog below. Each type has a fixed input contract and downstream surface compatibility.

| Type | Body style | Typical use | Primary surface |
|---|---|---|---|
| **Flex** | Free-form; user-defined inputs (freeText, recordField, relatedList, resource, apex) | Custom prompts invoked from Flow/Apex/LWC/Agent | Anywhere |
| **Field Generation** (a.k.a. Field Completion) | Bound to one target field on one SObject | One-click "Generate with AI" button on a field | Record page, Flow |
| **Sales Email** | Bound to a recipient (Lead/Contact) + related Account/Opportunity | Email composer integration | Sales Cloud Email |
| **Record Summary** | Bound to one SObject | AI summary panel on a record page | Lightning record page |
| **Chat / Service Replies** | Bound to Case or Messaging session | Agent-assist reply suggestions | Service Console |
| **Agent / Copilot** | Flex variant registered via `GenAiFunction` | Called as an agent action | Agentforce |

Pick the narrowest matching type. Flex is always an escape hatch but forfeits the type-specific UI affordances (e.g., the Sales Email composer card).

### Phase 2 — Author variables and grounding

Every merge field in the body resolves against a declared variable. Declare them **before** writing the body.

**Variable `valueType`:**

| valueType | Source | Example merge syntax |
|---|---|---|
| `primitive` / `freeText` | Runtime-supplied input | `{!$Input:userQuestion}` |
| `recordField` | Field on an SObject bound at runtime | `{!$Input:Account.Name}` |
| `relatedList` | Child records of a bound parent | `{!$Input:Account.Opportunities[]}` |
| `apex` | Output of an `@InvocableMethod` class implementing `Schema.SObjectField` contract | `{!$Apex:GetAccountInsights.summary}` |
| `flow` | Output variable of an Autolaunched Flow | `{!$Flow:GetOpenCases.caseList}` |
| `staticResource` | Text content of a Static Resource | `{!$Resource:EmailDisclaimer}` |
| `dataCloud` (Retrievers) | DMO fields or a Data Cloud Retriever | `{!$EinsteinSearch:DonorProfile.giftTotal}` |

**Grounding priority:**

1. Prefer `recordField` / `relatedList` — deterministic, governed by FLS.
2. Use `apex` or `flow` when you need derived data (rollups, joins, external callouts).
3. Use `dataCloud` Retrievers for unified-profile or semantic-search grounding; **delegate the DMO mapping and retriever definition to `sf-datacloud-harmonize` and `sf-datacloud-retrieve`**.
4. Use `staticResource` for boilerplate (legal footers, tone guidelines).
5. Use `freeText` only for inputs the caller truly controls at runtime.

**System prompt vs user prompt:** Prompt Builder separates **Model Instructions** (system prompt — persona, guardrails, output format) from the **Prompt Template body** (user prompt — grounded content). Put persona/policy in Model Instructions so they survive template body edits.

### Phase 3 — Write the template body

Rules:

- One clear instruction per paragraph.
- Name output fields explicitly when type is Field Generation: "Return only the text for the `Description__c` field."
- Include negative constraints for Trust Layer-sensitive templates: "Do not include SSNs, credit card numbers, or phone numbers in the output." (Trust Layer masking still runs; the instruction reduces model-side leakage attempts.)
- For Record Summary, cap output length: "Return ≤ 200 words."
- For Sales Email, include greeting, body, signature as distinct instructions.

### Phase 4 — Version, test, activate

Every save in Prompt Template Builder creates a new **version**. Only one version can be **Active** at a time per template.

1. **Test** in the Builder's preview pane with a real record ID (for bound types) or sample inputs (for Flex). Verify grounding resolves and output meets spec.
2. **Inspect the resolved prompt** (Builder shows the fully merged user prompt sent to the model). Confirm no unresolved `{!...}` tokens remain.
3. **Activate** the version you want live. Deactivation reverts to the previously active version.
4. **Version notes** — populate `versionNotes` in metadata so deploys document the intent (what changed, why).

### Phase 5 — Invoke from the chosen surface

**From Flow:** add a *Prompt Template* action element; bind inputs to flow variables; capture output in a text variable.

**From Apex:**

```apex
ConnectApi.EinsteinPromptTemplateGenerationsInput input =
    new ConnectApi.EinsteinPromptTemplateGenerationsInput();
input.inputParams = new Map<String, ConnectApi.WrappedValue>{
    'Input:Account' => wrap(accountId)
};
input.isPreview = false;
ConnectApi.EinsteinPromptTemplateGenerationsRepresentation out =
    ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate(
        'Account_Summary_Template', input);
String text = out.generations[0].response;
```

Wrap in Queueable for long-running templates; never call from a trigger synchronously.

**From LWC:** expose the Apex wrapper via `@AuraEnabled` and call from the component. Delegate LWC construction to `sf-lwc`.

**From Agent:** register as an action via `GenAiFunction` with `invocationTargetType: prompt`. Delegate to `sf-ai-agentforce`.

### Phase 6 — Deploy

```bash
sf project deploy start -m "GenAiPromptTemplate:Account_Summary_Template" -o MyOrg
```

Deploy the template *before* the Flow / Apex / `GenAiFunction` that references it.

---

## 5. Scoring rubric (130 points)

| Category | Points | Threshold to pass |
|---|---|---|
| **Template type correctness** (right type for the surface; not defaulting to Flex) | 15 | 10 |
| **Variable declarations** (every merge field has a declared variable; correct `valueType`) | 20 | 15 |
| **Grounding quality** (uses `recordField`/`relatedList`/DMO over `freeText` where possible) | 20 | 14 |
| **Body hygiene** (one instruction per paragraph; explicit output contract; length caps) | 20 | 14 |
| **System-vs-user separation** (persona & guardrails in Model Instructions, not body) | 10 | 7 |
| **Versioning & activation** (version notes populated; single Active version; prior version retained) | 10 | 7 |
| **Test evidence** (Builder preview executed on representative record ID / inputs; resolved prompt inspected) | 10 | 7 |
| **Invocation wiring** (Flow/Apex/LWC/Agent caller verified; dependency deploy order correct) | 15 | 10 |
| **Trust Layer awareness** (defers masking/retention to sf-ai-model-builder-trust-layer; no regulated data in `freeText`) | 10 | 7 |

**Total: 130 pts; pass threshold: 91.**

---

## 6. Anti-patterns

1. **Using Flex when a typed template fits.** A Sales Email authored as Flex loses the composer card and recipient binding. Pick the typed template whenever the surface matches.
2. **Putting the persona in the body.** Persona drift happens when every version rewrites "You are a helpful assistant…". Persona, tone, and refusal rules belong in **Model Instructions**; the body is just the grounded task.
3. **Merge fields without variable declarations.** `{!Account.Name}` without a declared `$Input:Account` renders as literal text in production and is easy to miss in Builder preview if you test with the same record every time.
4. **Using `freeText` for CRM data.** If the data is on a record, bind via `recordField`. Passing record values through `freeText` skips FLS and puts regulated data into callers' hands.
5. **Skipping the resolved-prompt inspection.** Builder shows the fully merged prompt sent to the model. Reviewing only the output hides injection, truncation, and unresolved-token bugs.
6. **Deploying templates without version notes.** `versionNotes: ""` makes every refresh PR indistinguishable. Populate it on every save.
7. **Invoking synchronously from a trigger.** Template calls are HTTP calls to the Einstein gateway — they count against callout limits and can exceed CPU time. Always Queueable/async from triggers.
8. **Hardcoding model names in the template.** The active generative model is a **Trust Layer / Model Builder concern**. Never pin `sfdc_ai__DefaultGPT4Omni` in the template body or metadata; the active default is chosen by admin configuration.
9. **Mixing standalone and agent templates.** A template invoked by a `GenAiFunction` still lives here; don't fork a duplicate "agent copy." One template, multiple invocation surfaces.

---

## 7. Common failure modes + remediation

| Symptom | Root cause | Fix |
|---|---|---|
| Unresolved `{!$Input:Foo}` tokens appear in the output | Variable declared with a different `developerName` than the merge field | Open the Variables panel in Builder; match case exactly; re-save (creates new version). |
| Template preview works, Flow invocation returns empty string | Flow variable not marked *Available for input* / wrong data type bound to template input | Open the Flow action element; rebind the input; save & activate Flow. |
| Apex call throws `INVALID_TYPE` on `EinsteinPromptTemplateGenerationsInput` | `package.xml` below v60.0 | Bump project API version to 60.0+ and redeploy the Apex class. |
| Data Cloud Retriever returns stale data in prompt | DMO not refreshed / stream mapping changed | Delegate to `sf-datacloud-prepare` (streams) and `sf-datacloud-harmonize` (DMOs); re-run Retriever. |
| Sales Email template ignores recipient's first name | Recipient variable bound to `Lead` but composer invoked on `Contact` | Add a polymorphic binding or create a second template; Builder does not auto-coerce. |
| Output leaks SSNs despite Trust Layer being on | Source field not tagged as sensitive in Data Masking config | Trust Layer masks tagged fields only. Delegate tagging fix to `sf-ai-model-builder-trust-layer`; do not edit the prompt body. |
| Every refresh creates a new Active version | Admin clicking *Save & Activate* instead of *Save* | Train on the distinction; revert unintended activations from the Versions tab. |

---

## 8. Cheat sheet

### 8.1 Metadata skeleton (`Account_Summary.genAiPromptTemplate-meta.xml`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GenAiPromptTemplate xmlns="http://soap.sforce.com/2006/04/metadata">
    <developerName>Account_Summary_Template</developerName>
    <masterLabel>Account Summary</masterLabel>
    <description>Summarize an Account for executive review.</description>
    <type>einstein_gpt__recordSummary</type>
    <activeVersionNumber>2</activeVersionNumber>
    <templateVersions>
        <versionNumber>2</versionNumber>
        <status>Active</status>
        <versionNotes>Added related Opportunities to grounding.</versionNotes>
        <modelConfigName>sfdc_ai__DefaultConfig</modelConfigName>
        <inputs>
            <apiName>Input:Account</apiName>
            <definition>SObject://Account</definition>
            <required>true</required>
        </inputs>
        <templateSource>
            <content>
Summarize {!$Input:Account.Name}.
Industry: {!$Input:Account.Industry}.
Open opportunities: {!$Input:Account.Opportunities[]}.
Return ≤ 150 words. Do not include phone numbers.
            </content>
        </templateSource>
    </templateVersions>
</GenAiPromptTemplate>
```

### 8.2 Template type → `<type>` value

| Type | Metadata `<type>` |
|---|---|
| Flex | `einstein_gpt__flex` |
| Field Generation | `einstein_gpt__fieldCompletion` |
| Sales Email | `einstein_gpt__salesEmail` |
| Record Summary | `einstein_gpt__recordSummary` |
| Chat / Service Replies | `einstein_gpt__serviceReplies` |

### 8.3 Apex invocation one-liner

```apex
ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate(
    'Account_Summary_Template',
    new ConnectApi.EinsteinPromptTemplateGenerationsInput()
);
```

### 8.4 Deploy order

`Apex / Flow (if used for grounding)` → `GenAiPromptTemplate` → `GenAiFunction (if agent-invoked)` → `Agent publish`.
