# Analytics Monorepo Structure

A folder structure pattern for analytics projects that centralizes metrics, data pipelines, published outputs, analysis, and automation in a single repo.

## Structure

```
project-root/
├── catalog/                         # Metric & source registries
│   ├── metrics.yaml                 # Every metric with status and promotion targets
│   └── sources.yaml                 # Upstream data sources with caveats
│
├── queries/                         # SQL extraction queries (consumed by sync_metrics.py)
│
├── data/                            # Cached/materialized data
│   ├── catalog_cache/               # Query results for non-promoted metrics
│   └── raw/                         # Raw upstream pulls (.gitignored)
│
├── lib/                             # Shared infrastructure
│   ├── connections.py               # Database connection helpers
│   ├── formatting.py                # Number/metric formatting
│   ├── html.py                      # Report rendering helpers (stat_card, chart_box, etc.)
│   ├── tokens.json                  # Design tokens (colors, spacing, fonts)
│   ├── tokens.css                   # CSS custom properties
│   ├── components.css               # Shared UI component styles
│   ├── charts.js                    # Chart.js helpers with token palette
│   └── tabs.js                      # Tab switching helpers
│
├── src/                             # Frontend (TypeScript, bundled)
│
├── reports/                         # Deep-dive reports (each has generate.py + output/)
│   ├── <name>/generate.py           # Entry point for each report
│   ├── <name>/output/               # Generated HTML + data.json (gitignored)
│   └── dashboard_validation/        # Nightwatch validation suite
│       └── checks/                  # Individual check modules (19 categories)
│
├── analysis/                        # Automated insight playbooks
│   ├── <name>/PLAN.md               # Full blueprint: data, method, output spec
│   ├── <name>/run.py                # Executable analysis
│   ├── <name>/output/               # findings.json + narrative.md (gitignored)
│   └── _lib/                        # Shared stats helpers (stats.py, output.py)
│
├── scripts/                         # Automation & operational scripts
│   ├── nightshift.py                # Overnight orchestrator (modes: overnight, evening, etc.)
│   ├── nightshift_trigger.py        # Creates cloud workstation tasks via API
│   ├── morning_briefing.py          # Daily Slack briefing
│   ├── doc_maintenance.py           # Daily doc staleness scanner
│   ├── metric_discovery.py          # Weekly metric discovery pipeline
│   ├── weekly_digest.py             # Auto-drafts weekly highlights
│   ├── nightagent_executor.py       # Nightagent execution wrapper
│   └── archive/                     # Deprecated scripts (preserved for reference)
│
├── docs/                            # Project documentation
│   ├── style-guide.md               # Visual design and code conventions
│   └── ways-of-working.md           # Daily cadence and workflow description
│
├── thoughts/shared/                 # Prose documentation (not code)
│   ├── plans/                       # Active implementation plans
│   │   ├── 003_dashboard_roadmap.md # Canonical roadmap (single source of truth)
│   │   └── archive/                 # Completed plans
│   ├── research/                    # Deep-dive investigations
│   ├── references/                  # External source material
│   └── sessions/                    # Saved session context
│
├── tests/                           # Automated tests (Playwright + node:test)
├── artifacts.yaml                   # Published artifact registry + dependency graph
├── AGENTS.md                        # AI agent guidance (~790 lines)
└── Justfile                         # Task runner (~35 recipes)
```

## Key Design Decisions

### Catalog-first metrics

Metrics are registered in `catalog/metrics.yaml` before any pipeline work begins. This ensures every metric is documented, its source is known, and its promotion status is tracked. See the [Metric Promotion Lifecycle](metric-promotion-lifecycle.md) framework.

### Queries separate from analysis

`queries/` holds analytical SQL used by the main dashboard sync. `analysis/` holds statistical playbooks (each with a PLAN.md + run.py). The distinction: queries feed the dashboard pipeline; analyses are investigative and produce findings/narratives.

### Analysis as a first-class directory

`analysis/` is distinct from `reports/` (published HTML), `queries/` (SQL), and `scripts/` (operational automation). Each analysis has:
- `PLAN.md` — full blueprint with research question, data sources, methodology, output spec
- `run.py` — executable Python that produces `findings.json` + `narrative.md`
- `output/` — gitignored results directory

Analyses follow a lifecycle: Proposed → In Progress → Ready for Review → Published. Results from `analysis/` feed into the combined deep-analysis report in `reports/`.

### Shared infrastructure in lib/

All visual constants (colors, fonts, spacing) live in `lib/tokens.json` and flow to CSS and Chart.js. Report rendering uses shared helpers from `lib/html.py`. This prevents visual inconsistency across outputs.

### Reports as Python modules

Each report is a self-contained Python module at `reports/<name>/generate.py`. Generated output goes to `reports/<name>/output/` (gitignored). This pattern supports unlimited reports without cluttering the root.

### Artifact registry as dependency graph

`artifacts.yaml` tracks every published output with `relates_to` and `feeds` fields, creating a machine-readable dependency graph. Each artifact also gets a shortcode file (`.cursor/artifacts/art01-*.md`) for quick agent lookup.

### Scripts for automation cadence

`scripts/` contains the operational automation: overnight orchestration, morning briefings, metric discovery, weekly digests. The `archive/` subdirectory preserves deprecated scripts for reference. All scripts support `--dry-run` for local testing.

### Data cache for non-promoted metrics

`data/catalog_cache/` stores query results for metrics at `onboarded` or `validated` status. These are available for ad-hoc analysis without being wired into the dashboard pipeline.

## Adapting This Pattern

The structure assumes Python + SQL + TypeScript. Adjust for your stack:

- Replace `lib/html.py` with your rendering framework
- Replace `lib/tokens.json` with your design system
- Replace `Justfile` with your task runner (Make, npm scripts, etc.)
- The `catalog/` pattern is language-agnostic — it's just YAML
- The `analysis/` pattern works with any statistical tooling (R, Julia, etc.)
