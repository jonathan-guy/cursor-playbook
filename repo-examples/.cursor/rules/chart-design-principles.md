---
description: Chart design principles — auto-injected when creating or modifying chart renderers
globs: reports/**/generate.py, reports/**/renderer.py, src/charts/**, lib/charts.js
---

# Chart Design Principles

When creating or modifying any chart, apply these principles. They prioritize data honesty and readability over visual flair.

## Match chart type to data nature

Use **bars** for discrete time buckets (daily observations) — each bar stands alone and there is no interpolation between missing days. Use **area** or **line** for continuous or smoothed series (weekly/monthly aggregations) where visual continuity communicates trend.

In practice, for dashboards with a timeframe toggle: render stacked **bars** at daily granularity (7d, 30d) and stacked **area** at weekly granularity (60d, 90d).

## Show volume alongside percentages

Percentage charts without volume context hide low-sample-size noise. A day with 1 item that was "100% Resolved" tells a very different story than a day with 40 items at 20% Resolved.

Add a compact **volume strip** — a thin bar chart (~50–60px tall, muted gray, no axis labels) beneath any percentage-based time series. The strip shows raw counts per bucket. Tooltips on hover provide the exact number.

## Dynamic granularity

When a dashboard supports multiple timeframes, switch the time bucketing to match the window. Daily buckets for short windows (7d, 30d) show day-to-day variance. Weekly buckets for longer windows (60d, 90d) smooth out noise and show trend.

Update chart titles dynamically to reflect the active granularity ("Daily Outcome Trend" vs "Weekly Outcome Trend").

## Trailing averages only when meaningful

Add rolling averages only when the window has enough data points (typically 30+ daily observations). For short windows or already-smoothed weekly data, trailing averages add noise without insight.

When shown, use subtle visual treatment: thin dashed lines (`borderDash: [3,3]`, `borderWidth: 1.5`, no points). The trailing average must be visually subordinate to the primary data.

## Consolidate over clutter

Prefer one rich chart (composition fill + volume strip) over two or three partial charts. Before adding a new chart, check if the information can be encoded into an existing chart as a secondary element.

## Stacked fills sum to 100%

For categorical breakdowns over time, use stacked fills that visually sum to 100%. This makes proportion shifts immediately visible without mental arithmetic.

## Color and opacity

Primary fills use semi-transparent palette colors (0.5–0.7 alpha). Borders use the full-opacity version. Trailing averages and secondary elements use lower opacity or dashed treatment.

## Timeframe toggle conventions

When a report has enough historical data, provide a pill-button timeframe toggle. Use **day-based labels** (`7d / 30d / 60d / 90d`) when the underlying data is daily. Use **week-based labels** (`4w / 8w / 13w / 26w`) when the data is weekly.
