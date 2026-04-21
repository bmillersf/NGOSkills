---
description: Auto-routes nonprofit demo environment prompts to the correct skill based on keyword matching
globs:
alwaysApply: true
---

# Nonprofit Demo Environment Skill Auto-Router

When the user's prompt contains keywords related to Salesforce nonprofit features or demo environment work,
automatically apply the matching skill(s) from the keyword index below.

> **Context**: This workspace builds **demo environments**, not production orgs. Integration and SSO
> questions are about explaining or visualizing the concept — not configuring live callouts or OAuth flows.
> When an integration topic arises, prefer a Mermaid diagram and talking track over configuration XML.

---

## Routing Rules

1. Scan the user prompt for keywords listed under each skill
2. If keywords from a single skill are found, apply that skill
3. If keywords from multiple skills match, apply the most specific skill first
4. Always determine NPC vs NPSP before generating code or configuration
5. If both NPC and NPSP keywords appear, apply sf-nonprofit-cloud first (it routes)

---

## Priority Order

When multiple skills match, prefer in this order:

### Always Co-Activate (does not replace other matches; runs alongside)
- `sf-subagent-orchestration` — co-activates whenever **any** other multi-phase `sf-*` skill is selected (anything in the End-to-End Demo Pipeline tier, the Demo Lifecycle tier, the Capability Showcase tier, or the Nonprofit Domain tier). It supplies the delegation policy (when to spawn `explore` / `generalPurpose` / `shell` subagents, the standard contract, parallel patterns) so the active skill's phase-level `**Delegation:**` annotations have a single source of truth. Single-question prompts that don't activate any other `sf-*` skill do **not** trigger this skill.

### End-to-End Demo Pipeline (resolve first — beats every single-phase skill)
0. `sf-demo-orchestrate` — user asks for the **whole pipeline** in one prompt (notes -> presenter-ready). Routes through all four single-phase skills in order with approval gates.

### Demo Lifecycle (resolve next — these define the type of task)
1. `sf-demo-author` — writing or authoring a demo script from notes
2. `sf-nonprofit-demo-data` — seeding or generating demo data
3. `sf-demo-validate` — validating or repairing a demo environment
4. `sf-demo-playwright` — generating automated pre-flight tests or a presenter guide

### Capability Showcase
5. `sf-ai-agentforce` — building Agentforce agents, topics, actions, PromptTemplates
6. `sf-ai-agentforce-persona` — agent personality and voice design
7. `sf-ai-agentforce-testing` — testing and validating agent routing
8. `sf-datacloud` — Data Cloud pipeline design and validation
9. `sf-diagram-mermaid` — architecture diagrams and integration storytelling

### Integration Storytelling (conceptual only in demo context)
10. `sf-integration` — explain what an integration would look like; generate diagrams and talking tracks — **do not generate Named Credential XML or live callout code for demo orgs**

### Nonprofit Domain
11. `sf-nonprofit-cloud` — platform router, apply first if NPC vs NPSP is ambiguous
12. `sf-nonprofit-npsp` — NPSP-specific work
13. `sf-nonprofit-fundraising` — NPC fundraising
14. `sf-nonprofit-grants` — NPC grants
15. `sf-nonprofit-program-case` — NPC programs
16. `sf-nonprofit-experience-cloud` — portals and community sites
17. `sf-nonprofit-experience-cloud-ux` — portal UX and design

---

## CRITICAL: Platform Separation

- NPSP keywords → route to `sf-nonprofit-npsp`
- NPC/Nonprofit Cloud keywords → route to `sf-nonprofit-fundraising` / `sf-nonprofit-grants` / `sf-nonprofit-program-case`
- NEVER mix NPSP and NPC object models in the same implementation
- When in doubt, ask: "Is this org running NPSP or Nonprofit Cloud?"

---

## Keyword Index

### sf-subagent-orchestration

  *(co-activation skill — no direct user trigger required; auto-applies whenever another multi-phase sf-* skill is active)*
  Direct triggers: delegate subagent, delegation policy, parallel subagents, run in parallel, spawn subagent
  spawn subagents, subagent contract, subagent delegation, subagent orchestration, subagent pattern
  subagent strategy, when to delegate

### sf-demo-orchestrate

  build me a demo, build the demo, demo pipeline, demo prep, demo workflow, end to end demo, end-to-end demo
  from discovery to presenter, full demo, full demo workflow, get me ready for a demo, get ready for a demo
  go from notes to demo, i want to prep for a demo, i want to prepare for a demo, notes to demo
  orchestrate demo, orchestrate the demo, prep a demo, prep for a demo, prep for the demo, prep the demo
  prepare a demo, prepare for a demo, prepare for the demo, prepare the demo, prepping a demo
  prepping for a demo, presenter ready, ready the demo, run the demo, run the full demo
  run the pipeline, run the workflow, ship a demo, take me from notes

### sf-demo-author

  author demo, click path, create a demo, demo narrative, demo script, demo story, demoscript, demoscript.md
  discovery notes, generate a demo, meeting notes to demo, write a demo, write demo, write the demo

### sf-nonprofit-demo-data

  demo data, demo data factory, demo records, generate demo records, persona data, populate org, populate the org
  realistic data, seed data, seed demo, seed org, seed the org, story data

### sf-demo-validate

  check demo, check demoscript, demo broken, demo not working, demo ready, fix demo, pre-demo check
  run demoscript, validate demo, validate environment, verify demo

### sf-demo-playwright

  automate demo, demo test suite, playwright, pre-flight, presenter guide, screenshot validation
  visual pre-flight

### sf-ai-agentforce

  agent action, agent builder, agent topic, agentforce, build agent, configure agent, genaifunction
  genaiplugin, prompt template, prompttemplate, topic routing

### sf-ai-agentforce-persona

  agent identity, agent persona, agent personality, agent tone, agent voice, design agent persona
  persona document, persona for agent

### sf-ai-agentforce-testing

  agent test, agent test spec, sf agent test, test agent, test topic routing, validate agent routing

### sf-datacloud

  act phase, activation target, calculated insight, connect phase, data cloud, data graph, data kit
  data model object, data space, data stream, data360, dlo, dmo, harmonize, identity resolution
  prepare phase, segment, unified profile

### sf-diagram-mermaid

  architecture diagram, class diagram, data flow, diagram, erd, entity relationship, entity-relationship
  explain integration, flowchart, how would integration work, integration architecture, integration diagram
  integration story, mermaid, sequence diagram, show integration, talk through integration, visualize, what would x look like

### sf-integration

  api integration, art of the possible, fake integration, integration concept, integration demo
  integration overview, integration pattern, integration talking points, mock integration, mock payload
  platform event, show data flowing, show me how integration works, simulate integration, simulated data
  third-party, what would a integration look like, webhook

  > **Demo context rule**: Three valid modes for demo orgs — choose based on what the user asks for:
  >
  > 1. **Storytelling** — Mermaid sequence diagram + presenter talking track explaining the integration concept
  > 2. **Art of the possible** — Simulate the integration with fake data: Anonymous Apex that mimics an
  >    inbound payload, seed records that "arrived from" a third-party system, or a Platform Event that
  >    fires as if triggered externally. Makes the data flow feel real without a live connection.
  > 3. **Production config** — Named Credential XML, External Service registrations, live callout Apex.
  >    Only generate this if the user explicitly asks for production configuration.
  >
  > Default to mode 1 or 2 in a demo environment. When in doubt, ask: "Do you want to talk through it,
  > fake it with data, or build it for real?"

### sf-nonprofit-cloud

  nonprofit cloud, nonprofit platform, nonprofit salesforce, nonprofit success pack, npc, npsp
  npsp to npc migration, person account vs contact, salesforce nonprofit, salesforce.org

### sf-nonprofit-experience-cloud

  client portal, community site, donor portal, experience cloud nonprofit, grantee portal, guest access nonprofit
  lwr site nonprofit, nonprofit portal, self-service portal, sharing rules nonprofit, volunteer portal

### sf-nonprofit-experience-cloud-ux

  donor experience, nonprofit portal design, portal accessibility, portal branding, portal design
  portal navigation, portal ui, portal ux, portal wireframe, volunteer experience

### sf-nonprofit-fundraising

  annual fund, campaign, capital campaign, donation, donor lifecycle, donor management, donor retention
  donor stewardship, fundraising, gift commitment, gift designation, gift entry, gift processing
  gift schedule, gift soft credit, gift transaction, major gift, nonprofit cloud fundraising, npc fundraising
  payment instrument, planned giving, pledge, recurring giving

### sf-nonprofit-grants

  application, award management, budget, disbursement schedule, funder reporting, funding award
  funding disbursement, funding program, grant application, grant compliance, grant management
  grant pipeline, grantmaking, nonprofit cloud grants, npc grantmaking, review process

### sf-nonprofit-npsp

  account merge, batch gift entry, contact merge, crlp, customizable rollup, data import, donor level
  engagement plan, gau allocation, general accounting unit, gw_volunteers__, household account
  household naming, individual bucket, lead conversion npsp, manage households, matching gift
  memorial gift, nonprofit success pack, npe01__, npe03__, npe4__, npe5__, npo02__, npsp, npsp batch
  npsp error, npsp health check, npsp settings, npsp__, ofm, one-to-one account, opp payment
  opportunity naming, outbound funds module, outfunds__, partial soft credit, pmdm__, pmm
  program management module, recurring donation, seasonal address, tdtm, tribute gift, v4s
  volunteers for salesforce

### sf-nonprofit-program-case

  benefit, benefit disbursement, case management, client management, indicator definition, indicator result
  intake, nonprofit cloud program, npc program, outcome activity, outcome management, outcome tracking
  program design, program enrollment, program management, referral, service delivery, social services
  wraparound services

---

*Updated 2026-04-14 — expanded for demo environment context with demo lifecycle, capability showcase, and integration storytelling tiers*
