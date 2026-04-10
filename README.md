# NGO Salesforce Skills

A curated collection of Cursor Agent Skills purpose-built for Salesforce development on the Nonprofit Cloud platform. These skills give Cursor's AI agent deep, domain-specific knowledge so it can generate, review, and validate Salesforce metadata, code, and configuration with minimal hand-holding.

## Repository Structure

```
skills/                  # Salesforce-domain skills
skills-cursor/           # Cursor IDE workflow skills
```

## Salesforce Skills (`skills/`)

### Agentforce & AI

| Skill | Description |
|---|---|
| **sf-ai-agentforce** | Build Agentforce agents via the Setup UI -- topics, actions, PromptTemplates, and `.genAiFunction` / `.genAiPlugin` metadata. |
| **sf-ai-agentforce-observability** | Extract and analyze Agentforce session traces (STDM data) from Data Cloud, including `.parquet` telemetry files. |
| **sf-ai-agentforce-persona** | Deep persona design for Agentforce agents with a 50-point scoring rubric covering identity, tone, voice, and register. |
| **sf-ai-agentforce-testing** | Dual-track testing workflow for Agentforce agents with 100-point scoring -- test specs, topic routing validation, and coverage analysis via `sf agent test`. |
| **sf-ai-agentscript** | Author deterministic Agentforce agents using the Agent Script DSL (`.agent` files) -- FSM-based state machines, slot filling, and instruction resolution. |

### Core Platform Development

| Skill | Description |
|---|---|
| **sf-apex** | Generate and review Apex classes, triggers, batch/queueable/schedulable jobs, and test classes with a 150-point scoring rubric. |
| **sf-lwc** | Lightning Web Components using the PICKLES methodology with 165-point scoring -- wire service, SLDS, Jest tests, and `.js-meta.xml` config. |
| **sf-flow** | Create and validate Salesforce Flows (record-triggered, screen, autolaunched, scheduled) and `.flow-meta.xml` files with 110-point scoring. |
| **sf-metadata** | Generate and query Salesforce metadata -- custom objects, fields, validation rules, and associated `-meta.xml` files with 120-point scoring. |
| **sf-soql** | SOQL/SOSL query generation, optimization, relationship queries, aggregates, and performance analysis with 100-point scoring. |
| **sf-testing** | Apex test execution, code coverage analysis, and test-fix loops with 120-point scoring for `*Test.cls` files. |
| **sf-debug** | Debug log analysis and troubleshooting -- governor limits, stack traces, and `.log` files with 100-point scoring. |
| **sf-deploy** | DevOps automation using `sf` CLI v2 -- metadata deploys, scratch orgs, sandboxes, and CI/CD pipelines. |
| **sf-data** | Salesforce data operations with 130-point scoring -- test data creation, bulk import/export, `sf data` CLI commands, and data factory patterns. |
| **sf-permissions** | Permission Set analysis, hierarchy visualization, and access auditing for `.permissionset-meta.xml` and `.permissionsetgroup-meta.xml`. |

### Integration & Security

| Skill | Description |
|---|---|
| **sf-integration** | Integration architecture with 120-point scoring -- Named Credentials, External Services, REST/SOAP callouts, Platform Events, and CDC. |
| **sf-connected-apps** | Connected Apps and OAuth configuration with 120-point scoring -- OAuth flows, JWT bearer auth, and `.connectedApp-meta.xml` files. |

### Data Cloud

| Skill | Description |
|---|---|
| **sf-datacloud** | Product orchestrator for the full Data Cloud lifecycle: connect, prepare, harmonize, segment, act. Routes to phase-specific skills. |
| **sf-datacloud-connect** | Data Cloud Connect phase -- manage connections, connectors, source objects, and database configuration. |
| **sf-datacloud-prepare** | Data Cloud Prepare phase -- data streams, DLOs, transforms, Document AI, and ingestion configuration. |
| **sf-datacloud-harmonize** | Data Cloud Harmonize phase -- DMOs, field mappings, relationships, identity resolution, and unified profiles. |
| **sf-datacloud-retrieve** | Data Cloud Retrieve phase -- SQL queries, async queries, vector search, search-index workflows, and metadata introspection. |
| **sf-datacloud-segment** | Data Cloud Segment phase -- segment creation, calculated insights, audience SQL, and membership analysis. |
| **sf-datacloud-act** | Data Cloud Act phase -- activations, activation targets, data actions, and downstream delivery. |

### Industries / OmniStudio

| Skill | Description |
|---|---|
| **sf-industry-commoncore-callable-apex** | `System.Callable` class generation and review with 120-point scoring -- OmniStudio extensions, `VlocityOpenInterface` migration. |
| **sf-industry-commoncore-datamapper** | OmniStudio Data Mapper (formerly DataRaptor) creation -- Extract, Transform, Load, and Turbo Extract configurations with 100-point scoring. |
| **sf-industry-commoncore-flexcard** | OmniStudio FlexCard creation with 130-point scoring -- data source bindings, Integration Procedure wiring, and accessibility. |
| **sf-industry-commoncore-integration-procedure** | OmniStudio Integration Procedure orchestration with 110-point scoring -- Data Mapper steps, Remote Actions, and HTTP callouts. |
| **sf-industry-commoncore-omniscript** | OmniStudio OmniScript creation with 120-point scoring -- guided digital experiences, multi-step forms, and element configuration. |
| **sf-industry-commoncore-omnistudio-analyze** | Cross-cutting OmniStudio analysis -- namespace detection (Core vs vlocity_cmt vs vlocity_ins), dependency visualization, and impact analysis. |

### Nonprofit Cloud

| Skill | Description |
|---|---|
| **sf-nonprofit-cloud** | Nonprofit Cloud architecture, data model design, and NPSP migration guidance with 100-point scoring. |
| **sf-nonprofit-experience-cloud** | Nonprofit Experience Cloud architecture with 120-point scoring -- donor/volunteer/client/grantee portals, sharing rules, and guest access. |
| **sf-nonprofit-experience-cloud-ux** | Nonprofit portal UX/UI design with 100-point scoring -- branding, navigation flows, responsive design, accessibility, and wireframes. |
| **sf-nonprofit-fundraising** | Fundraising architecture with 120-point scoring -- donor management, gift entry, campaigns, soft credits, recurring giving, and payment processing. |
| **sf-nonprofit-grants** | Grant management architecture with 110-point scoring -- applications, review workflows, disbursements, budgets, and compliance tracking. |
| **sf-nonprofit-program-case** | Program and case management architecture with 120-point scoring -- enrollment, service delivery, intake, outcome tracking, and referrals. |

### Visualization & Docs

| Skill | Description |
|---|---|
| **sf-diagram-mermaid** | Salesforce architecture diagrams using Mermaid (with ASCII fallback) -- ERDs, sequence diagrams, flowcharts, and class diagrams. |
| **sf-diagram-nanobananapro** | AI-powered image generation via Nano Banana Pro -- PNG/SVG output, UI mockups, wireframes, and visual ERDs. |
| **sf-docs** | Official Salesforce documentation retrieval from developer.salesforce.com and help.salesforce.com, with JS-heavy page extraction. |

### Demo Validation

| Skill | Description |
|---|---|
| **sf-demo-validate** | Autonomous demo script validation and repair with 200-point scoring -- platform prereqs, metadata, data quality, permissions, automations, UI, Experience Cloud sites, and end-to-end user simulation. Supports Agentforce, Data Cloud, Slack, Marketing Cloud, Tableau/CRM Analytics, and OmniStudio. |

---

## Cursor IDE Skills (`skills-cursor/`)

| Skill | Description |
|---|---|
| **babysit** | Keep a PR merge-ready by triaging comments, resolving clear conflicts, and fixing CI in a loop. |
| **create-hook** | Create Cursor hooks -- `hooks.json` authoring and hook script automation around agent events. |
| **create-rule** | Create Cursor rules for persistent AI guidance -- coding standards, project conventions, and `RULE.md` files in `.cursor/rules/`. |
| **create-skill** | Author new Cursor Agent Skills -- skill structure, `SKILL.md` format, and best practices. |
| **create-subagent** | Create Cursor subagents for specialized task delegation. |
| **migrate-to-skills** | Migrate legacy Cursor configurations to the Skills format. |
| **shell** | Shell command execution specialist for terminal operations. |
| **statusline** | Configure a custom status line in the Cursor CLI -- session context above the prompt. |
| **update-cli-config** | View and modify Cursor CLI configuration in `cli-config.json` -- permissions, approval mode, sandbox, and display options. |
| **update-cursor-settings** | Modify Cursor/VSCode `settings.json` -- themes, fonts, formatting, keybindings, and editor preferences. |

---

## Usage

1. Clone this repository into your Cursor skills directory (typically `~/.cursor/skills/`).
2. Skills are automatically discovered by Cursor when their `SKILL.md` frontmatter matches the user's current task context.
3. Each skill contains a `SKILL.md` file with trigger conditions, scoring rubrics, and step-by-step instructions that guide the AI agent.

## Skill Anatomy

Every skill follows the same structure:

```
skill-name/
  SKILL.md          # Frontmatter (name, description, triggers) + detailed instructions
  [supporting files] # Templates, reference data, examples (varies by skill)
```

The `SKILL.md` frontmatter defines:
- **name** -- unique identifier
- **description** -- what the skill does and when it triggers
- **TRIGGER when** -- conditions that activate the skill
- **DO NOT TRIGGER when** -- conditions that should route to a different skill instead
