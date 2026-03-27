#!/usr/bin/env bash
set -euo pipefail

# Voice-to-text dictation for Cursor.
# Records from mic, transcribes with Whisper (with jargon priming), copies to clipboard.
#
# Usage: bash dictate.sh [--model MODEL] [--no-jargon]
#   Press Enter to stop recording.

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
JARGON_FILE="$SKILL_DIR/jargon.txt"
MODEL="small"
USE_JARGON=true
RECORDING="/tmp/whisper-dictation.wav"
OUTDIR="/tmp/whisper-dictation-out"

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
echo "=== Whisper Dictation ==="
echo "Model: $MODEL | Jargon: $USE_JARGON"
echo "Speak now. Press ENTER to stop and transcribe."
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

echo ""
echo "--- Transcript ---"
echo "$TRANSCRIPT"
echo ""

printf "%s" "$TRANSCRIPT" | pbcopy
echo "(Copied to clipboard — auto-pasting into chat...)"

# Hide terminal (Ctrl+`) → focus returns to chat input → paste → re-show terminal
osascript <<'APPLESCRIPT'
tell application "System Events"
    key code 50 using control down
    delay 0.4
    keystroke "v" using command down
    delay 0.2
    key code 50 using control down
end tell
APPLESCRIPT
