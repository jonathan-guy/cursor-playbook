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

### To Build

| Component | When | What it does |
|-----------|------|-------------|
| **Morning Briefing** | 7:30 AM | Slack DM: overnight results, data freshness, action items, suggested focus for the day. |
| **Auto-Draft Highlights** | Monday AM | LLM generates first draft of weekly stakeholder bullets from the data. You edit and approve. |
| **Metric Discovery Scanner** | Wednesday | Diffs upstream data catalogs, flags new tables/columns that could power new metrics. |
| **Auto-Triage** | Continuous | When validation finds failures, attempts diagnosis before alerting (known patterns → auto-resolve). |
| **Stakeholder Briefing** | Weekly | Sends approved highlights to stakeholders via Slack with dashboard link. |

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
