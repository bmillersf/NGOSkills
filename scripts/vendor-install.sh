#!/usr/bin/env bash
# vendor-install.sh
#
# Materializes every vendor listed in vendor-pins.txt into .vendor/<slug>
# at the exact pinned SHA. Idempotent: re-running checks out pinned SHAs
# without re-cloning when the repo already exists.
#
# Does NOT create any symlinks into ~/.claude or ~/.cursor. That job belongs
# to scripts/sync-skills.sh --fix, which is called by scripts/setup.sh after
# this script completes.
#
# Usage:
#   scripts/vendor-install.sh            # install/verify all pins
#   scripts/vendor-install.sh <slug>     # only this vendor
#   scripts/vendor-install.sh --verify   # read-only; exit 1 on drift
#
# Exit codes:
#   0 = all vendors at pinned SHA
#   1 = drift detected (--verify) or install failed
#   2 = bad arguments

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PIN_FILE="${REPO_ROOT}/vendor-pins.txt"
VENDOR_DIR="${REPO_ROOT}/.vendor"
HOOKS_DIR="${REPO_ROOT}/scripts/vendor-hooks"

VERIFY_ONLY=0
QUIET=0
ONLY_SLUG=""

for arg in "$@"; do
  case "$arg" in
    --verify) VERIFY_ONLY=1 ;;
    --quiet)  QUIET=1 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    --*) echo "Unknown flag: $arg" >&2; exit 2 ;;
    *)
      if [ -n "$ONLY_SLUG" ]; then
        echo "Only one slug allowed; got '$ONLY_SLUG' and '$arg'" >&2; exit 2
      fi
      ONLY_SLUG="$arg"
      ;;
  esac
done

say() { [ "$QUIET" -eq 1 ] && return 0; echo "$@"; }

# Run scripts/vendor-hooks/<slug>-post-install.sh if it exists. Hooks get two
# args: the vendor slug and the vendor checkout path (.vendor/<slug>). They run
# AFTER the pinned SHA is on disk — whether freshly cloned, freshly checked
# out, or already in place. Hooks are expected to be idempotent. Errors are
# surfaced but do not abort the remaining vendors (one broken hook should not
# block the others from materializing).
run_post_install_hook() {
  local slug="$1" dest="$2"
  local hook="${HOOKS_DIR}/${slug}-post-install.sh"
  [ -x "$hook" ] || return 0
  say "  post-install: ${hook#$REPO_ROOT/}"
  if ! "$hook" "$slug" "$dest"; then
    echo "  WARN: post-install hook failed for ${slug} (continuing)" >&2
  fi
}

[ -f "$PIN_FILE" ] || { echo "ERROR: $PIN_FILE not found" >&2; exit 1; }
mkdir -p "$VENDOR_DIR"

DRIFT=0
PROCESSED=0

# Read pin file, skip blanks/comments
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in ''|\#*) continue ;; esac
  # shellcheck disable=SC2086
  set -- $line
  [ "$#" -eq 4 ] || { echo "malformed pin line: $line" >&2; exit 1; }
  slug="$1"; url="$2"; ref="$3"; sha="$4"

  if [ -n "$ONLY_SLUG" ] && [ "$ONLY_SLUG" != "$slug" ]; then continue; fi
  PROCESSED=$((PROCESSED+1))

  dest="${VENDOR_DIR}/${slug}"
  say "==> ${slug} (ref=${ref} sha=${sha:0:12})"

  if [ ! -d "$dest/.git" ]; then
    if [ "$VERIFY_ONLY" -eq 1 ]; then
      say "  DRIFT: not installed"
      DRIFT=$((DRIFT+1)); continue
    fi
    say "  cloning ${url}"
    git clone --quiet "$url" "$dest"
  fi

  current="$(git -C "$dest" rev-parse HEAD)"
  if [ "$current" = "$sha" ]; then
    say "  ok at ${sha:0:12}"
    # --verify is read-only by contract. Post-install hooks can have side
    # effects (rebuild binaries, touch ~/.claude/skills/), so only run them
    # when we're actually installing/bumping.
    [ "$VERIFY_ONLY" -eq 0 ] && run_post_install_hook "$slug" "$dest"
    continue
  fi

  if [ "$VERIFY_ONLY" -eq 1 ]; then
    say "  DRIFT: currently ${current:0:12}, expected ${sha:0:12}"
    DRIFT=$((DRIFT+1)); continue
  fi

  # Fetch if SHA not present
  if ! git -C "$dest" cat-file -e "${sha}^{commit}" 2>/dev/null; then
    say "  fetching"
    git -C "$dest" fetch --quiet --tags origin
  fi

  if ! git -C "$dest" cat-file -e "${sha}^{commit}" 2>/dev/null; then
    echo "  ERROR: sha ${sha} not reachable from origin" >&2
    DRIFT=$((DRIFT+1)); continue
  fi

  # Detached checkout at pinned SHA. We do not want teammate work in .vendor/.
  # Post-install hooks (e.g. gstack's setup) intentionally modify tracked files
  # in-place (patched name: fields, etc.), which leaves the working tree dirty
  # even when HEAD matches the pin. A plain `git checkout <sha>` would abort on
  # those modifications and the next pin bump would silently do nothing.
  # `git reset --hard` is safe here because the entire .vendor/<slug>/ directory
  # is declared non-teammate-editable by policy (documented in vendor-policy.md).
  git -C "$dest" -c advice.detachedHead=false reset --hard --quiet "$sha"
  # Always announce a real checkout even in --quiet mode; this is the one
  # side-effect a caller might care about.
  echo "[vendor-install] ${slug} -> ${sha:0:12}"
  run_post_install_hook "$slug" "$dest"
done < "$PIN_FILE"

if [ "$PROCESSED" -eq 0 ] && [ -n "$ONLY_SLUG" ]; then
  echo "ERROR: slug '$ONLY_SLUG' not in $PIN_FILE" >&2; exit 1
fi

if [ "$DRIFT" -gt 0 ]; then
  say "Drift: $DRIFT vendor(s) not at pinned SHA"
  exit 1
fi

say "All vendors at pinned SHAs."
