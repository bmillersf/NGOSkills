#!/usr/bin/env bash
# gstack-post-install.sh — runs after vendor-install.sh checks out gstack at
# its pinned SHA. Responsibilities:
#   1. Invoke gstack's own `./setup` to build the browser binary (via bun),
#      install Playwright Chromium, and link its ~45 skills into
#      ~/.claude/skills/ with the `gstack-` prefix (so /gstack-review,
#      /gstack-ship, etc. don't collide with gsd, superpowers, or sf-*).
#   2. Skip gracefully if bun is missing — gstack's non-browser skills still
#      work, and a warning is louder than a hard failure (this hook must not
#      abort vendor-install.sh for the other vendors).
#
# gstack is structurally different from the other vendors:
#   - Its skill directories live at the repo root, not under skills/.
#   - Its /browse and /qa skills require a compiled Bun+Playwright binary.
#   - Its setup script is the official supported install path.
#
# Rather than fight that layout in sync-skills.sh, we defer to gstack's own
# setup and let sync-skills.sh ignore .vendor/gstack/ entirely (it has no
# skills/ subdir to fan out).
#
# This hook is idempotent: gstack's setup detects a stale browse binary via
# mtime checks and only rebuilds when necessary.

set -euo pipefail

SLUG="${1:-gstack}"
DEST="${2:-}"

if [ -z "$DEST" ] || [ ! -d "$DEST" ]; then
  echo "[$SLUG-post-install] ERROR: vendor directory not provided or missing" >&2
  exit 1
fi

if ! command -v bun >/dev/null 2>&1; then
  echo "[$SLUG-post-install] bun not found — skipping gstack setup" >&2
  echo "[$SLUG-post-install]   Install bun: brew install oven-sh/bun/bun" >&2
  echo "[$SLUG-post-install]   Then re-run: scripts/vendor-install.sh gstack" >&2
  exit 0
fi

# gstack-patch-names walks the vendor tree and writes name: fields into each
# SKILL.md.tmpl. We do NOT want it modifying the pinned checkout — any diff
# there would register as drift on the next vendor-install --verify. Run
# setup in a mode that just builds the binary and links skills.
#
# gstack's setup auto-picks SKILL_PREFIX based on TTY detection. We force
# --prefix so every skill lands as /gstack-<name>, keeping the global command
# namespace clean.

# --quiet suppresses TTY prompts (prefix choice); gstack saves the config once
# and reuses it on subsequent runs.
echo "[$SLUG-post-install] running gstack ./setup --host claude --prefix --quiet"
if ! ( cd "$DEST" && ./setup --host claude --prefix --quiet ); then
  echo "[$SLUG-post-install] WARN: gstack setup exited non-zero" >&2
  exit 1
fi

echo "[$SLUG-post-install] ok"
