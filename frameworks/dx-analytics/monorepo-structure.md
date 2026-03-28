# Analytics Monorepo Structure

A folder structure pattern for analytics projects that centralizes metrics, data pipelines, published outputs, and automation in a single repo.

## Structure

```
project-root/
├── catalog/                         # Metric & source registries
│   ├── metrics.yaml                 # Every metric with status and promotion targets
│   └── sources.yaml                 # Upstream data sources with caveats
│
├── queries/                         # SQL extraction queries
├── pipelines/                       # ETL and data engineering (future)
│   ├── snowflake/                   # Snowflake-specific extractions
│   ├── api/                         # API-based data pulls
│   └── shared/                      # Connection helpers
│
├── data/                            # Cached/materialized data
│   ├── catalog_cache/               # Query results for non-promoted metrics
│   └── raw/                         # Raw upstream pulls (.gitignored)
│
├── lib/                             # Shared infrastructure
│   ├── connections.py               # Database connection helpers
│   ├── formatting.py                # Number/metric formatting
│   ├── html.py                      # Report rendering helpers
│   ├── tokens.json                  # Design tokens (colors, spacing, fonts)
│   ├── tokens.css                   # CSS custom properties
│   ├── components.css               # Shared UI component styles
│   └── charts.js                    # Chart.js helpers with token palette
│
├── src/                             # Frontend (TypeScript, bundled)
├── reports/                         # Deep-dive reports (each has generate.py + output/)
│
├── scripts/                         # Automation
│   ├── nightshift.py                # Overnight orchestrator
│   ├── morning_briefing.py          # Daily Slack briefing
│   └── discovery_scanner.py         # Metric discovery automation
│
├── docs/                            # Style guide, playbooks
│   └── style-guide.md              # Visual design and code conventions
│
├── tests/                           # Automated tests
├── artifacts.yaml                   # Published artifact registry
├── AGENTS.md                        # AI agent guidance
└── Justfile                         # Task runner
```

## Key Design Decisions

### Catalog-first metrics

Metrics are registered in `catalog/metrics.yaml` before any pipeline work begins. This ensures every metric is documented, its source is known, and its promotion status is tracked. See the [Metric Promotion Lifecycle](metric-promotion-lifecycle.md) framework.

### Queries separate from pipelines

`queries/` holds analytical SQL used by the main dashboard sync. `pipelines/` holds self-service data extraction and transformation work. The distinction: queries are consumed by the existing dashboard pipeline; pipelines are standalone extraction jobs you own.

### Shared infrastructure in lib/

All visual constants (colors, fonts, spacing) live in `lib/tokens.json` and flow to CSS and Chart.js. Report rendering uses shared helpers from `lib/html.py`. This prevents visual inconsistency across outputs.

### Reports as Python modules

Each report is a self-contained Python module at `reports/<name>/generate.py`. Generated output goes to `reports/<name>/output/` (gitignored). This pattern supports unlimited reports without cluttering the root.

### Data cache for non-promoted metrics

`data/catalog_cache/` stores query results for metrics at `onboarded` or `validated` status. These are available for ad-hoc analysis without being wired into the dashboard pipeline.

## Adapting This Pattern

The structure assumes Python + SQL + TypeScript. Adjust for your stack:

- Replace `lib/html.py` with your rendering framework
- Replace `lib/tokens.json` with your design system
- Replace `Justfile` with your task runner (Make, npm scripts, etc.)
- The `catalog/` pattern is language-agnostic — it's just YAML
