---
name: retro
description: Sprint or weekly RETROSPECTIVE — review what worked / didn't across a time period, extract process improvements. For end-of-day ritual, use /wrap-up instead.
argument-hint: "[time period]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Bash(date:*)
---

Retrospective analysis. Review a time period, extract patterns, improve the system.

## Steps

### Step 1: Determine scope

If user specified a time period, use that. Otherwise default to "this week."

### Step 2: Gather data (parallel reads)

Read simultaneously. For each file, gracefully handle missing-file errors — these logs are produced by hooks that ship disabled-by-default, so a fresh install will have none of them.

- Recent daily notes (last 5-7 days) — usually present
- `.claude/logs/verdicts.jsonl` (session quality trends) — only if `log-stop-verdict` hook is enabled; otherwise skip
- `.claude/logs/incident-log.md` (issues and blocks) — only if any incident-emitting hook is enabled
- `.claude/logs/failure-log.md` (tool failures) — only if `log-failures` hook is enabled
- `.claude/knowledge-nominations.md` (pending learnings) — usually present once auditor has run
- `Task Board.md` (completion rate) — usually present

If a file is missing, note it in the retro output ("Skipped: failure-log.md (hook not enabled)") rather than failing the whole command.

### Step 3: Analyze patterns

**What went well?**

- Tasks completed on time
- Smooth workflows (no blocks)
- Learnings successfully captured
- Quality verdicts trending positive

**What didn't go well?**

- Repeated failures (same error type)
- Blocked commands that should have been allowed
- Tasks that took much longer than expected
- Context flushes (/safe-clear) needed frequently
- Quality verdict blocks

**What to change?**

- Are there process bottlenecks?
- Are hooks too strict or too lenient?
- Are agents missing capabilities?
- Are commands missing or underused?

### Step 4: Extract improvements

For each identified improvement:

1. Is it a **knowledge-base rule**? → Promote directly
2. Is it a **process change**? → Add to Scratchpad for user review
3. Is it a **tool/config change**? → Create task on Task Board
4. Is it a **pattern to watch**? → Nominate to knowledge-nominations

### Step 5: Write retro report

Add to daily note:

```markdown
## Retrospective — [period]

### Went Well

- [bullets]

### Didn't Go Well

- [bullets]

### Action Items

- [ ] [specific improvement with owner]

### Metrics

- Tasks completed: [X]
- Quality verdict pass rate: [X]%
- Incidents: [X] (CRITICAL: [X], HIGH: [X])
- Context flushes: [X]
```

### Step 6: Create action items

Add any actionable improvements to `Task Board.md` → This Week.
