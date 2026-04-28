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
CURSOR_TARGET="${HOME}/.cursor/skills"
CURSOR_RULES_TARGET="${HOME}/.cursor/rules"
CLAUDE_TARGET_PARENT="${HOME}/.claude"
CLAUDE_TARGET_LINK="${CLAUDE_TARGET_PARENT}/skills"
CLAUDE_CONFIG_LINK="${CLAUDE_TARGET_PARENT}/CLAUDE.md"
CLAUDE_CONFIG_EXPECTED="${RULES_SRC}/agent-autonomy.mdc"

MODE="check"
REPLACE_REAL=0
QUIET=0
DRIFT=0
ACTIONS=0

# ----- args -----
for arg in "$@"; do
  case "$arg" in
    --check)        MODE="check" ;;
    --fix)          MODE="fix" ;;
    --replace-real) REPLACE_REAL=1 ;;
    --quiet)        QUIET=1 ;;
    -h|--help)
      sed -n '2,30p' "$0"
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

# ----- 4. Claude: directory-level symlink to NGOSkills/skills (sf-* only) -----
echo "[~/.claude/skills -> NGOSkills/skills]"
if [ ! -d "$CLAUDE_TARGET_PARENT" ]; then
  warn "Claude config dir missing: $CLAUDE_TARGET_PARENT  (Claude Code may not be installed)"
elif [ -L "$CLAUDE_TARGET_LINK" ]; then
  actual="$(readlink "$CLAUDE_TARGET_LINK")"
  if [ "$actual" = "$SF_SRC" ]; then
    ok "$CLAUDE_TARGET_LINK"
  else
    warn "wrong target: $CLAUDE_TARGET_LINK -> $actual  (expected $SF_SRC)"
  fi
elif [ -d "$CLAUDE_TARGET_LINK" ]; then
  warn "real dir (should be symlink): $CLAUDE_TARGET_LINK"
  echo "         To convert manually:"
  echo "           mv $CLAUDE_TARGET_LINK ${CLAUDE_TARGET_LINK}.bak"
  echo "           ln -s $SF_SRC $CLAUDE_TARGET_LINK"
  echo "         (Refusing to auto-replace this one even with --replace-real; it"
  echo "          could contain skills not in the repo. Inspect first.)"
else
  warn "missing: $CLAUDE_TARGET_LINK  (expected -> $SF_SRC)"
  if [ "$MODE" = "fix" ]; then
    ln -s "$SF_SRC" "$CLAUDE_TARGET_LINK"
    act "created: $CLAUDE_TARGET_LINK -> $SF_SRC"
  fi
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
