---
alwaysApply: false
description: Morning briefing — surfaces overnight validation results and automation status on the first session of the workday
---

# Morning Briefing

At the START of each conversation, silently check these conditions:

1. **Time check**: Is the current time between 7:00 AM and 11:00 AM local time?
2. **Already done check**: Read `.morning-briefing-last` in the repo root. Does it contain today's date (YYYY-MM-DD)?

If BOTH conditions are true (it is morning AND today's date is NOT in the file), run the briefing:

## Steps

1. Run `just validate` (static checks from committed data, ~15s, no credentials needed).
2. Read the validation results data file.
3. Check for overnight cloud workstation activity:
   - Did the trigger fire? (check logs)
   - Did the nightagent produce results? (check output data)
4. Present a compact briefing to the user:
   - **Validation**: pass/fail/warn counts and top 3 concerns with remediation hints.
   - **Overnight status**: whether the cloud run produced results and sent a notification.
   - **Nightagent**: tasks completed, branches pushed with change summaries.
   - **Suggested actions**: e.g., "Run `/nightwatch` for full report", "Fetch and review nightagent branch."
5. Write today's date to `.morning-briefing-last`.
6. **Friday feedback** (only on Fridays): collect weekly briefing feedback — which section was least useful. Over time, low-value sections get proposed for removal.

## Do NOT run if

- Outside the morning window.
- Today's date already appears in `.morning-briefing-last`.
- The user says "skip briefing" or "no briefing" in this session.
