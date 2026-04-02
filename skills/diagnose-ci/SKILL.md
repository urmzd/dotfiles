---
name: diagnose-ci
description: Find failing CI pipelines, pull logs, identify root cause, and suggest or apply fixes. Use when CI is red or the user asks why a pipeline failed.
allowed-tools: Bash Read Grep Glob Edit
user-invocable: true
arguments:
  - name: run_id
    description: Optional specific run ID to diagnose. If omitted, checks the most recent failed run.
    required: false
---

# Diagnose CI

Investigate and diagnose CI pipeline failures.

## Steps

1. **Find the failure**:
   - If a `run_id` is provided, use `gh run view <run_id> --log-failed`.
   - Otherwise, run `gh run list --status=failure --limit 5 --json databaseId,name,headBranch,conclusion,createdAt` to find recent failures.
   - Pick the most recent failure on the current branch (or the most recent overall if none match).

2. **Pull logs**: Run `gh run view <id> --log-failed` to get the failed step logs. If output is large, focus on the last 100 lines of the failing step.

3. **Diagnose**: Analyze the logs to identify:
   - The specific step that failed
   - The root cause (compile error, test failure, lint issue, missing secret, timeout, etc.)
   - The relevant file(s) and line(s) if applicable

4. **Suggest fix**: Based on the diagnosis:
   - If it's a code issue: show the fix and offer to apply it
   - If it's a config issue (missing secret, wrong action version): explain what to change
   - If it's flaky (timeout, network): suggest re-running with `gh run rerun <id>`

5. **Report**: Present a concise summary:
   ```
   ## CI Failure: <workflow name> (run #<id>)
   - Branch: <branch>
   - Failed step: <step name>
   - Root cause: <explanation>
   - Fix: <what to do>
   ```

## Rules

- Always check the current repo's workflows first (`gh run list`).
- If `gh` is not authenticated or the repo has no remote, report that clearly.
- Don't blindly re-run failed pipelines — diagnose first.
