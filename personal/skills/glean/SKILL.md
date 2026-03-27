---
name: glean
description: Query Glean AI chat to search company knowledge, policies, docs, and internal systems. Use when the user asks to search Glean, look up internal docs, find company information, ask Glean a question, or references app.glean.com.
---

# Glean Chat Skill

Query your company's knowledge base via [Glean AI chat](https://app.glean.com/chat) from the terminal.

## Prerequisites

Before running any command, verify auth: `uv run glean-cli.py auth status`.
If not authenticated, **STOP** and run `uv run glean-cli.py auth setup`. See [SETUP.md](SETUP.md).

## Quick Reference

All commands output JSON. Run from `{{SKILL_DIR}}`:

```bash
uv run glean-cli.py <command> [options]
```

## Ask a Question

```bash
uv run glean-cli.py ask "What is our PTO policy?"
uv run glean-cli.py ask "How do I set up VPN access?" --agent-id <agent-id>
```

Returns JSON with `answer`, `chat_id`, and `citations` (source docs with titles/URLs).

### Continue a Conversation

Pass `--chat-id` from a previous response to maintain context:

```bash
uv run glean-cli.py ask "Tell me more about the exceptions" --chat-id <chat-id>
```

### Stream a Response

For long answers, stream chunks in real-time (not JSON — raw text):

```bash
uv run glean-cli.py stream "Summarize our Q4 OKRs"
```

## Conversation History

```bash
uv run glean-cli.py history --limit 10
uv run glean-cli.py get <chat-id>
```

## Workflow Patterns

### Research a Topic

1. Ask an initial question: `uv run glean-cli.py ask "What is our deploy process?"`
2. Note the `chat_id` in the response
3. Ask follow-ups: `uv run glean-cli.py ask "Which teams own the CI pipeline?" --chat-id <id>`
4. Review citations to find source documents

### Find a Document

Ask Glean to locate specific docs:

```bash
uv run glean-cli.py ask "Where is the engineering onboarding guide?"
```

Citations in the response link to the actual documents.

### Answer from Company Context

When the user asks something that likely lives in internal docs (HR policies, team processes, architecture decisions, go/ links, Confluence pages, etc.), use this skill to query Glean before searching externally.

## Troubleshooting

| Error | Solution |
|-------|----------|
| "GLEAN_API_TOKEN not set" | Run `uv run glean-cli.py auth setup` |
| 401 Unauthorized | Token expired or missing CHAT scope — regenerate in Glean Admin |
| Connection error | Check GLEAN_SERVER_URL format (`https://<company>-be.glean.com`) |

Auth check: `uv run glean-cli.py auth status`
