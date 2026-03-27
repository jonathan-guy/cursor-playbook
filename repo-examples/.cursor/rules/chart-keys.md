# Exec Summary Chart Key Reference

When configuring `charts` in `execSummary` items in `dx-weekly-metrics.jsonc`, only use keys from the tables below. Using an invalid key produces a broken/empty chart.

## Card Keys (`"type": "card"`)

These render as sparkline cards with headline value + delta.

| Key | Label | Section |
|-----|-------|---------|
| `cdPrThroughput` | PR Throughput | cd-throughput |
| `cdTrueFeatureThroughput` | Feature PR Throughput | cd-throughput |
| `cdWeeklyMergedPrs` | Weekly Merged PRs | cd-throughput |
| `cdTotalFeatureThroughput` | Feature PR Throughput (total) | cd-throughput |
| `cdLeadTime` | Lead Time to Change | cd-ops |
| `cdDeployFreq` | Deploy Frequency | cd-ops |
| `prMergeTime` | PR Merge Time | code-review |
| `timeToFirstReviewP75` | Time to First Review P75 | code-review |
| `pctReviewedWithin24h` | % Reviewed Within 24h | code-review |
| `prReviewsDev` | PR Reviews / Eng | code-review |
| `prCommitsDuringReview` | PR Commits During Review | code-review |
| `ciPerformance` | CI Performance | build-perf-ci |
| `ciReliability` | CI Reliability | build-perf-ci |
| `ciTestFlakiness` | Test Flakiness | build-perf-ci |
| `ciBuildsDevLoad` | CI Builds / Eng | build-perf-ci |
| `localBuildTimeP75` | Local Build Time P75 | build-perf-local |
| `localBuildTime` | Local Build Time P95 | build-perf-local |
| `aiUsageMaturity` | Non-IDE AI Adoption | ai-maturity |
| `aiAttributedPrsWeek` | AI Attributed PRs/Week | ai-maturity |
| `aiPreReviewAllBots` | AI Screen Rate (All Bots) | code-review |
| `aiPreReviewAiOnly` | AI Review Screen Rate | code-review |

**Virtual card keys** (resolved by `_resolve_ai_headline_card`, not in card registry):

| Key | Label |
|-----|-------|
| `aiCodeWriterAdoption` | AI Code Writer Adoption |
| `aiNativeEngineers` | AI-Native Engineers |

## Inline Chart Keys (`"type": "inline-chart"`)

These render as full Chart.js charts within the exec summary item.

| Key | Renders | Data Source |
|-----|---------|-------------|
| `prClassificationMix` | Stacked bar: Feature/Maintenance/Bug mix | `dx-weekly-metrics.jsonc` → `prClassificationMix` |
| `aiTokenTotal` | Bar: total tokens per week | `sync_metrics.py` → AI token usage |
| `aiTokenPerPerson` | Stacked bar: winsorized avg + P95 excess | `sync_metrics.py` → AI token usage |
| `aiTokenP95P50` | Line: P95/P50 concentration ratio | `sync_metrics.py` → AI token usage |
| `aiTokenByTool` | Stacked bar: tokens by tool | `sync_metrics.py` → AI token usage |
| `opLoadTrend` | Stacked bar: pager + slack + oncall burden (12wk) | `dx-weekly-metrics.jsonc` → `opLoadTrend` (from weekly rows) |
| `locByClassification` | Grouped bar: pre/post-RIF p50 LOC by classification | `reports/loc_segmentation/output/data.json` |
| `locByAiAssisted` | Grouped bar: AI-assisted vs non-AI p50 LOC | `reports/loc_segmentation/output/data.json` |
| `prsPerDeployTrend` | Dual-line: median vs avg PRs per deploy | `reports/pr_deploy_divergence/output/data.json` |
| `tftAllEng` | Single-line: all-eng weighted feature PR throughput trend | `reports/feature_throughput_segmentation/output/data.json` |
| `tftByBrand` | Multi-line: TFT per eng by brand (Cash App, CB, Square) | `reports/feature_throughput_segmentation/output/data.json` |
| `lttcByBrand` | Multi-line: median LTTC by brand | `reports/lead_time_segmentation/output/data.json` |
| `tftByDisciplineSquare` | Multi-line: TFT per eng by discipline (Mobile/Server/Web) for Square | `reports/feature_throughput_segmentation/output/data.json` |
| `aiDauCodingSegments` | Stacked area: AI coding DAU segments (Daily/Near-Daily/Frequent/Occasional) | `dx-weekly-metrics.jsonc` → `aiDauSegmentsCoding` |

## Layout Options (`"chartLayout"`)

| Layout | Behavior |
|--------|----------|
| `single` | One chart at 100% width |
| `side-by-side` | Charts in a horizontal row |
| `stacked` | Charts stacked vertically (default) |
| `hero-plus-two-up` | First chart full-width, remaining in a row below |

## Adding a New Inline Chart

1. **`build.py` ~line 1077**: Add `elif chart_key == 'yourKey':` in the inline-chart resolution block
2. **`build.py` ~line 4490**: Add `else if (chartType === 'yourKey')` in `renderEsInlineChart`
3. **`build.py`**: Add a `function renderYourChart(container, chartData)` Chart.js renderer
4. **`dx-weekly-metrics.jsonc`**: Reference as `{"key": "yourKey", "type": "inline-chart"}`
5. **Update this file** with the new key
