---
name: fix-and-retry
description: Diagnose a CI failure, apply the fix, commit, push, and watch the re-run. Use after a pipeline fails and you want to fix and retry in one shot.
allowed-tools: Bash Read Grep Glob Edit
user-invocable: true
---

# Fix and Retry

Diagnose CI failure, fix it, and re-ship.

## Steps

1. **Diagnose**: Follow the `diagnose-ci` workflow:
   - `gh run list --status=failure --limit 1 --json databaseId,name,headBranch` to find the latest failure
   - `gh run view <id> --log-failed` to get error logs
   - Identify root cause and affected files

2. **Fix**: Apply the fix to the codebase. Read the affected file(s), make the edit, and verify the fix makes sense.

3. **Commit**: Create a conventional commit for the fix (e.g., `fix(ci): correct workflow syntax`). Use a HEREDOC for the message.

4. **Push**: `git push`

5. **Watch**: Poll `gh run list --branch $(git branch --show-current) --limit 1 --json databaseId,status,conclusion` every 15s (max 5 minutes) until the run completes.

6. **Report**: Show whether the re-run passed or failed. If it failed again, show the new error.

## Rules

- Only fix issues you can confidently diagnose from the logs. If the cause is unclear, report the diagnosis and ask the user rather than guessing.
- Never force push or amend the previous commit.
- If the fix requires secrets, env vars, or manual GitHub settings changes, explain what's needed instead of attempting it.
