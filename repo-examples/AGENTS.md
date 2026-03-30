# AGENTS.md

General agent guidance for this repository.

## What This Repo Is

This is a **DX Analytics monorepo** — the central hub for developer experience analytics, metrics, dashboards, and insights. The primary output is the executive dashboard and weekly highlights, but the repo also houses deep-dive reports, segmentation analyses, automated validation, and a growing metric catalog.

## Roadmap

All work is organized through the **roadmap document** at `thoughts/shared/plans/003_dashboard_roadmap.md`. This is the single source of truth for what we're building, why, and what's next. It covers the measurement framework (what metrics, which buckets), implementation workstreams, data architecture decisions, known risks, and candidate metrics.

The roadmap must be kept up to date. When completing work, making architectural decisions, or adding new metrics, update the relevant section. When starting a session on a non-trivial task, read the roadmap first.

The **Signal Deck** is published as a static site (`reports/roadmap_view/output/index.html`). It includes an Outputs tab (artifact map), Metric Catalog, and Roadmap tabs (workstreams, backlog, known issues). It must be manually regenerated when content changes.

## Metric Promotion Lifecycle

Every metric follows a 4-stage lifecycle. The canonical registry is `catalog/metrics.yaml`.

```
Discovered → Onboarded → Validated → Promoted
```

| Stage | What exists | How to get here |
|---|---|---|
| **Discovered** | A catalog entry with `status: discovered`. No query. | Automated discovery scan, brainstorm, or stakeholder request. |
| **Onboarded** | Catalog entry + SQL query + metric spec doc. | Run `/new-metric` skill. |
| **Validated** | Onboarded + backfilled data + passing quality checks. | Run query, cache results, verify with nightwatch. |
| **Promoted** | Validated + wired into a published output. | Run `/promote-metric` skill. |

Key rules:
- No metric reaches a published output without passing through `validated`.
- Analysis-only (validated but not promoted) is a first-class status.
- The catalog is the source of truth. Update it before updating any pipeline.

## Daily Cadence

The workflow is designed so that human time is spent on decisions and judgment, not on data plumbing or build mechanics. Heavy operations run on cloud workstations rather than blocking the local terminal.

| Time | Activity | Mode |
|---|---|---|
| 6:00 AM | Morning briefing arrives in Slack (local launchd, reads data branch) | Auto |
| 8:00 AM | Review briefing, run `/dawn-patrol` to review/merge nightagent branches | Human |
| 9 AM–5 PM | Deep work + on-demand dispatch: nightagent tasks dispatch anytime via `/delegate` | Human + Auto |
| 3:00 PM | Afternoon brief: scope tonight's automated work (batch tasks for overnight) | Human |
| 5:00 PM | NightShift: validation + doc maintenance + nightagent execution (single cloud task) | Auto |
| Wed 5 PM | Metric discovery: scan for new data sources, update catalogs | Auto |

Automations that support this cadence:
- **Morning briefing** (`scripts/morning_briefing.py`): overnight results, data freshness, action items, suggested focus.
- **Dawn Patrol** (`.cursor/skills/dawn-patrol/`): interactive review workflow for nightagent branches.
- **Daytime dispatch** (`just dispatch`): on-demand cloud tasks for nightagent code work, end-to-end refresh, and build+deploy. Available anytime.
- **Nightagent brief** (3 PM, `.cursor/skills/nightagent-brief/`): scopes tonight's automated work.
- **NightShift** (5 PM, `scripts/nightshift_trigger.py`): single cloud task — validation, Slack DM, doc maintenance, morning briefing, nightagent execution.
- **Doc maintenance** (daily, `scripts/doc_maintenance.py`): checks artifact freshness, catalog consistency, stale dates.
- **Metric discovery** (Wed, `scripts/metric_discovery.py`): scans data warehouse for new tables, checks access grants.
- **Weekly digest** (`scripts/weekly_digest.py`): auto-drafts weekly highlights.

## Style Guide

All visual design, chart patterns, component usage, and code conventions are documented in `docs/style-guide.md`. Key points:

- All colors, fonts, spacing from `lib/tokens.json`. Never hardcode hex values.
- Use chart helpers from `lib/charts.js`. No raw Chart.js instantiation.
- Use Python helpers from `lib/html.py` (`stat_card()`, `chart_box()`, etc.) for all reports.
- Python for backend, SQL for queries, TypeScript only for dashboard frontend.

### KPI Delta Comparisons

**KPI delta comparisons must be period-over-period.** When a dashboard uses timeframe toggle buttons (7d / 30d / etc.), KPI stat card deltas must compare the displayed period's rate to the equivalent prior period's rate. A 30-day card compares the last 30 days to the preceding 30 days. Never compare a sub-window against the headline of a longer window.

## Catalog Directory

`catalog/` contains the metric and source registries:

- `catalog/metrics.yaml` — every metric with status, source, query path, and promotion targets.
- `catalog/sources.yaml` — every upstream data source with connection details, refresh cadence, and known caveats.

Update them when adding, modifying, or removing metrics or data sources.

## Asking Clarifying Questions

**When in doubt, ask.** Do not guess at the user's intent when the request is ambiguous, under-specified, or could be interpreted multiple ways. A short clarifying question is always cheaper than undoing the wrong work.

Ask when:
- The scope of a change is unclear (e.g., "update the dashboard" — which part?).
- Multiple valid approaches exist and the trade-offs matter.
- A request could affect production data or published artifacts.
- You are unsure which metric, file, or section is being referenced.

Do not ask when:
- The request is unambiguous and you have everything you need.
- You can resolve the ambiguity by reading code or context that is readily available.

## Session Lifecycle

- **On session start**: `bd prime` injects beads context (~1-2k tokens of open tasks).
- **Before compaction**: `bd sync` saves work to git.
- **Before archiving**: Run `/anythingelse` to surface any discussed-but-unexecuted items. Triage before closing.
- **On session end**: Run quality gates, commit, push, `bd sync`. Work is NOT complete until `git push` succeeds.

## Nightagent Dispatch

Nightagent is available anytime — not just overnight. Throughout every session, actively identify tasks that should run on a cloud workstation rather than locally.

**Always dispatch to cloud:**
- End-to-end dashboard refresh (8–12 min pipeline): `just dispatch-endtoend`
- Full analysis pipeline runs: `just dispatch` (after writing spec via `/delegate`)
- Multi-site report builds: `just dispatch-build --sites <keys>`
- Any task that blocks the local terminal for > 2 minutes

**Suggest dispatch when you spot** a self-contained task during implementation:
- Touches 1–3 files with clear acceptance criteria.
- No product/design judgment required.
- Examples: CSS/styling fixes, wiring existing data into a new view, validation checks, SQL-backed metric onboarding.

**What to do when you spot one:**
1. Mention it briefly: "This is a good nightagent candidate. Want me to dispatch it now?"
2. If the user agrees to **dispatch now**, use `/delegate` which writes the spec and offers immediate dispatch.
3. If the user prefers **tonight**, use `/delegate` and choose the "queue for tonight" option.
4. If the user doesn't engage, note it and move on.

**Dispatch vs overnight queue:** Tasks dispatched during the day are marked `<!-- dispatched -->` in `.nightagent-requests.md`. The 5 PM NightShift automatically skips dispatched tasks so there's no double execution.

## Slash Commands

### RPI Workflow

| Command | Purpose |
|---------|---------|
| `/1_research_codebase` | Deep-dive investigation — saves to `thoughts/shared/research/` |
| `/2_create_plan` | Create phased implementation plan — saves to `thoughts/shared/plans/` |
| `/3_validate_plan` | Verify implementation matches plan |
| `/4_implement_plan` | Execute plan phase-by-phase with checkboxes |
| `/5_save_progress` | Save session context — saves to `thoughts/shared/sessions/` |
| `/6_resume_work` | Resume from a saved session |
| `/7_research_cloud` | Analyze cloud infrastructure (read-only) |
| `/8_define_test_cases` | Design acceptance test cases |

### Project Shortcuts

| Command | Purpose |
|---------|---------|
| `/sync` | Dry-run sync from data warehouse — shows what would change |
| `/sync-write` | Sync with write — backs up, syncs, rebuilds, opens in browser |
| `/build` | Build dashboard and open in browser for verification |
| `/publish` | Build and publish dashboard |
| `/delegate` | Hand off a task to nightagent — dispatch immediately or queue for tonight |
| `/endtoend` | Full pipeline refresh — defaults to cloud dispatch, can run locally |
| `/build-deploy` | Build and deploy static sites — offers cloud dispatch for heavy builds |

## Rules for Code Agents

1. **Always use `--json` flag** with `bd` commands for structured output.
2. **Always run quality gates** (`just lint`, `just build`, `just test`) before committing.
3. **Always create/update beads** when starting or finishing work.
4. **Never edit the `const DASHBOARD_DATA` block** in the dashboard HTML — it is generated.
5. **Never run `sync-write` without reviewing a dry-run first.**
6. **Never commit `.env`** or any credentials.

## Architecture Quick Reference

```
queries/*.sql          → Data warehouse queries (one per metric group)
sync_metrics.py        → Fetches data → writes dx-weekly-metrics.jsonc
build.py               → Reads JSONC → injects DASHBOARD_DATA → writes HTML
dx-weekly-metrics.jsonc → Primary data file (weekly rows, monthly, scores, metadata)
tests/*.mjs            → Playwright + node:test dashboard tests

src/                   → TypeScript frontend (bundled by esbuild)
  main.ts              → Entry point: reads DASHBOARD_DATA, wires chart renderers
  chart-helpers.ts     → Shared Chart.js config, palette, utility functions
  charts/*.ts          → One module per chart

lib/                   → Shared Python + frontend infrastructure
  connections.py       → connect_snowflake(), connect_getdx()
  formatting.py        → Canonical metric formatting (format_metric())
  html.py              → Self-contained HTML report renderer (render_report(), stat_card(), etc.)
  tokens.json          → Single source of truth for design tokens
  tokens.css           → CSS custom properties derived from tokens.json
  components.css       → Shared component styles (.stat-card, .chart-box, .tbl-wrap, etc.)
  charts.js            → Shared Chart.js helpers (VR.barChart, VR.lineChart, etc.)
  tabs.js              → Tab switching helpers (VRTabs.initTabs)

reports/               → Deep-dive reports (each has its own generate.py)
  <name>/generate.py   → Entry point: `uv run python -m reports.<name>.generate`
  <name>/output/       → Generated HTML + data.json (gitignored)

analysis/              → Automated insight playbooks (statistical analyses)
  <name>/PLAN.md       → Full blueprint: data, method, output spec, trigger
  <name>/run.py        → Executable analysis
  <name>/output/       → findings.json + narrative.md (gitignored)
  _lib/                → Shared stats helpers (stats.py, output.py)

scripts/               → Automation & operational scripts
  nightshift.py        → NightShift orchestrator (overnight, evening, thursday-extras modes)
  nightshift_trigger.py → Creates cloud workstation tasks via API
  morning_briefing.py  → Daily briefing (overnight results, data freshness, action items)
  doc_maintenance.py   → Daily doc staleness scanner
  metric_discovery.py  → Weekly metric discovery pipeline
  weekly_digest.py     → Auto-drafts weekly highlights
  nightagent_executor.py → Nightagent execution wrapper

catalog/               → Metric and source registries
  metrics.yaml         → Every metric with status, source, query path
  sources.yaml         → Every upstream data source

thoughts/shared/       → Prose documentation (not code)
  plans/               → Implementation plans + canonical roadmap
  research/            → Deep-dive investigations
  references/          → External source material
  sessions/            → Saved session context for resuming work
```

## Deep Analysis Workstream

Deep analysis is a **first-class workstream** — one of the primary ways this project delivers value. Analyses go beyond descriptive dashboards to answer "why did this happen?", "what's driving this trend?", and "what should we do about it?"

### Analysis Promotion Lifecycle

Every analysis follows a 4-stage lifecycle, tracked in the roadmap backlog.

```
Proposed → In Progress → Ready for Review → Published
```

Key rules:
- **No analysis reaches "Published" without human approval.**
- **"In Progress" is liberally used.** WIP analyses are visible in the report behind a click-through acknowledgment gate.
- **Nightagent has full autonomy** to execute analyses overnight, but results always land at "Ready for Review."
- **Analyses must prefer validated and promoted metrics.** Discovered or onboarded metrics should not be used.
- **Missing data** must be noted in the narrative's Limitations section AND auto-added to the roadmap backlog with a `[data-gap]` tag.

### Analysis Quality Bar

The `/deep-analysis` skill defines a 10-step methodology (Frame → Data Survey → Scaffold → Exploratory → Design → Execute → Robustness → Accuracy Audit → Triangulation → Synthesis). Key requirements:

- **Pre-registration** of hypotheses before seeing results
- **At least 2 robustness checks** per finding
- **Triangulation** across methods where feasible
- **Confidence tier assignment** (High/Medium/Low) for every finding
- **Effect sizes** alongside p-values for every statistical test
- **Adversarial accuracy audit** as a hard gate: devil's advocate, pre-mortem, statistical trap checklist

The nightagent should self-iterate: run the analysis, evaluate quality, refine 1-2 times, then present the best version.

### Analysis Directory

`analysis/` houses the analytical playbooks. Each subdirectory has a `PLAN.md` (full blueprint) and optionally a `run.py` (executable). This is distinct from `reports/` (published HTML), `queries/` (SQL), and `scripts/` (operational automation).

## Reports Convention

Each report lives in `reports/<name>/` with underscored names (valid Python module):

```
reports/deploy_freq_segmentation/
  __init__.py
  generate.py      # entry point
  output/           # gitignored — contains index.html, data.json
```

**Adding a new report:**
1. Create `reports/<name>/__init__.py` and `reports/<name>/generate.py`
2. Import connections from `lib.connections`, use `lib.html` for rendering
3. Write output to `reports/<name>/output/index.html`
4. Follow the chart design principles in `.cursor/rules/chart-design-principles.md`
5. Use **metric status indicators** for any metric that may not yet have data
6. Use **tiered tabs** for reports with 4+ tabs
7. Run: `just generate-report <name>`

### Metric Status Indicators

Every metric displayed in a report should indicate its pipeline status:

- `status_pill(status)` — inline badge. Statuses: `exists` (green), `wip` (amber), `missing` (red).
- `placeholder_card(label, status)` — dashed-border placeholder for metrics without data.
- `stat_card(..., status='wip')` — auto-renders a placeholder when status is wip/missing.

### Tiered Tab Navigation

Reports with multiple tabs should visually distinguish primary from secondary tabs:

- **4+ tabs**: use tiered `tab_bar(primary, secondary)` helper. Primary tabs are larger/bolder on the left; a vertical separator divides them from smaller secondary tabs.
- **2-3 equal-weight tabs**: use flat `.sub-tabs` / `.sub-tab` (no tiers needed).

## Adding a New Dashboard Chart

Each chart flows through the full pipeline: SQL → sync → JSONC → build → TypeScript → HTML.

### Checklist

1. **SQL query** — `queries/<name>.sql`
2. **Fetch function** — `sync_metrics.py`: add `fetch_<name>(conn)`, register in stem set, fetch block, and pop+write block.
3. **Build passthrough** — `build.py`: add to `load_data()`, return dict, and `DASHBOARD_DATA` template.
4. **TypeScript renderer** — `src/charts/<name>.ts`: export `render<Name>Chart(containerId, data)`.
5. **Wire in main** — `src/main.ts`: import and call the renderer.
6. **HTML container** — Dashboard HTML: add a `chart-tile` div with `data-component` attribute.
7. **Verify** — `just bundle && just build && just test`.

## Component Naming

All UI components use `data-component` attributes for AI-agent discoverability.

**Convention:** `data-component="<type>-<name>"` where type is one of:
- `stat-` — stat cards
- `chart-` — chart containers
- `table-` — data tables
- `insight-` — insight/callout boxes

The component helpers accept a `name=` parameter that auto-generates the attribute.

## Design Tokens

All visual constants live in `lib/tokens.json` and are exposed as CSS custom properties, Chart.js palette, and Python formatting functions. To change a color, font, or spacing globally, edit `lib/tokens.json` and regenerate.

## URL Conventions

**Never use `#` (hash/fragment) in shareable URLs.** Slack interprets `#` followed by text as a channel link, breaking pasted URLs. Use query parameters instead (e.g., `?tab=trends` not `#trends`).

## Report Formatting Standard

All published reports follow the formatting standard in `.cursor/rules/blockcell-formatting.md`:

- **Max-width**: 1200px, centered.
- **Colors**: CSS custom properties from `lib/tokens.css` — never hardcode.
- **Typography**: `--font-*` size tokens (xs through 2xl).
- **Spacing**: `--sp-*` tokens — not raw pixel values.
- **Components**: Shared classes from `lib/components.css`.

## Commentary Tone

When writing exec summary highlights or commentary:
- Matter-of-fact. No editorializing.
- Lead with the metric name and what happened.
- Contextualize threshold crossings and trend changes.
- Overview must touch on every highlight.

## Internal Update Format

All internal update reports (OKR progress, team updates, weekly digests, status pages) must follow the structured update pattern:

- **Highlights sorted by importance.** Every update section sorts items by importance descending.
- **Visible importance labels.** Each highlight gets a badge (Critical / High / Medium / Low).
- **Source citations with count.** Every claim links to its source.
- **Metric trend charts per section.** Embed relevant Chart.js sparklines inline when data-backed.
- **Section navigation.** Reports with 4+ sections include jump-to-section nav and deep-link URL params.
- **KTLO sections collapsed.** Low-priority sections use `<details>` collapsed by default.

## Branching Strategy

```
feature branch → staging → main
```

- **`main`** — production. Only receives merges from `staging`.
- **`staging`** — integration/validation. All significant changes land here first.
- **Feature branches** — short-lived. Branch from `staging`, PR into `staging`.

**Rules:**
- Never push directly to `main` — always go through `staging` first.
- Trivial fixes may skip staging at the user's discretion.

## Night Shift Commit Restrictions

Night Shift and nightagent automations follow these commit rules:

- **Nightagent code tasks** may only commit to and push `nightagent/*` feature branches. They must never merge, fast-forward, or push directly to `staging` or `main`. All merges require human approval.
- **End-to-end refresh** is an exception: it commits machine-generated data directly to staging, with a safety guard verifying that no other file was modified.
- **Nightwatch** is strictly read-only — no commits on any branch.
- The "Landing the Plane" rules below apply to **interactive sessions only**.

## Landing the Plane

*Applies to interactive (human-driven) sessions only.*

1. Run `/anythingelse` to catch discussed-but-unexecuted items. Triage before proceeding.
2. Run quality gates: `just lint && just build && just test`
3. Update beads: `bd close` / `bd update` as needed
4. Push: `git pull --rebase && bd sync && git push`
5. Verify: `git status` shows "up to date with origin"

**Work is NOT complete until `git push` succeeds. NEVER stop before pushing.**
