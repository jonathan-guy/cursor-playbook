#!/usr/bin/env bash
set -euo pipefail

# Voice-to-nightagent quick fix.
# Records from mic, transcribes with Whisper, appends to .nightagent-quick-fixes.md.
#
# Usage: bash dictate-fix.sh [--model MODEL] [--no-jargon]
#   Press Enter to stop recording. Take as long as you need — pauses are fine.

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
JARGON_FILE="$SKILL_DIR/jargon.txt"
MODEL="turbo"
USE_JARGON=true
RECORDING="/tmp/whisper-dictation-fix.wav"
OUTDIR="/tmp/whisper-dictation-fix-out"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME")"
QUICK_FIXES="$REPO_ROOT/.nightagent-quick-fixes.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)      MODEL="$2"; shift 2 ;;
    --no-jargon)  USE_JARGON=false; shift ;;
    *)            shift ;;
  esac
done

JARGON_ARGS=()
if $USE_JARGON && [[ -f "$JARGON_FILE" ]]; then
  JARGON_ARGS=(--initial_prompt "$(cat "$JARGON_FILE")")
fi

cleanup() {
  [[ -n "${REC_PID:-}" ]] && kill "$REC_PID" 2>/dev/null || true
}
trap cleanup EXIT

echo ""
echo "=== Quick Fix Dictation ==="
echo "Model: $MODEL | Target: .nightagent-quick-fixes.md"
echo "Speak your fix. Press ENTER when done."
echo ""

rec -q -r 16000 -c 1 -b 16 "$RECORDING" &
REC_PID=$!

read -r -s
kill "$REC_PID" 2>/dev/null || true
wait "$REC_PID" 2>/dev/null || true
unset REC_PID

echo "Recording stopped. Transcribing..."
echo ""

source ~/whisper-env/bin/activate

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

whisper "$RECORDING" \
  --model "$MODEL" \
  --language en \
  --output_dir "$OUTDIR" \
  --output_format txt \
  --condition_on_previous_text False \
  "${JARGON_ARGS[@]}" 2>&1

TRANSCRIPT=$(cat "$OUTDIR"/*.txt | sed 's/^[[:space:]]*//')

if [[ -z "$TRANSCRIPT" ]]; then
  echo "No speech detected. Nothing queued."
  exit 0
fi

echo "$TRANSCRIPT" >> "$QUICK_FIXES"

echo ""
echo "Queued quick fix:"
echo "  $TRANSCRIPT"
echo ""
echo "  -> $QUICK_FIXES"
echo "  Nightagent will pick this up at the 3 PM briefing."
