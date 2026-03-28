---
name: promote-metric
description: Promote a validated metric to a published output (executive dashboard, deep-dive report, Signal Deck, etc.). Provides the implementation checklist for wiring into the target output. Use when the user invokes /promote-metric, asks to promote a metric, add a metric to the dashboard, or surface a validated metric.
---

# Promote Metric Workflow

Moves a metric from `validated` to `promoted` status by wiring it into one or more published outputs. This skill assumes the metric has already been vetted via the `/new-metric` skill.

## Pre-Flight

### Step 1: Find the metric in the catalog

Search `catalog/metrics.yaml` for the metric by name or ID.

- If the metric is at `promoted` status and the user wants to add it to an **additional** output, proceed to Step 3 (the metric is already validated).
- If the metric is at `validated` status, proceed to Step 2.
- If the metric is at `onboarded` status, it needs validation first. Ask the user: "This metric hasn't been validated yet. Should I run the validation checks first, or proceed with promotion anyway?"
- If the metric is at `discovered` status or not found, redirect to `/new-metric`.

### Step 2: Confirm readiness

Present the metric's catalog entry to the user:

- Name, definition, source, query path
- Current status and any existing promotions
- Quality check results (if available from nightwatch)
- Any notes or caveats

Ask: **"Ready to promote this metric?"**

### Step 3: Choose target output(s)

Use AskQuestion with multi-select (`allow_multiple: true`):

**Prompt:** "Which output(s) should this metric appear in?"

| Option | Description |
|--------|-------------|
| `executive-dashboard-card` | Stat card on Rachel's dashboard (sparkline + trend delta) |
| `executive-dashboard-chart` | Time-series or distribution chart in a dashboard tab |
| `exec-summary` | Inline chart or callout in Weekly Highlights |
| `unified-segmentation` | Segmentation deep-dive with brand/org/discipline slicing |
| `standalone-report` | New or existing deep-dive report |
| `signal-deck` | Metric catalog or reference on Signal Deck |
| `org-lead-reports` | Per-leader org-level view |

### Step 4: Implementation checklist

Based on the target(s) chosen, present the appropriate checklist.

**For stat cards on the executive dashboard:**

1. Ensure the metric data exists in `dx-weekly-metrics.jsonc` → `weekly.rows[]`
   - If not: add a fetch function in `sync_metrics.py`, register the stem, run sync
2. Add entry to `metricMetadata.weekly` in the JSONC with a `card` block:
   - `section`, `label`, `format`, `colorLogic`, `order`, `tooltip`
3. Run `just bundle && just build && just test`

**For charts on the executive dashboard:**

Follow the full "Adding a New Dashboard Chart" checklist from `AGENTS.md`:
1. SQL query → `queries/<name>.sql`
2. Fetch function → `sync_metrics.py`
3. Build passthrough → `build.py`
4. TypeScript renderer → `src/charts/<name>.ts`
5. Wire in → `src/main.ts`
6. HTML container → `dx-executive-dashboard.html`
7. Run `just bundle && just build && just test`

**For unified segmentation:**

1. Add a `MetricDef` entry to `reports/unified_segmentation/metric_registry.py`
2. Write or extend the source SQL with segmentation dimensions
3. Run `just generate-report unified_segmentation`

**For standalone reports:**

1. Create `reports/<name>/__init__.py` and `reports/<name>/generate.py`
2. Use `lib.connections` for DB, `lib.html` for rendering
3. Follow `docs/style-guide.md` for visual patterns
4. Run `just generate-report <name>`

**For exec summary:**

1. Add the chart key to `.cursor/rules/chart-keys.md`
2. Wire the data in `build.py`'s exec summary chart builder
3. Run `just build && just test`

### Step 5: Update the catalog

After implementation is complete, update `catalog/metrics.yaml`:

1. Set `status: promoted`
2. Add the target output ID(s) to `promoted_to[]`
3. Add relevant quality checks to `quality_checks[]`

### Step 6: Update related docs

- If this is a new dashboard card: update `.cursor/rules/pipeline-map.md` and `.cursor/rules/chart-data-dictionary.md`
- If this adds to a report: update `artifacts.yaml` if the report isn't already listed
- Confirm the metric appears correctly in Signal Deck's Metric Catalog tab

## Critical Rules

1. **Never skip the catalog update.** The catalog must reflect reality.
2. **Always run quality gates** after wiring: `just lint && just build && just test`.
3. **Follow the style guide.** All new charts and cards must use `lib/tokens.json` colors and `lib/charts.js` helpers.
4. **Data quality first.** If the metric's data shows anomalies during promotion, stop and investigate before publishing.
5. **Document methodology.** Any new dashboard card needs a tooltip with query path and calculation logic.
