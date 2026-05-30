---
name: fix-and-retry
description: >
  Diagnose a failing CI run, apply the code fix, commit it, push, and watch the
  re-run until it passes or fails -- the full fix-and-retry loop in one shot. Use
  after a pipeline fails and the user says "fix it and retry", "fix the CI and
  push", or "make CI green". Do NOT use for a read-only investigation that stops
  at a recommendation (use diagnose-ci); do NOT use for a routine commit unrelated
  to a CI failure (use ship).
allowed-tools: Bash(git *), Bash(gh *), Read, Grep, Glob, Edit
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

4. **Push**: Before pushing, capture the pre-push run id (`gh run list --branch $(git branch --show-current) --limit 1 --json databaseId -q '.[0].databaseId'`). Then `git push`.

5. **Watch**: Poll for a NEWER run, not the previous failed one. Match the new run by the pushed commit's `headSha` (`git rev-parse HEAD`) -- e.g. `gh run list --branch $(git branch --show-current) --limit 5 --json databaseId,headSha,status,conclusion` and pick the run whose `headSha` equals the new HEAD (and whose id differs from the captured pre-push id). Poll every 15s (max 5 minutes) until that run completes. This prevents the watcher from latching onto the previous failed run before the new run is registered.

6. **Report**: Show whether the re-run passed or failed. If it failed again, show the new error.

## Rules

- Only fix issues you can confidently diagnose from the logs. If the cause is unclear, report the diagnosis and ask the user rather than guessing.
- Never force push or amend the previous commit.
- If the fix requires secrets, env vars, or manual GitHub settings changes, explain what's needed instead of attempting it.

## Gotchas

- A new CI run is not registered the instant you push. Capture the pre-push run id (step 4) and poll for a run whose `headSha` matches the newly pushed HEAD before reading status. If you watch `--limit 1` blindly, the watcher can latch onto the previous failed run and report a false failure.
