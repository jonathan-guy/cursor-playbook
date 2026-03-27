#!/usr/bin/env bash
set -euo pipefail

# Transcribe a voice memo and format it as a Cursor instruction.
# Transcribes the audio, copies the text to clipboard, and prints it
# so you can paste it directly into Cursor chat.
#
# Usage: bash instruct.sh <audio_file> [--model MODEL]
#
# Workflow:
#   1. Record a voice memo on Mac/iPhone
#   2. bash instruct.sh ~/voice-memo.m4a
#   3. Cmd+V into Cursor chat

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
JARGON_FILE="$SKILL_DIR/jargon.txt"
MODEL="turbo"
AUDIO=""
OUTDIR="/tmp/whisper-instruct"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    -*)      shift ;;
    *)       AUDIO="$1"; shift ;;
  esac
done

if [[ -z "$AUDIO" ]]; then
  echo "Usage: bash instruct.sh <audio_file> [--model MODEL]" >&2
  exit 1
fi

if [[ ! -f "$AUDIO" ]]; then
  echo "Error: File not found: $AUDIO" >&2
  exit 1
fi

JARGON_ARGS=()
if [[ -f "$JARGON_FILE" ]]; then
  JARGON_ARGS=(--initial_prompt "$(cat "$JARGON_FILE")")
fi

source ~/whisper-env/bin/activate

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

echo "Transcribing voice memo..."
whisper "$AUDIO" --model "$MODEL" --language en \
  --output_dir "$OUTDIR" --output_format txt \
  --condition_on_previous_text False \
  "${JARGON_ARGS[@]}" 2>&1

TRANSCRIPT=$(cat "$OUTDIR"/*.txt | sed 's/^[[:space:]]*//')

echo ""
echo "=== Instruction from voice memo ==="
echo ""
echo "$TRANSCRIPT"
echo ""
echo "==================================="

printf "%s" "$TRANSCRIPT" | pbcopy
echo "(Copied to clipboard -- Cmd+V into Cursor chat)"
