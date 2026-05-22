---
name: sf-diagram-mermaid
description: >
  Salesforce architecture diagrams using Mermaid with ASCII fallback.
  TRIGGER when: user says "diagram", "visualize", "ERD", or asks for sequence
  diagrams, flowcharts, class diagrams, or architecture visualizations in Mermaid;
  user says "draw an ERD", "flowchart of this process", "sequence diagram for
  [integration]", "architecture diagram", or "make a diagram of this".
  Also triggers in demo environments when user asks how an integration would work,
  wants to explain a data flow, or needs a talking track alongside a diagram.
  DO NOT TRIGGER when: user wants PNG/SVG image output (use sf-diagram-nanobananapro),
  or asks about non-Salesforce systems.
license: MIT
compatibility: "Requires Mermaid-capable renderer for diagram previews"
metadata:
  version: "1.4.0"
  author: "Jag Valaiyapathy"
  scoring: "80 points across 5 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-04
upstream_refs:
  - url: https://mermaid.js.org/intro/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://mermaid.js.org/syntax/flowchart.html
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://github.com/mermaid-js/mermaid/releases
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "80-pt rubric (5 categories: Accuracy 20 / Clarity 20 / Completeness 15 / Styling 15 / Best Practices 10) extracted from existing scoring section in this SKILL.md (line 191). Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  diagram_mermaid_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Mermaid syntax + diagram accuracy. Maps to Accuracy (20). Diagram code parses cleanly, actors / steps / relationships match the documented system, no fabricated objects or flows."
      automatic_hard_fail_rules:
        - "Mermaid code that doesn't parse (mermaid CLI / live editor returns syntax error)"
        - "Actor / entity that doesn't exist in the system being diagrammed (hallucination)"
        - "Flow step or relationship that misrepresents the actual integration / data model (inversion of direction, missing required step, wrong actor on a step)"
        - "ERD with relationship cardinality wrong (1:1 where 1:N is documented, or vice versa)"
        - "Sequence diagram with messages that don't match the actual API contract"
    - name: Robustness
      max: 25
      hard_fail_below: 12
      description: "Completeness + edge-case coverage. Maps to Completeness (15). All relevant steps / entities included; error paths / fallbacks shown when the use case demands it."
      automatic_hard_fail_rules:
        - "Critical step in the documented flow missing from the diagram (auth handshake, error retry, state transition)"
        - "ERD missing a required junction object that the data model uses"
        - "Sequence diagram showing only the happy path when the user explicitly asked about error handling / fallback"
        - "Architecture diagram missing the system-of-record boundary when the question is about data residency / sharing"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Clarity + best-practices conventions. Maps to Clarity (20) + Best Practices (10). Proper Mermaid notation (graph TD/LR, sequenceDiagram, erDiagram, classDiagram), labeled edges, readable layout, no jargon-heavy node names."
      automatic_hard_fail_rules:
        - "Wrong Mermaid diagram type chosen (flowchart for what should be sequenceDiagram, ER for what should be classDiagram)"
        - "Edges unlabeled when the question is about what data flows where"
        - "Node names exposing internal API names instead of human labels (e.g., 'PersonExamination__c' instead of 'Background Check')"
        - "Nesting / subgraph depth >3 (cognitive overload + Mermaid renderer struggles)"
        - "ASCII fallback skipped when explicitly requested or in a no-renderer environment"
    - name: Performance
      max: 25
      hard_fail_below: 10
      description: "Styling + render hygiene. Maps to Styling (15). Color / theme used consistently, annotations present where helpful, diagram fits intended viewport."
      automatic_hard_fail_rules:
        - "Hardcoded color scheme that fails dark mode (light-only colors with no themable token)"
        - "Diagram exceeds practical viewport without subgraph decomposition (>30 nodes in one flat graph)"
        - "Talking track / demo storytelling output requested but only the diagram code returned"
        - "Mermaid code committed without a paired rendered image when sf-diagram-nanobananapro is the expected handoff target"
  test_rubric:
    unit:
      required: true
      criteria: "Mermaid code parses without syntax errors. Diagram type matches the question shape (flow / sequence / ER / class)."
    integration:
      required: true
      criteria: "Rendered diagram (via Mermaid CLI or the live editor) displays without truncation. Edge labels + node labels readable at intended viewport."
    smoke:
      required: true
      criteria: "Audience can follow the diagram alone (without the talking track) for the documented use case. Demo storytelling mode also produces a presenter narration that matches the diagram step-for-step."
---

# sf-diagram-mermaid: Salesforce Diagram Generation

Expert diagram creator specializing in Salesforce architecture visualization and demo integration storytelling. Generate clear, accurate diagrams using Mermaid syntax as the structural source, then render them as polished images via `sf-diagram-nanobananapro` for end-user delivery. Mermaid code is retained for version control and docs; the rendered image is the primary visual output.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 80-pt rubric across 5 diagramming categories, extracted from this skill's existing scoring section (line 191) and mapped onto the 4-dim shape. Correctness floor at 14 — diagrams that misrepresent the system (wrong actor on a step, inverted relationship cardinality, fabricated objects) are worse than no diagram, since they encode the wrong mental model. Hard-fail rules block Mermaid syntax errors, hallucinated entities, missing required steps, wrong diagram type, internal API names exposed as node labels, and demo-storytelling mode requested without a paired talking track. Disable with `eval_harness.enabled: false`.

## Demo Integration Storytelling Mode

When the user is working in a **demo environment** and asks how an integration would work, wants to explain a data flow to an audience, or uses phrases like "show me what it would look like" or "talk through the integration" — produce both a diagram **and** a presenter talking track.

**Output format for demo storytelling**:

````markdown
## Integration Story: [System] ↔ Salesforce

### The Narrative
[2-3 sentence plain-English description of what the integration does and why it matters to the nonprofit]

### Architecture Diagram
```mermaid
sequenceDiagram
  ...
```

### Presenter Talking Track
**Setup line** (before clicking): "[What to say before showing the diagram]"

**Step-by-step**:
- *Arrow 1*: "[What to say as you walk through this step]"
- *Arrow 2*: "[What to say here]"
- ...

**Capability hook** (closing): "[What this means for the organization — the 'so what' for the audience]"

### If They Ask "Is This Live?"
"[Honest, confident answer about what's configured vs. what's conceptual in this demo environment]"
````

This format lets a presenter walk through the diagram live without needing to improvise. The "If They Ask" section prevents the demo from stalling if a skeptical audience member probes.

---

## Core Responsibilities

1. **Diagram Generation**: Create Mermaid diagrams from requirements or existing metadata
2. **Multi-Format Output**: Provide both Mermaid code and ASCII art fallback
3. **sf-metadata Integration**: Auto-discover objects/fields for ERD diagrams
4. **Validation & Scoring**: Score diagrams against 5 categories (0-80 points)

## Supported Diagram Types

| Type | Mermaid Syntax | Use Case |
|------|---------------|----------|
| OAuth Flows | `sequenceDiagram` | Authorization Code, JWT Bearer, PKCE, Device Flow |
| Data Models | `flowchart LR` | Object relationships with color coding (preferred) |
| Integration Sequences | `sequenceDiagram` | API callouts, event-driven flows |
| **Demo Integration Story** | `sequenceDiagram` | Show what an integration *would* look like in a demo — includes talking track and "If They Ask" script |
| System Landscapes | `flowchart` | High-level architecture, component diagrams |
| Role Hierarchies | `flowchart` | User hierarchies, profile/permission structures |
| Agentforce Flows | `flowchart` | Agent → Topic → Action flows |

### Additional Mermaid Diagram Types (reference)

As of Mermaid 11.14.0 the following diagram types are also available if a specific use case calls for them. They are **not** part of the core Salesforce templates above, but can be used ad hoc when the standard types don't fit:

- `architecture-beta` — cloud/system architecture with groups, services, and edges
- `block-beta` — block layouts (panels, grids) useful for landscape wireframes
- `packet-beta` — byte/bit packet layouts (rarely relevant for Salesforce)
- `kanban` — Kanban boards
- `timeline` — chronological events
- `mindmap` — hierarchical idea maps
- `sankey-beta`, `xychart-beta`, `quadrantChart`, `radar-beta`, `treemap`, `venn`, `ishikawa`, `treeview` — specialty charts

Prefer the core types in the table above for Salesforce work; reach for these only when the user asks for a shape the core types can't produce.

## Workflow (5-Phase Pattern)

### Phase 1: Requirements Gathering

**Ask the user** to gather:
- Diagram type (OAuth, ERD, Integration, Landscape, Role Hierarchy, Agentforce)
- Specific flow or scope (e.g., "JWT Bearer flow" or "Account-Contact-Opportunity model")
- Output preference (Mermaid only, ASCII only, or Both)
- Any custom styling requirements

**Then**:
1. If ERD requested, check for sf-metadata availability
2. Create a task list for multi-diagram requests

### Phase 2: Template Selection

**Select template based on diagram type**:

| Diagram Type | Template File |
|--------------|---------------|
| Authorization Code Flow | `oauth/authorization-code.md` |
| Authorization Code + PKCE | `oauth/authorization-code-pkce.md` |
| JWT Bearer Flow | `oauth/jwt-bearer.md` |
| Client Credentials Flow | `oauth/client-credentials.md` |
| Device Authorization Flow | `oauth/device-authorization.md` |
| Refresh Token Flow | `oauth/refresh-token.md` |
| Data Model (ERD) | `datamodel/salesforce-erd.md` |
| Integration Sequence | `integration/api-sequence.md` |
| System Landscape | `architecture/system-landscape.md` |
| Role Hierarchy | `role-hierarchy/user-hierarchy.md` |
| Agentforce Flow | `agentforce/agent-flow.md` |

**Template Path Resolution** (try in order):
1. **Marketplace folder** (always available): `~/.claude/plugins/marketplaces/sf-skills/sf-diagram-mermaid/assets/[template]`
2. **Project folder** (if working in sf-skills repo): `[project-root]/sf-diagram-mermaid/assets/[template]`
3. **Cache folder** (if installed individually): `~/.claude/plugins/cache/sf-diagram-mermaid/*/sf-diagram-mermaid/assets/[template]`

**Example**: To load JWT Bearer template:
```
Read: ~/.claude/plugins/marketplaces/sf-skills/sf-diagram-mermaid/assets/oauth/jwt-bearer.md
```

### Phase 3: Data Collection

**For OAuth Diagrams**:
- Use standard actors (Browser, Client App, Salesforce)
- Apply CloudSundial-inspired styling
- Include all protocol steps with numbered sequence

**For ERD/Data Model Diagrams**:
1. If org connected, query record counts for LDV indicators:
   ```bash
   python3 scripts/query-org-metadata.py --objects Account,Contact --target-org myorg
   ```
2. Identify relationships (Lookup vs Master-Detail)
3. Determine object types (Standard, Custom, External)
4. Generate `flowchart LR` with color coding (preferred format)

**For Integration Diagrams**:
- Identify all systems involved
- Capture request/response patterns
- Note async vs sync interactions

### Phase 4: Diagram Generation

**Generate Mermaid code**:
1. Apply color scheme from `references/color-palette.md`
2. Add annotations and notes where helpful
3. Include autonumber for sequence diagrams
4. For data models: Use `flowchart LR` with object-type color coding
5. Keep ERD objects simple - show object name and record count only (no fields)

**Generate ASCII fallback**:
1. Use box-drawing characters: `┌ ─ ┐ │ └ ┘ ├ ┤ ┬ ┴ ┼`
2. Use arrows: `──>` `<──` `───` `─┼─`
3. Keep width under 80 characters when possible

**Run Validation**:
```
Score: XX/80 ⭐⭐⭐⭐ Rating
├─ Accuracy: XX/20      (Correct actors, flow steps, relationships)
├─ Clarity: XX/20       (Easy to read, proper labeling)
├─ Completeness: XX/15  (All relevant steps/entities included)
├─ Styling: XX/15       (Color scheme, theming, annotations)
└─ Best Practices: XX/10 (Proper notation, UML conventions)
```

### Phase 5: Output & Documentation

**Note**: This phase produces the Mermaid source. Phase 5.5 (Visual Rendering) runs immediately after to generate the rendered image, which becomes the primary deliverable. The format below is the **fallback** used only when Phase 5.5 is skipped.

**Mermaid-only delivery format** (used only when user requests "Mermaid only" or "no image"):

````markdown
## [Diagram Title]

### Mermaid Diagram
```mermaid
[Generated Mermaid code]
```

### ASCII Fallback
```
[Generated ASCII diagram]
```

### Key Points
- [Important note 1]
- [Important note 2]

### Diagram Score
[Validation results]
````

### Phase 5.5: Visual Rendering via Nano Banana (Default)

After generating the Mermaid diagram, **render it as a polished image** by delegating to `sf-diagram-nanobananapro`.

**This phase runs by default.** Skip only if the user explicitly says "Mermaid only", "text only", or "no image."

**Workflow**:
1. Take the completed Mermaid diagram code from Phase 4
2. Convert it into a Nano Banana image prompt that preserves the structure, relationships, labels, and annotations
3. Delegate to `sf-diagram-nanobananapro` Pattern E (Mermaid-to-Visual Rendering)
4. Deliver both outputs:
   - The **rendered image** as the primary visual for the end user
   - The **Mermaid source code** in a collapsible `<details>` block for version control and documentation

**Prompt conversion rules** (Mermaid → Nano Banana):
- Translate node labels into entity/box descriptions with their names
- Translate edge labels into labeled relationship arrows
- Preserve directional flow (LR, TB, etc.) as spatial layout instructions
- Map Mermaid styling (colors, thickness) to visual descriptions ("blue boxes", "thick arrows for master-detail")
- Include the diagram type in the prompt ("ERD", "sequence diagram", "flowchart", "architecture overview")
- Add "Salesforce architect.salesforce.com aesthetic, clean white background, professional" as the default style

**Updated delivery format**:

````markdown
## [Diagram Title]

[Rendered image from Nano Banana — displayed inline]

<details>
<summary>Mermaid source (for docs and version control)</summary>

```mermaid
[Generated Mermaid code]
```

</details>

### Key Points
- [Important note 1]
- [Important note 2]

### Diagram Score
[Validation results]
````

### Phase 5.7: Preview (Optional)

Offer localhost preview for real-time Mermaid iteration before visual rendering. See [references/preview-guide.md](references/preview-guide.md) for setup instructions.

---

## Mermaid Styling Guide

Use Tailwind 200-level pastel fills with dark strokes. See [references/mermaid-styling.md](references/mermaid-styling.md) for complete color palette and examples.

**Quick reference**:
```
%%{init: {"flowchart": {"nodeSpacing": 80, "rankSpacing": 70}} }%%
style A fill:#fbcfe8,stroke:#be185d,color:#1f2937
```

Either the legacy `%%{init: ...}%%` directive or the YAML frontmatter form is valid:

```
---
config:
  flowchart:
    nodeSpacing: 80
    rankSpacing: 70
    curve: stepBefore
---
flowchart LR
```

### Optional: Modern shape / edge features (Mermaid v11.3.0+ and v11.10.0+)

These are **optional** enhancements. Keep the base templates as-is; reach for these only when the user asks for them or when the default shapes are insufficient.

- **Typed shape syntax (v11.3.0+)**: `A@{ shape: rect }`, `A@{ shape: cyl }` (database), `A@{ shape: doc }`, `A@{ shape: docs }` (multi-doc), `A@{ shape: hex }`, `A@{ shape: bolt }` (com link), `A@{ shape: cloud }`, `A@{ shape: das }` (direct access storage), etc. 30 new semantic shapes total.
- **Icon shape**: `A@{ icon: "fa:fa-server", form: "rounded", label: "API", pos: "b", h: 48 }` — requires a registered icon pack.
- **Image shape**: `A@{ img: "https://…/logo.png", label: "…", w: 60, h: 60, constraint: "on" }`.
- **Edge IDs (v11.10.0+)**: `A e1@--> B` — assign an ID to an edge so it can be styled, animated, or curve-overridden later.
- **Edge animations (v11.10.0+)**: after assigning an ID, either set properties (`e1@{ animate: true, animation: fast }`) or apply a `classDef` with `stroke-dasharray` (escape commas as `\,`). Useful for demo integration storytelling to show data flowing from one system to Salesforce.
- **Per-edge curve override (v11.10.0+)**: `e1@{ curve: stepBefore }` — overrides the diagram-level curve on just that edge.

---

## Scoring Thresholds

| Rating | Score | Meaning |
|--------|-------|---------|
| ⭐⭐⭐⭐⭐ Excellent | 72-80 | Production-ready, comprehensive, well-styled |
| ⭐⭐⭐⭐ Very Good | 60-71 | Complete with minor improvements possible |
| ⭐⭐⭐ Good | 48-59 | Functional but could be clearer |
| ⭐⭐ Needs Work | 35-47 | Missing key elements or unclear |
| ⭐ Critical Issues | <35 | Inaccurate or incomplete |

---

## OAuth Flow Quick Reference

| Flow | Use Case | Key Detail | Template |
|------|----------|------------|----------|
| **Authorization Code** | Web apps with backend | User → Browser → App → SF | `oauth/authorization-code.md` |
| **Auth Code + PKCE** | Mobile, SPAs, public clients | code_verifier + SHA256 challenge | `oauth/authorization-code-pkce.md` |
| **JWT Bearer** | Server-to-server, CI/CD | Sign JWT with private key | `oauth/jwt-bearer.md` |
| **Client Credentials** | Service accounts, background | No user context | `oauth/client-credentials.md` |
| **Device Authorization** | CLI, IoT, Smart TVs | Poll for token after user auth | `oauth/device-authorization.md` |
| **Refresh Token** | Extend access | Reuse existing tokens | `oauth/refresh-token.md` |

Templates in `assets/oauth/`.

---

## Data Model Notation Reference

### Preferred Format: `flowchart LR`

Use `flowchart LR` (left-to-right) for data model diagrams. This format supports:
- Individual node color coding by object type
- Thick arrows (`==>`) for Master-Detail relationships
- Left-to-right flow for readability

### Relationship Arrows
```
-->   Lookup (LK) - optional parent, no cascade delete
==>   Master-Detail (MD) - required parent, cascade delete
-.->  Conversion/special relationship (e.g., Lead converts)
```

### Object Node Format
```
ObjectName["ObjectName<br/>(record count)"]
```

Example: `Account["Account<br/>(317)"]`

---

## Enhanced ERD Features

### Object Type Color Coding

When using the flowchart-based ERD format, objects are color-coded by type:

| Object Type | Color | Fill | Stroke |
|-------------|-------|------|--------|
| Standard Objects | Sky Blue | `#bae6fd` | `#0369a1` |
| Custom Objects (`__c`) | Orange | `#fed7aa` | `#c2410c` |
| External Objects (`__x`) | Green | `#a7f3d0` | `#047857` |

### LDV (Large Data Volume) Indicators

For orgs with large datasets, query record counts and display LDV indicators:

```bash
python3 ~/.claude/plugins/marketplaces/sf-skills/sf-diagram-mermaid/scripts/query-org-metadata.py \
    --objects Account,Contact,Opportunity \
    --target-org myorg
```

Objects with >2M records display: `LDV[~4M]`

### OWD (Org-Wide Defaults)

Display sharing model on entities: `OWD:Private`, `OWD:ReadWrite`, `OWD:Parent`

### Relationship Types

| Label | Type | Arrow Style | Behavior |
|-------|------|-------------|----------|
| `LK` | Lookup | `-->` | Optional parent, no cascade |
| `MD` | Master-Detail | `==>` | Required parent, cascade delete |

In flowchart format:
- Lookup: `-->` (single arrow)
- Master-Detail: `==>` (thick double arrow)

### Data Model Templates

| Template | Objects | Path |
|----------|---------|------|
| **Core** | Account, Contact, Opportunity, Case | `assets/datamodel/salesforce-erd.md` |
| **Sales Cloud** | Account, Contact, Lead, Opportunity, Product, Campaign | `assets/datamodel/sales-cloud-erd.md` |
| **Service Cloud** | Case, Entitlement, Knowledge, ServiceContract | `assets/datamodel/service-cloud-erd.md` |
| **Campaigns** | Campaign, CampaignMember, CampaignInfluence | `assets/datamodel/campaigns-erd.md` |
| **Territory Management** | Territory2, Territory2Model, UserTerritory2Association | `assets/datamodel/territory-management-erd.md` |
| **Party Model** | AccountContactRelation, ContactContactRelation | `assets/datamodel/party-model-erd.md` |
| **Quote & Order** | Quote, QuoteLineItem, Order, OrderItem | `assets/datamodel/quote-order-erd.md` |
| **Forecasting** | ForecastingItem, ForecastingQuota, OpportunitySplit | `assets/datamodel/forecasting-erd.md` |
| **Consent (GDPR)** | Individual, ContactPointEmail, DataUsePurpose | `assets/datamodel/consent-erd.md` |
| **Files** | ContentDocument, ContentVersion, ContentDocumentLink | `assets/datamodel/files-erd.md` |
| **Scheduler** | ServiceAppointment, ServiceResource, ServiceTerritory | `assets/datamodel/scheduler-erd.md` |
| **Field Service** | WorkOrder, ServiceAppointment, TimeSheet | `assets/datamodel/fsl-erd.md` |
| **B2B Commerce** | WebStore, WebCart, BuyerGroup, BuyerAccount | `assets/datamodel/b2b-commerce-erd.md` |
| **Revenue Cloud** | ProductCatalog, ProductSellingModel, PriceAdjustment | `assets/datamodel/revenue-cloud-erd.md` |

### ERD Conventions Documentation

See `references/erd-conventions.md` for complete documentation of:
- Object type indicators (`[STD]`, `[CUST]`, `[EXT]`)
- LDV display format
- OWD display format
- Relationship type labels
- Color palette details

---

## Best Practices

### Sequence Diagrams
- Use `autonumber` for OAuth flows (step tracking)
- Use `->>` for requests, `-->>` for responses
- Use `activate`/`deactivate` for long-running processes
- Group related actors with `box` blocks
- Add `Note over` for protocol details (tokens, codes)

### Data Model Diagrams
- Use `flowchart LR` format (left-to-right flow)
- Keep objects simple: name + record count only (no fields)
- Color code by object type: Blue=Standard, Orange=Custom, Green=External
- Use `-->` for Lookup, `==>` for Master-Detail relationships
- Add LDV indicator for objects >2M records
- Use API names, not labels (e.g., `Account` not "Accounts")

### Integration Diagrams
- Show error paths with `alt`/`else` blocks
- Include timeout handling for external calls
- Mark async calls with `-)` notation
- Add system icons for clarity (☁️ 🔄 🏭 💾)

### ASCII Diagrams
- Keep width ≤80 characters
- Use consistent box sizes
- Align arrows clearly
- Add step numbers for sequences

---

## Cross-Skill Integration

| Skill | When to Use | Example |
|-------|-------------|---------|
| sf-metadata | Get real object/field definitions for ERD | Use the **sf-metadata** skill: "Describe Lead object" |
| sf-connected-apps | Link OAuth flow to Connected App setup | "Generate JWT Bearer diagram for this Connected App" |
| sf-ai-agentscript | Visualize Agentforce agent architecture | "Create flow diagram for FAQ Agent" |
| sf-flow | Document Flow logic as flowchart | "Diagram the approval process flow" |

## Dependencies

**Optional**: sf-metadata (for ERD auto-discovery)

---

## Example Usage

### 1. OAuth Flow Request
```
User: "Create a JWT Bearer OAuth flow diagram"

You should:
1. Load assets/oauth/jwt-bearer.md
2. Generate Mermaid sequenceDiagram
3. Generate ASCII fallback
4. Score and deliver
```

### 2. Data Model Request
```
User: "Create an ERD for Account, Contact, Opportunity, and Case"

You should:
1. If org connected: Query record counts via query-org-metadata.py
2. Load assets/datamodel/salesforce-erd.md (or cloud-specific template)
3. Generate Mermaid flowchart LR with:
   - Object nodes (name + record count, no fields)
   - Color coding by object type (Standard=Blue, Custom=Orange)
   - Relationship arrows (LK=-->, MD===>)
4. Generate ASCII fallback
5. Score and deliver
```

### 3. Integration Diagram Request
```
User: "Diagram our Salesforce to SAP integration flow"

You should:
1. Ask clarifying questions (sync/async, trigger, protocol)
2. Load assets/integration/api-sequence.md
3. Generate Mermaid sequenceDiagram
4. Generate ASCII fallback
5. Score and deliver
```

### 4. Demo Integration Storytelling Request
```
User: "Show me what a Stripe integration would look like for our donation flow"
User: "How would Bloomerang sync to Salesforce? I need to explain it in the demo."
User: "Talk me through how an SMS notification integration would work."

You should:
1. Recognize this is a demo storytelling request — no live connection exists
2. Generate a sequenceDiagram showing the systems, trigger, data flow, and Salesforce outcome
3. Write a presenter talking track: setup line, step-by-step narration, capability hook
4. Add an "If They Ask" script for the honest answer about live vs. conceptual
5. Do NOT generate Named Credential XML or callout code unless explicitly asked
6. Suggest sf-integration Mode 2 (Art of the Possible) if they want to make the data feel real
```

---

## Notes

- **Mermaid Rendering**: Works in GitHub, VS Code, Notion, Confluence, and most modern tools
- **ASCII Purpose**: Terminal compatibility, documentation that needs plain text
- **Color Accessibility**: Palette designed for color-blind accessibility
- **Template Customization**: Templates are starting points; customize per requirements

---

## License

MIT License.
Copyright (c) 2024-2025 Jag Valaiyapathy
