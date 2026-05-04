#!/usr/bin/env bash
# sync-skills.sh
#
# Health-check and sync for the NGOSkills repo into Cursor and Claude.
# Manages: skill symlinks, Cursor rule symlinks, and Claude's global CLAUDE.md.
#
# Source of truth (canonical, all in NGOSkills repo):
#   skills/                     -> Salesforce / nonprofit "sf-*" skills
#   skills-cursor/              -> Cursor-ecosystem skills
#   .cursor/rules/*.mdc, *.md   -> Always-apply behavior rules
#   .cursor/rules/agent-autonomy.mdc -> ALSO source for ~/.claude/CLAUDE.md
#
# Targets:
#   ~/.cursor/skills/<name>     -> per-skill symlink to canonical (BOTH groups)
#   ~/.cursor/rules/<rule>      -> per-rule symlink to canonical
#   ~/.claude/skills            -> directory-level symlink to NGOSkills/skills
#                                  (sf-* group ONLY; cursor-native skills are
#                                   not exposed to Claude per user policy)
#   ~/.claude/CLAUDE.md         -> symlink to NGOSkills/.cursor/rules/agent-autonomy.mdc
#                                  (gives Claude the same behavior policy as Cursor)
#
# Modes:
#   --check          (default) Read-only audit. Exits 1 if any drift detected.
#   --fix            Create missing per-skill symlinks. Never deletes anything.
#   --replace-real   With --fix: also convert real directories that should be
#                    symlinks. Backs up the real dir to /tmp first.
#                    DANGEROUS — requires --fix and explicit confirmation.
#   --quiet          Suppress OK lines; only print drift/actions.
#
# Safety invariants:
#   - Never iterates paths that resolve through a symlink.
#   - Refuses to run if the canonical source itself is a symlink.
#   - Never uses `rm -rf` on anything that could resolve into canonical.
#   - All paths are absolute; no `cd` into target dirs.

set -euo pipefail

# ----- config -----
REPO_ROOT="${HOME}/Cursor/Skills/NGOSkills"
SF_SRC="${REPO_ROOT}/skills"
CURSOR_SRC="${REPO_ROOT}/skills-cursor"
RULES_SRC="${REPO_ROOT}/.cursor/rules"
VENDOR_ROOT="${REPO_ROOT}/.vendor"
CURSOR_TARGET="${HOME}/.cursor/skills"
CURSOR_RULES_TARGET="${HOME}/.cursor/rules"
CURSOR_AGENTS_TARGET="${HOME}/.cursor/agents"
CURSOR_COMMANDS_TARGET="${HOME}/.cursor/commands"
CLAUDE_TARGET_PARENT="${HOME}/.claude"
CLAUDE_TARGET_LINK="${CLAUDE_TARGET_PARENT}/skills"
CLAUDE_AGENTS_TARGET="${CLAUDE_TARGET_PARENT}/agents"
CLAUDE_COMMANDS_TARGET="${CLAUDE_TARGET_PARENT}/commands"
CLAUDE_CONFIG_LINK="${CLAUDE_TARGET_PARENT}/CLAUDE.md"
CLAUDE_CONFIG_EXPECTED="${RULES_SRC}/agent-autonomy.mdc"

# Vendor layout: each line in vendor-pins.txt resolves to .vendor/<slug>/.
# We look for these subdirs in each vendor and link their contents:
#   skills/    -> per-skill dir symlinks into ~/.claude/skills and ~/.cursor/skills
#   agents/    -> per-file .md symlinks into ~/.claude/agents and ~/.cursor/agents
#   commands/  -> per-file/dir symlinks into ~/.claude/commands and ~/.cursor/commands
#
# Vendor hooks are NEVER auto-linked (supply-chain risk — review and install manually).

MODE="check"
REPLACE_REAL=0
QUIET=0
MIGRATE_CLAUDE_SKILLS=0
DRIFT=0
ACTIONS=0

# ----- args -----
for arg in "$@"; do
  case "$arg" in
    --check)        MODE="check" ;;
    --fix)          MODE="fix" ;;
    --replace-real) REPLACE_REAL=1 ;;
    --migrate-claude-skills) MIGRATE_CLAUDE_SKILLS=1 ;;
    --quiet)        QUIET=1 ;;
    -h|--help)
      sed -n '2,35p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# ----- helpers -----
ok()   { [ "$QUIET" -eq 1 ] || echo "  ok    $1"; }
warn() { echo "  DRIFT $1"; DRIFT=$((DRIFT+1)); }
act()  { echo "  fix   $1"; ACTIONS=$((ACTIONS+1)); }
err()  { echo "ERROR $1" >&2; exit 1; }

# Verify a target path is a symlink pointing at the expected absolute path.
# Args: target, expected
check_link() {
  local target="$1" expected="$2"
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    warn "missing: $target  (expected -> $expected)"
    if [ "$MODE" = "fix" ]; then
      ln -s "$expected" "$target"
      act "created: $target -> $expected"
    fi
    return
  fi
  if [ -L "$target" ]; then
    local actual
    actual="$(readlink "$target")"
    if [ "$actual" = "$expected" ]; then
      ok "$target"
    else
      warn "wrong target: $target -> $actual  (expected $expected)"
    fi
    return
  fi
  # Exists but is not a symlink => real file/dir = drift
  warn "real dir (should be symlink): $target"
  if [ "$MODE" = "fix" ] && [ "$REPLACE_REAL" -eq 1 ]; then
    local backup="/tmp/sync-skills-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup"
    # Use cp -RP to preserve symlinks as symlinks; this dir is real so it copies content.
    cp -RP "$target" "$backup/"
    rm -rf "$target"
    ln -s "$expected" "$target"
    act "replaced real dir with symlink: $target  (backup: $backup)"
  fi
}

# ----- preflight: never operate if canonical source itself is a symlink -----
if [ -L "$SF_SRC" ]; then
  err "Refusing to run: canonical source $SF_SRC is itself a symlink. Investigate before re-running."
fi
if [ -L "$CURSOR_SRC" ]; then
  err "Refusing to run: canonical source $CURSOR_SRC is itself a symlink. Investigate before re-running."
fi
if [ ! -d "$SF_SRC" ]; then
  err "Canonical source missing: $SF_SRC"
fi

if [ "$REPLACE_REAL" -eq 1 ]; then
  echo "Mode: $MODE (replace-real enabled)"
else
  echo "Mode: $MODE"
fi
echo "Canonical sf-*:        $SF_SRC"
echo "Canonical cursor-native: $CURSOR_SRC"
echo ""

# ----- 1. Cursor target dir exists? -----
if [ ! -d "$CURSOR_TARGET" ] && [ ! -L "$CURSOR_TARGET" ]; then
  warn "Cursor skills dir missing: $CURSOR_TARGET"
  if [ "$MODE" = "fix" ]; then
    mkdir -p "$CURSOR_TARGET"
    act "created dir: $CURSOR_TARGET"
  fi
fi

# ----- 2. sf-* skills: per-skill symlinks in ~/.cursor/skills/ -----
echo "[sf-* skills -> ~/.cursor/skills/]"
# IMPORTANT: enumerate canonical without following symlinks (use -P, the default)
while IFS= read -r path; do
  [ -z "$path" ] && continue
  name="$(basename "$path")"
  check_link "${CURSOR_TARGET}/${name}" "${SF_SRC}/${name}"
done < <(find "$SF_SRC" -maxdepth 1 -mindepth 1 -type d -not -name '.*' | sort)
echo ""

# ----- 3. cursor-native skills: per-skill symlinks in ~/.cursor/skills/ -----
if [ -d "$CURSOR_SRC" ]; then
  echo "[cursor-native skills -> ~/.cursor/skills/]"
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    name="$(basename "$path")"
    check_link "${CURSOR_TARGET}/${name}" "${CURSOR_SRC}/${name}"
  done < <(find "$CURSOR_SRC" -maxdepth 1 -mindepth 1 -type d -not -name '.*' | sort)
  echo ""
fi

# ----- 3b. Cursor rules: per-rule symlinks in ~/.cursor/rules/ -----
if [ -d "$RULES_SRC" ]; then
  echo "[Cursor rules -> ~/.cursor/rules/]"
  if [ ! -d "$CURSOR_RULES_TARGET" ] && [ ! -L "$CURSOR_RULES_TARGET" ]; then
    warn "Cursor rules dir missing: $CURSOR_RULES_TARGET"
    [ "$MODE" = "fix" ] && mkdir -p "$CURSOR_RULES_TARGET" && act "created dir: $CURSOR_RULES_TARGET"
  fi
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    name="$(basename "$path")"
    check_link "${CURSOR_RULES_TARGET}/${name}" "${RULES_SRC}/${name}"
  done < <(find "$RULES_SRC" -maxdepth 1 -mindepth 1 -type f \( -name '*.mdc' -o -name '*.md' \) | sort)
  echo ""
fi

# ----- 4. Claude skills: per-skill symlinks (sf-* + vendor skills) -----
# Historically ~/.claude/skills was a directory-level symlink to NGOSkills/skills.
# With vendor packs (superpowers, gsd) we now need per-skill symlinks so sources
# can be mixed. Run once with --migrate-claude-skills to convert.
echo "[~/.claude/skills/ (per-skill symlinks: sf-* + vendor)]"
if [ ! -d "$CLAUDE_TARGET_PARENT" ]; then
  warn "Claude config dir missing: $CLAUDE_TARGET_PARENT  (Claude Code may not be installed)"
elif [ -L "$CLAUDE_TARGET_LINK" ]; then
  # Legacy directory-level symlink. Needs migration to a real dir before we can
  # mix vendor skills in.
  if [ "$MIGRATE_CLAUDE_SKILLS" -eq 1 ] && [ "$MODE" = "fix" ]; then
    actual="$(readlink "$CLAUDE_TARGET_LINK")"
    echo "  migrating: $CLAUDE_TARGET_LINK was symlink -> $actual"
    rm "$CLAUDE_TARGET_LINK"
    mkdir -p "$CLAUDE_TARGET_LINK"
    act "converted to real dir: $CLAUDE_TARGET_LINK  (was -> $actual)"
  else
    warn "legacy directory symlink at $CLAUDE_TARGET_LINK (points at $(readlink "$CLAUDE_TARGET_LINK"))"
    echo "         Needs migration to a real dir so vendor skills can be mixed in."
    echo "         Run: scripts/sync-skills.sh --fix --migrate-claude-skills"
  fi
elif [ ! -d "$CLAUDE_TARGET_LINK" ]; then
  warn "missing: $CLAUDE_TARGET_LINK"
  [ "$MODE" = "fix" ] && mkdir -p "$CLAUDE_TARGET_LINK" && act "created dir: $CLAUDE_TARGET_LINK"
fi

if [ -d "$CLAUDE_TARGET_LINK" ] && [ ! -L "$CLAUDE_TARGET_LINK" ]; then
  # sf-* skills
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    name="$(basename "$path")"
    check_link "${CLAUDE_TARGET_LINK}/${name}" "${SF_SRC}/${name}"
  done < <(find "$SF_SRC" -maxdepth 1 -mindepth 1 -type d -not -name '.*' | sort)

  # vendor skills (from .vendor/<slug>/skills/)
  if [ -d "$VENDOR_ROOT" ]; then
    while IFS= read -r vpath; do
      [ -z "$vpath" ] && continue
      vslug="$(basename "$vpath")"
      vskills="${vpath}/skills"
      [ -d "$vskills" ] || continue
      while IFS= read -r skpath; do
        [ -z "$skpath" ] && continue
        skname="$(basename "$skpath")"
        check_link "${CLAUDE_TARGET_LINK}/${skname}" "${vskills}/${skname}"
      done < <(find "$vskills" -maxdepth 1 -mindepth 1 -type d -not -name '.*' | sort)
    done < <(find "$VENDOR_ROOT" -maxdepth 1 -mindepth 1 -type d -not -name '.*' | sort)
  fi
fi
echo ""

# ----- 4a. Claude agents: per-file symlinks from vendors (gsd agents, etc.) -----
echo "[~/.claude/agents/ (per-file symlinks from vendor agents)]"
if [ -d "$CLAUDE_TARGET_PARENT" ] && [ -d "$VENDOR_ROOT" ]; then
  [ ! -d "$CLAUDE_AGENTS_TARGET" ] && [ "$MODE" = "fix" ] && mkdir -p "$CLAUDE_AGENTS_TARGET" && act "created dir: $CLAUDE_AGENTS_TARGET"
  if [ ! -d "$CLAUDE_AGENTS_TARGET" ]; then
    warn "missing: $CLAUDE_AGENTS_TARGET  (run --fix to create)"
  else
    while IFS= read -r vpath; do
      [ -z "$vpath" ] && continue
      vagents="${vpath}/agents"
      [ -d "$vagents" ] || continue
      while IFS= read -r apath; do
        [ -z "$apath" ] && continue
        aname="$(basename "$apath")"
        check_link "${CLAUDE_AGENTS_TARGET}/${aname}" "${apath}"
      done < <(find "$vagents" -maxdepth 1 -mindepth 1 -type f -name '*.md' | sort)
    done < <(find "$VENDOR_ROOT" -maxdepth 1 -mindepth 1 -type d -not -name '.*' | sort)
  fi
fi
echo ""

# ----- 4b. Claude commands: per-entry symlinks from vendor commands -----
echo "[~/.claude/commands/ (per-entry symlinks from vendor commands)]"
if [ -d "$CLAUDE_TARGET_PARENT" ] && [ -d "$VENDOR_ROOT" ]; then
  [ ! -d "$CLAUDE_COMMANDS_TARGET" ] && [ "$MODE" = "fix" ] && mkdir -p "$CLAUDE_COMMANDS_TARGET" && act "created dir: $CLAUDE_COMMANDS_TARGET"
  if [ ! -d "$CLAUDE_COMMANDS_TARGET" ]; then
    warn "missing: $CLAUDE_COMMANDS_TARGET  (run --fix to create)"
  else
    while IFS= read -r vpath; do
      [ -z "$vpath" ] && continue
      vcmds="${vpath}/commands"
      [ -d "$vcmds" ] || continue
      while IFS= read -r cpath; do
        [ -z "$cpath" ] && continue
        cname="$(basename "$cpath")"
        check_link "${CLAUDE_COMMANDS_TARGET}/${cname}" "${cpath}"
      done < <(find "$vcmds" -maxdepth 1 -mindepth 1 \( -type f -o -type d \) -not -name '.*' | sort)
    done < <(find "$VENDOR_ROOT" -maxdepth 1 -mindepth 1 -type d -not -name '.*' | sort)
  fi
fi
echo ""

# ----- 4c-pre2. Vendor hooks: gsd's executable hook scripts. -----
#
# gsd ships hook scripts that improve execution quality when registered in
# settings.json:
#   - gsd-context-monitor.js (PostToolUse) — warns agent when context nears full
#   - gsd-session-state.sh   (SessionStart) — injects STATE.md head for orientation
#                                              (opt-in via .planning/config.json)
#   - gsd-check-update.js    (SessionStart) — banner when new gsd version ships
#   - gsd-statusline.js      (statusLine)   — shows phase/plan state
#   - gsd-phase-boundary.sh, gsd-prompt-guard.js, gsd-read-guard.js, etc.
#
# These hooks use __dirname to locate sibling files (hooks/../get-shit-done/...),
# so symlinking them into ~/.claude/hooks/ works correctly because the sibling
# ~/.claude/get-shit-done/ exists (linked in 4c-pre below).
#
# Registering them in settings.json is a SEPARATE concern — this block only
# makes the scripts available at the expected path. Registration lives in the
# user's settings.json (hand-edited or managed by the update-config skill).
echo "[~/.claude/hooks/ (gsd hook scripts)]"
GSD_HOOKS_SRC="${VENDOR_ROOT}/gsd/hooks"
CLAUDE_HOOKS_TARGET="${CLAUDE_TARGET_PARENT}/hooks"
if [ ! -d "$GSD_HOOKS_SRC" ]; then
  : # gsd not installed
elif [ ! -d "$CLAUDE_TARGET_PARENT" ]; then
  : # already warned
else
  if [ ! -d "$CLAUDE_HOOKS_TARGET" ]; then
    if [ "$MODE" = "fix" ]; then
      mkdir -p "$CLAUDE_HOOKS_TARGET"
      act "created dir: $CLAUDE_HOOKS_TARGET"
    else
      warn "missing: $CLAUDE_HOOKS_TARGET  (run --fix to create)"
    fi
  fi
  if [ -d "$CLAUDE_HOOKS_TARGET" ]; then
    while IFS= read -r hpath; do
      [ -z "$hpath" ] && continue
      hname="$(basename "$hpath")"
      check_link "${CLAUDE_HOOKS_TARGET}/${hname}" "$hpath"
    done < <(find "$GSD_HOOKS_SRC" -maxdepth 1 -mindepth 1 -type f \( -name 'gsd-*.js' -o -name 'gsd-*.sh' \) | sort)
  fi
fi
echo ""

# ----- 4c-pre. Vendor runtime payloads: `get-shit-done/` from gsd. -----
#
# gsd's agents and commands reference @~/.claude/get-shit-done/references/...
# (187 references across 98 files). Without this symlink they silently 404 and
# execution/planning agents run without their TDD rules, thinking-models,
# verification checklists, etc. — i.e., gsd workflows work, but degraded.
#
# This is symlinked as a single directory (not fanned out file-by-file) because
# gsd treats get-shit-done/ as a single cohesive payload (pristine-vs-user
# artifacts, USER_OWNED_ARTIFACTS semantics, etc.), and fanning it out would
# break gsd's own self-management if the user later wants to run its native
# `node bin/install.js` to upgrade.
#
# Only extended to other vendors on demand — superpowers and gstack don't have
# this pattern. If a new vendor ships a get-shit-done/-style payload, add it
# here explicitly rather than making the loop generic (explicitness > cleverness
# for supply-chain-adjacent file layout).
echo "[~/.claude/get-shit-done (gsd runtime payload)]"
GSD_PAYLOAD_SRC="${VENDOR_ROOT}/gsd/get-shit-done"
GSD_PAYLOAD_DST="${CLAUDE_TARGET_PARENT}/get-shit-done"
if [ ! -d "$GSD_PAYLOAD_SRC" ]; then
  : # gsd not installed; no action
elif [ ! -d "$CLAUDE_TARGET_PARENT" ]; then
  : # already warned above
else
  check_link "$GSD_PAYLOAD_DST" "$GSD_PAYLOAD_SRC"
fi
echo ""

# ----- 4c. Cursor: vendor skills + agents + commands -----
echo "[~/.cursor/skills/ ~/.cursor/agents/ ~/.cursor/commands/ (vendor fan-out)]"
if [ -d "$VENDOR_ROOT" ]; then
  [ ! -d "$CURSOR_AGENTS_TARGET" ] && [ "$MODE" = "fix" ] && mkdir -p "$CURSOR_AGENTS_TARGET" && act "created dir: $CURSOR_AGENTS_TARGET"
  [ ! -d "$CURSOR_COMMANDS_TARGET" ] && [ "$MODE" = "fix" ] && mkdir -p "$CURSOR_COMMANDS_TARGET" && act "created dir: $CURSOR_COMMANDS_TARGET"
  while IFS= read -r vpath; do
    [ -z "$vpath" ] && continue
    # skills
    vskills="${vpath}/skills"
    if [ -d "$vskills" ] && [ -d "$CURSOR_TARGET" ]; then
      while IFS= read -r skpath; do
        [ -z "$skpath" ] && continue
        skname="$(basename "$skpath")"
        check_link "${CURSOR_TARGET}/${skname}" "${vskills}/${skname}"
      done < <(find "$vskills" -maxdepth 1 -mindepth 1 -type d -not -name '.*' | sort)
    fi
    # agents
    vagents="${vpath}/agents"
    if [ -d "$vagents" ] && [ -d "$CURSOR_AGENTS_TARGET" ]; then
      while IFS= read -r apath; do
        [ -z "$apath" ] && continue
        aname="$(basename "$apath")"
        check_link "${CURSOR_AGENTS_TARGET}/${aname}" "${apath}"
      done < <(find "$vagents" -maxdepth 1 -mindepth 1 -type f -name '*.md' | sort)
    fi
    # commands
    vcmds="${vpath}/commands"
    if [ -d "$vcmds" ] && [ -d "$CURSOR_COMMANDS_TARGET" ]; then
      while IFS= read -r cpath; do
        [ -z "$cpath" ] && continue
        cname="$(basename "$cpath")"
        check_link "${CURSOR_COMMANDS_TARGET}/${cname}" "${cpath}"
      done < <(find "$vcmds" -maxdepth 1 -mindepth 1 \( -type f -o -type d \) -not -name '.*' | sort)
    fi
  done < <(find "$VENDOR_ROOT" -maxdepth 1 -mindepth 1 -type d -not -name '.*' | sort)
fi
echo ""

# ----- 4b. Claude global config: ~/.claude/CLAUDE.md -> agent-autonomy.mdc -----
echo "[~/.claude/CLAUDE.md -> NGOSkills/.cursor/rules/agent-autonomy.mdc]"
if [ ! -d "$CLAUDE_TARGET_PARENT" ]; then
  : # already warned above
elif [ ! -f "$CLAUDE_CONFIG_EXPECTED" ]; then
  warn "agent-autonomy.mdc missing in repo: $CLAUDE_CONFIG_EXPECTED"
elif [ -L "$CLAUDE_CONFIG_LINK" ]; then
  actual="$(readlink "$CLAUDE_CONFIG_LINK")"
  if [ "$actual" = "$CLAUDE_CONFIG_EXPECTED" ]; then
    ok "$CLAUDE_CONFIG_LINK"
  else
    warn "wrong target: $CLAUDE_CONFIG_LINK -> $actual  (expected $CLAUDE_CONFIG_EXPECTED)"
  fi
elif [ -f "$CLAUDE_CONFIG_LINK" ]; then
  warn "real file (should be symlink): $CLAUDE_CONFIG_LINK"
  echo "         Inspect/preserve any local content before manually replacing with:"
  echo "           ln -sf $CLAUDE_CONFIG_EXPECTED $CLAUDE_CONFIG_LINK"
else
  warn "missing: $CLAUDE_CONFIG_LINK  (expected -> $CLAUDE_CONFIG_EXPECTED)"
  if [ "$MODE" = "fix" ]; then
    ln -s "$CLAUDE_CONFIG_EXPECTED" "$CLAUDE_CONFIG_LINK"
    act "created: $CLAUDE_CONFIG_LINK -> $CLAUDE_CONFIG_EXPECTED"
  fi
fi
echo ""

# ----- 5. Reverse audit: anything in ~/.cursor/skills/ that isn't expected? -----
# (informational only; we never auto-delete)
echo "[reverse audit: unexpected entries in ~/.cursor/skills/]"
EXPECTED=$(mktemp)
{
  find "$SF_SRC" -maxdepth 1 -mindepth 1 -type d -not -name '.*' -exec basename {} \;
  [ -d "$CURSOR_SRC" ] && find "$CURSOR_SRC" -maxdepth 1 -mindepth 1 -type d -not -name '.*' -exec basename {} \;
  if [ -d "$VENDOR_ROOT" ]; then
    while IFS= read -r vpath; do
      [ -z "$vpath" ] && continue
      [ -d "${vpath}/skills" ] || continue
      find "${vpath}/skills" -maxdepth 1 -mindepth 1 -type d -not -name '.*' -exec basename {} \;
    done < <(find "$VENDOR_ROOT" -maxdepth 1 -mindepth 1 -type d -not -name '.*' | sort)
  fi
} | sort -u > "$EXPECTED"

UNEXPECTED=0
while IFS= read -r entry; do
  name="$(basename "$entry")"
  case "$name" in .*) continue ;; esac
  if ! grep -qx "$name" "$EXPECTED"; then
    echo "  info  unexpected: ${CURSOR_TARGET}/${name}  (not in NGOSkills repo)"
    UNEXPECTED=$((UNEXPECTED+1))
  fi
done < <(find "$CURSOR_TARGET" -maxdepth 1 -mindepth 1 \( -type d -o -type l \) | sort)
[ "$UNEXPECTED" -eq 0 ] && [ "$QUIET" -eq 0 ] && echo "  (none)"
rm -f "$EXPECTED"
echo ""

# ----- summary -----
echo "Summary: drift=$DRIFT actions=$ACTIONS unexpected=$UNEXPECTED"
if [ "$MODE" = "check" ] && [ "$DRIFT" -gt 0 ]; then
  exit 1
fi
exit 0
