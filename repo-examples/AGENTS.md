# AGENTS.md

General agent guidance for this repository. For Claude Code-specific instructions, see `CLAUDE.md`.

## Roadmap

All velocity reporting work is organized through the **roadmap document** at `thoughts/shared/plans/003_dashboard_roadmap.md`. This is the single source of truth for what we're building, why, and what's next. It covers the measurement framework (what metrics, which buckets), implementation workstreams (data reliability, automation, reports platform, etc.), data architecture decisions, known risks, and candidate metrics from brainstorming.

The roadmap must be kept up to date. When completing work, making architectural decisions, or adding new metrics, update the relevant section. When starting a session on a non-trivial task, read the roadmap first to understand context and priorities.

The **Signal Deck** is published at https://blockcell.sqprod.co/sites/signal-deck/ (`reports/roadmap_view/output/index.html`). It includes an Outputs tab (artifact map) and Roadmap tabs (workstreams, backlog, known issues). It must be manually regenerated when content changes — it is not auto-built.

**Editing the roadmap view:**
- **Content changes** (backlog items, workstream names/status/sub-items, risk bullets): edit `003_dashboard_roadmap.md`, then run `just generate-report roadmap_view` and redeploy.
- **Layout/styling changes** (framework diagram, workstream purpose lines in `WS_PURPOSES`, tier labels, CSS, tab structure): edit `reports/roadmap_view/wireframes.py`, then regenerate and redeploy.
- The canonical entry point is `generate.py`, which delegates rendering to `wireframes.py`'s `render_variant_b()`. Both `just generate-report roadmap_view` and `uv run python -m reports.roadmap_view.wireframes` work; the former is the production path.

## Asking Clarifying Questions

**When in doubt, ask.** Do not guess at the user's intent when the request is ambiguous, under-specified, or could be interpreted multiple ways. A short clarifying question is always cheaper than undoing the wrong work.

Ask when:
- The scope of a change is unclear (e.g., "update the dashboard" — which part?).
- Multiple valid approaches exist and the trade-offs matter.
- A request could affect production data or published artifacts.
- You are unsure which metric, file, or section is being referenced.
- The request conflicts with an existing rule or convention in this repo.

Do not ask when:
- The request is unambiguous and you have everything you need.
- You can resolve the ambiguity by reading code or context that is readily available.

Prefer a single focused question over a wall of options. If you need to ask multiple things, batch them into one message.

## Session Lifecycle

- **On session start**: `bd prime` injects beads context (~1-2k tokens of open tasks).
- **Before compaction**: `bd sync` saves work to git.
- **On session end**: Run quality gates, commit, push, `bd sync`. Work is NOT complete until `git push` succeeds.

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
| `/sync` | Dry-run sync from Snowflake — shows what would change |
| `/sync-write` | Sync with write — backs up, syncs, rebuilds, opens in browser |
| `/build` | Build dashboard and open in browser for verification |
| `/publish` | Build and publish dashboard |

## Rules for Claude Code

1. **Always use `--json` flag** with `bd` commands for structured output.
2. **Always run quality gates** (`just lint`, `just build`, `just test`) before committing.
3. **Always create/update beads** when starting or finishing work.
4. **Never edit the `const DASHBOARD_DATA` block** in `dx-executive-dashboard.html` — it is generated.
5. **Never run `sync-write` without reviewing a dry-run first.**
6. **Never commit `.env`** or any credentials.

## Architecture Quick Reference

```
queries/*.sql          → Snowflake/GetDX queries (one per metric group)
sync_metrics.py        → Fetches data → writes dx-weekly-metrics.jsonc
build.py               → Reads JSONC → injects DASHBOARD_DATA → writes dx-executive-dashboard.html
dx-weekly-metrics.jsonc → Primary data file (weekly rows, monthly, DXI, metadata, exec summaries)
dx-executive-dashboard.html → Template AND output (HTML structure: safe to edit. DASHBOARD_DATA block: never edit)
tests/*.mjs            → Playwright + node:test dashboard tests

src/                   → TypeScript frontend (bundled by esbuild into dist/dashboard.js)
  main.ts              → Entry point: reads DASHBOARD_DATA, wires chart renderers
  chart-helpers.ts     → Shared Chart.js config, palette, utility functions
  charts/*.ts          → One module per chart (ai-adoption, daily-deploys, etc.)

lib/                   → Shared Python + frontend infrastructure
  connections.py       → connect_snowflake(), connect_getdx() — use instead of sys.path hacks
  formatting.py        → Canonical metric formatting (format_metric())
  html.py              → Self-contained HTML report renderer (render_report(), stat_card(), etc.)
  tokens.json          → Single source of truth for design tokens (colors, spacing, fonts)
  tokens.css           → CSS custom properties derived from tokens.json
  components.css       → Shared component styles (.stat-card, .chart-box, .tbl-wrap, etc.)
  charts.js            → Shared Chart.js helpers (VR.barChart, VR.lineChart, etc.)

reports/               → Graduated deep-dive reports (each has its own generate.py)
  <name>/generate.py   → Entry point: `uv run python -m reports.<name>.generate`
  <name>/output/       → Generated HTML + data.json (gitignored)

scripts/               → Ad-hoc analysis scripts (may graduate to reports/)
```

## Reports Convention

Each report lives in `reports/<name>/` with underscored names (valid Python module):

```
reports/deploy_freq_segmentation/
  __init__.py
  generate.py      # entry point — run with `uv run python -m reports.deploy_freq_segmentation.generate`
  output/           # gitignored — contains index.html, data.json
```

**Adding a new report:**
1. Create `reports/<name>/__init__.py` and `reports/<name>/generate.py`
2. Import connections from `lib.connections`, use `lib.html` for rendering
3. Write output to `reports/<name>/output/index.html`
4. Optionally write `data.json` for LLM querying
5. Run: `just generate-report <name>`

## Adding a New Dashboard Chart

Each chart flows through the full pipeline: SQL → sync → JSONC → build → TypeScript → HTML.
Follow this checklist in order.

### 1. SQL query — `queries/<name>.sql`

Write the Snowflake or GetDX query. Follow the header format from Plan 006.

### 2. Fetch function — `sync_metrics.py`

Add a `fetch_<name>(conn)` function near the other chart fetch functions (~line 350):

```python
def fetch_<name>(conn) -> list[dict]:
    sql = (QUERIES_DIR / '<name>.sql').read_text()
    cur = conn.cursor()
    cur.execute(sql)
    rows = cur.fetchall()
    return [{'col1': row[0], ...} for row in rows if row[0] is not None]
```

Then register in 3 places in the same file:

- **Stem set** (~line 1576): add `'<name>'` to `snowflake_stems` (or `getdx_stems`). `all_known_stems` is derived automatically.
- **Fetch + stash** (in the Snowflake or GetDX block, ~line 1750): add an `if only is None or '<name>' in only:` block that calls the function and stashes `all_fetched['__<name>']`.
- **Pop + write** (~line 1920): pop from `all_fetched` and write to `data['<jsonKey>']`.

### 3. Build passthrough — `build.py`

- In `load_data()` (~line 164): add `<var> = raw.get('<jsonKey>', [])`
- In the return dict (~line 204): add `'<jsonKey>': <var>,`
- In the `DASHBOARD_DATA` template (~line 1208): add `<dashboardKey>: {json.dumps(<var>)},`

### 4. TypeScript renderer — `src/charts/<name>.ts`

Create a module exporting `render<Name>Chart(containerId: string, data: any)`.
Import `Chart, ensureCanvas, mergeOpts, BASE_OPTS, shortWeek` from `../chart-helpers`.

### 5. Wire in main — `src/main.ts`

Import the renderer and add a call in the `DOMContentLoaded` handler:

```typescript
render<Name>Chart('<container-id>', d.<dashboardKey>);
```

### 6. HTML container — `dx-executive-dashboard.html`

Add a `chart-tile` div in the appropriate section:

```html
<div class="chart-tile">
  <div id="<container-id>" data-component="chart-<name>" style="min-height: 220px;"></div>
  <div class="metric-info">?<div class="metric-info-tooltip">...</div></div>
</div>
```

### 7. Verify

Run `just bundle && just build && just test`.

## Component Naming

All UI components use `data-component` attributes for AI-agent discoverability.

**Convention:** `data-component="<type>-<name>"` where type is one of:
- `stat-` — stat cards (e.g., `data-component="stat-total-deploys"`)
- `chart-` — chart containers (e.g., `data-component="chart-freq-trend"`)
- `table-` — data tables (e.g., `data-component="table-team-mapping"`)
- `insight-` — insight/callout boxes (e.g., `data-component="insight-methodology"`)

The `lib/html.py` component helpers (`stat_card()`, `chart_box()`, `table_wrap()`, `insight_box()`) accept a `name=` parameter that auto-generates the `data-component` attribute.

**Usage in prompts:** Reference components by their `data-component` value:
> "Change the color of the stat-total-deploys card to green"
> "Add a tooltip to chart-freq-trend showing the exact value"

## Design Tokens

All visual constants live in `lib/tokens.json` and are exposed as:
- CSS custom properties in `lib/tokens.css` (e.g., `var(--accent-primary)`)
- Chart palette in `lib/charts.js` (e.g., `VR.color(0)`)
- Number formats in `lib/formatting.py` (e.g., `format_metric(v, 'percentage')`)

To change a color, font, or spacing globally across all reports, edit `lib/tokens.json` and regenerate.

## Blockcell Report Formatting

All Blockcell-hosted reports must follow the formatting standard documented in `.cursor/rules/blockcell-formatting.md`. Key parameters:

- **Max-width**: 1200px, centered. Apply to both `h1` and `[data-component="report-body"]`.
- **Colors**: Use `lib/tokens.css` custom properties — never hardcode hex values.
- **Typography**: Use `--font-*` size tokens (xs through 2xl) from `lib/tokens.json`.
- **Spacing**: Use `--sp-*` tokens (xs through 2xl) — not raw pixel values.
- **Components**: Use shared classes from `lib/components.css` (`.stat-card`, `.chart-box`, `.tbl-wrap`, `.sub-tabs`, etc.).
- **Charts**: Wrap `<canvas>` in a height-bounded container; use `VR.lineChart()` / `VR.barChart()` from `lib/charts.js`.

When creating or modifying any Blockcell report, consult the full standard for details.

## Commentary Tone

When writing exec summary highlights or commentary, follow the rules in `AGENTS.md` under "Weekly Highlights":
- Matter-of-fact. No editorializing.
- Lead with the metric name and what happened.
- Contextualize threshold crossings and trend changes.
- Overview must touch on every highlight.

### Methodology Notes (footerNotes)

`footerNotes` in each week's exec summary must be relevant to the highlights surfaced in that week's `items[]`. They exist to help a reader interpret the findings — not to catalog every known data caveat.

- **Tie each note to a highlight.** Every footerNote should provide methodology context, population assumptions, or a data-quality caveat that directly helps interpret one or more of the week's highlighted findings.
- **Do not carry forward stale warnings.** If a caveat from a prior week no longer relates to any current highlight, drop it. If the underlying issue persists and is relevant, update the note to reflect the current state.
- **Review prior week's notes when authoring.** When creating a new week's exec summary, check the previous week's `footerNotes` and decide for each: update, drop, or carry forward based on relevance to the new highlights.
- **Standing notes are fine when relevant.** Evergreen notes (e.g., population definition) are acceptable if they help interpret a surfaced metric — but they still must connect to something in `items[]`.

### Segmentation Deep-Dive Charts in Highlights

Several inline charts in the exec summary are computed at build time from segmentation deep-dive report data (`reports/*/output/data.json`), not from the main dashboard's per-org query pipeline. These include:

- `tftByBrand` / `tftByDisciplineSquare` — from `feature_throughput_segmentation`
- `lttcByBrand` — from `lead_time_segmentation`
- `locByClassification` / `locByAiAssisted` — from `loc_segmentation`

Because the segmentation pipeline uses a different aggregation method than the main dashboard stat cards, values may differ slightly (e.g., different median interpolation, rounding precision). **Any highlight that includes one of these charts must include a note in its `notes[]` array** stating the data source and that the main dashboard card may show slightly different values. Example:

> "Lead time to change computed from segmentation deep-dive (per-service median, Tier 0/1 engineering services). Main dashboard card uses a different aggregation method that may show slightly different values."

## Branching Strategy

```
feature branch → staging → main
```

- **`main`** — production. Published to Blockcell. Only receives merges from `staging`.
- **`staging`** — integration/validation. All significant changes land here first via PR or merge. Run and verify before promoting to `main`.
- **Feature branches** — short-lived. Branch from `staging`, PR into `staging`.

**Workflow:**
1. Create feature branch from `staging` (or `main` if starting fresh)
2. Push feature branch, merge into `staging`
3. Validate on staging (build, test, visual check)
4. When ready, merge `staging` → `main` (via PR or fast-forward)

**Rules:**
- Never push directly to `main` — always go through `staging` first.
- Trivial fixes (typos, comment changes) may skip staging at the user's discretion.
- CI runs on PRs to both `main` and `staging`.

## Landing the Plane

1. Run quality gates: `just lint && just build && just test`
2. Update beads: `bd close` / `bd update` as needed
3. Push: `git pull --rebase && bd sync && git push`
4. Verify: `git status` shows "up to date with origin"

**Work is NOT complete until `git push` succeeds. NEVER stop before pushing.**
