#!/usr/bin/env bash
set -euo pipefail

# Transcribe audio files with Whisper. Auto-loads jargon for domain accuracy.
# Usage: bash transcribe.sh <audio_file> [--model MODEL] [--lang LANG] [--clipboard] [--srt] [--no-jargon]

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
JARGON_FILE="$SKILL_DIR/jargon.txt"
MODEL="turbo"
LANG="en"
CLIPBOARD=false
FORMAT="txt"
AUDIO=""
USE_JARGON=true
OUTDIR="/tmp/whisper-out"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)      MODEL="$2"; shift 2 ;;
    --lang)       LANG="$2"; shift 2 ;;
    --clipboard)  CLIPBOARD=true; shift ;;
    --srt)        FORMAT="srt"; shift ;;
    --no-jargon)  USE_JARGON=false; shift ;;
    -*)           echo "Unknown flag: $1" >&2; exit 1 ;;
    *)            AUDIO="$1"; shift ;;
  esac
done

if [[ -z "$AUDIO" ]]; then
  echo "Usage: bash transcribe.sh <audio_file> [--model MODEL] [--lang LANG] [--clipboard] [--srt] [--no-jargon]" >&2
  exit 1
fi

if [[ ! -f "$AUDIO" ]]; then
  echo "Error: File not found: $AUDIO" >&2
  exit 1
fi

JARGON_ARGS=()
if $USE_JARGON && [[ -f "$JARGON_FILE" ]]; then
  JARGON_ARGS=(--initial_prompt "$(cat "$JARGON_FILE")")
fi

source ~/whisper-env/bin/activate

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

whisper "$AUDIO" --model "$MODEL" --language "$LANG" \
  --output_dir "$OUTDIR" --output_format "$FORMAT" \
  "${JARGON_ARGS[@]}" 2>&1

echo ""
echo "--- Transcript ---"
cat "$OUTDIR"/*."$FORMAT"

if $CLIPBOARD; then
  cat "$OUTDIR"/*."$FORMAT" | pbcopy
  echo ""
  echo "(Copied to clipboard)"
fi
