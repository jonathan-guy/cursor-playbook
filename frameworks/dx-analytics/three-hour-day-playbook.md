# Three-Hour Day Playbook

A framework for reducing hands-on-keyboard time from 16+ hours to ~3 hours per day by automating everything except decisions that require human judgment.

## Core Principle

Your job shifts from **doing the work** to **reviewing and directing AI-generated work**. The automation stack handles data pipelines, validation, report generation, and even drafting insights. You handle prioritization, quality judgment, and stakeholder communication.

## Daily Schedule

| Time | Activity | Duration | Mode |
|------|----------|----------|------|
| 7:30 AM | Morning briefing arrives in Slack | — | Auto |
| 8:00 AM | Review briefing, triage alerts, approve/reject overnight PRs | 30 min | Human |
| 9:00 AM | Deep work: one focused task (analysis, insight writing, stakeholder prep) | 90 min | Human |
| 3:00 PM | Afternoon brief: scope tonight's automated work | 30 min | Human |
| 5:00 PM | Quick review: check mid-day results, merge approved PRs | 30 min | Human |
| 6 PM–2 AM | Overnight automation: validation + autonomous builder | — | Auto |

**Total human time: ~3 hours.** Weekends and holidays: morning briefing only (5 min review).

## Automation Stack

### Already Running (Nightshift)

| Component | When | What it does |
|-----------|------|-------------|
| **Nightwatch** | 2 AM | Validates all dashboard data (arithmetic, time-series, freshness, cross-report consistency). Sends Slack DM with results. |
| **Nightagent** | 6 PM + 1 AM | Picks up backlog items, creates feature branches, opens draft PRs. Quality gates enforced. |
| **Nightagent Brief** | 3 PM | Afternoon briefing: analyzes git activity, presents top backlog candidates, scopes tonight's work. |
| **End-to-End Refresh** | Weekly (manual) | Full pipeline: sync all data, build dashboard, generate reports, publish everything. |

### Built (Phase 4 Automation Stack)

| Component | Script | When | What it does |
|-----------|--------|------|-------------|
| **Morning Briefing** | `scripts/morning_briefing.py` | Daily (overnight) | Slack DM: nightwatch results, auto-triage, data freshness, open draft PRs, day context. |
| **Auto-Triage** | `scripts/auto_triage.py` | Integrated into morning briefing + nightwatch | Pattern-matches failures into known categories (stale data, GetDX lag, roster inflation, etc). Reduces manual triage by ~60%. |
| **Discovery Scanner** | `scripts/discovery_scanner.py` | Sunday overnight | Scans Snowflake INFORMATION_SCHEMA, scores new tables by DX relevance, sends Slack notification. |
| **Weekly Draft + Honest Take** | `scripts/weekly_digest.py --save-draft` | Sunday overnight | Writes highlight draft to `data/weekly/` with WoW trends and an "Honest Take" section for private stakeholder notes. |
| **Stakeholder Briefing** | `scripts/rachel_briefing.py` | After draft review | Reads approved draft (with honest-take), sends formatted Slack DM to stakeholder. |

All scripts support `--dry-run` for local testing. Wired into `scripts/nightshift.py` overnight schedule.

## What Gets Your 3 Hours

The human hours are spent on:

1. **Morning review (30 min):** Read the briefing. Approve or reject nightagent PRs. Flag anything urgent.
2. **Deep work (90 min):** One task that requires judgment — writing insights, designing a new analysis, preparing for a stakeholder conversation. AI drafts the starting point; you refine.
3. **Afternoon scoping (30 min):** Review the nightagent brief. Decide what gets built tonight. Add context or constraints.
4. **End-of-day review (30 min):** Check that automated outputs look right. Merge what's good.

## Key Design Decisions

- **Drafts, not finals.** Automation produces drafts that you review. Nothing reaches stakeholders without your approval.
- **Quality gates are non-negotiable.** Every automated change runs lint, build, and test. Failures block the PR.
- **Nightagent never merges.** It opens draft PRs only. You merge after review.
- **One deep-work task per day.** Context-switching is the enemy. Pick one thing for your 90-minute block and protect it.

## Adapting for a Team

When adding a collaborator:

- **Split the morning review.** One person reviews data quality, the other reviews PRs.
- **Assign deep-work blocks by domain.** Analyst focuses on insights; engineer focuses on pipeline improvements.
- **Keep the afternoon brief centralized.** One person scopes the nightagent to avoid conflicts.
- **Document everything in the catalog.** The metric catalog and source registry ensure both team members have full context.
