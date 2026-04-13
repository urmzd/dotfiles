---
name: status
description: Check active repos for recent activity and local state. Scans a folder for git repos with commits in the last 5-7 days and reports their status including uncommitted changes.
allowed-tools: Bash
user-invocable: true
arguments:
  - name: folder
    description: Folder to scan for git repos (defaults to ~/github)
    required: false
---

# Status

Scan a directory for git repositories with recent activity and report their status.

## Invocation

The user may pass a folder path as an argument. Default to `~/github` if none provided.

## Steps

1. **Discover repos**: Find all directories containing a `.git` folder (one level deep only; do not recurse into nested repos).

2. **Filter by activity**: Only include repos that have commits in the last 7 days on any local branch (`git log --all --since='7 days ago' --oneline -1`). Skip repos with no recent activity.

3. **For each active repo**, gather:
   - **Repo name** (directory basename)
   - **Current branch** vs **default branch** (use `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` or fall back to checking for main/master)
   - **Uncommitted changes**: `git status --porcelain` (staged, unstaged, untracked counts)
   - **Unpushed commits**: commits ahead of upstream (`git rev-list @{u}..HEAD --count 2>/dev/null`)
   - **Behind upstream**: commits behind (`git fetch --quiet && git rev-list HEAD..@{u} --count 2>/dev/null`)
   - **CI status**: `gh run list --limit 1 --json status,conclusion,name`. Show latest workflow run status (passing/failing/in-progress)

4. **Output format**: Print a clean, grouped summary. For each repo use this structure:

```
## repo-name [branch: feature/xyz -> main]
- Status: 3 modified, 1 untracked
- Ahead: 2 commits unpushed
- Behind: 5 commits (needs pull/rebase)
- CI: passing | failing (ci.yml) | in progress
- Action needed: pull, push, commit changes, fix CI
```

5. **Summary table** at the end: one-line-per-repo showing repo name, branch, dirty/clean, ahead/behind counts, CI status, and action needed.

## Rules

- Run `git fetch --quiet` before checking ahead/behind so counts are current.
- Run repo checks in parallel where possible (use `&` and `wait` in bash).
- If a directory isn't a valid git repo or has no remote, note it and move on.
- Keep output concise; skip sections that have nothing to report (e.g., don't show "Behind: 0").
- Only show repos with recent activity (last 7 days) to keep the report focused.
