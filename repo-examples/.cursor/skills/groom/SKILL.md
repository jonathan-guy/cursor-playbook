---
name: groom
description: Groom the velocity dashboard backlog — scan for stale items, graduate done work, re-tier, renumber, and keep the roadmap clean. Use when the user invokes /groom, asks to groom the backlog, clean up the roadmap, or review backlog health.
---

# Backlog Grooming

Read the prioritized backlog in `thoughts/shared/plans/003_dashboard_roadmap.md` and interactively clean it up.

## When to Run

- On demand when the user invokes `/groom`
- As a lightweight health scan during nightagent briefing (Step 1.5 — see nightagent-brief skill)

## Backlog Location

The backlog lives in `thoughts/shared/plans/003_dashboard_roadmap.md` under `### Prioritized backlog`. Graduated items go into `## What's Already Been Done`.

## Item Format

Every backlog item must follow this template:

```
N. `[status]` `[WSn]` **Short title** — 1-2 sentence description. No implementation details.
```

Status tags: `[in progress]`, `[not started]`, `[blocked]`, `[deferred]`.

Implementation details belong in workstream sections of the roadmap or in dedicated plan docs, not in the backlog line item.

## Tier Criteria

- **Tier 1** (~7 items): Actively worked or next up. Ships a user-visible metric or feature.
- **Tier 2** (~10 items): Important, unblocked, ready when Tier 1 frees up. May be infra or research.
- **Tier 3** (no limit): Nice to have, exploratory, or depends on higher-tier work.
- **Blocked**: External dependency. Each item names the blocker.
- **Deferred**: Intentionally parked. Brief reason why.

## Step 1: Read and Summarize

Read the backlog section. Present a compact summary table:

```
| #  | Title                        | Status       | Tier |
|----|------------------------------|--------------|------|
| 1  | FinPlat org segmentation     | not started  | 1    |
| 2  | Features Shipped / week      | not started  | 1    |
| ...                                                     |
```

## Step 2: Flag Issues

Scan for and report items in these categories:

### Graduate
Items marked `[done]` still in the backlog. Should be moved to "What's Already Been Done" with a 1-line summary in the appropriate subsection (Dashboard frontend, Data pipeline, Query standardization, Shared infrastructure, Reports, Research and discovery).

### Stale
Items marked `[in progress]` with no recent git activity in related files or branches. Check with:
```bash
git log --since="2 weeks ago" --all --oneline -- <relevant files or paths>
```

Also flag items with outdated references (deleted plan files, renamed branches, stale sprint labels).

### Re-tier
Items whose priority may have shifted:
- Tier 1 items sitting `[not started]` for 2+ weeks
- Tier 2/3 items that are now more urgent due to stakeholder requests or unblocked dependencies
- Items whose scope or effort changed significantly

### Merge/Split
- Sub-tasks that should be bullet points inside a parent item (not separate backlog entries)
- Items that are too broad and should be split into distinct deliverables

## Step 3: Ask for Decisions

Use the AskQuestion tool to present flagged items. Group by category. For each flag, propose a specific action (graduate to section X, demote to Tier 3, merge into #N, etc.) and let the user approve, reject, or modify.

## Step 4: Apply Changes

After the user approves:

1. Graduate done items (move to "What's Already Been Done", add 1-line bullet)
2. Apply tier changes
3. Renumber sequentially 1-N with no gaps
4. Update any cross-references in other items (e.g., "depends on #N")
5. Update the "Last groomed" date in the backlog header
6. Update the Appendix (Delta-V metrics) if backlog numbers changed

## Step 5: Regenerate Signal Deck

If any backlog content changed:

```bash
just generate-report roadmap_view
```

The Signal Deck's Backlog tab is rendered from the roadmap markdown.

## Quick Operations

These can be invoked directly without a full groom cycle:

### Add Item
"Add to backlog: [description]"
1. Assign the next sequential number
2. Ask which tier and workstream tag (AskQuestion)
3. Write in the normalized 1-2 sentence format
4. Confirm placement

### Close Item
"Close backlog #N" or "mark #N done"
1. Move to the appropriate "What's Already Been Done" subsection
2. Renumber remaining items
3. Update cross-references (other items that say "depends on #N")
4. Update Appendix if the item was referenced there

### Promote/Demote
"Promote #N to Tier 1" or "Demote #N to Tier 3"
1. Move the item to the target tier section
2. Renumber sequentially within the tier

## Nightwatch Integration

On Wednesday nights, nightwatch runs a read-only backlog health scan (Step 7) and writes findings to `reports/dashboard_validation/output/.nightwatch-backlog-health.json`. The Thursday morning Slack DM includes the suggestions with a CTA to run `/groom` in Cursor.

### Entry modes

**From nightwatch (preferred on Thursdays):** If `.nightwatch-backlog-health.json` exists and is < 24 hours old, pre-load its suggestions. Skip the scan and go straight to Step 3 (Ask for Decisions) with the pre-loaded suggestions. The user confirms which actions to apply.

**Fresh scan (default):** If the file is missing or stale (> 24h), run the full Steps 1-2 scan.

To check freshness:
```bash
# File age in hours
python3 -c "
import json, datetime as dt
from pathlib import Path
f = Path('reports/dashboard_validation/output/.nightwatch-backlog-health.json')
if f.exists():
    d = json.loads(f.read_text())
    gen = dt.datetime.fromisoformat(d['generated_at'])
    age_h = (dt.datetime.now(dt.timezone.utc) - gen).total_seconds() / 3600
    print(f'Age: {age_h:.1f}h — {\"fresh\" if age_h < 24 else \"stale\"}'  )
else:
    print('Not found — run fresh scan')
"
```

### JSON format

The nightwatch scan writes this structure (the groom skill reads it):

```json
{
  "generated_at": "ISO8601 with timezone",
  "total_items": 33,
  "last_groomed": "March 2026",
  "suggestions": [
    {
      "type": "graduate | stale | cold_tier1 | format_drift | unblocked",
      "item_num": 3,
      "title": "Headless Goose PRs chart",
      "detail": "Why this was flagged",
      "action": "Concrete suggested action"
    }
  ],
  "summary": "Human-readable summary line"
}
```

## Critical Rules

1. **Never change item scope during grooming.** Grooming is about organizing, not redefining what work means. If scope needs to change, flag it for the user.
2. **Keep descriptions to 1-2 sentences.** If an item's description exceeds this, trim it and note where the detail lives (workstream section, plan doc).
3. **Renumber after every structural change.** No gaps, no letter suffixes, sequential 1-N.
4. **Update "Last groomed" date** in the backlog header after every groom session.
5. **Regenerate Signal Deck** after content changes to keep the published view in sync.
