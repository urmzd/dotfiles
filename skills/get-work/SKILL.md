---
name: get-work
description: Scan a folder for git repos and report GitHub status, branch divergence, and what's needed to get each repo up to date. Use when checking on multiple repos at once.
allowed-tools: Bash
user-invocable: true
arguments:
  - name: folder
    description: Folder to scan for git repos (defaults to ~/Developer)
    required: false
---

# Get Work

Scan a directory for git repositories and produce a status report for each.

## Invocation

The user may pass a folder path as an argument. Default to `~/Developer` if none provided.

## Steps

1. **Discover repos**: Find all directories containing a `.git` folder (one level deep only; do not recurse into nested repos).

2. **For each repo**, gather:
   - **Repo name** (directory basename)
   - **Current branch** vs **default branch** (use `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` or fall back to checking for main/master)
   - **On non-default branch?** Flag it clearly
   - **Uncommitted changes**: `git status --porcelain` (staged, unstaged, untracked counts)
   - **Unpushed commits**: commits ahead of upstream (`git rev-list @{u}..HEAD --count 2>/dev/null`)
   - **Behind upstream**: commits behind (`git fetch --quiet && git rev-list HEAD..@{u} --count 2>/dev/null`)
   - **Open PRs by me**: `gh pr list --author @me --state open --json number,title,url --limit 5` (skip if `gh` auth fails)
   - **Stashes**: `git stash list | wc -l`
   - **CI status**: `gh run list --limit 1 --json status,conclusion,name`. Show latest workflow run status (passing/failing/in-progress)

3. **Output format**: Print a clean, grouped summary. For each repo use this structure:

```
## repo-name [branch: feature/xyz → main]
- Status: 3 modified, 1 untracked
- Ahead: 2 commits unpushed
- Behind: 5 commits (needs pull/rebase)
- Stashes: 1
- Open PRs:
  - #42 "Add widget" — https://github.com/...
- CI: ✓ passing | ✗ failing (ci.yml) | ⏳ in progress
- Action needed: pull, push, commit changes, fix CI
```

4. **Summary table** at the end: one-line-per-repo showing repo name, branch, dirty/clean, ahead/behind counts, CI status, and action needed.

## Rules

- Run `git fetch --quiet` before checking ahead/behind so counts are current.
- Run repo checks in parallel where possible (use `&` and `wait` in bash).
- If a directory isn't a valid git repo or has no remote, note it and move on.
- Keep output concise; skip sections that have nothing to report (e.g., don't show "Stashes: 0").
