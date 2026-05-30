---
name: diagnose-ci
description: >
  Investigate failing REMOTE CI runs on GitHub Actions: find the failed run, pull
  the failed-step logs with gh, identify the root cause (compile error, test
  failure, lint, missing secret, timeout), and recommend a fix. Read-only: it does
  not commit, push, or edit. Use when CI is red, a GitHub Actions run failed, or
  the user asks "why did the pipeline fail". Do NOT use for local build/test/runtime
  failures on your machine (use diagnose-runtime); do NOT apply the fix and re-ship
  (use fix-and-retry) -- this skill investigates and recommends only.
allowed-tools: Bash(gh *), Bash(git *), Read, Grep, Glob
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

4. **Recommend fix**: Based on the diagnosis (read-only: recommend, do not apply):
   - If it's a code issue: show the exact fix and point the user to `fix-and-retry` to apply + re-ship it.
   - If it's a config issue (missing secret, wrong action version): explain what to change.
   - If it's flaky (timeout, network): suggest re-running with `gh run rerun <id>`.

5. **Report**: Present a concise summary:
   ```text
   ## CI Failure: <workflow name> (run #<id>)
   - Branch: <branch>
   - Failed step: <step name>
   - Root cause: <explanation>
   - Fix: <what to do>
   ```

## Rules

- Always check the current repo's workflows first (`gh run list`).
- If `gh` is not authenticated or the repo has no remote, report that clearly.
- Don't blindly re-run failed pipelines; diagnose first.

## Gotchas

- `gh run view <id> --log-failed` returns empty for a cancelled run (no step is marked "failed", so there is nothing to dump). Fall back to `gh run view <id> --json jobs` and inspect each job's `conclusion`/`steps` to find the cancelled or failed step, then read its log directly.
