#!/usr/bin/env bash
set -euo pipefail

# Auto-update jargon.txt from project catalogs and config files.
# Run weekly (nightagent) or manually to keep Whisper transcription accurate.
#
# Usage: bash update_jargon.sh [--repo-root /path/to/project]

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
JARGON_FILE="$SKILL_DIR/jargon.txt"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME")"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    *)           shift ;;
  esac
done

METRICS_YAML="$REPO_ROOT/catalog/metrics.yaml"
SOURCES_YAML="$REPO_ROOT/catalog/sources.yaml"
ARTIFACTS_YAML="$REPO_ROOT/artifacts.yaml"
TMPFILE="/tmp/jargon-terms.txt"

echo "Updating jargon.txt from project catalogs..."
echo "Repo: $REPO_ROOT"

> "$TMPFILE"

# Foundation terms (always included)
cat >> "$TMPFILE" <<'EOF'
Velocity Dashboard
Blockcell
Snowflake
JSONC
Buildkite
esbuild
Playwright
Chart.js
Cursor
Claude Code
BuilderBot
DORA metrics
LTTC
Lead Time to Change
TFT
True Feature Throughput
DXI
Developer Experience Index
LOC
Lines of Code
deploy frequency
change-fail rate
PR throughput
PR merge time
CI reliability
AI adoption
AI-assisted PRs
autonomous PRs
exec summary
stat card
chart tile
nightwatch
nightagent
nightshift
NightShift
sync_metrics
design tokens
data-component
Justfile
Signal Deck
eng roster
jargon priming
voice memo
dictation
Blox
Goose
Anthropic
EOF

# Extract metric names from metrics.yaml
if [[ -f "$METRICS_YAML" ]]; then
  grep '  name:' "$METRICS_YAML" | sed 's/.*name: *"\(.*\)".*/\1/' >> "$TMPFILE"
fi

# Extract source names from sources.yaml
if [[ -f "$SOURCES_YAML" ]]; then
  grep '  name:' "$SOURCES_YAML" | sed 's/.*name: *"\(.*\)".*/\1/' >> "$TMPFILE"
fi

# Extract artifact names from artifacts.yaml
if [[ -f "$ARTIFACTS_YAML" ]]; then
  grep '  name:' "$ARTIFACTS_YAML" | sed 's/.*name: *"\(.*\)".*/\1/' | sed "s/.*name: *'\(.*\)'.*/\1/" >> "$TMPFILE"
fi

# Deduplicate, sort, remove blanks, join with ", "
RESULT=$(sort -uf "$TMPFILE" | grep -v '^$' | tr '\n' ',' | sed 's/,/, /g' | sed 's/, $//')

echo "$RESULT" > "$JARGON_FILE"

TERM_COUNT=$(sort -uf "$TMPFILE" | grep -v '^$' | wc -l | tr -d ' ')
echo "Updated $JARGON_FILE with $TERM_COUNT terms."
echo ""
echo "First 300 chars: $(head -c 300 "$JARGON_FILE")"
rm -f "$TMPFILE"
