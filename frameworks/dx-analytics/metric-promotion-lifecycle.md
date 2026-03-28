# Metric Promotion Lifecycle

A reusable framework for managing metrics in an analytics project. Metrics flow through four stages, decoupling discovery from publication.

## The Four Stages

```
Discovered → Onboarded → Validated → Promoted
```

### 1. Discovered

A signal or data source has been identified as potentially useful. Sources include automated catalog scans, brainstorming sessions, stakeholder requests, or upstream pipeline changes.

**Artifact:** A row in the metric catalog with `status: discovered`. No query, no data.

### 2. Onboarded

The metric has been defined (name, formula, grain, entity type, direction), its upstream source validated, and a query written.

**Artifact:** Catalog entry with `status: onboarded`, a SQL query file, and a metric spec document.

### 3. Validated

The metric has been backfilled with historical data, quality-checked, and reviewed. It is queryable and its data can be cached for ad-hoc analysis. This is a first-class status — not every metric needs to reach a dashboard.

**Artifact:** Everything from onboarded, plus cached data and passing quality checks.

### 4. Promoted

The metric appears in one or more published outputs (dashboards, reports, etc.). The catalog records which outputs include it.

**Artifact:** Full pipeline wiring — sync, build, render, and test coverage for the target output(s).

## Key Principles

- **No metric reaches a published output without passing through validated.** Even simple metrics need a quality check before stakeholders see them.
- **Promotion is an explicit decision.** It requires choosing a target output and following the appropriate implementation checklist.
- **Analysis-only is a first-class outcome.** A validated metric that is not promoted is still valuable — queryable, documented, and available for ad-hoc work.
- **Demotion is allowed.** Remove a metric from outputs by updating its catalog entry.
- **The catalog is the source of truth.** Always update the catalog before updating any pipeline.

## Catalog Schema (YAML)

```yaml
- id: metric_snake_case_id
  name: "Human Readable Name"
  status: discovered | onboarded | validated | promoted
  bucket: delivery | drag | ai_maturity | quality  # domain-specific
  source: snowflake | postgres | api | sheets
  query: queries/file_name.sql
  direction: higher | lower | neutral
  grain: weekly | daily | monthly
  entity: per_engineer | per_service | per_team | aggregate
  promoted_to: []        # list of output IDs
  owner: username
  quality_checks: []     # list of validation categories
  notes: ""
```

## Implementation in Cursor

This lifecycle is enforced through two complementary skills:

1. **`/new-metric`** — Handles discovery through validation (stages 1-3). Defines the metric, finds sources, checks for duplicates, assesses risks, writes to the catalog.
2. **`/promote-metric`** — Handles validation to promotion (stage 4). Selects target outputs, provides the implementation checklist, updates the catalog.

A Cursor rule file (`.cursor/rules/metric-promotion.md`) auto-injects the lifecycle documentation when editing catalog or pipeline files.
