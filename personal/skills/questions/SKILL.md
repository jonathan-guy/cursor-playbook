---
name: questions
description: Pause and ask clarifying questions before acting on a request. Use when the user invokes /questions, asks you to ask clarifying questions, or when a request is ambiguous and would benefit from scoping before implementation.
---

# Clarifying Questions

Before taking any action on the user's request, analyze it for gaps and ask clarifying questions.

## Process

1. **Analyze the request** -- identify scope ambiguity, unstated assumptions, missing constraints, and multiple valid interpretations. Do not start implementing.
2. **Formulate 2-4 focused questions** that would most reduce uncertainty. Prioritize questions where the answer changes what you'd build.
3. **Ask using the AskQuestion tool** with structured multiple-choice options when the set of reasonable answers is small and known. Fall back to conversational questions when the answer space is open-ended.
4. **Batch questions into one message** -- don't drip-feed them one at a time.
5. **After receiving answers**, restate your understanding of the task in one or two sentences and proceed.

## What to Look For

- **Scope**: Is the request scoped to one file, one feature, or the whole project?
- **Ambiguous references**: Does "it", "the component", or "the bug" refer to something specific?
- **Unstated constraints**: Are there performance, compatibility, or style requirements not mentioned?
- **Multiple valid approaches**: Could this be done in meaningfully different ways that the user should choose between?
- **Side effects**: Will this change break other things or require coordinated updates?
- **Acceptance criteria**: How will the user know the task is done correctly?

## When to Skip

If the request is completely unambiguous and you have everything you need, say so briefly and proceed. Don't ask questions for the sake of asking.
