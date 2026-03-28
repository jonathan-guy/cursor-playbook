---
description: Enforces double-confirmation before commits and blocks dangerous git operations
alwaysApply: true
---

# Commit Safety

All git operations in this repo require extra caution. Follow these rules for every commit.

## Before Staging

1. Run `git diff --stat` and show the summary to the user.
2. If more than 10 files are changed, call out the count explicitly: "This commit touches N files."
3. Never stage files matching `.env`, `credentials.*`, or `*.secret`.

## Before Committing

Show the user a confirmation prompt using **bold orange text**:

**<span style="color: #FF8C00;">About to commit N files to branch `<branch>`. Proceed?</span>**

Wait for explicit "yes" or "go ahead" before running `git commit`.

## Before Merging to staging or main

Show a second confirmation with the merge target:

**<span style="color: #FF8C00;">About to merge `<source>` into `<target>`. This affects production. Proceed?</span>**

Wait for explicit confirmation before merging.

## Blocked Operations

- **Never** run `git push --force` on any branch.
- **Never** run `git reset --hard` without user confirmation.
- **Never** amend a commit that has been pushed to remote.
- **Never** push directly to `main` — all changes go through `staging` first.

## Reorganization Commits

For commits that are part of a repo reorganization (folder restructure, file moves, bulk renames):

1. Prefer small, atomic commits (one logical change per commit).
2. Show the full file list in the diff summary.
3. Run `just lint` before committing to catch import breakage from file moves.
4. If a file move could break imports or references, grep for the old path first and fix references before committing.
