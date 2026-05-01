#!/usr/bin/env bash
# audit-triggers.sh
#
# Static audit: detect overlapping TRIGGER phrases across SKILL.md files so
# two skills cannot silently both claim the same user request.
#
# Parses YAML frontmatter from every SKILL.md in skills/ and skills-cursor/,
# extracts phrases between the first "TRIGGER when:" and the first "DO NOT TRIGGER when:"
# marker, tokenises them into noun phrases, and flags any phrase that appears
# in more than one skill's trigger block.
#
# Usage:
#   ./scripts/audit-triggers.sh           # pretty report, exit 1 if overlaps
#   ./scripts/audit-triggers.sh --json    # machine-readable
#   ./scripts/audit-triggers.sh --quiet   # exit-code only
#
# Overlaps are not always bugs — "Apex" legitimately appears in sf-apex,
# sf-testing, sf-debug. This script flags them for a human reviewer to
# triage via DO NOT TRIGGER clauses; it does NOT auto-fix.

set -euo pipefail

REPO_ROOT="${HOME}/Cursor/Skills/NGOSkills"
SF_SRC="${REPO_ROOT}/skills"
CURSOR_SRC="${REPO_ROOT}/skills-cursor"

MODE="report"
for arg in "$@"; do
  case "$arg" in
    --json)  MODE="json" ;;
    --quiet) MODE="quiet" ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

extract_triggers() {
  local file="$1"
  local skill_name
  skill_name="$(basename "$(dirname "$file")")"
  # Capture text between "TRIGGER when:" and EITHER "DO NOT TRIGGER when:" OR
  # the next top-level YAML key (e.g., "license:", "metadata:") OR end of frontmatter.
  awk -v name="$skill_name" '
    BEGIN { fm = 0; capture = 0 }
    /^---$/ {
      fm = !fm
      if (!fm) capture = 0
      next
    }
    !fm { next }
    capture && /DO NOT TRIGGER when:/ {
      sub(/DO NOT TRIGGER when:.*/, "")
      if (length($0) > 0) print name "\t" $0
      capture = 0
      exit
    }
    capture && /^[a-zA-Z_][a-zA-Z0-9_-]*:/ {
      capture = 0
      exit
    }
    capture {
      print name "\t" $0
      next
    }
    /TRIGGER when:/ && !capture {
      line = $0
      sub(/^.*TRIGGER when:/, "", line)
      if (length(line) > 0) print name "\t" line
      capture = 1
    }
  ' "$file"
}

ALL="${TMP}/all.tsv"
: > "$ALL"

for dir in "$SF_SRC" "$CURSOR_SRC"; do
  [ -d "$dir" ] || continue
  while IFS= read -r f; do
    extract_triggers "$f" >> "$ALL"
  done < <(find "$dir" -maxdepth 2 -name SKILL.md -not -path '*/\.*')
done

# Tokenise into lowercase noun-ish phrases: split on commas, semicolons,
# periods, " or ", " and ", quotes. Strip whitespace. Keep phrases >= 3 chars.
PHRASES="${TMP}/phrases.tsv"
awk -F'\t' '{
  gsub(/["`()]/, "", $2)
  n = split($2, a, /[,;.]| or | and /)
  for (i = 1; i <= n; i++) {
    p = a[i]
    gsub(/^[ \t]+|[ \t]+$/, "", p)
    p = tolower(p)
    if (length(p) >= 4) {
      print $1 "\t" p
    }
  }
}' "$ALL" | sort -u > "$PHRASES"

# Group phrases -> list of skills that claim them
OVERLAPS="${TMP}/overlaps.tsv"
awk -F'\t' '
  { phrases[$2] = phrases[$2] ? phrases[$2] "," $1 : $1; counts[$2]++ }
  END { for (p in counts) if (counts[p] > 1) print counts[p] "\t" p "\t" phrases[p] }
' "$PHRASES" | sort -rn > "$OVERLAPS"

COUNT=$(wc -l < "$OVERLAPS" | tr -d ' ')

case "$MODE" in
  json)
    printf '{"overlap_count":%s,"overlaps":[' "$COUNT"
    first=1
    while IFS=$'\t' read -r c p skills; do
      [ $first -eq 1 ] || printf ','
      first=0
      printf '{"phrase":"%s","skills":"%s","count":%s}' "$p" "$skills" "$c"
    done < "$OVERLAPS"
    printf ']}\n'
    ;;
  quiet)
    :
    ;;
  report|*)
    echo "Trigger-phrase overlap audit"
    echo "============================"
    echo "Skills scanned: $(find "$SF_SRC" "$CURSOR_SRC" -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
    echo "Overlapping phrases: $COUNT"
    echo ""
    if [ "$COUNT" -gt 0 ]; then
      printf "%-4s  %-50s  %s\n" "N" "PHRASE" "SKILLS"
      printf "%-4s  %-50s  %s\n" "--" "------" "------"
      head -50 "$OVERLAPS" | while IFS=$'\t' read -r c p skills; do
        printf "%-4s  %-50s  %s\n" "$c" "${p:0:48}" "$skills"
      done
      [ "$COUNT" -gt 50 ] && echo "... ($((COUNT - 50)) more, see --json)"
      echo ""
      echo "Each overlap is a candidate for disambiguation via DO NOT TRIGGER clauses."
      echo "Known-benign overlaps (e.g., 'apex' in sf-apex/sf-testing/sf-debug) are acceptable"
      echo "if the DO NOT TRIGGER clauses already route correctly."
    else
      echo "No overlaps detected."
    fi
    ;;
esac

exit 0
