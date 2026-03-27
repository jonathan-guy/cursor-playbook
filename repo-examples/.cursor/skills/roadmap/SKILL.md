---
name: roadmap
description: Add, update, or remove known bugs and backlog items in the dashboard roadmap. Use when the user invokes /roadmap, mentions a bug to track, wants to add/update/remove a backlog item, or references the roadmap's known risks or prioritized backlog.
---

# Roadmap — Bug & Backlog Management

Add, update, or remove entries in the **Known Risks and Inconsistencies** (bugs) or **Prioritized backlog** sections of the dashboard roadmap.

**Target file:** `thoughts/shared/plans/003_dashboard_roadmap.md`

## Step 1: Read the roadmap and detect intent

Read `thoughts/shared/plans/003_dashboard_roadmap.md`. From the user's message, determine:

1. **Section** — bug (Known Risks) or backlog (Prioritized backlog). Ask if ambiguous.
2. **Operation** — add, update, or remove. Ask if ambiguous.

## Step 2: Locate the relevant section

- **Bugs** live under `## Known Risks and Inconsistencies` with four `###` subsections:
  - `### Data Accuracy` — data staleness, upstream ETL, population scoping
  - `### Metric Integrity` — calculation errors, inconsistent aggregation
  - `### Query & Backend` — SQL issues, sync pipeline, connections
  - `### Dashboard UI` — rendering, layout, visual glitches

- **Backlog** lives under `### Prioritized backlog` (inside `## What's Next`) with bold-text tier groups:
  - `**Tier 1 — Top priority**`
  - `**Tier 2 — Important**`
  - `**Tier 3 — Lower priority**`
  - `**Blocked:**` and `**Deferred:**` (plain bullet lists)

## Step 3: Check for duplicates / locate existing entry

Scan the target section for an entry that is substantively equivalent (same underlying issue or feature, even if worded differently).

- **Add**: if a duplicate exists, tell the user and stop. Quote the existing entry.
- **Update / Remove**: if no match is found, tell the user. For updates, offer to add instead.

## Step 4: Make the edit

### Bug entries

Format: `- **Short label** — Description of the issue.`

- **Add**: infer the correct `###` subsection from context. Append the new bullet at the end of that subsection.
- **Update**: edit the matching bullet in place, preserving the `**label** — description` format.
- **Remove**: confirm with the user by showing the entry, then delete the bullet line.

### Backlog entries

Format: `N. \`[status]\` \`[WSn]\` **Title** — Description.`

Statuses: `[not started]`, `[in progress]`, `[blocked]`, `[done]`, `[deferred]`.
Workstream tags: `[WS1]`–`[WS7]` (omit if the item doesn't clearly map to one).

- **Add**: infer tier and status from context (default: Tier 3, `[not started]`). Infer workstream tag if obvious. Append at the end of the tier group with the next sequential number.
- **Update**: edit in place. If the tier changes, move the entry to the new tier group. Renumber both the source and destination tier groups.
- **Remove**: confirm with the user by showing the entry, then delete. Renumber the tier group.

Blocked/deferred items use plain bullets (no numbers):
`- \`[blocked]\` \`[WS4]\` **Title** — Description.`

## Step 5: Show the result

After editing, show the user:
1. The added/changed/removed line(s) with surrounding context.
2. The line number in the file.

## Step 6: Regenerate and deploy the roadmap view

```bash
cd /Users/jguy/velocity-reporting && \
  uv run python -m reports.roadmap_view.generate 2>&1 && \
  just publish-report roadmap_view 2>&1
```

Confirm success by checking for exit code 0 and reporting the published URL:
`https://blockcell.sqprod.co/sites/signal-deck/`

Do **not** commit. Leave changes uncommitted for the user to review.
