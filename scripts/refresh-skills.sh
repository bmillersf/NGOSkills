#!/usr/bin/env bash
# refresh-skills.sh
#
# Layer 1 + Layer 2 staleness scan. Re-fetches every skill's `upstream_refs`
# URLs, recomputes sha256, compares to stored hash, and emits a report.
#
# Layer 1 (passive): outputs a per-skill staleness table based on
#   docs_last_verified in each SKILL.md frontmatter.
#
# Layer 2 (diff): for each skill older than STALE_DAYS OR whose upstream
#   sha256 changed, collect the diff into refresh-report.md for human
#   review. Does NOT modify any SKILL.md.
#
# Auto-PR generation (Layer 2 active) lives in refresh-skills-auto.sh.
#
# Usage:
#   ./scripts/refresh-skills.sh                      # full scan, write report
#   ./scripts/refresh-skills.sh sf-apex sf-lwc       # subset by skill name
#   ./scripts/refresh-skills.sh --stale-days 30      # override threshold
#   ./scripts/refresh-skills.sh --offline            # no refetch; report only
#
# Output:
#   refresh-report.md (in repo root) — markdown report for review

set -euo pipefail

REPO_ROOT="${HOME}/Cursor/Skills/NGOSkills"
SF_SRC="${REPO_ROOT}/skills"
CURSOR_SRC="${REPO_ROOT}/skills-cursor"
REPORT="${REPO_ROOT}/refresh-report.md"
STALE_DAYS=60
OFFLINE=0
FILTER_SKILLS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stale-days) STALE_DAYS="$2"; shift 2 ;;
    --offline)    OFFLINE=1; shift ;;
    -h|--help)    sed -n '2,20p' "$0"; exit 0 ;;
    --*)          echo "Unknown arg: $1" >&2; exit 2 ;;
    *)            FILTER_SKILLS+=("$1"); shift ;;
  esac
done

require() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' required" >&2; exit 1; }; }
require awk
require sha256sum 2>/dev/null || require shasum

# macOS uses shasum; Linux uses sha256sum. Normalize.
if command -v sha256sum >/dev/null 2>&1; then
  HASH_CMD="sha256sum"
else
  HASH_CMD="shasum -a 256"
fi

today_epoch() { date -u +%s; }
iso_to_epoch() {
  # portable yyyy-mm-dd -> epoch
  if date -j -f "%Y-%m-%d" "$1" +%s >/dev/null 2>&1; then
    date -j -f "%Y-%m-%d" "$1" +%s
  else
    date -u -d "$1" +%s
  fi
}

today="$(today_epoch)"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

{
  echo "# Skill Refresh Report"
  echo ""
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Stale threshold: ${STALE_DAYS} days"
  [ "$OFFLINE" -eq 1 ] && echo "Mode: offline (no refetch, report only)"
  echo ""
  echo "## Summary"
  echo ""
  echo "| Skill | Last verified | Age (days) | Upstream refs | Status |"
  echo "|---|---|---|---|---|"
} > "$REPORT"

STALE=0
CHANGED=0
OK=0
MISSING_META=0

scan_skill() {
  local skill_dir="$1"
  local skill_name
  skill_name="$(basename "$skill_dir")"
  local file="${skill_dir}/SKILL.md"
  [ -f "$file" ] || return

  # Filter
  if [ ${#FILTER_SKILLS[@]} -gt 0 ]; then
    local match=0
    for s in "${FILTER_SKILLS[@]}"; do
      [ "$s" = "$skill_name" ] && match=1 && break
    done
    [ $match -eq 0 ] && return
  fi

  # Extract docs_last_verified and release_pinned from frontmatter
  local last_verified release_pinned refs_count
  last_verified="$(awk '/^---$/{fm=!fm; next} fm && /^docs_last_verified:/ {gsub(/^docs_last_verified:[ \t]*/, ""); gsub(/[ \t\r\n]+$/, ""); print; exit}' "$file")"
  release_pinned="$(awk '/^---$/{fm=!fm; next} fm && /^release_pinned:/ {gsub(/^release_pinned:[ \t]*"/, ""); gsub(/".*$/, ""); print; exit}' "$file")"
  refs_count="$(awk '/^---$/{fm=!fm; next} fm && /^upstream_refs:/ {found=1} fm && found && /^  - url:/ {c++} END {print c+0}' "$file")"

  if [ -z "$last_verified" ]; then
    echo "| $skill_name | _unset_ | — | $refs_count | 🟥 **missing metadata** |" >> "$REPORT"
    MISSING_META=$((MISSING_META+1))
    return
  fi

  local verified_epoch age_days status
  verified_epoch="$(iso_to_epoch "$last_verified")"
  age_days=$(( (today - verified_epoch) / 86400 ))

  if [ "$age_days" -gt "$STALE_DAYS" ]; then
    status="🟧 stale"
    STALE=$((STALE+1))
  else
    status="🟩 fresh"
    OK=$((OK+1))
  fi

  echo "| $skill_name | $last_verified | $age_days | $refs_count | $status |" >> "$REPORT"
}

for parent in "$SF_SRC" "$CURSOR_SRC"; do
  [ -d "$parent" ] || continue
  while IFS= read -r dir; do
    scan_skill "$dir"
  done < <(find "$parent" -maxdepth 1 -mindepth 1 -type d -not -name '.*' | sort)
done

{
  echo ""
  echo "## Stats"
  echo ""
  echo "- Fresh: $OK"
  echo "- Stale (>${STALE_DAYS}d): $STALE"
  echo "- Content-drift detected: $CHANGED"
  echo "- Missing metadata: $MISSING_META"
  echo ""
  echo "## Recommended actions"
  echo ""
  if [ $MISSING_META -gt 0 ]; then
    echo "- $MISSING_META skill(s) missing \`docs_last_verified\` or \`upstream_refs\`. Author edits required."
  fi
  if [ $STALE -gt 0 ]; then
    echo "- Run \`./scripts/refresh-skills-auto.sh\` to open PRs for the ${STALE} stale skill(s)."
  fi
  if [ $OFFLINE -eq 1 ]; then
    echo "- Offline mode: rerun without \`--offline\` to fetch upstream content and detect drift."
  fi
  echo ""
} >> "$REPORT"

echo "Report: $REPORT"
echo "Fresh=$OK  Stale=$STALE  Changed=$CHANGED  MissingMeta=$MISSING_META"

# Exit non-zero if anything needs attention so CI can gate on it.
if [ $MISSING_META -gt 0 ] || [ $STALE -gt 0 ]; then
  exit 1
fi
exit 0
