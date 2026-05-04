#!/usr/bin/env bash
# auto-update-skills.sh
#
# Auto-update the NGOSkills repo when there's a remote update available.
# Designed to be called from Cursor's beforeSubmitPrompt hook and Claude Code's
# SessionStart hook without ever introducing UI latency or breaking the user's
# work-in-progress.
#
# Two-phase design (network never blocks the user):
#   Phase A — APPLY (synchronous, fast, all local):
#     - If a pending update marker exists from a previous background fetch,
#       fast-forward merge it now. Takes milliseconds.
#   Phase B — FETCH (asynchronous, slow, network):
#     - If rate-limit allows, spawn a background `git fetch` and exit.
#     - Result lands in marker file for the next invocation to apply.
#
# Modes:
#   (default)        Run Phase A, then trigger Phase B in background. Always exit 0.
#   --fetch-only     Run Phase B synchronously in foreground (used by background spawn).
#   --apply-only     Run Phase A only, no background fetch.
#   --force          Ignore rate-limit; do a fresh fetch+apply synchronously.
#   --status         Print current state (last fetch, pending update, branch). No changes.
#   --quiet          Suppress informational output; only print on actual update applied.
#
# Safety invariants:
#   - Only operates if HEAD is on the configured default branch (master/main).
#   - Refuses to touch a dirty working tree.
#   - Only fast-forward merges; never rebase, never overwrite.
#   - All errors are swallowed and logged; never blocks the calling hook.
#   - Rate-limited via a marker file so prompts don't trigger fetches storms.

set -uo pipefail

# ----- config -----
REPO_ROOT="${HOME}/Cursor/Skills/NGOSkills"
REMOTE="${NGOSKILLS_REMOTE:-public}"      # which git remote to pull from
DEFAULT_BRANCH="${NGOSKILLS_BRANCH:-main}" # which branch to auto-update
RATE_LIMIT_SECONDS="${NGOSKILLS_RATE_LIMIT:-1800}" # default: 30 min between fetches
CACHE_DIR="${HOME}/.cache/ngoskills"
LAST_FETCH_FILE="${CACHE_DIR}/last-fetch"
PENDING_UPDATE_FILE="${CACHE_DIR}/pending-update"
LOG_FILE="${CACHE_DIR}/auto-update.log"

# ----- args -----
MODE="default"
QUIET=0
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --fetch-only) MODE="fetch" ;;
    --apply-only) MODE="apply" ;;
    --status)     MODE="status" ;;
    --force)      FORCE=1 ;;
    --quiet)      QUIET=1 ;;
    -h|--help)
      sed -n '2,33p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 0 ;;  # never block hooks
  esac
done

mkdir -p "$CACHE_DIR" 2>/dev/null || true

# ----- helpers -----
log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$LOG_FILE" 2>/dev/null || true
}
say() {
  [ "$QUIET" -eq 1 ] && return 0
  echo "$@"
}
inrepo() {
  git -C "$REPO_ROOT" "$@"
}

# ----- preflight (silent fail) -----
[ ! -d "$REPO_ROOT/.git" ] && { log "no git repo at $REPO_ROOT"; exit 0; }

CURRENT_BRANCH="$(inrepo branch --show-current 2>/dev/null || true)"
if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
  log "skip: on branch '$CURRENT_BRANCH', not '$DEFAULT_BRANCH'"
  [ "$MODE" = "status" ] && say "skip: on '$CURRENT_BRANCH', not '$DEFAULT_BRANCH'"
  exit 0
fi

DIRTY="$(inrepo status --porcelain 2>/dev/null | head -1)"
if [ -n "$DIRTY" ]; then
  log "skip: working tree is dirty"
  [ "$MODE" = "status" ] && say "skip: working tree is dirty"
  exit 0
fi

# ----- status mode -----
if [ "$MODE" = "status" ]; then
  echo "branch:           $CURRENT_BRANCH"
  echo "remote:           $REMOTE"
  echo "rate-limit:       ${RATE_LIMIT_SECONDS}s"
  if [ -f "$LAST_FETCH_FILE" ]; then
    last="$(cat "$LAST_FETCH_FILE")"
    age=$(( $(date +%s) - last ))
    echo "last fetch:       ${age}s ago"
  else
    echo "last fetch:       never"
  fi
  if [ -f "$PENDING_UPDATE_FILE" ]; then
    echo "pending update:   yes ($(cat "$PENDING_UPDATE_FILE"))"
  else
    echo "pending update:   no"
  fi
  exit 0
fi

# ----- Phase A: APPLY pending update (fast, local-only) -----
apply_pending() {
  [ ! -f "$PENDING_UPDATE_FILE" ] && return 0
  pending_sha="$(cat "$PENDING_UPDATE_FILE" 2>/dev/null)"
  [ -z "$pending_sha" ] && { rm -f "$PENDING_UPDATE_FILE"; return 0; }

  # Verify the pending sha is reachable locally and is a fast-forward
  if ! inrepo cat-file -e "$pending_sha" 2>/dev/null; then
    log "pending sha $pending_sha not in local objects; clearing marker"
    rm -f "$PENDING_UPDATE_FILE"
    return 0
  fi

  local_sha="$(inrepo rev-parse HEAD 2>/dev/null)"
  if [ "$local_sha" = "$pending_sha" ]; then
    rm -f "$PENDING_UPDATE_FILE"
    return 0
  fi

  # Confirm fast-forward is possible (HEAD is ancestor of pending_sha)
  if ! inrepo merge-base --is-ancestor HEAD "$pending_sha" 2>/dev/null; then
    log "skip apply: not a fast-forward from HEAD to $pending_sha"
    rm -f "$PENDING_UPDATE_FILE"
    return 0
  fi

  if inrepo merge --ff-only "$pending_sha" >/dev/null 2>&1; then
    new_sha="$(inrepo rev-parse --short HEAD)"
    log "applied update -> $new_sha"
    say "[ngoskills] Updated to $new_sha (run scripts/sync-skills.sh --check to verify symlinks)."

    # Vendor pin bumps may have landed in this ff-merge. Materialize any new
    # vendor SHAs, then re-link. vendor-install.sh is idempotent; if the new
    # SHA isn't in the local clone yet it will `git fetch`, which can be slow
    # on first pull, so we spawn it in the background. sync-skills.sh runs
    # synchronously here to re-link anything from the NGOSkills tree that the
    # ff-merge added; a second sync runs after the vendor refresh finishes.
    if [ -x "$REPO_ROOT/scripts/sync-skills.sh" ]; then
      "$REPO_ROOT/scripts/sync-skills.sh" --fix --quiet >/dev/null 2>&1 || true
    fi
    if [ -x "$REPO_ROOT/scripts/vendor-install.sh" ]; then
      (
        "$REPO_ROOT/scripts/vendor-install.sh" --quiet >/dev/null 2>>"$LOG_FILE" || true
        "$REPO_ROOT/scripts/sync-skills.sh" --fix --quiet >/dev/null 2>&1 || true
      ) </dev/null >/dev/null 2>&1 &
    fi
    rm -f "$PENDING_UPDATE_FILE"
    return 0
  fi

  log "fast-forward merge failed for $pending_sha"
  rm -f "$PENDING_UPDATE_FILE"
}

# ----- Phase B: FETCH from remote (slow, network) -----
do_fetch() {
  log "fetching from $REMOTE/$DEFAULT_BRANCH"
  if ! inrepo fetch --quiet "$REMOTE" "$DEFAULT_BRANCH" 2>>"$LOG_FILE"; then
    log "fetch failed"
    date +%s > "$LAST_FETCH_FILE"  # rate-limit even on failure to avoid hammering
    return 0
  fi
  date +%s > "$LAST_FETCH_FILE"

  remote_sha="$(inrepo rev-parse "$REMOTE/$DEFAULT_BRANCH" 2>/dev/null)"
  local_sha="$(inrepo rev-parse HEAD 2>/dev/null)"
  if [ -z "$remote_sha" ] || [ "$remote_sha" = "$local_sha" ]; then
    log "up to date ($local_sha)"
    rm -f "$PENDING_UPDATE_FILE"
    return 0
  fi

  if inrepo merge-base --is-ancestor HEAD "$remote_sha" 2>/dev/null; then
    log "pending update available: $remote_sha"
    echo "$remote_sha" > "$PENDING_UPDATE_FILE"
  else
    log "remote diverged from local; not a fast-forward (manual intervention needed)"
    rm -f "$PENDING_UPDATE_FILE"
  fi
}

rate_limit_ok() {
  [ "$FORCE" -eq 1 ] && return 0
  [ ! -f "$LAST_FETCH_FILE" ] && return 0
  last="$(cat "$LAST_FETCH_FILE" 2>/dev/null || echo 0)"
  age=$(( $(date +%s) - last ))
  [ "$age" -ge "$RATE_LIMIT_SECONDS" ]
}

# ----- main -----
case "$MODE" in
  apply)
    apply_pending
    ;;
  fetch)
    # Synchronous fetch (called by background process or --force)
    do_fetch
    ;;
  default)
    # Phase A first (fast)
    apply_pending
    # Phase B in background if rate-limit allows (no UI latency)
    if rate_limit_ok; then
      ( "$0" --fetch-only --quiet </dev/null >/dev/null 2>&1 & )
    fi
    ;;
esac

exit 0
