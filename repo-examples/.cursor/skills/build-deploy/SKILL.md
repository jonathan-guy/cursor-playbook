---
name: build-deploy
description: Build and deploy selected Blockcell sites. Presents the 6 most recently touched sites for multi-select, then builds and deploys in parallel. Use when the user invokes /build, /build-deploy, asks to rebuild, redeploy, publish, or refresh any Blockcell artifact.
---

# Build & Deploy to Blockcell

Selectively build and deploy Blockcell-hosted sites. Shows the 6 most recently interacted-with sites for multi-select, then builds and deploys selected ones in parallel.

## Step 1 — Find recently touched sites

Run this to rank deployable artifacts by most recent commit:

```bash
cd /Users/jguy/velocity-reporting && \
for entry in \
  "dashboard|DX Executive Dashboard|src/ build.py dx-weekly-metrics.jsonc lib/" \
  "signal-deck|Signal Deck|reports/roadmap_view/ artifacts.yaml thoughts/shared/plans/" \
  "unified-seg|Velocity Segmentation Deep Dive|reports/unified_segmentation/" \
  "loc-seg|AI-Assisted PR Analysis|reports/loc_segmentation/" \
  "pr-deploy|PR-Deploy Divergence|reports/pr_deploy_divergence/" \
  "guardrails|Guardrail Framework|reports/guardrail_framework/"; do
  key=$(echo "$entry" | cut -d'|' -f1)
  name=$(echo "$entry" | cut -d'|' -f2)
  paths=$(echo "$entry" | cut -d'|' -f3)
  ts=$(git log -1 --format='%at' -- $paths 2>/dev/null || echo "0")
  echo "$ts|$key|$name"
done | sort -rn | head -6
```

Each output line is `timestamp|key|display_name`, sorted most-recent-first. Take the top 6.

## Step 2 — Ask user which sites to deploy

Use the **AskQuestion** tool with a single multi-select question (`allow_multiple: true`). Use each entry's `key` as the option `id` and `display_name` as the `label`. Present in recency order (most recent first).

## Step 3 — Build and deploy selected sites

For each selected key, run its build + deploy command. **Launch all selected sites in parallel** using separate Shell tool calls.

### Registry

| Key | Display Name | Report Module | Blockcell Site Slug |
|-----|-------------|---------------|---------------------|
| `dashboard` | DX Executive Dashboard | _(special — see below)_ | `dx-executive-dashboard` |
| `signal-deck` | Signal Deck | `roadmap_view` | `signal-deck` |
| `unified-seg` | Velocity Segmentation Deep Dive | `unified_segmentation` | `velocity-segmentation-deepdive` |
| `loc-seg` | AI-Assisted PR Analysis | `loc_segmentation` | `vr-loc-segmentation` |
| `pr-deploy` | PR-Deploy Divergence | `pr_deploy_divergence` | `dx-pr-deploy-divergence` |
| `guardrails` | Guardrail Framework | `guardrail_framework` | `guardrail-framework` |

### Dashboard build + deploy (`dashboard` key)

```bash
cd /Users/jguy/velocity-reporting && \
  export PATH="/Users/jguy/Library/nodejs/nodejs-24.13.1-block-2024/bin:$PATH" && \
  npx esbuild src/main.ts --bundle --format=iife --outfile=dist/dashboard.js 2>&1 && \
  uv run build 2>&1 && \
  ./publish.sh 2>&1
```

### Report build + deploy (all other keys)

Substitute `{MODULE}` and `{SITE}` from the registry:

```bash
cd /Users/jguy/velocity-reporting && \
  set -a && source .env 2>/dev/null; set +a && \
  uv run python -m reports.{MODULE}.generate 2>&1 && \
  cd reports/{MODULE}/output && \
  zip -r /tmp/{SITE}.zip . && \
  curl -fsS -X POST -H "Accept: application/json" \
    -F "file=@/tmp/{SITE}.zip" \
    "https://blockcell.sqprod.co/api/v1/sites/{SITE}/upload?force=true" && \
  rm /tmp/{SITE}.zip
```

Example for `guardrails`: `{MODULE}` = `guardrail_framework`, `{SITE}` = `guardrail-framework`.

## Verification

For each deployed site, confirm:
1. Exit code 0
2. `"success":true` in the curl/publish response
3. Report the Blockcell URL: `https://blockcell.sqprod.co/sites/{SITE}/`

Summarize all deployed URLs at the end.

## Staging deploy

For the main dashboard only, deploy to staging instead of production:

```bash
./publish.sh dx-executive-dashboard-staging
```

URL: `https://blockcell.sqprod.co/sites/dx-executive-dashboard-staging/`

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `npx: command not found` | Ensure PATH includes `/Users/jguy/Library/nodejs/nodejs-24.13.1-block-2024/bin` |
| `uv run build` fails | Check `dx-weekly-metrics.jsonc` for syntax errors (trailing commas OK, JSONC) |
| curl upload fails | Verify VPN (WARP) is connected |
| Report generate fails with auth error | Ensure `.env` has valid Snowflake credentials and SSO token is fresh |
