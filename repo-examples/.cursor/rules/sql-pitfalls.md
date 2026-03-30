---
description: Known SQL pitfalls and data gotchas — auto-injected when editing queries
globs: queries/**, sync_metrics.py
---

# SQL Pitfalls & Data Gotchas

Hard-won lessons from data bugs. Read before writing any new query.

## 1. Roster Excludes Bot Authors

The standard `eng_roster` CTE filters to human employees via `DIM_USER.LDAP`. **Service accounts are silently dropped.**

If your query involves bot-authored PRs:
- Source bot PRs from the CDP events table, not from activity tables with a roster join.
- Verify that headless/autonomous PRs are not dropped by the join.

## 2. Merge Date Pipeline Lag for Recently Onboarded Repos

`FACT_PULL_REQUESTS.MERGED_AT` has pipeline lag for repos recently onboarded to the analytics platform. Symptom: all merge dates cluster in the current week instead of distributing historically.

When querying bot or workstation PRs:
- Use the event creation timestamp as the date dimension.
- Use the PR table only for merge state verification, not for the date.

## 3. CDP Events Table Deduplication

Event tables fire multiple events for the same PR (re-opens, collaborator opens, etc.). Always deduplicate:

```sql
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY repo_slug, pr_number
    ORDER BY created_at
) = 1
```

## 4. Date Boundary Conventions

| Pattern | Meaning | When to use |
|---------|---------|-------------|
| `< DATE_TRUNC('week', CURRENT_DATE)` | Excludes current (partial) week | Metrics where you want complete weeks only |
| `< CURRENT_DATE` | Excludes today, includes partial current week | Metrics where current-week data is relevant |

Use the same upper bound across all CTEs in a query to keep weeks comparable.

## 5. Activity Table vs PR Table

These are different tables with different schemas:

| Table | PR number column | Merge date column | Has AI/collaboration fields |
|-------|-----------------|-------------------|-----------------------------|
| Activity table | `PR_NUMBER` | `PR_MERGED_AT` | Yes |
| PR table | `NUMBER` | `MERGED_AT` | No |

Use the activity table when you need collaboration metadata. Use the PR table for merge state verification of externally-sourced PRs.

## 6. Roster CTE Column Names

The standard roster pattern uses a user dimension table:

```sql
WITH eng_roster AS (
    SELECT DISTINCT LOWER(LDAP) AS ldap
    FROM REPORTING_TABLES.DIM_USER
    WHERE IS_CURRENT = TRUE
      AND LDAP IS NOT NULL
      AND ORG_HIERARCHY LIKE 'Engineering (%'
)
```

Verify exact column names against your schema. Common mistakes: using non-existent columns or unreliable status fields.

## 7. Hybrid Scope Pattern

When a query mixes human-authored and bot-authored PRs, use hybrid scoping:
- **Bot/autonomous PRs**: Company-wide (bots have no org affiliation).
- **Human PRs**: Scoped to engineering org via roster.
- Exclude bot PRs from the human bucket using `NOT EXISTS` to avoid double-counting.
