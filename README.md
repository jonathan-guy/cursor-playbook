# Cursor IDE Configuration Playbook

Personal reference for Cursor IDE configuration patterns, agent skills, and repo automation tricks developed on an analytics monorepo project (Q1–Q2 2026).

## Architecture: Three-Tier Context Injection

The core idea is a layered system where AI agents get the right domain knowledge automatically, based on what they're doing.

### Tier 1: Always-On (`AGENTS.md`)

Root-level agent instructions loaded on every interaction. Contains architecture reference, branching strategy, session lifecycle, step-by-step checklists (e.g. "Adding a New Chart"), commentary tone rules, and the "Landing the Plane" protocol. Currently ~790 lines and growing.

See [`repo-examples/AGENTS.md`](repo-examples/AGENTS.md) for a redacted version.

### Tier 2: Context-Injected Rules (`.cursor/rules/*.md`)

Domain-specific knowledge files that inject automatically based on trigger conditions. The agent gets the right context without you having to mention it.

Rules now fall into three categories:

#### Always-Apply Rules

Loaded on every interaction, regardless of which files are open.

| Rule | What it provides |
|------|-----------------|
| `commit-safety.md` | Double-confirmation before commits, blocks force-push/hard-reset, safe reorganization guidelines. |
| `artifact-numbers.mdc` | Maps shortcodes (art01–art24) to artifact names/metadata. When the user says "art07", the agent knows they mean the Deep Analysis hub. |
| `dawn-patrol.mdc` | Session-start check: counts unmerged `nightagent/*` branches and suggests `/dawn-patrol` to review them. Once per session. |
| `proactive-dispatch.mdc` | Continuous habit: identifies self-contained tasks that should run on a cloud workstation instead of locally. Suggests dispatch for heavy operations. |

#### Glob-Triggered Rules

Auto-inject when the agent edits matching file patterns.

| Rule | Triggers on | What it provides |
|------|------------|-----------------|
| `sql-pitfalls.md` | `queries/**`, `sync_metrics.py` | Hard-won SQL gotchas: bot exclusion logic, pipeline lag for specific repos, CDP dedup patterns, date boundary conventions, table schema differences. |
| `blockcell-formatting.md` | `reports/**/generate.py`, `lib/html.py`, `lib/tokens.*` | Universal formatting standard: 1200px max-width, design tokens, shared component classes. |
| `chart-design-principles.md` | `reports/**/generate.py`, `src/charts/**`, `lib/charts.js` | Chart type selection (bars vs area), volume strips beneath percentage charts, dynamic granularity, stacked fills, trailing average treatment. |

**Key insight:** Editing a SQL query? The agent automatically knows every data pitfall. Editing a chart? It knows the design principles. No manual context needed.

#### Time-Conditional Rules

Trigger based on time of day, not file patterns. These drive the daily automation cadence.

| Rule | Window | What it does |
|------|--------|-------------|
| `morning-briefing.md` | 7–11 AM PT | On session start, runs validation checks and surfaces overnight automation results (Blox task status, nightagent branches, data freshness). Writes a breadcrumb file to avoid re-running. Friday variant includes a feedback collection loop. |
| `nightagent-briefing-reminder.md` | 2–6 PM PT | On session start, auto-triggers the afternoon briefing skill to scope tonight's automated work. Checks for today's briefing output before firing. |

Time-conditional rules are a powerful pattern: they encode *when* to do something, not just *what*. The agent inherits a daily rhythm without the user having to remember to invoke anything.

See [`repo-examples/.cursor/rules/`](repo-examples/.cursor/rules/) for examples.

### Tier 3: On-Demand Skills (`.cursor/skills/*/SKILL.md`)

Full workflow recipes invoked via slash commands or natural language. Not just context — step-by-step procedures with error handling, verification, and cleanup.

The project now has **24 repo-level skills**, organized by archetype:

#### Pipeline & Operations

| Skill | Slash Command | Archetype | What it does |
|-------|--------------|-----------|-------------|
| `endtoend` | `/endtoend` | Sequential pipeline | Full refresh: sync → lint → build → generate reports → test → publish. ~10 min. Defaults to cloud dispatch. |
| `build-deploy` | `/build-deploy` | Multi-select + parallel | Presents AskQuestion site picker, launches all deploys in parallel Shell calls. |
| `nightwatch` | `/nightwatch` | Validation suite | 443 data integrity checks across 19 categories. |
| `nightshift` | `/nightshift` | Orchestrator | Manages the NightShift automation system — overnight, evening, thursday-extras, report-refresh modes on ephemeral cloud workstations. |
| `builderbot` | `/builderbot` | API integration | Creates tasks on BuilderBot for ephemeral cloud workstations. |

#### Autonomous Work

| Skill | Slash Command | Archetype | What it does |
|-------|--------------|-----------|-------------|
| `nightagent` | `/nightagent` | Autonomous builder | Picks up backlog items, creates feature branches, runs quality gates, generates change summaries. |
| `nightagent-brief` | `/nightagent-brief` | Interactive scoping | 3 PM briefing: analyzes git, presents candidates, writes execution plan. |
| `delegate` | `/delegate` | Dispatch + handoff | Converts in-session ideas into task specs, dispatches immediately to a cloud workstation or queues for tonight. |
| `dawn-patrol` | `/dawn-patrol` | Interactive review | Reviews unmerged nightagent branches: presents change summaries, diffs, risk flags. Walk through accept/edit/skip/reject per branch. |

#### Analysis & Metrics

| Skill | Slash Command | Archetype | What it does |
|-------|--------------|-----------|-------------|
| `deep-analysis` | `/deep-analysis` | Multi-pass investigation | 4 mandatory passes (exploratory → primary → robustness → accuracy audit). Triangulates across methods, gates every finding through an adversarial audit. |
| `new-metric` | `/new-metric` | Structured intake | Vets upstream sources, checks duplicates, detects conflicts, discovers dimensions, assesses misinterpretation risk. Produces a Metric Intelligence Report. |
| `promote-metric` | `/promote-metric` | Checklist | Wires a validated metric into a published output (dashboard, report, signal deck). |
| `metric-discovery` | `/metric-discovery` | Discovery pipeline | Scans Snowflake for new data sources, checks access grants, explores schemas, updates catalogs. |

#### Reference Skills

Reference skills don't execute workflows — they provide structured domain knowledge the agent can consult. Think of them as queryable documentation.

| Skill | What it provides |
|-------|-----------------|
| `chart-data-dictionary` | Methodology reference for every chart: exact numerator/denominator logic, population definitions, source systems. |
| `data-catalog` | Table and column inventory for all data sources (~600 tables across 6 databases). Agent knows what columns exist without querying `INFORMATION_SCHEMA`. |
| `pipeline-map` | End-to-end trace map for every metric: SQL → sync → JSONC → build → TypeScript renderer → HTML. Documents 5 population filter definitions. |
| `chart-keys` | Valid `execSummary` chart key reference — prevents broken charts from invalid key references. |

#### Planning & Workflow

| Skill | Slash Command | Archetype | What it does |
|-------|--------------|-----------|-------------|
| `promote` | `/promote` | Git workflow | Commit → staging → main → push. Single confirmation. |
| `roadmap` | `/roadmap` | CRUD | Add/update/remove backlog items in the roadmap. |
| `groom` | `/groom` | Interactive cleanup | Scans backlog for stale items, graduates done work, re-tiers. |
| `replan` | `/replan` | Plan revision | Diffs codebase against existing plan, edits plan in-place. |
| `banner` | `/banner` | Simple toggle | Shows/hides the dashboard update banner. |
| `blurb` | `/blurb` | Content generation | Generates a self-contained handoff blurb summarizing the current conversation for another agent or human. |
| `anythingelse` | `/anythingelse` | Audit | Scans the conversation for discussed-but-unexecuted items. Surfaces verbal commitments, side ideas, and deferred work before wrapping up. |

#### Skill Archetypes

The most reusable patterns across these skills:

1. **Sequential pipeline** (`endtoend`) — Run steps in order, stop on failure, report which step failed. Each step has a verify command.
2. **Multi-select + parallel execution** (`build-deploy`) — AskQuestion with `allow_multiple: true` for site selection, then launch parallel Shell calls with `block_until_ms: 0`.
3. **Reference skill** (`data-catalog`, `pipeline-map`) — Not a workflow. Structured domain knowledge the agent reads on demand or when triggered by file-pattern context.
4. **Dispatch + handoff** (`delegate`) — Converts freeform intent into a structured spec, validates it, then dispatches to a remote execution environment. Supports immediate and deferred execution.
5. **Multi-pass investigation** (`deep-analysis`) — 4+ mandatory analytical passes with decision gates between them. Earlier passes feed later ones. Adversarial audit as final gate.
6. **Interactive review** (`dawn-patrol`, `groom`) — Present items one at a time with structured accept/edit/skip/reject options.

---

## Personal Cursor Environment (`~/.cursor/`)

Config that follows you across all projects.

### Personal Skills

| Skill | Slash Command | What it does | Key trick |
|-------|--------------|-------------|-----------|
| [`questions`](personal/skills/questions/SKILL.md) | `/questions` | Forces agent to pause and ask 2-4 clarifying questions before acting | A "circuit breaker" that overrides the agent's default "just do it" behavior |
| [`whisper`](personal/skills/whisper/SKILL.md) | `/whisper` | Voice-to-text: live dictation, voice memos, conversational voice agent, quick-fix dictation for nightagent tasks | Ships a `jargon.txt` priming file and an `update_jargon.sh` that auto-syncs from project catalogs |
| `eng-ai-chat` | — | Searches internal company knowledge grounded in application context | MCP-backed: retrieves AI-generated summaries, dev guides, code search, Google Docs |
| `gdrive` | — | Google Drive/Docs/Sheets/Slides: search, read, write, share, insert images | MCP-backed: full CRUD on Drive plus image insertion into Docs and Slides |
| `go-link` | — | Resolves internal `go/` shortlinks to full URLs | Simple URL rewrite: `go/foo` → `https://go.example.com/foo` |
| `blockcell` | — | Deploy static site prototypes to internal hosting | Shared via symlink from `~/.agents/skills/` |
| `create-rule` | — | Creates `.cursor/rules/*.md` files with proper glob triggers | Meta-skill: guides agent through rule authoring conventions |
| `create-skill` | — | Guides through SKILL.md authoring with best practices | Meta-skill: ensures consistent skill structure |
| `update-cursor-settings` | — | Modifies Cursor/VSCode `settings.json` | Meta-skill: safe settings mutation with backup |

### Personal Rules

| Rule | File | What it does |
|------|------|-------------|
| [Plan mode confirmations](personal/rules/plan-mode-confirmations.mdc) | `plan-mode-confirmations.mdc` | Requires using AskQuestion with clickable options for plan-mode confirmations. Styles the lead-in in **bold orange** (#FF8C00) for visual distinction. |
| [Post-answer continuation](personal/rules/post-answer-continuation.mdc) | `post-answer-continuation.mdc` | After receiving any AskQuestion answer (clicked or typed), immediately continue the workflow. Prevents the "acknowledge and stop" anti-pattern. Handles free-text interpretation and out-of-band interruptions. |

The post-answer-continuation rule is the single most impactful behavioral rule. Without it, agents frequently acknowledge your answer and then stop — waiting for a follow-up message that shouldn't be needed.

### `.gitignore` Allowlist Strategy

The `~/.cursor/` directory uses a deny-all, selectively un-ignore `.gitignore`:

```gitignore
*                          # ignore everything
!skills/                   # then selectively un-ignore
!skills/**
!rules/
!rules/**
!plans/
!plans/**
!projects/*/agent-transcripts/**
!projects/*/agent-notes/**
!plugins/**
!skills-cursor/**
!commands/**
!subagents/**
# ... etc
```

This versions only the useful parts (skills, rules, plans, transcripts) while keeping ephemeral state out. See [`personal/cursor-gitignore`](personal/cursor-gitignore) for the full file.

---

## Repo-Level Tooling Tricks

### Hermit (Pinned Toolchain)

`bin/` directory managed by [Hermit](https://cashapp.github.io/hermit/) ensures everyone (including CI and ephemeral workstations) uses identical tool versions. `bin/activate-hermit` bootstraps the environment. No "works on my machine" issues.

### Pre-Commit Hooks

Two hooks that prevent common mistakes:

```yaml
# .pre-commit-config.yaml
- id: lint
  entry: uv run ruff check .
  types: [python]

- id: no-env
  name: Block .env commits
  entry: bash -c 'echo "ERROR: .env files must not be committed" && exit 1'
  files: ^\.env$
```

The `no-env` hook is a credential-leak guardrail that blocks the commit entirely.

See [`repo-examples/.pre-commit-config.yaml`](repo-examples/.pre-commit-config.yaml).

### `data-component` Naming Convention

All UI elements use `data-component` attributes for AI-agent discoverability:

```html
<div data-component="stat-total-deploys">...</div>
<div data-component="chart-freq-trend">...</div>
```

Prefixes: `stat-`, `chart-`, `table-`, `insight-`. This makes every element addressable in natural language prompts: "Change the color of the `stat-total-deploys` card to green."

The component helpers (`stat_card()`, `chart_box()`, `table_wrap()`, `insight_box()`) accept a `name=` parameter that auto-generates the attribute.

### Design Token System

Single source of truth in `lib/tokens.json`, exposed as:
- CSS custom properties (`var(--accent-primary)`)
- Chart palette (`VR.color(0)`)
- Number formats (`format_metric(v, 'percentage')`)

Change a color, font, or spacing globally by editing one JSON file.

### Import-Only CI Verification

CI does `importlib.import_module()` on every report's `generate.py` — catches broken imports without needing database credentials.

### Artifact Registry as Dependency Graph

`artifacts.yaml` at the repo root tracks every published output with `relates_to` and `feeds` fields, creating a machine-readable dependency graph. This auto-renders in a published artifact map visualization. Each artifact also gets a shortcode file (`.cursor/artifacts/art01-*.md`) so agents can resolve "art07" to the full artifact metadata.

---

## Research-Plan-Implement (RPI) Framework

A structured methodology for AI-assisted development. The full 600-line playbook is at [`frameworks/rpi/PLAYBOOK.md`](frameworks/rpi/PLAYBOOK.md) with a reusable plan template at [`frameworks/rpi/PLAN-TEMPLATE.md`](frameworks/rpi/PLAN-TEMPLATE.md).

### The 8 Slash Commands

| # | Command | Purpose |
|---|---------|---------|
| 1 | `/1_research_codebase` | Deep-dive investigation — spawns parallel agents, saves to `thoughts/shared/research/` |
| 2 | `/2_create_plan` | Interactive planning — generates phased approach with checkboxes |
| 3 | `/3_validate_plan` | Verify implementation matches plan |
| 4 | `/4_implement_plan` | Execute plan phase-by-phase, updating checkboxes as you go |
| 5 | `/5_save_progress` | Save session context for later resumption |
| 6 | `/6_resume_work` | Resume from a saved session |
| 7 | `/7_research_cloud` | Read-only cloud infrastructure analysis |
| 8 | `/8_define_test_cases` | Design acceptance tests using comment-first DSL approach |

### Key Ideas

- **Research before coding.** Even if you think you know the codebase, run `/1_research_codebase` first. Research docs become valuable references.
- **Plans as specs.** Plans with checkboxes serve as both technical spec and progress tracker.
- **Session persistence via markdown.** `thoughts/shared/` accumulates research, plans, and session state as plain markdown files — no database, no special tooling.
- **Parallel agents for research.** A single research query spawns locator, analyzer, and pattern-finder agents simultaneously.
- **Test-first via `/8_define_test_cases`.** Design test cases as comments before writing any implementation code.

---

## Shared Skill Libraries via Symlinks

Skills can come from a shared library (e.g., a team agent-skills repo) and be symlinked into `~/.cursor/skills/`:

```
~/.cursor/skills/
  questions/SKILL.md        # personal — lives here directly
  whisper/SKILL.md          # personal — lives here directly
  gdrive -> ~/.agents/skills/gdrive     # symlink to shared library
  blockcell -> ~/.agents/skills/blockcell
  eng-ai-chat -> ~/.agents/skills/eng-ai-chat
  go-link -> ~/.agents/skills/go-link
```

This pattern lets you mix personal skills with team-provided ones, and update the shared library independently (e.g., `git pull` in `~/.agents/skills/`).

---

## Autonomous Overnight System (NightShift)

A multi-phase daily cycle with human-in-the-loop checkpoints, running on ephemeral cloud workstations via BuilderBot.

### Daily Cadence

| Time | Phase | Skill/Script | Mode |
|------|-------|-------------|------|
| 6:00 AM | **Morning Briefing** | `morning_briefing.py` via launchd | Auto — Slack DM with validation results, data freshness, action items |
| 8:00 AM | **Dawn Patrol** | `/dawn-patrol` | Interactive — review/merge nightagent branches (accept/edit/skip/reject per branch) |
| 9 AM–5 PM | **Daytime Dispatch** | `/delegate`, `just dispatch` | On-demand — dispatch self-contained tasks to cloud workstations anytime |
| 3:00 PM | **Afternoon Brief** | `/nightagent-brief` | Interactive — analyzes git activity, presents backlog candidates, scopes tonight's work |
| 5:00 PM | **NightShift** | `nightshift_trigger.py` | Auto — single cloud task: validation + nightagent execution + Slack notification |
| Wed 5 PM | **Metric Discovery** | `metric_discovery.py` | Auto — scans data warehouse for new tables, checks access, surfaces onboarding opportunities |

**Total human time: ~3 hours.** See [`frameworks/dx-analytics/three-hour-day-playbook.md`](frameworks/dx-analytics/three-hour-day-playbook.md).

### NightShift Modes

NightShift is a single orchestrator (`scripts/nightshift.py`) that supports multiple modes, triggered by launchd plist schedules or on-demand via `just nightshift-trigger`:

| Mode | Schedule | What it does |
|------|----------|-------------|
| `overnight` | Daily 5 PM | Validation + Slack DM + doc maintenance + morning briefing + nightagent execution |
| `evening` | Daily 9 PM | Lightweight: BB Support dashboard refresh only |
| `thursday-extras` | Thu 5 PM | Full overnight + metric discovery (full mode) |
| `report-refresh` | On demand | Regenerate and deploy all reports |
| `monthly-summary` | Monthly | Generate monthly trend summary |
| `weekly-digest` | Weekly | Auto-draft weekly highlights for stakeholder |
| `dispatch` | On demand | Execute tasks from `.nightagent-requests.md` immediately |

### Architecture

```
launchd plist (local Mac schedule)
  → nightshift_trigger.py
  → BuilderBot API (provisions ephemeral cloud workstation)
  → Agent clones repo, executes skill/script
  → Results: branches pushed, Slack DMs sent, reports deployed
  → Workstation self-destructs
```

**Daytime dispatch** is the same architecture but on-demand: `/delegate` writes a spec, `just dispatch` creates a BuilderBot task immediately.

**Sparse checkout optimization:** The trigger script only needs itself and its deps — not the full repo. When triggered from GitHub Actions, use sparse checkout to minimize clone size.

### Safety Guardrails

- **No briefing = forced read-only.** Without a completed briefing, all items are read-only (research only, no code changes).
- **Branch restrictions.** Nightagent may only commit to `nightagent/*` branches. Nightwatch is strictly read-only. The only automation that writes to `staging` is the end-to-end refresh (machine-generated data file only, with a safety guard verifying no other files were modified).
- **Manual approval.** BuilderBot tasks require human approval in the UI.
- **Ephemeral contract file.** `.nightagent-requests.md` bridges briefing and execution phases. Gitignored and disposable.
- **Dry-run validation.** `just nightagent-dry-run` grades specs before dispatch (checks for required fields, verify commands, credential tier assignment).
- **Dispatched-task deduplication.** Tasks dispatched during the day are marked `<!-- dispatched -->` in the requests file. The 5 PM NightShift skips them automatically.

### Dawn Patrol (Morning Review)

The `/dawn-patrol` skill is the human-in-the-loop gate for all autonomous work. It:

1. Fetches all unmerged `nightagent/*` branches
2. For each branch, presents: change summary, diff stats, risk flags, narrative explanation
3. Offers per-branch options: **Accept** (merge to staging), **Edit** (make changes first), **Skip** (defer), **Reject** (delete branch)
4. Handles merge conflicts if they arise

The `dawn-patrol.mdc` rule suggests running this at session start whenever unmerged branches exist.

### Self-Improving Documentation

The overnight validation suite reads agent transcripts, finds recurring errors, and proposes doc updates to `.cursor/rules/` and `AGENTS.md`. The system patches its own instructions based on observed failures.

---

## Deep Analysis as a First-Class Workstream

Analysis isn't just a feature — it's one of the primary ways the project delivers value. The `/deep-analysis` skill implements a rigorous 10-step methodology:

```
Frame → Survey Data → Scaffold → Exploratory Pass → Design → Primary Analysis
  → Robustness & Sensitivity → Accuracy Audit → Triangulation → Synthesize
```

Key design decisions:

- **4 mandatory passes.** Exploratory → primary → robustness → accuracy audit. No shortcuts, even under time pressure.
- **Adversarial accuracy audit.** Every finding goes through a devil's advocate check, pre-mortem, statistical trap checklist (Simpson's paradox, survivorship bias, confounding, etc.), and subgroup consistency verification.
- **Confidence tiers.** High (multiple methods converge + all robustness checks pass) / Medium (primary + 1 robustness check) / Low (single method, marginal significance). Never assign High to a single-method finding.
- **Practical significance over p-values.** Effect sizes in interpretable units are mandatory. A finding that answers "so what?" ships; one that only reports p < 0.05 doesn't.
- **Data-gap flagging.** When an analysis reveals missing data that would strengthen conclusions, the gap is noted in limitations AND auto-added to the backlog with a `[data-gap]` tag.

Analyses follow a lifecycle: **Proposed → In Progress → Ready for Review → Published**. The nightagent can execute analyses autonomously overnight, but results always land at "Ready for Review" — only a human can promote to Published.

See [`repo-examples/.cursor/skills/deep-analysis/SKILL.md`](repo-examples/.cursor/skills/deep-analysis/SKILL.md) for the full 370-line skill definition.

---

## Patterns Worth Remembering

1. **Glob-scoped rules as "just-in-time" context** — Scope domain knowledge to the files where it's needed instead of stuffing everything into one giant system prompt.

2. **Time-conditional rules as daily rhythm** — Encode *when* to do something, not just *what*. Morning briefing, afternoon scoping, and dawn patrol all trigger automatically based on time of day.

3. **Skills as workflow recipes, not prompts** — Each skill is a step-by-step runbook with error handling, not just a personality injection.

4. **Reference skills as queryable documentation** — Not every skill needs to *do* something. Data catalogs, pipeline maps, and chart dictionaries are skills the agent consults — structured domain knowledge that's always available.

5. **Safety through forced read-only defaults** — When context is missing, default to the safest behavior.

6. **Ephemeral contract files** — Bridge two separate agent sessions (briefing writes, execution reads) without a shared database. Gitignore them.

7. **`uv run` with PEP 723 inline deps** — Self-contained scripts that auto-install their own dependencies. Zero setup for one-off tools.

8. **Whisper jargon priming** — A plain text file of domain terms fed as `--initial_prompt` dramatically improves transcription accuracy. Auto-sync from project catalogs with `update_jargon.sh`.

9. **The "questions" meta-skill** — A circuit breaker that forces the agent to scope before implementing. Attach to any ambiguous request.

10. **Post-answer continuation rule** — The single most impactful behavioral rule. Forces the agent to immediately act after receiving an AskQuestion answer instead of acknowledging and stopping.

11. **Bold orange confirmations** — A one-line rule that creates a strong visual signal for the plan-mode handoff moment.

12. **`artifacts.yaml` as dependency graph** — `relates_to` and `feeds` fields create a machine-readable artifact map that auto-renders in a published visualization. Shortcode files (`.cursor/artifacts/art01-*.md`) give agents quick artifact lookup.

13. **Plan files as cross-session handoffs** — `.cursor/plans/*.plan.md` files persist across sessions. Use them to hand off multi-step work between sessions, capturing state, decisions, and remaining steps.

14. **AskQuestion for multi-select UIs** — The `AskQuestion` tool with `allow_multiple: true` creates a structured picker. Combine with parallel Shell calls for batch operations (see `build-deploy` skill).

15. **Metric promotion lifecycle (catalog-first)** — Register metrics in `catalog/metrics.yaml` before writing queries. The 4-stage lifecycle (Discovered → Onboarded → Validated → Promoted) prevents metrics from reaching outputs without validation.

16. **`[nightagent-ready]` tags in the backlog** — Tag backlog items with an inline spec (file paths, changes, acceptance criteria) so the autonomous builder can pick them up without ambiguity.

17. **Golden assertions for data validation** — Manually maintained expected values (e.g., headcount by date) that nightwatch validates against. Catches silent data drift that statistical checks would miss.

18. **Sparse checkout in GitHub Actions** — For trigger scripts that don't need the full repo, use sparse checkout to minimize clone size and avoid credential exposure.

19. **Delegate + dispatch pattern** — `/delegate` converts in-session ideas into structured specs, then `just dispatch` sends them to a cloud workstation immediately. Dispatched tasks are marked so the overnight run skips them. No double-execution.

20. **Adversarial accuracy audit** — Every statistical finding goes through a devil's advocate, pre-mortem, statistical trap checklist, and subgroup consistency check. Findings that fail the audit don't ship — they're dropped or deferred.

21. **Proactive dispatch as a continuous habit** — Don't wait for the user to ask. Throughout every session, identify tasks that should run remotely. Heavy operations (pipeline refresh, multi-report builds) should default to cloud dispatch.

22. **Internal knowledge search mandate** — Before telling a user you can't find something, try the internal knowledge search tool first. It synthesizes across dev guides, code search, docs, and Slack archives. This is how you discover infra setup patterns, permission flows, and team ownership.

23. **Voice-to-nightagent pipeline** — `Cmd+Shift+F` records voice, transcribes via Whisper with jargon priming, appends to `.nightagent-quick-fixes.md`. The 3 PM briefing picks it up. Fix bugs by talking.

---

## File Index

```
frameworks/                            # Reusable development methodology
  rpi/
    PLAYBOOK.md                        # Research-Plan-Implement framework (600 lines)
    PLAN-TEMPLATE.md                   # Reusable implementation plan template
  dx-analytics/
    monorepo-structure.md              # Analytics monorepo folder structure pattern
    metric-promotion-lifecycle.md      # 4-stage metric lifecycle framework
    three-hour-day-playbook.md         # Three-hour day automation playbook

personal/                              # ~/.cursor/ config (cross-project)
  rules/
    plan-mode-confirmations.mdc        # Bold orange "ready?" styling + AskQuestion requirement
    post-answer-continuation.mdc       # Never stall after receiving an answer
  skills/
    questions/SKILL.md                 # Clarifying questions meta-skill
    whisper/
      SKILL.md                         # Whisper voice-to-text (dictation, voice agent, transcription)
      jargon.txt                       # Domain vocabulary for priming
      scripts/
        dictate.sh                     # Live mic → clipboard (Cmd+Shift+D)
        dictate-fix.sh                 # Live mic → nightagent quick-fix (Cmd+Shift+F)
        voice-agent.sh                 # Conversational Claude loop with TTS
        voice_agent_api.py             # Anthropic API wrapper for voice agent
        instruct.sh                    # Voice memo → clipboard
        transcribe.sh                  # File → transcript
        update_jargon.sh              # Auto-sync jargon from project catalogs
  cursor-gitignore                     # ~/.cursor/.gitignore (deny-all + allowlist)

repo-examples/                         # Repo-level config examples
  AGENTS.md                            # Root agent instructions (redacted)
  .pre-commit-config.yaml              # Lint + credential guard hooks
  .cursor/
    rules/
      blockcell-formatting.md          # Glob-triggered formatting standard
      chart-keys.md                    # Reference data (always available)
      chart-design-principles.md       # Chart type selection, volume strips, granularity
      commit-safety.md                 # Double-confirm before commits
      sql-pitfalls.md                  # SQL gotchas and data pitfalls
      morning-briefing.md              # Time-conditional morning automation
      proactive-dispatch.md            # Continuous cloud dispatch suggestions
    skills/
      banner/SKILL.md                  # Simple toggle skill
      roadmap/SKILL.md                 # CRUD workflow skill
      groom/SKILL.md                   # Interactive grooming skill
      build-deploy/SKILL.md            # Multi-select build/deploy skill
      endtoend/SKILL.md               # Sequential pipeline skill
      delegate/SKILL.md               # Dispatch + handoff skill
      deep-analysis/SKILL.md          # Multi-pass investigation skill
      dawn-patrol/SKILL.md            # Interactive branch review skill
```
