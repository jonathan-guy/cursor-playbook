# Analytics Monorepo Structure

A folder structure pattern for analytics projects that centralizes metrics, data pipelines, published outputs, and automation in a single repo.

## Structure

```
project-root/
├── catalog/                         # Metric & source registries
│   ├── metrics.yaml                 # Every metric with status and promotion targets
│   └── sources.yaml                 # Upstream data sources with caveats
│
├── queries/                         # SQL extraction queries (consumed by sync_metrics.py)
├── pipelines/                       # Standalone extraction jobs
│   ├── snowflake/                   # Snowflake-specific extractions
│   ├── api/                         # API-based data pulls (e.g. PagerDuty resolver)
│   │   └── pagerduty_resolver_fetch.py
│   └── shared/                      # Shared pipeline utilities (e.g. refresh events)
│       └── refresh_events.py
│
├── data/                            # Cached/materialized data
│   ├── catalog_cache/               # Query results for non-promoted metrics
│   └── raw/                         # Raw upstream pulls (.gitignored)
│
├── lib/                             # Shared infrastructure
│   ├── connections.py               # Database connection helpers
│   ├── formatting.py                # Number/metric formatting
│   ├── html.py                      # Report rendering helpers (stat_card, chart_box, etc.)
│   ├── favicon.py                   # Favicon helper for generated reports
│   ├── tokens.json                  # Design tokens (colors, spacing, fonts)
│   ├── tokens.css                   # CSS custom properties
│   ├── components.css               # Shared UI component styles
│   ├── charts.js                    # Chart.js helpers with token palette
│   └── tabs.js                      # Tab switching helpers (VRTabs.initTabs)
│
├── src/                             # Frontend (TypeScript, bundled)
├── reports/                         # Deep-dive reports (each has generate.py + output/)
│   └── dashboard_validation/        # Nightwatch validation suite
│       └── checks/                  # Individual check modules (19 categories)
│
├── scripts/                         # Automation & ad-hoc analysis
│   ├── nightshift.py                # Overnight orchestrator (modes: overnight, evening, wednesday)
│   ├── nightshift_trigger.py        # Creates BuilderBot tasks via API
│   ├── morning_briefing.py          # Daily Slack briefing
│   ├── auto_triage.py               # Pattern-matches failures into known categories
│   ├── weekly_digest.py             # Auto-drafts weekly highlights + honest take
│   ├── rachel_briefing.py           # Stakeholder briefing DM
│   ├── discovery_scanner.py         # Metric discovery automation
│   ├── nightagent_executor.py       # Nightagent execution wrapper
│   ├── nightagent_slack.py          # Nightagent Slack notification helper
│   └── archive/                     # Deprecated scripts (preserved for reference)
│
├── docs/                            # Project documentation
│   ├── style-guide.md               # Visual design and code conventions
│   ├── gemini.md                    # Gemini integration notes
│   ├── research.md                  # Pointer to thoughts/shared/research/
│   └── AUTOMATION-SETUP.md          # Automation setup guide
│
├── thoughts/shared/                 # Prose documentation (not code)
│   ├── plans/                       # Active implementation plans
│   │   ├── 003_dashboard_roadmap.md # Canonical roadmap (single source of truth)
│   │   └── archive/                 # Completed plans (004, 005, 006, 010)
│   ├── research/                    # Deep-dive investigations
│   ├── references/                  # External source material
│   └── sessions/                    # Saved session context
│
├── tests/                           # Automated tests (Playwright + node:test)
├── artifacts.yaml                   # Published artifact registry + dependency graph
├── AGENTS.md                        # AI agent guidance
└── Justfile                         # Task runner
```

## Key Design Decisions

### Catalog-first metrics

Metrics are registered in `catalog/metrics.yaml` before any pipeline work begins. This ensures every metric is documented, its source is known, and its promotion status is tracked. See the [Metric Promotion Lifecycle](metric-promotion-lifecycle.md) framework.

### Queries separate from pipelines

`queries/` holds analytical SQL used by the main dashboard sync. `pipelines/` holds self-service data extraction and transformation work. The distinction: queries are consumed by the existing dashboard pipeline; pipelines are standalone extraction jobs you own.

As of Phase 5, `pipelines/api/` and `pipelines/shared/` are active with real scripts moved from `scripts/` (e.g., `pagerduty_resolver_fetch.py`, `refresh_events.py`).

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
