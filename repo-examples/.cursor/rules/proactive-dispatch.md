---
alwaysApply: true
description: Throughout every session, identify tasks that should run on a cloud workstation instead of locally
---

# Proactive Cloud Dispatch

Throughout every session, actively identify tasks that should run on a cloud workstation instead of locally. This is a continuous habit, not a one-time check.

## When to Suggest Dispatch

**Suggest immediately** for these task types — they should never block the local terminal:

- End-to-end dashboard refresh
- Full analysis pipeline runs
- Multi-report generation and deployment
- Data syncs that take > 2 minutes

**Suggest when you spot** a clearly scoped, self-contained task during implementation:

- Touches 1–3 files with clear acceptance criteria
- No product/design judgment required — the implementation is mechanical once specified
- Examples: CSS/styling fixes, wiring existing data into a new view, adding validation checks

**Phrasing**: "This is a good nightagent candidate. Want me to dispatch it now, or keep working on it here?"

## When NOT to Suggest

- Quick edits (< 5 min, fewer than 3 changes)
- Deploy-only operations (fast local uploads)
- Tasks requiring interactive feedback or user review mid-implementation
- Exploratory work where the approach isn't settled yet

## Interaction Rules

- **Don't interrupt flow.** If the user is deep in implementation, note the candidate briefly and move on.
- **One suggestion at a time.** Don't batch multiple dispatch suggestions.
- **Respect "no".** If the user declines dispatch, don't re-suggest the same task.
- **Default to cloud for heavy ops.** When the user asks for an end-to-end refresh or analysis pipeline, default to suggesting cloud dispatch.
