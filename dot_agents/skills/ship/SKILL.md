---
name: ship
description: >
  Generate a conventional commit message from staged or unstaged changes and
  create an atomic commit, then optionally push and watch CI until it passes or
  fails. Use when the user says "write a commit", "generate a commit message",
  "commit this", "git add .", or "ship this". Push and CI-watch are optional and
  skipped if the user only wants a commit. Do NOT open a pull request (use pr);
  do NOT diagnose-then-fix a failing pipeline (use fix-and-retry); do NOT do a
  read-only CI investigation without committing (use diagnose-ci).
allowed-tools: Bash(git *), Bash(gh *), Read, Grep, Glob
user-invocable: true
arguments:
  - name: message
    description: Optional commit message. If omitted, auto-generate from staged changes.
    required: false
---

# Ship

Commit, push, and watch the CI pipeline.

## Steps

1. **Stage changes**: Run `git status --porcelain`. If there are unstaged/untracked changes, stage them (prefer specific files over `git add -A`; never stage `.env` or credential files).

2. **Commit**: If a message argument is provided, use it. Otherwise, generate a conventional commit message from the diff (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`). Use the repo's recent `git log --oneline -10` to match style.

3. **Push (optional)**: Only if the user wants to push. Run `git push`. If no upstream is set, use `git push -u origin HEAD`. If the user only asked for a commit, stop here and report the commit.

4. **Watch CI (optional)**: After push, run `gh run list --branch $(git branch --show-current) --limit 1 --json databaseId,status,conclusion` in a loop (max 5 minutes, poll every 15s). Report the final status.

5. **On failure**: If CI fails, run `gh run view <id> --log-failed` and show the relevant error output so the user can decide next steps.

## Rules

- Never commit files that look like secrets (.env, credentials.json, *.pem, *.key).
- Never force push.
- If there are no changes to commit, say so and stop.
- If CI isn't set up (no workflows found), just push and report that there's no CI to watch.

## Gotchas

- The `gh run` is not registered immediately after `git push`. Poll with retry (a few attempts, a couple seconds apart) before concluding "no run found" -- the run may take several seconds to appear.
- If `git push` is rejected by branch protection (protected branch, required reviews, required status checks), stop and report the rejection. Do not retry, force push, or attempt to bypass protection.
