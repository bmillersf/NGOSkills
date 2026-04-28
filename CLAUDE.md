# Using NGO Salesforce Skills with Claude

This guide covers how to load these skills into Claude so they work the same way they do in Cursor — with automatic domain routing, scoring rubrics, and deep Salesforce/nonprofit context applied to every response.

---

## Important: What Claude Can and Cannot Do Automatically

| Action | Cursor | Claude |
|---|---|---|
| `"Install skills from [repo]"` | ✅ Clones repo + installs automatically | ❌ Cannot clone repos or write files |
| `"Update my skills from the repo"` | ✅ Pulls latest and updates automatically | ❌ Cannot access GitHub |
| `"Apply the sf-apex skill"` | ✅ Loads skill file and executes | ✅ Works if skill is in project knowledge |
| Following skill methodology once loaded | ✅ | ✅ Identical output quality |

**Cursor** has native git and file system access — a single prompt installs everything.

**Claude.ai** does not have access to GitHub or your file system. It cannot clone repositories, run shell commands, or write files on your behalf. The setup requires you to upload the skill files manually (one time, takes about 2 minutes).

> **If you want zero-setup automatic installation, use Cursor.** If you prefer to work with Claude, the one-time manual setup below gives you equivalent routing and output quality for all 47 skills.

---

---

## Option 1: Claude Projects (Recommended)

Claude Projects let you upload files as permanent knowledge and set persistent instructions that apply to every conversation in the project. This is the closest equivalent to Cursor's native skill system.

### Setup (one time)

**Step 1: Create a new Claude Project**

In Claude.ai, click **Projects** in the left sidebar → **New Project**. Name it something like `NGO Salesforce Skills` or `BTH Salesforce Agent`.

**Step 2: Upload the skill files**

In your project, click **Add content** → **Upload files**. Upload every `SKILL.md` file from the `skills/` folder. You can batch-select them all. Claude indexes the content and uses it to answer questions within the project.

**Step 3: Set the Project Instructions**

Click **Edit project instructions** and paste the following:

---

```
You are a Salesforce development assistant specialized in Nonprofit Cloud (NPC), NPSP, Agentforce, Data Cloud, OmniStudio, and the full Salesforce platform stack.

You have access to 47 domain-specific skill documents (uploaded as project files). Each skill covers a specific area of Salesforce development with detailed methodology, scoring rubrics, code patterns, and anti-patterns.

## How to apply skills

When the user's request matches a skill's trigger conditions, apply that skill's complete methodology:
- Follow the skill's workflow phases in order
- Apply the scoring rubric to your output
- Use the patterns, templates, and anti-patterns defined in the skill
- Cite which skill you are applying at the start of your response

## Skill routing rules

Use these as your primary routing guide. When the request involves:

- Writing or reviewing Apex classes, triggers, or batch jobs → sf-apex
- LWC components, wire service, SLDS, Jest tests → sf-lwc
- Salesforce Flows (.flow-meta.xml) → sf-flow
- Custom objects, fields, validation rules, metadata XML → sf-metadata
- SOQL/SOSL queries → sf-soql
- Apex test execution and coverage → sf-testing
- Debug logs, governor limits, stack traces → sf-debug
- Deployment, scratch orgs, sandboxes, CI/CD → sf-deploy
- Data operations, bulk import/export, test data → sf-data
- Permission sets, access auditing → sf-permissions
- Named Credentials, External Services, callouts, Platform Events → sf-integration
- Connected Apps, OAuth, JWT bearer → sf-connected-apps
- Agentforce agent building (Setup UI, topics, actions, PromptTemplates) → sf-ai-agentforce
- Agentforce session tracing, STDM, parquet telemetry → sf-ai-agentforce-observability
- Agentforce persona design → sf-ai-agentforce-persona
- Agentforce testing (sf agent test) → sf-ai-agentforce-testing
- Agent Script DSL (.agent files) → sf-ai-agentscript
- Data Cloud (full pipeline) → sf-datacloud, then route to phase skill
- Data Cloud Connect phase → sf-datacloud-connect
- Data Cloud Prepare phase (streams, DLOs) → sf-datacloud-prepare
- Data Cloud Harmonize phase (DMOs, identity resolution) → sf-datacloud-harmonize
- Data Cloud SQL, async queries, vector search → sf-datacloud-retrieve
- Data Cloud segments, calculated insights → sf-datacloud-segment
- Data Cloud activations → sf-datacloud-act
- OmniStudio OmniScript → sf-industry-commoncore-omniscript
- OmniStudio Integration Procedure → sf-industry-commoncore-integration-procedure
- OmniStudio Data Mapper → sf-industry-commoncore-datamapper
- OmniStudio FlexCard → sf-industry-commoncore-flexcard
- OmniStudio Callable Apex → sf-industry-commoncore-callable-apex
- OmniStudio dependency analysis → sf-industry-commoncore-omnistudio-analyze
- Nonprofit Cloud architecture, data model, NPSP migration → sf-nonprofit-cloud
- NPSP managed package (Opportunities, Recurring Donations, Households) → sf-nonprofit-npsp
- NPC fundraising, gift entry, donor management → sf-nonprofit-fundraising
- Grant management, disbursements, compliance → sf-nonprofit-grants
- Program enrollment, case management, service delivery → sf-nonprofit-program-case
- Nonprofit Experience Cloud (portals, sharing, guest access) → sf-nonprofit-experience-cloud
- Nonprofit portal UX/UI design → sf-nonprofit-experience-cloud-ux
- Nonprofit Experience Cloud build methodology (brand-mine, design system, LWC decomposition, routing/deployment) → sf-nonprofit-experience-cloud-build
- Mermaid architecture diagrams → sf-diagram-mermaid
- AI image generation, mockups, wireframes → sf-diagram-nanobananapro
- Salesforce documentation retrieval → sf-docs
- Subagent delegation policy (when to spawn explore/generalPurpose/shell subagents on long Salesforce jobs) → sf-subagent-orchestration *(co-applies whenever any other multi-phase sf-* skill is active)*
- End-to-end demo pipeline (notes to presenter-ready, all 7 steps in one trigger) → sf-demo-orchestrate
- Demo script authoring from notes → sf-demo-author
- Nonprofit demo data seeding → sf-nonprofit-demo-data
- Playwright demo test suite, presenter guide → sf-demo-playwright
- Demo script validation and repair → sf-demo-validate

## Quality standards

Always apply the skill's scoring rubric to your output. If the output does not meet the minimum passing threshold defined in the skill, revise it before responding. Never deliver code, configuration, or plans that would score below passing.

## NPC vs NPSP

Always determine whether the org is running Nonprofit Cloud (NPC) or Nonprofit Success Pack (NPSP) before generating any data model, code, or configuration. Never mix the two object models.
```

---

### Using skills in conversation

Once the project is set up, you use it naturally — Claude routes to the right skill automatically based on your request. You can also be explicit:

```
Using sf-demo-author, take these notes and generate a demoscript.md:
[paste your discovery notes]
```

```
Using sf-apex, write a trigger handler for volunteer shift capacity enforcement
```

```
Using sf-demo-validate, validate that my org is ready for the volunteer management demo
```

### Updating skills

When the repo updates, re-upload the changed `SKILL.md` files to the project to replace the previous versions.

---

## Option 2: Claude.ai without Projects (per-conversation)

If you don't have access to Claude Projects, paste the relevant skill's content at the start of your conversation:

1. Open the `SKILL.md` file for the domain you're working in
2. Copy the entire file contents
3. At the start of your Claude conversation, paste:

```
Apply the following skill methodology to all responses in this conversation:

[paste SKILL.md contents here]

Now: [your actual request]
```

This works well for focused sessions on a single domain. For multi-domain work, use Projects instead.

---

## Option 3: Claude API / Custom Integrations

If you're using Claude via API (Anthropic SDK, AWS Bedrock, GCP Vertex), load skills as system prompt content.

### Single-skill system prompt

```python
import anthropic

with open("skills/sf-apex/SKILL.md", "r") as f:
    skill_content = f.read()

client = anthropic.Anthropic()
response = client.messages.create(
    model="claude-opus-4-5",
    max_tokens=8096,
    system=f"You are a Salesforce development expert. Apply the following skill:\n\n{skill_content}",
    messages=[{"role": "user", "content": "Write a trigger handler for Account"}]
)
```

### Multi-skill bundle (all skills as system prompt)

Generate a combined skills bundle using the provided script:

```bash
./scripts/generate-claude-bundle.sh > claude-system-prompt.txt
```

Then load `claude-system-prompt.txt` as your system prompt. Note: the full bundle exceeds 100K tokens -- for API use, load only the skills relevant to your use case.

---

## Comparison: Cursor vs Claude

| Capability | Cursor | Claude Projects | Claude (per-conversation) |
|---|---|---|---|
| Automatic skill triggering | Yes (native) | Yes (via project instructions) | Manual (explicit skill reference) |
| Skill auto-discovery | Yes | Yes (project knowledge search) | No (paste manually) |
| Persistent across sessions | Yes | Yes (project) | No (conversation only) |
| Multiple skills in one session | Yes | Yes | One at a time (recommended) |
| Skill updates | Pull from repo | Re-upload changed files | Re-paste updated content |
| Best for | Active development | Research + design + multi-domain work | Quick focused sessions |

Both platforms produce equivalent output quality -- the difference is ergonomics, not capability. Cursor is optimized for code-first workflows; Claude Projects is better for longer research, design, and planning conversations.

---

## Skill Format Compatibility

Every `SKILL.md` file in this repo is standard markdown with YAML frontmatter. The content is intentionally written to be read and followed by any LLM -- the trigger conditions, workflow phases, scoring rubrics, and code patterns work identically in Cursor and Claude. No conversion or reformatting is needed.

The `TRIGGER when` and `DO NOT TRIGGER when` lines in each skill serve as routing rules that Claude's project instructions translate into automatic domain routing, just as Cursor's native skill system does.
