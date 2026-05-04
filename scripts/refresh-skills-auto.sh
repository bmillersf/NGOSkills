#!/usr/bin/env bash
# refresh-skills-auto.sh
#
# Layer 2 active: queue generator for subagent-driven SKILL.md refresh PRs.
#
# Flow:
#   1. Run refresh-skills.sh to produce refresh-report.md + drift list
#   2. For each drifted/stale skill, emit a subagent prompt block to
#      .claude/refresh-queue.md
#   3. Classify severity by diff size + section touched:
#        - trivial         (frontmatter only, ≤5 lines)
#        - additive        (body, ≤20 lines, no scoring/workflow touched)
#        - behavior-change (body, >20 lines OR anti-patterns touched)
#        - methodology-refused (scoring rubric / workflow phases / TRIGGER)
#   4. Parent Claude agent reads refresh-queue.md and spawns subagents to
#      propose edits per skill. No Anthropic SDK calls from this script.
#
# Usage:
#   ./scripts/refresh-skills-auto.sh
#   ./scripts/refresh-skills-auto.sh --stale-days 30
#
# Output:
#   .claude/refresh-queue.md (in repo root)

set -euo pipefail

REPO_ROOT="${HOME}/Cursor/Skills/NGOSkills"
QUEUE_DIR="${REPO_ROOT}/.claude"
QUEUE="${QUEUE_DIR}/refresh-queue.md"
REPORT="${REPO_ROOT}/refresh-report.md"
STALE_DAYS="${STALE_DAYS:-60}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stale-days) STALE_DAYS="$2"; shift 2 ;;
    -h|--help)    sed -n '2,25p' "$0"; exit 0 ;;
    *)            echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$QUEUE_DIR"

# Step 1: Always regenerate the drift report first.
echo "[refresh-skills-auto] Running refresh-skills.sh --stale-days ${STALE_DAYS}..."
"${REPO_ROOT}/scripts/refresh-skills.sh" --stale-days "$STALE_DAYS" || true

if [ ! -f "$REPORT" ]; then
  echo "ERROR: $REPORT not produced by refresh-skills.sh" >&2
  exit 1
fi

# Step 2: Extract stale/drifted skills from the report. Lines matching
# "🟧 stale" or "🟥 **missing metadata**" in the summary table.
# bash 3.2 (macOS default) has no mapfile; read into array portably.
DRIFTED=()
while IFS= read -r _line; do
  [ -n "$_line" ] && DRIFTED+=("$_line")
done < <(awk -F'|' '/🟧 stale|🟥/ {gsub(/^ +| +$/, "", $2); print $2}' "$REPORT")

# Step 3: Classify severity + emit queue entries.
classify_severity() {
  local skill_file="$1"
  # Very rough classifier — subagent gets the real diff, this just picks the label.
  # We don't have a stored-vs-current diff here (Layer 2 diff lives in refresh-report.md),
  # so we inspect: age_days (from report), refs_count, and whether the skill has a
  # scoring rubric section. This is a heuristic starting classification the subagent
  # will refine when it sees the actual content diff.
  local has_rubric
  has_rubric="$(grep -c '^## .*[Ss]coring [Rr]ubric' "$skill_file" || true)"
  if [ "$has_rubric" -gt 0 ]; then
    echo "methodology-refused"
  else
    echo "additive"   # default; subagent reclassifies as trivial / behavior-change
  fi
}

find_skill_file() {
  local name="$1"
  for base in "${REPO_ROOT}/skills" "${REPO_ROOT}/skills-cursor"; do
    if [ -f "${base}/${name}/SKILL.md" ]; then
      echo "${base}/${name}/SKILL.md"
      return 0
    fi
  done
  return 1
}

{
  echo "# Skill Refresh Queue"
  echo ""
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Source: \`refresh-report.md\` (stale threshold: ${STALE_DAYS}d)"
  echo ""
  echo "## How to consume this queue"
  echo ""
  echo "For each entry below, spawn a Claude Code subagent (one per skill, in parallel)"
  echo "with the **Subagent brief** block as the prompt. The parent agent collects the"
  echo "proposed diffs, opens a PR per skill on branch \`refresh/<skill>-$(date -u +%Y%m%d)\`,"
  echo "and labels it with the severity."
  echo ""
  echo "---"
  echo ""

  if [ ${#DRIFTED[@]} -eq 0 ]; then
    echo "_No drifted skills. Queue empty._"
  fi

  for skill in "${DRIFTED[@]}"; do
    [ -z "$skill" ] && continue
    skill_file="$(find_skill_file "$skill" || true)"
    if [ -z "$skill_file" ]; then
      echo "## ${skill}"
      echo ""
      echo "_Skipped: SKILL.md not found._"
      echo ""
      continue
    fi
    severity="$(classify_severity "$skill_file")"

    echo "## ${skill}  \`severity: ${severity}\`"
    echo ""
    echo "**File**: \`${skill_file#$REPO_ROOT/}\`"
    echo ""
    echo "**Subagent brief**:"
    echo ""
    echo "\`\`\`"
    echo "Goal: Propose SKILL.md edits for ${skill} based on upstream doc drift."
    echo ""
    echo "Inputs:"
    echo "  - Current SKILL.md: ${skill_file}"
    echo "  - Drift summary: ${REPORT}"
    echo "  - Upstream refs: parse from frontmatter upstream_refs array"
    echo ""
    echo "Constraints (in order of severity):"
    echo "  - trivial          → URL / sha256 / typo / new CLI flag only"
    echo "  - additive         → new feature / command; no scoring or workflow edits"
    echo "  - behavior-change  → API deprecation / default change; add 'requires-human-review' label"
    echo "  - methodology-refused → REFUSE to edit scoring rubric, workflow phases,"
    echo "                          TRIGGER/DO NOT TRIGGER clauses, or anti-patterns."
    echo "                          Only bump docs_last_verified."
    echo ""
    echo "Pre-classified severity: ${severity}"
    echo "  (Reclassify if actual diff warrants; never escalate past methodology-refused.)"
    echo ""
    echo "Return format:"
    echo "  1. Unified diff against current SKILL.md"
    echo "  2. One-paragraph rationale per change"
    echo "  3. Proposed PR title: 'refresh(${skill}): <1-line summary> (<severity>)'"
    echo "  4. Proposed PR labels: refresh, ${severity}"
    echo ""
    echo "Done criteria:"
    echo "  - docs_last_verified bumped to $(date +%Y-%m-%d)"
    echo "  - sha256 values in upstream_refs re-populated if refetched"
    echo "  - release_pinned unchanged unless explicitly a release bump"
    echo "  - No edits to scoring rubric / workflow phases / TRIGGER clauses / anti-patterns"
    echo "\`\`\`"
    echo ""
  done

  echo "## Next step"
  echo ""
  echo "Parent agent: read each brief above, spawn one subagent per skill in parallel,"
  echo "collect returned diffs, and open PRs via \`gh pr create\` on branch"
  echo "\`refresh/<skill>-$(date -u +%Y%m%d)\`. Do NOT auto-merge — label only."
  echo ""
} > "$QUEUE"

echo "[refresh-skills-auto] Queue written: $QUEUE"
echo "[refresh-skills-auto] Drifted skills queued: ${#DRIFTED[@]}"
exit 0
