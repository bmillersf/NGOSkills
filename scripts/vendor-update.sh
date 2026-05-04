#!/usr/bin/env bash
# vendor-update.sh
#
# Shows what's upstream for each vendor, and --apply rewrites vendor-pins.txt
# to the current upstream tip (or a specific ref). Apply does NOT commit — it
# leaves a dirty working tree so you can review the one-line pin diff and open
# a PR.
#
# Usage:
#   scripts/vendor-update.sh                     # dry-run, show pending diffs for all
#   scripts/vendor-update.sh <slug>              # dry-run for one
#   scripts/vendor-update.sh <slug> --apply      # bump pin to origin/HEAD (default branch)
#   scripts/vendor-update.sh <slug> --apply --ref v1.2.3   # bump pin to a specific tag/SHA
#
# After --apply:
#   1. git diff vendor-pins.txt     → review the new SHA
#   2. scripts/vendor-install.sh    → materialize the new tree
#   3. Read diff of changed skill/agent/command markdown (script prints commands)
#   4. scripts/sync-skills.sh --fix → re-link anything new
#   5. git commit vendor-pins.txt   → PR for team review

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PIN_FILE="${REPO_ROOT}/vendor-pins.txt"
VENDOR_DIR="${REPO_ROOT}/.vendor"

APPLY=0
ONLY_SLUG=""
TARGET_REF=""

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --ref)   TARGET_REF="${2:-}"; shift ;;
    -h|--help) sed -n '2,21p' "$0"; exit 0 ;;
    --*) echo "Unknown flag: $1" >&2; exit 2 ;;
    *)
      [ -z "$ONLY_SLUG" ] || { echo "Only one slug allowed" >&2; exit 2; }
      ONLY_SLUG="$1"
      ;;
  esac
  shift
done

[ -f "$PIN_FILE" ] || { echo "ERROR: $PIN_FILE not found" >&2; exit 1; }
if [ "$APPLY" -eq 1 ] && [ -z "$ONLY_SLUG" ]; then
  echo "--apply requires a <slug>. Bump one vendor at a time so each PR is reviewable." >&2
  exit 2
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in ''|\#*) printf '%s\n' "$line" >> "$tmp"; continue ;; esac
  # shellcheck disable=SC2086
  set -- $line
  slug="$1"; url="$2"; ref="$3"; sha="$4"

  if [ -n "$ONLY_SLUG" ] && [ "$slug" != "$ONLY_SLUG" ]; then
    printf '%s\n' "$line" >> "$tmp"; continue
  fi

  dest="${VENDOR_DIR}/${slug}"
  if [ ! -d "$dest/.git" ]; then
    echo "==> ${slug}: not installed; run scripts/vendor-install.sh first" >&2
    printf '%s\n' "$line" >> "$tmp"; continue
  fi

  echo "==> ${slug}"
  git -C "$dest" fetch --quiet --tags origin
  default_branch="$(git -C "$dest" remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')"

  if [ "$APPLY" -eq 1 ]; then
    resolve_ref="${TARGET_REF:-origin/${default_branch:-main}}"
    new_sha="$(git -C "$dest" rev-parse "${resolve_ref}^{commit}" 2>/dev/null)" || {
      echo "  ERROR: ref '${resolve_ref}' did not resolve in $dest" >&2; exit 1
    }
    new_ref="${TARGET_REF:-${default_branch:-main}}"
    if [ "$new_sha" = "$sha" ]; then
      echo "  already at ${new_sha:0:12}; no change"
      printf '%s\n' "$line" >> "$tmp"; continue
    fi
    printf '%-12s %-60s %-10s %s\n' "$slug" "$url" "$new_ref" "$new_sha" >> "$tmp"
    echo "  bump: ${sha:0:12} -> ${new_sha:0:12}  (${ref} -> ${new_ref})"
    echo ""
    echo "  Review the upstream diff before opening your PR:"
    echo "    git -C ${dest} log --oneline ${sha}..${new_sha}"
    echo "    git -C ${dest} diff ${sha}..${new_sha} -- 'skills/**/SKILL.md' 'agents/**' 'commands/**'"
    echo ""
    echo "  Then: scripts/vendor-install.sh ${slug} && scripts/sync-skills.sh --fix"
  else
    # Dry-run: report tip vs pinned
    tip_branch="origin/${default_branch:-main}"
    tip_sha="$(git -C "$dest" rev-parse "${tip_branch}" 2>/dev/null)"
    if [ "$tip_sha" = "$sha" ]; then
      echo "  up-to-date at ${sha:0:12}"
    else
      behind="$(git -C "$dest" rev-list --count "${sha}..${tip_sha}" 2>/dev/null || echo '?')"
      echo "  ${behind} commit(s) behind ${tip_branch}"
      echo "    pinned: ${sha}"
      echo "    tip:    ${tip_sha}"
      echo "  View changes:"
      echo "    git -C ${dest} log --oneline ${sha}..${tip_sha}"
    fi
    printf '%s\n' "$line" >> "$tmp"
  fi
done < "$PIN_FILE"

if [ "$APPLY" -eq 1 ]; then
  mv "$tmp" "$PIN_FILE"
  trap - EXIT
  echo ""
  echo "Updated ${PIN_FILE}. Review with: git diff vendor-pins.txt"
fi
