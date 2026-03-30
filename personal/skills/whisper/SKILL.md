---
name: whisper
description: Transcribe audio files to text using OpenAI Whisper. Use when the user invokes /whisper, asks to transcribe audio, convert speech to text, or process voice recordings.
---

# Whisper Voice-to-Text

Transcribe audio files using the locally installed OpenAI Whisper (`~/whisper-env`).
All scripts auto-load domain jargon from `~/.cursor/skills/whisper/jargon.txt` via `--initial_prompt`.

## Scripts

| Script | Purpose | Shortcut |
|--------|---------|----------|
| `dictate.sh` | Live mic → clipboard → paste into chat | `Cmd+Shift+D` |
| `dictate-fix.sh` | Live mic → append to `.nightagent-quick-fixes.md` | `Cmd+Shift+F` |
| `voice-agent.sh` | Conversational loop: speak → Claude responds aloud | -- |
| `instruct.sh` | Voice memo file → clipboard instruction | -- |
| `transcribe.sh` | Audio file → transcript (txt/srt) | -- |
| `update_jargon.sh` | Auto-update jargon from project catalogs | -- |

All scripts live in `~/.cursor/skills/whisper/scripts/`.

## 1. Live Dictation (Cmd+Shift+D)

Keybinding is set in Cursor. Requires terminal to be visible.

1. Press `Cmd+Shift+D`
2. Speak into mic (pauses are fine — take your time)
3. Press `Enter` when done
4. Text is transcribed and copied to clipboard
5. Auto-pasted into Cursor chat

Options: `bash dictate.sh --model small` (faster model), `bash dictate.sh --no-jargon`

## 1b. Quick Fix Dictation (Cmd+Shift+F)

Queue a nightagent task by voice — no file editing needed.

1. Press `Cmd+Shift+F`
2. Speak your fix ("Signal Deck make all tab font sizes 14px")
3. Press `Enter` when done
4. Transcript is appended to `.nightagent-quick-fixes.md`
5. Nightagent picks it up at the 3 PM briefing

## 1c. Voice Agent (Conversational)

Talk to Claude hands-free in a loop — for driving, walking, or thinking out loud. Whisper transcribes
your speech, Claude responds via the Anthropic API, and macOS TTS reads the response aloud.

```bash
bash ~/.cursor/skills/whisper/scripts/voice-agent.sh
```

1. Speak into mic, press `Enter` when done
2. Whisper transcribes, Claude thinks, TTS reads the response
3. Repeat — conversation history is maintained across turns
4. Say "goodbye" or press `Ctrl+C` to exit

Options:
- `--voice Samantha` (default) — change TTS voice (try `Reed`, `Flo`, `Shelley`)
- `--reset` — clear conversation history and start fresh
- `--no-jargon` — skip domain jargon priming

Conversation history is saved to `/tmp/voice-agent-history.json` between sessions.

**Dependencies:** `anthropic` Python package (installed in `~/whisper-env`).

## 2. Voice Memo → Instruction

For longer/rambling thoughts recorded as voice memos:

```bash
bash ~/.cursor/skills/whisper/scripts/instruct.sh ~/voice-memo.m4a
```

Transcribes with `turbo` model, copies to clipboard. Paste into Cursor chat.

## 3. File Transcription

```bash
bash ~/.cursor/skills/whisper/scripts/transcribe.sh ~/recording.mp3
# Options: --model small  --lang en  --clipboard  --srt  --no-jargon
```

## Jargon Priming

Domain terms are stored in `~/.cursor/skills/whisper/jargon.txt`. This file is automatically
passed as `--initial_prompt` to every transcription, improving accuracy for project-specific
vocabulary.

To update jargon manually: edit `~/.cursor/skills/whisper/jargon.txt` directly.
To auto-update from project catalogs: `bash ~/.cursor/skills/whisper/scripts/update_jargon.sh`
To skip jargon for a run: add `--no-jargon` to any script.

## Quick Transcribe (inline)

```bash
source ~/whisper-env/bin/activate && whisper "$AUDIO_FILE" \
  --model turbo --language en --output_dir /tmp/whisper-out \
  --output_format txt --initial_prompt "$(cat ~/.cursor/skills/whisper/jargon.txt)" 2>&1
cat /tmp/whisper-out/*.txt
```

## Model Selection

| Model | Speed | Quality | Use when |
|-------|-------|---------|----------|
| `turbo` | Fast | High | Default for live dictation and file transcription |
| `small` | Faster | Good | Short clips, quick notes |
| `medium` | Moderate | Better | Accented speech, important recordings |
| `large-v3` | Slow | Best | Noisy audio, maximum accuracy |
| `tiny` | Fastest | Fair | Bulk batch jobs |

## Python API

```python
import whisper
model = whisper.load_model("turbo")
result = model.transcribe("audio.mp3",
    initial_prompt=open("jargon.txt").read())
text = result["text"]
segments = result["segments"]  # list of {start, end, text}
```

## Useful Flags

| Flag | Effect |
|------|--------|
| `--language en` | Skip language detection (faster) |
| `--initial_prompt "..."` | Prime with context (auto-loaded from jargon.txt) |
| `--word_timestamps True` | Per-word timing in JSON output |
| `--condition_on_previous_text False` | Reduce hallucination on long audio |
| `--hallucination_silence_threshold 1` | Skip silent segments that cause hallucinated text |

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `whisper: command not found` | `source ~/whisper-env/bin/activate` |
| `rec: command not found` | `brew install sox` |
| FP16 warning on CPU | Normal; auto-falls back to FP32 |
| Hallucinated repeated text | Add `--condition_on_previous_text False` |
| Wrong language detected | Set `--language en` explicitly |
| Slow on large files | Use `small` model or split with `ffmpeg -ss START -to END` |
| Upgrade Whisper | `source ~/whisper-env/bin/activate && pip install -U openai-whisper` |
