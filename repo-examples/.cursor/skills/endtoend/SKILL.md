---
name: endtoend
description: Run the full weekly velocity dashboard pipeline end-to-end. Syncs all data from Snowflake/GetDX, builds the dashboard, generates segmentation deep-dive reports, runs quality gates, and deploys everything to Blockcell. Use when the user invokes /endtoend, asks for a full refresh, weekly refresh, end-to-end run, or wants to refresh and publish the dashboard.
---

# End-to-End Dashboard Refresh

Full pipeline: **sync → lint → build → generate reports → test → publish dashboard → publish reports**.

Estimated wall-clock time: ~8–12 minutes (sync dominates at ~5 min).

## Prerequisites

- VPN (WARP) connected (required for Blockcell uploads)
- `.env` present in repo root with Snowflake/GetDX credentials
- SSO browser auth may be needed if token cache is stale

## Pipeline Steps

Run these steps sequentially. Stop and report on failure unless noted otherwise.

### Step 1 — Sync data (~5 min)

```bash
set -a && source .env && set +a && PYTHONUNBUFFERED=1 uv run sync-metrics --write 2>&1
```

- **Background immediately** (`block_until_ms=0`) — this takes ~5 minutes.
- **Monitor for SSO**: If no Snowflake query output appears within 15 seconds, alert the user that SSO may need browser login. Do not wait silently.
- Poll the terminal until sync completes. Look for the final summary line.
- If sync fails, stop and report. Do not proceed with stale data.

### Step 2 — Lint

```bash
just lint
```

If lint fails, attempt `just fix` and re-lint. If still failing, report and stop.

### Step 3 — Build dashboard

```bash
just build
```

This bundles TypeScript (`esbuild`) and runs `build.py` to inject data into the HTML.

### Step 4 — Generate all reports

```bash
set -a && source .env && set +a && PYTHONUNBUFFERED=1 just generate-reports
```

Runs every `reports/*/generate.py`. Each report queries Snowflake/GetDX (SSO token is cached from Step 1). If an individual report fails, log the failure but continue generating the rest.

### Step 5 — Test

```bash
just test
```

Playwright + node:test dashboard tests. Report pass/fail but do not block publishing on test failure — flag it in the summary instead.

### Step 6 — Publish main dashboard

```bash
./publish.sh
```

Uploads `dx-executive-dashboard.html` to `https://hosting.example.com/sites/dx-executive-dashboard/`.

If curl fails, remind the user to check WARP VPN.

### Step 7 — Publish deep-dive reports

For each report below, zip its output directory and upload to Blockcell:

| Report module | Output directory | Blockcell site name |
|---|---|---|
| `loc_segmentation` | `reports/loc_segmentation/output/` | `vr-loc-segmentation` |
| `unified_segmentation` | `reports/unified_segmentation/output/` | `velocity-segmentation-deepdive` |
| `roadmap_view` | `reports/roadmap_view/output/` | `signal-deck` |

Upload command for each:

```bash
cd reports/<module>/output \
  && zip -r /tmp/<site>.zip . \
  && curl -fsS -X POST -H "Accept: application/json" \
       -F "file=@/tmp/<site>.zip" \
       "https://hosting.example.com/api/v1/sites/<site>/upload?force=true" \
  && rm /tmp/<site>.zip
```

Reports without Blockcell sites (`ai_code_writer_segmentation`, `pr_deploy_divergence`, `dashboard_validation`) are generated in Step 4 but not published.

### Step 8 — Summary

Print a summary table:

```
Pipeline Summary
────────────────────────────────────────
Sync:       ✓ completed (latest week: YYYY-MM-DD)
Lint:       ✓ passed
Build:      ✓ completed
Reports:    ✓ 7/7 generated (or X/7 with failures noted)
Tests:      ✓ passed (or ✗ N failures — review before sharing)
────────────────────────────────────────
Published:
  Dashboard:                https://hosting.example.com/sites/dx-executive-dashboard/
  LOC Segmentation:         https://hosting.example.com/sites/vr-loc-segmentation/
  Velocity Segmentation:    https://hosting.example.com/sites/velocity-segmentation-deepdive/
  Signal Deck:              https://hosting.example.com/sites/signal-deck/
```

## Error Handling

- **Sync hung / no SSO prompt**: Alert user within 15 seconds. Do not poll silently.
- **Lint failure**: Try `just fix`, re-lint. Stop if still broken.
- **Report generation failure**: Log which report failed, continue with the rest.
- **Blockcell upload failure**: Check WARP VPN. Retry once. If still failing, note in summary.
- **Test failure**: Do not block publishing — flag in summary for user to review.
