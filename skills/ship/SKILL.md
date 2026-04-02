---
name: ship
description: Commit with conventional message, push, and watch CI pipeline until it passes or fails. Use when shipping code changes.
allowed-tools: Bash
user-invocable: true
arguments:
  - name: message
    description: Optional commit message. If omitted, auto-generate from staged changes.
    required: false
---

# Ship

Commit, push, and watch the CI pipeline.

## Steps

1. **Stage changes**: Run `git status --porcelain`. If there are unstaged/untracked changes, stage them (prefer specific files over `git add -A` — never stage `.env` or credential files).

2. **Commit**: If a message argument is provided, use it. Otherwise, generate a conventional commit message from the diff (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`). Use the repo's recent `git log --oneline -10` to match style.

3. **Push**: Run `git push`. If no upstream is set, use `git push -u origin HEAD`.

4. **Watch CI**: After push, run `gh run list --branch $(git branch --show-current) --limit 1 --json databaseId,status,conclusion` in a loop (max 5 minutes, poll every 15s). Report the final status.

5. **On failure**: If CI fails, run `gh run view <id> --log-failed` and show the relevant error output so the user can decide next steps.

## Rules

- Never commit files that look like secrets (.env, credentials.json, *.pem, *.key).
- Never force push.
- If there are no changes to commit, say so and stop.
- If CI isn't set up (no workflows found), just push and report that there's no CI to watch.
