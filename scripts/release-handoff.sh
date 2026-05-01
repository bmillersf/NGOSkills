#!/usr/bin/env bash
# release-handoff.sh
#
# Layer 4: Salesforce release-cut handoff. Runs manually ~6 weeks before GA
# when a new release notes TOC publishes.
#
# Flow:
#   1. Fetch the release notes TOC HTML
#   2. Extract <h2> / <h3> section headings (feature areas)
#   3. For each heading, extract keyword tokens
#   4. Cross-reference tokens against TRIGGER clauses in every SKILL.md
#   5. Emit prioritized review list: skill → matched release note sections
#
# Usage:
#   ./scripts/release-handoff.sh "Summer '26"
#   ./scripts/release-handoff.sh "Summer '26" --toc-url <override>
#
# Output:
#   release-handoff-<release-slug>.md in repo root

set -euo pipefail

REPO_ROOT="${HOME}/Cursor/Skills/NGOSkills"
RELEASE="${1:-}"
[ -z "$RELEASE" ] && { echo "Usage: $0 \"Summer '26\"" >&2; exit 2; }
shift || true

# Default TOC URL pattern; overridable via --toc-url.
# Assumption: Salesforce release notes TOC lives at
#   https://help.salesforce.com/s/articleView?id=release-notes.rn_summary.htm
# and is re-pointed to the latest release at publication time. The `rn_summary`
# slug is the stable entry point across releases (Spring/Summer/Winter).
TOC_URL="https://help.salesforce.com/s/articleView?id=release-notes.rn_summary.htm"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --toc-url) TOC_URL="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

slug="$(echo "$RELEASE" | tr "[:upper:] '" "[:lower:]--" | tr -d '[:punct:]' | tr -s '-')"
OUT="${REPO_ROOT}/release-handoff-${slug}.md"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "[release-handoff] Fetching TOC: $TOC_URL"
if command -v curl >/dev/null 2>&1; then
  curl -sSL --max-time 30 "$TOC_URL" -o "$tmp/toc.html" || true
fi

# Extract heading text. If fetch failed or JS-heavy, fall back to a stub set
# so the rest of the pipeline still produces a usable skeleton for the user.
if [ -s "$tmp/toc.html" ]; then
  # Rough h2/h3 extraction; covers both server-rendered and hybrid pages.
  grep -oE '<h[23][^>]*>[^<]+</h[23]>' "$tmp/toc.html" \
    | sed -E 's/<[^>]+>//g' \
    | awk 'NF' \
    | sort -u > "$tmp/headings.txt"
else
  printf '%s\n' \
    "Sales Cloud" "Service Cloud" "Marketing Cloud" "Data Cloud" \
    "Agentforce" "Industries" "Platform" "Analytics" "Security and Identity" \
    "Experience Cloud" "Mobile" > "$tmp/headings.txt"
  echo "[release-handoff] Warning: TOC fetch empty; using stub heading set" >&2
fi

# For each heading, emit keywords (lowercased words, drop stopwords).
stop='the|and|for|with|in|on|to|a|of|by'
awk -v stop="$stop" '
  {
    line=tolower($0)
    n=split(line, w, /[^a-z0-9]+/)
    for (i=1;i<=n;i++) if (length(w[i])>2 && w[i] !~ "^("stop")$") print w[i] "\t" $0
  }
' "$tmp/headings.txt" | sort -u > "$tmp/kw.tsv"

# Walk every SKILL.md, extract TRIGGER clause text, match against keywords.
: > "$tmp/matches.tsv"
while IFS= read -r skill_md; do
  name="$(basename "$(dirname "$skill_md")")"
  trigger="$(awk '
    /^---$/{fm=!fm; next}
    fm && /TRIGGER when:/ {collect=1}
    fm && collect { print; if (/DO NOT TRIGGER/) collect=0 }
  ' "$skill_md" | tr '[:upper:]' '[:lower:]')"
  [ -z "$trigger" ] && continue
  while IFS=$'\t' read -r kw heading; do
    if echo "$trigger" | grep -q -F -- "$kw"; then
      echo -e "${name}\t${heading}\t${kw}" >> "$tmp/matches.tsv"
    fi
  done < "$tmp/kw.tsv"
done < <(find "${REPO_ROOT}/skills" "${REPO_ROOT}/skills-cursor" \
           -maxdepth 2 -name SKILL.md 2>/dev/null)

# Build the output report.
{
  echo "# Release Handoff: ${RELEASE}"
  echo ""
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "TOC source: ${TOC_URL}"
  echo ""
  echo "## Prioritised review list"
  echo ""
  echo "| Skill | Matched release note sections | Match count |"
  echo "|---|---|---|"
  if [ -s "$tmp/matches.tsv" ]; then
    awk -F'\t' '
      { secs[$1]=secs[$1] $2 " ¦ "; count[$1]++ }
      END {
        for (s in count) printf "%s\t%s\t%d\n", s, secs[s], count[s]
      }
    ' "$tmp/matches.tsv" \
      | sort -t$'\t' -k3,3 -nr \
      | awk -F'\t' '{gsub(/ ¦ $/, "", $2); printf "| %s | %s | %d |\n", $1, $2, $3}'
  else
    echo "| _no matches_ | _check TOC fetch + keyword extraction_ | 0 |"
  fi
  echo ""
  echo "## Next step"
  echo ""
  echo "For each skill above, run:"
  echo ""
  echo "    ./scripts/refresh-skills-auto.sh <skill-name>"
  echo ""
  echo "Then review the generated PR and bump \`release_pinned\` to \`${RELEASE}\` once verified."
} > "$OUT"

echo "[release-handoff] Report: $OUT"
exit 0
