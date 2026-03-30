#!/usr/bin/env bash
set -euo pipefail

# Conversational voice agent: Whisper STT → Claude API → macOS TTS.
# Runs in a terminal loop. Say "goodbye" or press Ctrl+C to exit.
#
# Usage: bash voice-agent.sh [--model MODEL] [--no-jargon] [--voice VOICE] [--reset]

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
JARGON_FILE="$SKILL_DIR/jargon.txt"
MODEL="turbo"
USE_JARGON=true
VOICE="Samantha"
RECORDING="/tmp/voice-agent-recording.wav"
OUTDIR="/tmp/voice-agent-out"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)      MODEL="$2"; shift 2 ;;
    --no-jargon)  USE_JARGON=false; shift ;;
    --voice)      VOICE="$2"; shift 2 ;;
    --reset)
      python "$SCRIPT_DIR/voice_agent_api.py" --reset
      echo "Starting fresh conversation."
      shift ;;
    *)            shift ;;
  esac
done

JARGON_ARGS=()
if $USE_JARGON && [[ -f "$JARGON_FILE" ]]; then
  JARGON_ARGS=(--initial_prompt "$(cat "$JARGON_FILE")")
fi

source ~/whisper-env/bin/activate

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME")"
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  source "$REPO_ROOT/.env" 2>/dev/null || true
  set +a
fi

cleanup() {
  [[ -n "${REC_PID:-}" ]] && kill "$REC_PID" 2>/dev/null || true
}
trap cleanup EXIT

echo ""
echo "=== Voice Agent ==="
echo "Whisper: $MODEL | Voice: $VOICE | Jargon: $USE_JARGON"
echo "Speak, then press ENTER. Say \"goodbye\" to exit."
echo ""

while true; do
  echo "---"
  echo "Listening... (press ENTER when done)"

  rec -q -r 16000 -c 1 -b 16 "$RECORDING" &
  REC_PID=$!

  read -r -s
  kill "$REC_PID" 2>/dev/null || true
  wait "$REC_PID" 2>/dev/null || true
  unset REC_PID

  echo "Transcribing..."

  rm -rf "$OUTDIR"
  mkdir -p "$OUTDIR"

  whisper "$RECORDING" \
    --model "$MODEL" \
    --language en \
    --output_dir "$OUTDIR" \
    --output_format txt \
    --condition_on_previous_text False \
    "${JARGON_ARGS[@]}" 2>&1 | grep -v "^$"

  TRANSCRIPT=$(cat "$OUTDIR"/*.txt 2>/dev/null | sed 's/^[[:space:]]*//')

  if [[ -z "$TRANSCRIPT" ]]; then
    echo "(No speech detected — try again)"
    continue
  fi

  echo ""
  echo "You: $TRANSCRIPT"
  echo ""

  if echo "$TRANSCRIPT" | grep -iq "goodbye\|good bye\|bye bye"; then
    say -v "$VOICE" "Goodbye! Talk to you later."
    echo "Claude: Goodbye! Talk to you later."
    break
  fi

  echo "Thinking..."
  RESPONSE=$(python "$SCRIPT_DIR/voice_agent_api.py" "$TRANSCRIPT" 2>&1)

  echo "Claude: $RESPONSE"
  echo ""

  say -v "$VOICE" "$RESPONSE" &
  SAY_PID=$!

  wait "$SAY_PID" 2>/dev/null || true
done

echo ""
echo "=== Session ended ==="
echo "History saved to /tmp/voice-agent-history.json"
