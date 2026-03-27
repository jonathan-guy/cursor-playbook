# Cursor IDE Configuration Playbook

Personal reference for Cursor IDE configuration patterns, agent skills, and repo automation tricks developed on the [velocity-reporting](https://github.com/jonathan-guy) project (Q1 2026).

## Architecture: Three-Tier Context Injection

The core idea is a layered system where AI agents get the right domain knowledge automatically, based on what they're doing.

### Tier 1: Always-On (`AGENTS.md` / `CLAUDE.md`)

Root-level agent instructions loaded on every interaction. Contains architecture reference, branching strategy, session lifecycle, step-by-step checklists (e.g. "Adding a New Chart"), commentary tone rules, and the "Landing the Plane" protocol.

Both `AGENTS.md` and `CLAUDE.md` are identical — the former for generic agents, the latter for Claude Code specifically.

See [`repo-examples/AGENTS.md`](repo-examples/AGENTS.md) for the full file.

### Tier 2: Glob-Triggered Rules (`.cursor/rules/*.md`)

Domain-specific knowledge files that auto-inject when the agent edits matching file patterns. The agent gets the right context without you having to mention it.

| Rule | Triggers on | What it provides |
|------|------------|-----------------|
| `pipeline-map.md` | `sync_metrics.py`, `build.py`, `src/charts/**`, `queries/**` | End-to-end trace map for every metric (SQL -> sync -> JSONC -> JS -> HTML). Documents 5 different population filter definitions with headcount overlap %. |
| `data-catalog.md` | `queries/**`, `sync_metrics.py` | Inventory of ~582 Snowflake + GetDX tables across 6 databases. Agent knows what columns exist without querying `INFORMATION_SCHEMA`. |
| `upstream-repo-catalog.md` | `queries/**`, `sync_metrics.py` | Maps Snowflake databases to upstream GitHub repos. Includes 12 "Lessons Learned" data pitfalls. |
| `chart-data-dictionary.md` | `dx-weekly-metrics.jsonc`, `build.py`, `src/charts/**` | Methodology reference for all 47 charts: exact numerator/denominator logic, population definitions. |
| `chart-keys.md` | *(always available)* | Valid `execSummary` chart key reference — prevents broken charts from invalid key references. |
| `blockcell-formatting.md` | `reports/**/generate.py`, `lib/html.py`, `lib/tokens.*` | Universal formatting standard: 1200px max-width, design tokens, shared component classes. |

**Key insight:** Editing a SQL query? The agent automatically knows every available table. Editing a chart? It knows the exact data shape and methodology. No manual context needed.

See [`repo-examples/.cursor/rules/`](repo-examples/.cursor/rules/) for examples.

### Tier 3: On-Demand Skills (`.cursor/skills/*/SKILL.md`)

Full workflow recipes invoked via slash commands or natural language. Not just context — step-by-step procedures with error handling, verification, and cleanup.

---

## Personal Cursor Environment (`~/.cursor/`)

Config that follows you across all projects.

### Personal Skills

| Skill | Slash Command | What it does | Key trick |
|-------|--------------|-------------|-----------|
| [`questions`](personal/skills/questions/SKILL.md) | `/questions` | Forces agent to pause and ask 2-4 clarifying questions before acting | A "circuit breaker" that overrides the agent's default "just do it" behavior |
| [`whisper`](personal/skills/whisper/SKILL.md) | `/whisper` | Transcribes audio via local Whisper (live dictation, voice memo, file) | Ships a `jargon.txt` priming file with domain-specific vocabulary — dramatically improves accuracy without fine-tuning |
| [`glean`](personal/skills/glean/SKILL.md) | `/glean` | Queries company Glean AI (enterprise knowledge base) from terminal | Self-contained `uv run` script with PEP 723 inline deps — zero setup files needed |

### Personal Rules

| Rule | File | What it does |
|------|------|-------------|
| [Plan mode confirmations](personal/rules/plan-mode-confirmations.mdc) | `plan-mode-confirmations.mdc` | Styles all "ready to proceed?" lines in **bold orange** (#FF8C00) — makes the plan-mode handoff moment visually unmissable |

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

### Design Token System

Single source of truth in `lib/tokens.json`, exposed as:
- CSS custom properties (`var(--accent-primary)`)
- Chart palette (`VR.color(0)`)
- Number formats (`format_metric(v, 'percentage')`)

Change a color, font, or spacing globally by editing one JSON file.

### Import-Only CI Verification

CI does `importlib.import_module()` on every report's `generate.py` — catches broken imports without needing database credentials.

---

## Autonomous Overnight System (NightShift)

A three-phase daily cycle with human-in-the-loop checkpoints, running on ephemeral cloud workstations via GitHub Actions.

| Time | Phase | Skill | Mode |
|------|-------|-------|------|
| 3 PM | **Briefing** | `/nightagent-brief` | Interactive — user picks up to 3 backlog items |
| 6 PM | **Execution** | `/nightagent` | Autonomous — creates feature branches, opens draft PRs |
| 2 AM | **Validation** | `/nightwatch` | Autonomous — 190+ data integrity checks |
| 5 AM | **Notification** | Slack DM | Automated — sends results summary |
| Thursday AM | **Grooming** | `/groom` | Interactive — processes nightwatch suggestions |

### Architecture

```
GitHub Actions cron
  -> nightshift_trigger.py (sparse checkout — only fetches this script)
  -> BuilderBot API
  -> ephemeral Blox workstation
  -> Goose agent executes skill
```

### Safety Guardrails

- **No briefing = forced read-only.** Without a completed briefing, all items are read-only (research only, no code changes).
- **Commented-out code with markers.** Sync function additions are committed with `# --- NIGHTAGENT: Uncomment after verifying ---` markers.
- **Draft PRs only.** Nightagent never merges — only opens draft PRs on feature branches.
- **Manual approval.** BuilderBot tasks require human approval in the UI.
- **Ephemeral contract file.** `.nightagent-requests.md` bridges briefing and execution phases, is gitignored (disposable).
- **Sparse checkout in GHA.** Only fetches the trigger script, not the whole repo.

### Self-Improving Documentation

Nightwatch Step 5 reads agent transcripts, finds recurring errors, and proposes doc updates to `.cursor/rules/` and `AGENTS.md`. The system patches its own instructions based on observed failures.

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
  go-link -> ~/.agents/skills/go-link
```

This pattern lets you mix personal skills with team-provided ones, and update the shared library independently (e.g., `git pull` in `~/.agents/skills/`).

---

## Patterns Worth Remembering

1. **Glob-scoped rules as "just-in-time" context** — Scope domain knowledge to the files where it's needed instead of stuffing everything into one giant system prompt.

2. **Skills as workflow recipes, not prompts** — Each skill is a step-by-step runbook with error handling, not just a personality injection.

3. **Safety through forced read-only defaults** — When context is missing, default to the safest behavior.

4. **Ephemeral contract files** — Bridge two separate agent sessions (briefing writes, execution reads) without a shared database. Gitignore them.

5. **`uv run` with PEP 723 inline deps** — Self-contained scripts that auto-install their own dependencies. Zero setup for one-off tools.

6. **Whisper jargon priming** — A plain text file of domain terms fed as `--initial_prompt` dramatically improves transcription accuracy.

7. **The "questions" meta-skill** — A circuit breaker that forces the agent to scope before implementing. Attach to any ambiguous request.

8. **Bold orange confirmations** — A one-line rule that creates a strong visual signal for the plan-mode handoff moment.

9. **`artifacts.yaml` as dependency graph** — `relates_to` and `feeds` fields create a machine-readable artifact map that auto-renders in a published visualization.

10. **449 plan files as audit trail** — Every non-trivial agent task generates a `.plan.md` in `~/.cursor/plans/`. Useful for replaying decisions.

---

## File Index

```
frameworks/                            # Reusable development methodology
  rpi/
    PLAYBOOK.md                        # Research-Plan-Implement framework (600 lines)
    PLAN-TEMPLATE.md                   # Reusable implementation plan template

personal/                              # ~/.cursor/ config (cross-project)
  rules/
    plan-mode-confirmations.mdc        # Bold orange "ready?" styling
  skills/
    questions/SKILL.md                 # Clarifying questions meta-skill
    whisper/
      SKILL.md                         # Whisper transcription skill
      jargon.txt                       # Domain vocabulary for priming
      scripts/
        dictate.sh                     # Live mic -> clipboard (Cmd+Shift+D)
        instruct.sh                    # Voice memo -> clipboard
        transcribe.sh                  # File -> transcript
    glean/
      SKILL.md                         # Glean AI chat skill
      glean-cli.py                     # Self-contained CLI (PEP 723 deps)
  cursor-gitignore                     # ~/.cursor/.gitignore (deny-all + allowlist)

repo-examples/                         # Repo-level config examples
  AGENTS.md                            # Root agent instructions
  .pre-commit-config.yaml              # Lint + credential guard hooks
  .cursor/
    rules/
      blockcell-formatting.md          # Glob-triggered formatting standard
      chart-keys.md                    # Reference data (always available)
    skills/
      banner/SKILL.md                  # Simple toggle skill
      roadmap/SKILL.md                 # CRUD workflow skill
      groom/SKILL.md                   # Interactive grooming skill
      build-deploy/SKILL.md            # Multi-select build/deploy skill
```
