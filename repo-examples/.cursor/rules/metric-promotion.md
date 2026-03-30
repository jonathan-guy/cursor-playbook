---
description: Metric promotion lifecycle — governs how metrics flow from discovery to published outputs
globs: catalog/**, sync_metrics.py, build.py, reports/**/generate.py
---

# Metric Promotion Lifecycle

Every metric in this repo follows a 4-stage lifecycle. The canonical registry is `catalog/metrics.yaml`.

## Stages

### 1. Discovered

A signal or data source has been identified as potentially useful. It may come from:
- Snowflake catalog scans (automated discovery)
- Brainstorming sessions
- Stakeholder requests
- Upstream ETL changes

**What exists:** A row in `catalog/metrics.yaml` with `status: discovered`. No query, no data.

### 2. Onboarded

The metric has been defined, its source validated, and a query written. The `/new-metric` skill handles this.

**What exists:** A catalog entry with `status: onboarded`, a SQL query in `queries/`, and a metric spec document in `thoughts/shared/research/`.

### 3. Validated

The metric has been backfilled, quality-checked, and reviewed. It is queryable and its data can be cached in `data/catalog_cache/` for ad-hoc analysis.

**What exists:** Everything from onboarded, plus cached data and passing quality checks. The metric is usable for analysis but does not appear in any published output.

### 4. Promoted

The metric appears in one or more published outputs (executive dashboard, deep-dive report, Signal Deck, etc.). The `promoted_to` field in the catalog lists which outputs include it.

**What exists:** Full pipeline wiring — sync, build, render, and test coverage for the target output(s).

## Rules

1. **No metric reaches a published output without passing through `validated`.** Even simple metrics need a quality check before stakeholders see them.
2. **Promotion is an explicit decision.** Use the `/promote-metric` skill to move a metric from validated to promoted. This ensures the right implementation checklist is followed.
3. **Analysis-only is a first-class status.** A metric at `validated` that is not promoted is still valuable — it's queryable, documented, and available for ad-hoc analysis.
4. **Demotion is allowed.** If a metric is removed from a published output, update its `promoted_to` list. If removed from all outputs, set status back to `validated`.
5. **The catalog is the source of truth.** When adding, promoting, or removing a metric, update `catalog/metrics.yaml` first.

## Catalog Schema

```yaml
- id: metric_snake_case_id
  name: "Human Readable Name"
  status: discovered | onboarded | validated | promoted
  bucket: delivery | drag | ai_maturity | bumper_rails
  source: snowflake | getdx | github_api | sheets | cross_source | blockcell
  query: queries/file_name.sql        # null for discovered
  promoted_to: []                      # list of output IDs from artifacts.yaml
  owner: yourname
  direction: higher | lower | neutral
  grain: weekly | daily | monthly
  entity: per_engineer | per_service | per_team | aggregate
  quality_checks: []                   # list of nightwatch check categories
  notes: ""                            # methodology notes, caveats
```

## Relationship to Existing Tools

- `/new-metric` skill: Handles phases 1–3 (discover → onboard → validate). Writes to `catalog/metrics.yaml` at the end of Phase 7.
- `/promote-metric` skill: Handles phase 4 (validate → promote). Provides the implementation checklist for wiring into an output.
- Nightwatch: Runs quality checks on promoted metrics. Can also run checks on validated metrics when requested.
- Signal Deck: Displays the catalog status distribution on its Metric Catalog tab.
