#!/bin/bash
# refresh-nonprofit-content.sh
# One-command refresh of nonprofit knowledge base.
# Run after each Salesforce release to pull latest documentation.
#
# Usage:
#   ./scripts/refresh-nonprofit-content.sh              # Standard refresh
#   ./scripts/refresh-nonprofit-content.sh --deep        # Deep crawl (depth=3, 500 pages)
#   ./scripts/refresh-nonprofit-content.sh --quick       # Quick update (depth=1, 50 pages)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_DIR="$REPO_ROOT/.venv-nke"
ENGINE="$SCRIPT_DIR/nonprofit-knowledge-engine.py"
REQUIREMENTS="$SCRIPT_DIR/requirements-knowledge-engine.txt"

# ── Parse mode ───────────────────────────────────────────────────────────────

MAX_DEPTH=2
MAX_PAGES=200
DELAY=1.0

case "${1:-}" in
  --deep)
    MAX_DEPTH=3
    MAX_PAGES=500
    DELAY=0.8
    echo "🔬 Deep refresh: depth=$MAX_DEPTH, max_pages=$MAX_PAGES"
    ;;
  --quick)
    MAX_DEPTH=1
    MAX_PAGES=50
    DELAY=1.5
    echo "⚡ Quick refresh: depth=$MAX_DEPTH, max_pages=$MAX_PAGES"
    ;;
  "")
    echo "📚 Standard refresh: depth=$MAX_DEPTH, max_pages=$MAX_PAGES"
    ;;
  *)
    echo "Usage: $0 [--deep | --quick]"
    exit 1
    ;;
esac

# ── Ensure virtualenv ────────────────────────────────────────────────────────

if [ ! -d "$VENV_DIR" ]; then
  echo "Creating virtualenv at $VENV_DIR..."
  python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

echo "Installing/updating dependencies..."
pip install -q -r "$REQUIREMENTS"

# ── Run refresh ──────────────────────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Nonprofit Knowledge Engine — Refresh"
echo "  $(date -u '+%Y-%m-%d %H:%M UTC')"
echo "════════════════════════════════════════════════════════════"
echo ""

python3 "$ENGINE" refresh \
  --max-depth "$MAX_DEPTH" \
  --max-pages "$MAX_PAGES" \
  --delay "$DELAY"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Refresh complete!"
echo ""
echo "  Content:   $REPO_ROOT/content/"
echo "  NPSP:      $REPO_ROOT/content/npsp/"
echo "  NPC:       $REPO_ROOT/content/npc/"
echo "  Index:     $REPO_ROOT/content/keyword-index.json"
echo "  Rule:      $REPO_ROOT/.cursor/rules/nonprofit-auto-router.md"
echo "════════════════════════════════════════════════════════════"
