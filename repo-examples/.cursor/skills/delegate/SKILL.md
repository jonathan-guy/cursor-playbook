---
name: delegate
description: Convert an in-session idea or plan into a nightagent task spec, then either dispatch immediately to a cloud workstation or queue for tonight's NightShift.
---

# Delegate to Nightagent

Converts a freeform task description into a properly-formatted nightagent task spec mid-session. Supports **immediate dispatch** to a cloud workstation or **overnight queuing**.

## When to Run

- On demand when the user invokes `/delegate`
- When the user says "hand this off to nightagent" or "dispatch this"
- When the proactive dispatch rule suggests a task and the user agrees

## Step 1: Gather Context

Collect information to write a high-quality spec. Run these in parallel:

```bash
git diff --stat
git diff --name-only
git rev-parse --abbrev-ref HEAD
cat .nightagent-requests.md 2>/dev/null || echo "(no file)"
```

Also consider what the user just described or was working on.

## Step 2: Generate Task Spec

Build the spec with all required fields.

### Auto-Infer Credential Tier

| Target files contain | Tier |
|---|---|
| `queries/*.sql`, `sync_metrics.py` | `snowflake` |
| `reports/*/generate.py` (no data fetch) | `none` |
| `lib/`, `src/`, CSS/HTML only | `none` |
| Slack integration scripts | `slack` |
| `analysis/*/run.py` (needs data warehouse) | `snowflake` |

### Auto-Classify Mode

| Signal | Mode |
|---|---|
| Task is "run X, copy Y, deploy Z" | `scripted` |
| Task requires writing/refactoring code | `agent` |
| Task says "research", "investigate" | `agent` (read-only) |

### Write Verify Commands

Every spec needs verify commands:

- **Code change exists**: `rg 'pattern' path/to/file.py`
- **File was created**: `test -f path/to/output.html`
- **Report generates**: `just generate-report <name>`
- **Quality gates**: `just check`

## Step 3: Present for Approval

Show the spec to the user. Then ask using AskQuestion:

- `approve` — "Write it — looks good"
- `edit` — "I want to tweak it first"
- `cancel` — "Never mind"

## Step 3.5: Dispatch Timing

After approval, ask:

- `now` — "Dispatch now (creates a cloud task immediately)"
- `tonight` — "Queue for tonight's NightShift"

Default: **now** for tasks during working hours, **tonight** for afternoon briefing items.

## Step 4: Write to .nightagent-requests.md

### File Format

```markdown
<!-- nightagent briefing output -- YYYY-MM-DD H:MM PM -->
<!-- briefing_completed: true -->

## Tasks

### 1. Title (full-write|read-only, scripted|agent)

Description.

**credential_tier:** none|github|slack|snowflake|full

**Context:** Background the agent needs.

**Target files:**
- `path/to/file.py` — what to change

**Reference files:**
- `path/to/reference.py` — pattern to follow

**Steps:**
1. Concrete step
2. Another step

**Verify:**
- name: "Check description"
  run: rg 'pattern' path/to/file.py

**Acceptance criteria:**
- What done looks like

## Config
- max_items: 1
- briefing_completed: true
```

### Freshness Check

- **Same day**: append after existing tasks.
- **Different day**: create fresh.

## Step 5: Validate

Run the dry-run validator (`just nightagent-dry-run`). Report the grade. If below B, suggest improvements.

## Step 6: Dispatch or Confirm

**If "Dispatch now"**: Run `just dispatch`, capture the task key, report the dispatch URL, and poll for completion.

**If "Queue for tonight"**: Confirm with the user that the task is queued for the NightShift.

## Critical Rules

1. **Always get approval before writing.** Never write the file without confirmation.
2. **Never execute the task directly.** Dispatch goes through the cloud API.
3. **Max 8 total items.** If appending would exceed 8, ask which to drop.
4. **Assign the lowest credential tier** that covers the task.
5. **Never modify source code.** Only write to `.nightagent-requests.md`.
