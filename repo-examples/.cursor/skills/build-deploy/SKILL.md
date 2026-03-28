---
name: build-deploy
description: Build and deploy selected Blockcell sites. Presents all deployable sites for multi-select with build/deploy-only toggle, then builds and deploys in parallel. Use when the user invokes /build, /build-deploy, asks to rebuild, redeploy, publish, or refresh any Blockcell artifact.
---

# Build & Deploy to Blockcell

## Step 1 — Ask what to deploy

**Do NOT run any shell commands first.** Go straight to AskQuestion with two questions in a single call:

**Question 1** — id: `sites`, multi-select (`allow_multiple: true`), prompt: "Which sites?"

| Option id | Label |
|-----------|-------|
| `all` | All Sites |
| `dashboard` | DX Executive Dashboard |
| `signal-deck` | Signal Deck |
| `unified-seg` | Velocity Metrics Deep Dive |
| `loc-seg` | AI-Assisted PR Analysis |
| `pr-deploy` | PR-Deploy Divergence |
| `guardrails` | Guardrail Framework |
| `bb-support` | BuilderBot Support Dashboard |
| `dx-metrics` | DX Metrics Q2 |

**Question 2** — id: `mode`, single-select, prompt: "Build mode?"

| Option id | Label |
|-----------|-------|
| `build-deploy` | Build & Deploy |
| `deploy-only` | Deploy Only (skip builds, upload existing output) |

If user selects `all`, expand to all individual sites.

### Free-text fallback

If the user responds with prose instead of selecting options, map their response to the closest site(s) and mode:

- "just the dashboard" / "rebuild the dashboard" → `dashboard` + `build-deploy`
- "deploy everything" / "all sites" → `all` + `build-deploy`
- "redeploy signal deck" / "republish signal deck" → `signal-deck` + `deploy-only`
- "build unified seg and loc seg" → `unified-seg`, `loc-seg` + `build-deploy`

Confirm your interpretation in one line, then proceed to Step 2.

## Step 2 — Build and deploy in parallel

Launch **every** selected site simultaneously using separate Shell tool calls, each with **`block_until_ms: 0`** so they all start at once. Do NOT wait for one to finish before launching the next.

### Registry

| Key | Module | Blockcell Slug |
|-----|--------|----------------|
| `dashboard` | _(special)_ | `dx-executive-dashboard` |
| `signal-deck` | `roadmap_view` | `signal-deck` |
| `unified-seg` | `unified_segmentation` | `velocity-segmentation-deepdive` |
| `loc-seg` | `loc_segmentation` | `vr-loc-segmentation` |
| `pr-deploy` | `pr_deploy_divergence` | `dx-pr-deploy-divergence` |
| `guardrails` | `guardrail_framework` | `guardrail-framework` |
| `bb-support` | `builderbot_support` | `builderbot-support-dashboard` |
| `dx-metrics` | `dx_metrics_q2` | `vr-gsm-q2-okrs` |

### Dashboard commands

**Build & Deploy:**
```bash
cd /Users/jguy/velocity-reporting && \
  export PATH="/Users/jguy/Library/nodejs/nodejs-24.13.1-block-2024/bin:$PATH" && \
  npx esbuild src/main.ts --bundle --format=iife --outfile=dist/dashboard.js 2>&1 && \
  uv run build 2>&1 && \
  ./publish.sh 2>&1
```

**Deploy Only:**
```bash
cd /Users/jguy/velocity-reporting && ./publish.sh 2>&1
```

**Staging deploy** (when user asks for staging):
```bash
cd /Users/jguy/velocity-reporting && ./publish.sh dx-executive-dashboard-staging 2>&1
```

### Report commands (all other keys)

Substitute `{MODULE}` and `{SITE}` from the registry.

**Build & Deploy:**
```bash
cd /Users/jguy/velocity-reporting && \
  set -a && source .env 2>/dev/null; set +a && \
  uv run python -m reports.{MODULE}.generate 2>&1 && \
  ./publish.sh {SITE} reports/{MODULE}/output 2>&1
```

**Deploy Only:**
```bash
cd /Users/jguy/velocity-reporting && \
  ./publish.sh {SITE} reports/{MODULE}/output 2>&1
```

## Step 3 — Verify

After all commands finish (poll terminal files), confirm each has exit code 0. Summarize as a table:

| Site | Status | URL |
|------|--------|-----|
| ... | pass/fail | `https://blockcell.sqprod.co/sites/{SITE}/` |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `npx: command not found` | Ensure PATH includes the nodejs bin dir |
| `uv run build` fails | Check `dx-weekly-metrics.jsonc` for syntax errors |
| curl upload fails | Verify VPN (WARP) is connected |
| Report generate fails with auth error | Ensure `.env` has valid Snowflake credentials and SSO token is fresh |
