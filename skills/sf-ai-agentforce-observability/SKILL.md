---
name: sf-ai-agentforce-observability
description: >
  Agentforce session tracing extraction and analysis.
  TRIGGER when: user extracts STDM data from Data Cloud, analyzes agent session
  traces, debugs agent conversations via telemetry, or works with .parquet files
  from Agentforce; or asks "why did my agent do that", says "agent is acting weird",
  "trace this agent session", "debug agent conversation".
  DO NOT TRIGGER when: testing agents (use sf-ai-agentforce-testing), Apex debug
  logs (use sf-debug), or building agents (use sf-ai-agentforce).
license: MIT
compatibility: "Requires Data 360 enabled org with Agentforce Session Tracing"
metadata:
  version: "1.0.0"
  author: "Jag Valaiyapathy"
  data_model: "Session Tracing Data Model (STDM)"
  storage_format: "Parquet (via PyArrow)"
  analysis_library: "Polars"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.agent_metrics_intro.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/data/data-cloud-query/guide/dc-agent-data-model.html
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/data-cloud
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_datacloud.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "100-pt rubric (4 categories: STDM Query Correctness 30 / Auth + Storage Hygiene 25 / Analysis + Debug Quality 25 / Cost + Volume Discipline 20) — newly authored 2026-05-22 to fill the harness coverage gap. Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  observability_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 16
      description: "STDM query correctness. Maps to STDM Query Correctness (30). The Session Tracing Data Model is the foundation; wrong DMO / wrong join / CRM-SOQL syntax in a Data Cloud SQL context produces empty or misleading results."
      automatic_hard_fail_rules:
        - "CRM SOQL syntax used in a Data Cloud SQL context (different planes; SOQL doesn't run against STDM DMOs)"
        - "STDM DMO referenced that doesn't exist in the version installed on the org (e.g., older SSDM version missing newer-Spring DMOs)"
        - "Salesforce Standard Data Model below v1.124 used (session tracing DMOs require ≥v1.124 — silent empty result)"
        - "DMO suffix wrong (__dlm vs __dll vs no suffix — wrong table referenced)"
        - "Session timeline reconstruction missing required event ordering (event_timestamp + sequence_number — events render out of order)"
    - name: Robustness
      max: 25
      hard_fail_below: 16
      description: "Auth + storage hygiene. Maps to Auth + Storage Hygiene (25). Heavy floor — observability data includes prompt content + tool inputs + customer queries; weak auth or unencrypted-at-rest Parquet leaks regulated data."
      automatic_hard_fail_rules:
        - "JWT bearer credentials (private key, consumer key) inlined in extraction script or env var instead of using sf-connected-apps Named Credential pattern"
        - "Extracted Parquet written to a location not gitignored (telemetry leak via repo)"
        - "PII / customer query content written to Parquet without classification / retention policy"
        - "Connected App used for STDM extraction without least-privilege OAuth scope (Full instead of Api+RefreshToken)"
        - "JWT certificate expiration not tracked (extraction silently breaks at cert rotation)"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Analysis + debug quality. Maps to Analysis + Debug Quality (25). Polars over Pandas (memory-efficient lazy eval); session timeline + execution-lifecycle phases mapped correctly; debug output cites specific event IDs."
      automatic_hard_fail_rules:
        - "Pandas used for >100k-row analysis when Polars lazy-eval is the documented pattern (memory blowout)"
        - "Session timeline rendered without mapping to the 6-phase agent execution lifecycle (raw event dump — caller can't see which phase failed)"
        - "Debug claim made without citing the specific event_id / session_id / trace_id (unverifiable conclusion)"
        - "Tool-call analysis missing tool input + output content (caller can't see what the agent actually saw / decided on)"
        - "Polars eager .collect() on a multi-million-row LazyFrame (defeats lazy-eval — same memory blowout as Pandas)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Cost + volume discipline. Maps to Cost + Volume Discipline (20). High-volume extractions (1-10M records/day) must be chunked + cost-aware; Data Cloud Query credits consumed per call."
      automatic_hard_fail_rules:
        - "Multi-million-row extraction in a single sync query without async query workflow"
        - "Date filter / partition pruning absent on a large STDM extraction (cost amplifier)"
        - "Re-extracting the same window repeatedly without caching the Parquet (credit waste)"
        - "Extraction cadence (e.g., every 5 min) not aligned with billing-cycle / credit-pool (over-burn)"
        - "Large query result paginated client-side instead of using the Data Cloud paginated query API"
---

<!-- TIER: 1 | ENTRY POINT -->
<!-- This is the starting document - read this FIRST -->
<!-- Pattern: Follows sf-data for Python extraction scripts -->

# sf-ai-agentforce-observability: Agentforce Session Tracing Extraction & Analysis

Expert in extracting and analyzing Agentforce session tracing data from Salesforce Data 360. Supports high-volume data extraction (1-10M records/day), Parquet storage, and Polars-based analysis for debugging agent behavior.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 100-pt rubric across 4 STDM-extraction + analysis categories, newly authored 2026-05-22 to fill the harness coverage gap. Two heavy floors: Correctness 16 (wrong DMO / wrong join / SSDM-version-too-old produces empty or misleading results) and Robustness 16 (telemetry data includes prompt content + tool inputs + customer queries; weak auth or unencrypted Parquet leaks regulated data). Hard-fail rules block CRM SOQL in Data Cloud SQL context, SSDM <v1.124, JWT credentials inlined, Parquet not gitignored, Pandas on >100k rows when Polars is the pattern, debug claims without event_id citation, multi-million-row sync queries (must be async), and missing date-filter / partition pruning. Disable with `eval_harness.enabled: false`.

## Core Responsibilities

1. **Session Extraction**: Extract STDM (Session Tracing Data Model) data via Data 360 Query API
2. **Data Storage**: Write to Parquet format with PyArrow for efficient storage
3. **Analysis**: Polars-based lazy evaluation for memory-efficient analysis
4. **Debugging**: Session timeline reconstruction for troubleshooting agent issues
5. **Cross-Skill Integration**: Works with sf-connected-apps for auth, sf-ai-agentscript for fixes

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Quick start** | [README.md](README.md) | Installation & basic usage |
| **Data model** | [references/data-model-reference.md](references/data-model-reference.md) | Full STDM schema documentation |
| **Query patterns** | [references/query-patterns.md](references/query-patterns.md) | Data Cloud SQL examples |
| **Analysis recipes** | [references/analysis-cookbook.md](references/analysis-cookbook.md) | Common Polars patterns |
| **CLI reference** | [references/cli-reference.md](references/cli-reference.md) | Complete command documentation |
| **Auth setup** | [references/auth-setup.md](references/auth-setup.md) | JWT Bearer configuration |
| **Troubleshooting** | [references/troubleshooting.md](references/troubleshooting.md) | Common issues & fixes |
| **Analysis examples** | [references/analysis-examples.md](references/analysis-examples.md) | Session summary & debug timeline output |
| **Billing & issues** | [references/billing-and-troubleshooting.md](references/billing-and-troubleshooting.md) | Credit consumption & common errors |
| **Builder trace API** | [references/builder-trace-api.md](references/builder-trace-api.md) | Internal trace endpoint investigation & capture tooling |
| **Execution lifecycle** | [references/agent-execution-lifecycle.md](references/agent-execution-lifecycle.md) | 6-phase model, script-to-trace mapping, timing analysis |

---

## CRITICAL: Prerequisites Checklist

Before extracting session data, verify:

| Check | How to Verify | Why |
|-------|---------------|-----|
| **Data 360 enabled** | Setup → Data 360 | Required for Query API |
| **Salesforce Standard Data Model v1.124+** | Setup → Apps → Packaging → Installed Packages | Required for session tracing DMOs |
| **Einstein Generative AI enabled** | Setup → Einstein Generative AI | Enables agent capabilities |
| **Session Tracing enabled** | Setup → Einstein Audit, Analytics, and Monitoring | Must toggle ON to collect data |
| **JWT Auth configured** | Use `sf-connected-apps` | Required for Data 360 API |

> **Official Setup Guide**: [Set Up Agentforce Session Tracing](https://help.salesforce.com/s/articleView?id=ai.generative_ai_session_trace_setup.htm)

### Auth Setup (via sf-connected-apps)

```bash
# 1. Create key directory
mkdir -p ~/.sf/jwt

# 2. Generate certificate (naming convention: {org}-agentforce-observability)
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
  -keyout ~/.sf/jwt/myorg-agentforce-observability.key \
  -out ~/.sf/jwt/myorg-agentforce-observability.crt \
  -subj "/CN=AgentforceObservability/O=MyOrg"

# 3. Secure the private key
chmod 600 ~/.sf/jwt/myorg-agentforce-observability.key

# 4. Create External Client App in Salesforce (see references/auth-setup.md)
# Required scopes: cdp_query_api, refresh_token/offline_access
```

**Key Path Resolution Order:**
1. Explicit `--key-path` argument
2. App-specific: `~/.sf/jwt/{org}-agentforce-observability.key`
3. Generic fallback: `~/.sf/jwt/{org}.key`

See [references/auth-setup.md](references/auth-setup.md) for detailed instructions.

---

## T6 Live API Discovery Summary

**Validated: January 30, 2026** | **24 DMOs Found** | **260+ Test Points**

| Category | DMOs | Status |
|----------|------|--------|
| **Session Tracing** | 5 | All Found (Session, Interaction, Step, Message, Participant) |
| **Agent Optimizer** | 6 | All Found (Moment, Tag system) |
| **GenAI Audit** | 13 | All Found (Generation, Quality, Feedback, Gateway) |
| **RAG Quality** | 3 | Not Found (GenAIRetriever* DMOs don't exist) |

**Key Discoveries:**
- Field naming is bifurcated: DMO/table names use uppercase `AIAgent` (e.g. `AIAgentSession__dlm`), while field names use lowercase `AiAgent` (e.g. `AiAgentSessionId__c`). Don't rename one to match the other — both are correct in their own scope.
- Agent name location: Stored on `Moment`, not `Session`
- Channel types: `E & O`, `Builder`, `SCRT2 - EmbeddedMessaging`, `Voice`, `NGC`
- Participant roles: `USER`, `AGENT` (not Owner/Observer)

---

## Session Tracing Data Model (STDM)

> See [references/data-model-reference.md](references/data-model-reference.md) for the complete field-level schema of all 5 core DMOs + 13 GenAI Audit DMOs.

**5 Core DMOs** — all field names use `AiAgent` prefix (lowercase 'i'):

| DMO | Key | Relationship | Primary Fields |
|-----|-----|-------------|----------------|
| `AIAgentSession__dlm` | `Id__c` | Root | StartTimestamp, EndTimestamp, ChannelType, EndType |
| `AIAgentInteraction__dlm` | `Id__c` | Session → N Turns | TopicApiName, InteractionType, TraceId |
| `AIAgentInteractionStep__dlm` | `Id__c` | Turn → N Steps | StepType (LLM/ACTION), InputValue, OutputValue, Error |
| `AIAgentMoment__dlm` | `Id__c` | Session (NOT Turn) | **AgentApiName lives here**, RequestSummary, ResponseSummary |
| `AIAgentMessage__dlm` | `Id__c` | Turn → Messages | Content, Role, Timestamp |

**13 GenAI Trust Layer DMOs** — detectors for toxicity, PII, prompt defense, instruction adherence:

| DMO | Purpose | Key Fields |
|-----|---------|------------|
| `GenAIGatewayRequest__dlm` | LLM request details | model, provider, tokens, safety flags |
| `GenAIGeneration__dlm` | LLM output | responseText, links to Steps via GenerationId |
| `GenAIContentQuality__dlm` | Trust Layer assessment | isToxicityDetected |
| `GenAIContentCategory__dlm` | Detector results | detectorType, category, confidence value |
| `GenAIFeedback__dlm` | User feedback | GOOD/BAD + detail comments |

---

## Workflow (5-Phase Pattern)

### Phase 1: Requirements Gathering

**Ask the user** to gather:

| # | Question | Options |
|---|----------|---------|
| 1 | Target org | Org alias from `sf org list` |
| 2 | Time range | Last N days / Date range |
| 3 | Agent filter | All agents / Specific API names |
| 4 | Output format | Parquet (default) / CSV |
| 5 | Analysis type | Summary / Debug session / Full extraction |

### Phase 2: Auth Configuration

Verify JWT auth is configured:

```python
from scripts.auth import Data360Auth

auth = Data360Auth(
    org_alias="myorg",
    consumer_key="YOUR_CONSUMER_KEY"
)

# Test authentication
token = auth.get_token()
print(f"Auth successful: {token[:20]}...")
```

If auth fails, use the **sf-connected-apps** skill: "Setup JWT Bearer for Data 360"

### Phase 3: Extraction

**Basic Extraction (last 7 days):**
```bash
python3 scripts/cli.py extract \
  --org prod \
  --days 7 \
  --output ./stdm_data
```

**Filtered Extraction:**
```bash
python3 scripts/cli.py extract \
  --org prod \
  --since 2026-01-01 \
  --until 2026-01-28 \
  --agent Customer_Support_Agent \
  --output ./stdm_data
```

**Session Tree (specific session):**
```bash
python3 scripts/cli.py extract-tree \
  --org prod \
  --session-id "a0x..." \
  --output ./debug_session
```

### Phase 4: Analysis

**Session Summary:**
```python
from scripts.analyzer import STDMAnalyzer
from pathlib import Path

analyzer = STDMAnalyzer(Path("./stdm_data"))

# High-level summary
summary = analyzer.session_summary()
print(summary)

# Step distribution by agent
steps = analyzer.step_distribution(agent_name="Customer_Support_Agent")
print(steps)

# Topic routing analysis
topics = analyzer.topic_analysis()
print(topics)
```

**Debug Specific Session:**
```bash
python3 scripts/cli.py debug-session \
  --data-dir ./stdm_data \
  --session-id "a0x..."
```

### Phase 5: Integration & Next Steps

Based on analysis findings:

| Finding | Next Step | Skill |
|---------|-----------|-------|
| Topic mismatch | Improve topic descriptions | `sf-ai-agentscript` |
| Action failures | Debug Flow/Apex | `sf-flow`, `sf-debug` |
| Slow responses | Optimize actions | `sf-apex` |
| Missing coverage | Add test cases | `sf-ai-agentforce-testing` |

---

## CLI Quick Reference

### Extraction Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `extract` | Extract session data | `extract --org prod --days 7` |
| `extract-tree` | Extract full session tree | `extract-tree --org prod --session-id "a0x..."` |
| `extract-incremental` | Resume from last run | `extract-incremental --org prod` |

### Analysis Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `analyze` | Generate summary stats | `analyze --data-dir ./stdm_data` |
| `debug-session` | Timeline view | `debug-session --session-id "a0x..."` |
| `topics` | Topic analysis | `topics --data-dir ./stdm_data` |

### Common Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--org` | Target org alias | Required |
| `--consumer-key` | ECA consumer key | `$SF_CONSUMER_KEY` env var |
| `--key-path` | JWT private key path | `~/.sf/jwt/{org}-agentforce-observability.key` |
| `--days` | Last N days | 7 |
| `--since` / `--until` | Date range (YYYY-MM-DD) | - / Today |
| `--agent` | Filter by agent API name | All |
| `--output` | Output directory | `./stdm_data` |
| `--verbose` | Detailed logging | False |

See [references/cli-reference.md](references/cli-reference.md) for complete documentation.

---

## Analysis Examples

> See [references/analysis-examples.md](references/analysis-examples.md) for full session summary and debug timeline output examples.

**Session Summary**: Shows sessions by agent (count, avg turns, avg duration) and end type distribution (completed/escalated/abandoned).

**Debug Timeline**: Reconstructs a session step-by-step — input → topic routing → LLM steps → action steps → output — with timestamps and I/O payloads.

---

## Cross-Skill Integration

| Skill | When | How to Invoke |
|-------|------|---------------|
| `sf-connected-apps` | Auth setup | Use the **sf-connected-apps** skill: "JWT Bearer for Data Cloud" |
| `sf-ai-agentscript` | Fix topic routing issues | Use the **sf-ai-agentscript** skill: "Fix topic: [issue]" |
| `sf-flow` / `sf-debug` | Debug action failures | Use the **sf-debug** skill: "Analyze agent action failure" |
| `sf-ai-agentforce-testing` | Create test cases from patterns | Use the **sf-ai-agentforce-testing** skill: "Add test cases" |
| `sf-ai-agentforce-testing` | Real-time agent trace analysis | Use **sf-ai-agentforce-testing** Phase F: trace-enriched preview testing |

---

## Key Insights

| Insight | Description | Action |
|---------|-------------|--------|
| **STDM is read-only** | Data 360 stores traces; cannot modify | Use for analysis only |
| **Session lag** | Data may lag 5-15 minutes | Don't expect real-time |
| **Volume limits** | Query API: 10M records/day | Use incremental extraction |
| **Parquet efficiency** | 10x smaller than JSON | Always use Parquet for storage |
| **Lazy evaluation** | Polars scans without loading | Handles 100M+ rows |
| **~24 records per LLM call** | Each round-trip generates ~24 records | Factor into volume estimates |

---

## Billing & Common Issues

> See [references/billing-and-troubleshooting.md](references/billing-and-troubleshooting.md) for credit consumption details and error resolution.

**Quick reference**: Session Tracing consumes Data 360 credits. ~24 records per LLM round-trip. 1,000 sessions/day × 4 turns × 24 = ~96K records/day. Use [Digital Wallet](https://help.salesforce.com/s/articleView?id=sf.digital_wallet.htm) for consumption tracking.

| Error | Quick Fix |
|-------|-----------|
| `401 Unauthorized` | Refresh token or reconfigure ECA |
| `No session data` | Enable Session Tracing in Agent Settings |
| `Query timeout` | Add date filters, use incremental |
| `Memory error` | Use Polars lazy frames |

---

## Output Directory Structure

```
stdm_data/
├── sessions/          # date=YYYY-MM-DD/part-0000.parquet
├── interactions/      # date=YYYY-MM-DD/part-0000.parquet
├── steps/             # date=YYYY-MM-DD/part-0000.parquet
├── messages/          # date=YYYY-MM-DD/part-0000.parquet
└── metadata/          # extraction.json + watermark.json (incremental)
```

---

## Dependencies

**Python 3.10+**: `polars>=1.0`, `pyarrow>=15.0`, `pyjwt>=2.8`, `cryptography>=42.0`, `httpx>=0.27`, `rich>=13.0`, `click>=8.1`, `pydantic>=2.6`

Install: `pip install -r requirements.txt`
