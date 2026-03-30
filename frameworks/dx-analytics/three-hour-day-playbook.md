# Three-Hour Day Playbook

A framework for reducing hands-on-keyboard time from 16+ hours to ~3 hours per day by automating everything except decisions that require human judgment.

## Core Principle

Your job shifts from **doing the work** to **reviewing and directing AI-generated work**. The automation stack handles data pipelines, validation, report generation, and even drafting insights. You handle prioritization, quality judgment, and stakeholder communication.

## Daily Schedule

| Time | Activity | Duration | Mode |
|------|----------|----------|------|
| 6:00 AM | Morning briefing arrives in Slack (local launchd trigger) | — | Auto |
| 8:00 AM | Review briefing, run `/dawn-patrol` to review/merge nightagent branches | 30 min | Human |
| 9:00 AM | Deep work: one focused task (analysis, insight writing, stakeholder prep) | 90 min | Human |
| 9 AM–5 PM | On-demand dispatch: `/delegate` sends self-contained tasks to cloud anytime | — | Human + Auto |
| 3:00 PM | Afternoon brief: scope tonight's automated work via `/nightagent-brief` | 30 min | Human |
| 5:00 PM | NightShift triggers: validation + nightagent + doc maintenance (single cloud task) | — | Auto |
| Wed 5 PM | Metric discovery: scan data warehouse for new tables, update catalogs | — | Auto |

**Total human time: ~3 hours.** Weekends and holidays: morning briefing only (5 min review).

## Automation Stack

### NightShift Orchestrator

All NightShift modes run on ephemeral cloud workstations. Local launchd plists trigger `nightshift_trigger.py`, which calls the cloud workstation API. The workstation clones the repo, executes the scheduled work, then self-destructs.

| Mode | Schedule | What it does |
|------|----------|-------------|
| `overnight` | Daily 5 PM | Validation + Slack DM + doc maintenance + morning briefing prep + nightagent execution |
| `evening` | Daily 9 PM | Lightweight: support dashboard refresh only |
| `thursday-extras` | Thu 5 PM | Full overnight + metric discovery (full mode) |
| `report-refresh` | On demand | Regenerate and deploy all reports |
| `monthly-summary` | Monthly | Generate monthly trend summary |
| `weekly-digest` | Weekly | Auto-draft weekly highlights for stakeholder |
| `dispatch` | On demand | Execute tasks from `.nightagent-requests.md` immediately |

### Component Skills

| Component | Skill | What it does |
|-----------|-------|-------------|
| **Nightwatch** | `/nightwatch` | 443+ checks across 19 categories: arithmetic invariants, time-series health, cross-report consistency, golden assertions. |
| **Nightagent** | `/nightagent` | Picks up backlog items (tagged `[nightagent-ready]`), creates `nightagent/*` feature branches, runs quality gates. |
| **Nightagent Brief** | `/nightagent-brief` | Afternoon briefing: analyzes git activity, presents top backlog candidates, writes execution plan. |
| **Dawn Patrol** | `/dawn-patrol` | Morning review: walks through unmerged nightagent branches with accept/edit/skip/reject options. |
| **End-to-End Refresh** | `/endtoend` | Full pipeline: sync → lint → build → generate reports → test → publish. ~10 min. |
| **Delegate** | `/delegate` | Converts freeform ideas to nightagent specs, dispatches immediately or queues for tonight. |

### Supporting Scripts

| Script | When | What it does |
|--------|------|-------------|
| `morning_briefing.py` | Daily (overnight) | Slack DM: nightwatch results, data freshness, nightagent summaries, suggested actions. |
| `doc_maintenance.py` | Daily (overnight) | Checks artifact freshness, catalog consistency, stale dates. Queues fixes for nightagent. |
| `metric_discovery.py` | Weekly (Wed/Sun) | Scans data warehouse INFORMATION_SCHEMA, scores new tables by relevance, surfaces onboarding opportunities. |
| `weekly_digest.py` | Weekly | Auto-drafts highlights with WoW trends for stakeholder review. |
| `nightshift_trigger.py` | Scheduled (launchd) | Creates cloud workstation tasks via API. Supports all NightShift modes. |
| `nightagent_executor.py` | Called by agent | Wraps nightagent execution with logging, credential loading, and error handling. |

### Time-Conditional Rules

Two `.cursor/rules/` files encode the daily rhythm so the agent auto-triggers the right workflow:

| Rule | Window | Effect |
|------|--------|--------|
| `morning-briefing.md` | 7–11 AM | Auto-runs validation + overnight status briefing on first session of the day |
| `nightagent-briefing-reminder.md` | 2–6 PM | Auto-starts the afternoon briefing if not already done today |

## What Gets Your 3 Hours

1. **Morning review (30 min):** Read the briefing. Run `/dawn-patrol` to review nightagent branches. Approve or reject. Flag anything urgent.
2. **Deep work (90 min):** One task that requires judgment — writing insights, designing a new analysis, preparing for a stakeholder conversation. AI drafts the starting point; you refine.
3. **Afternoon scoping (30 min):** Review the nightagent brief. Decide what gets built tonight. Dispatch urgent items immediately via `/delegate`.

## Daytime Dispatch

Cloud dispatch isn't limited to the overnight window. Throughout the day:

- **`/delegate`** converts any in-session idea to a spec, then dispatches to a cloud workstation immediately or queues for tonight.
- **`just dispatch-endtoend`** runs the full pipeline refresh on cloud (~10 min, doesn't block your terminal).
- **`just dispatch-build --sites <keys>`** builds and deploys specific reports on cloud.
- Dispatched tasks are marked `<!-- dispatched -->` in `.nightagent-requests.md` so the 5 PM NightShift skips them automatically.

## Key Design Decisions

- **Drafts, not finals.** Automation produces drafts that you review. Nothing reaches stakeholders without your approval.
- **Quality gates are non-negotiable.** Every automated change runs lint, build, and test. Failures block the merge.
- **Nightagent never merges.** It pushes to `nightagent/*` feature branches. You merge after review via dawn patrol.
- **One deep-work task per day.** Context-switching is the enemy. Pick one thing for your 90-minute block and protect it.
- **Voice-to-nightagent pipeline.** `Cmd+Shift+F` records voice → Whisper transcribes → appended to quick-fixes file → nightagent picks it up at 3 PM. Fix bugs by talking.
- **Self-improving documentation.** Nightwatch reads agent transcripts, finds recurring errors, and proposes doc updates. The system patches its own instructions.

## Adapting for a Team

When adding a collaborator:

- **Split the morning review.** One person reviews data quality, the other reviews PRs.
- **Assign deep-work blocks by domain.** Analyst focuses on insights; engineer focuses on pipeline improvements.
- **Keep the afternoon brief centralized.** One person scopes the nightagent to avoid conflicts.
- **Document everything in the catalog.** The metric catalog and source registry ensure both team members have full context.
