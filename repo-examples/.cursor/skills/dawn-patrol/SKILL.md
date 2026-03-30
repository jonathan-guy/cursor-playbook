---
name: dawn-patrol
description: Review and merge nightagent branches interactively. Discovers unmerged nightagent/* branches, summarizes changes, and walks through accept/edit/skip/reject per branch.
---

# Dawn Patrol — Nightagent Branch Review

Interactive review workflow for autonomous builder branches. Presents change summaries, diffs, and risk flags, then walks through per-branch decisions.

## When to Run

- User invokes `/dawn-patrol`
- Morning briefing suggests unmerged nightagent branches exist
- User asks to review overnight work or merge nightagent changes

## Step 1: Discover Branches

```bash
git fetch origin --prune
git branch -r --no-merged staging | grep 'origin/nightagent/'
```

If no branches found, report "No unmerged nightagent branches" and stop.

## Step 2: Summarize Each Branch

For each branch, gather:

1. **Diff stats**: `git diff staging...<branch> --stat`
2. **Full diff**: `git diff staging...<branch>` (for review)
3. **Commit messages**: `git log staging..<branch> --oneline`
4. **Change summary**: Read `data.json` on the branch if it exists (nightagent writes summaries there)
5. **Risk flags**: Check for changes to critical files (sync_metrics.py, build.py, queries/), large diffs, or missing tests

Present a compact summary table:

| Branch | Files Changed | Insertions | Risk | Summary |
|--------|--------------|------------|------|---------|

## Step 3: Walk Through Each Branch

For each branch, present the summary and ask using AskQuestion:

- **Accept** — Merge to staging (`git merge --no-ff <branch>`)
- **Edit** — Check out the branch for manual edits before merging
- **Skip** — Leave for later (don't merge, don't delete)
- **Reject** — Delete the branch (`git push origin --delete <branch>`)

### On Accept

```bash
git checkout staging
git merge --no-ff origin/nightagent/<name> -m "Merge nightagent/<name>: <summary>"
git push origin staging
git push origin --delete nightagent/<name>
```

Run quality gates after merge: `just lint && just build && just test`. If gates fail, offer to revert.

### On Edit

```bash
git checkout -b nightagent/<name> origin/nightagent/<name>
```

Tell the user to make changes and come back when ready.

### On Reject

```bash
git push origin --delete nightagent/<name>
```

Confirm before deleting.

## Step 4: Summary

After processing all branches, present a summary:

- Accepted: N branches merged to staging
- Skipped: N branches left for later
- Rejected: N branches deleted
- Quality gates: pass/fail status

## Critical Rules

1. **Never auto-merge.** Every branch requires explicit user approval.
2. **Run quality gates after each merge.** If they fail, offer to revert immediately.
3. **Preserve skip decisions.** Skipped branches stay on remote for future review.
4. **Handle merge conflicts gracefully.** If a merge conflicts, present the conflict and offer to resolve or skip.
