---
name: use-worktrees
description: >
  Create, enter, and clean up git worktrees under the mandatory layout:
  every worktree lives at <repo-root>/.worktrees/<name> in the target repo's
  primary checkout, .worktrees/ is always gitignored, and the primary checkout
  never leaves the default branch. Use when creating a worktree, working on
  parallel branches, isolating an agent's edits, or when the user says
  "worktree", "work in parallel", or "branch without switching". Do NOT use
  for commit/PR/merge flow (use ship, pr, merge-ready) or for plain single
  branch work that needs no isolation.
allowed-tools: Bash(git *), Read, Grep, Glob
user-invocable: true
arguments:
  - name: task
    description: Short slug for the worktree (becomes .worktrees/<task>). Optional.
    required: false
---

# Use Worktrees

Worktrees give each parallel task its own working directory while sharing one
repository. This skill defines where they live and the invariants that keep
the primary checkout safe.

## Policy (non-negotiable)

1. **One location**: every worktree lives at `<repo-root>/.worktrees/<name>`,
   where `<repo-root>` is the primary checkout of the repo being worked on.
   Never `.claude/worktrees/`, never sibling directories (`../repo-feature`),
   never temp dirs, never nested inside another worktree.
2. **Per-repo, even cross-project**: when a session in project A creates a
   worktree for project B, it goes in B's own root (`<B-root>/.worktrees/`),
   not under A and not in any shared location.
3. **Always ignored**: `.worktrees/` must be gitignored. Check with
   `git check-ignore -q .worktrees`; if not ignored, append `.worktrees/` to
   `.git/info/exclude` (repo-local, safe in shared repos). Only add it to the
   tracked `.gitignore` when the user wants it committed for the whole team.
4. **The default branch never moves**: the primary checkout stays on the
   default branch (`main`/`master`) permanently. Never `git switch` or
   `git checkout` a feature branch there, never commit on it directly; update
   it only with `git pull --ff-only`. All branch work happens inside
   worktrees.

## Create a worktree

```bash
root=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
git -C "$root" check-ignore -q .worktrees || printf '.worktrees/\n' >> "$root/.git/info/exclude"
default=$(git -C "$root" symbolic-ref -q --short refs/remotes/origin/HEAD || echo HEAD)
git -C "$root" worktree add -b <branch> "$root/.worktrees/<task>" "$default"
```

**Notes**:
- Deriving `root` from the git common dir means this works from inside
  another worktree too: the new one still lands in the primary checkout.
- Branch from `origin/HEAD` (the remote default) so the local default branch
  is never involved. If `origin/HEAD` is unset, run
  `git remote set-head origin --auto` once.
- For another repo, run the same commands with `git -C /path/to/repo`.
- To work on an existing branch: `git worktree add "$root/.worktrees/<task>" <branch>`.

## Clean up

```bash
git worktree list                                  # see what exists
git worktree remove .worktrees/<task>              # add --force if dirty
git branch -d <branch>                             # after merge
git worktree prune                                 # clear stale metadata
```

## Claude Code specifics

- **This machine automates the policy**: a `WorktreeCreate` hook
  (`~/.claude/hooks/worktree-create.sh`, registered in
  `~/.claude/settings.json`) makes `claude --worktree` and subagent
  `isolation: worktree` create under `.worktrees/` automatically, and
  `~/.gitignore_global` ignores `.worktrees/` everywhere.
- **EnterWorktree tool**: never use its name-based mode (it defaults to
  `.claude/worktrees/`). Create the worktree with git as above, then call
  `EnterWorktree` with `path: <repo-root>/.worktrees/<task>`.
- On machines without the hook, follow the manual commands above; the policy
  is the same for every tool (claude-code, codex, gemini, copilot).

## Gotchas

- Git refuses to check out a branch that is already checked out in another
  worktree. Because the primary checkout holds the default branch, no
  worktree can ever claim it: branch from `origin/HEAD` instead of `main`.
- A worktree is a fresh checkout: gitignored files (`.env`, `node_modules/`,
  `.venv/`) are absent. Re-run dependency install and `direnv allow` per
  worktree. Projects can list files to copy in `.worktreeinclude`
  (gitignore syntax); the Claude Code hook honors it.
- Deleting a worktree directory by hand leaves stale metadata; always use
  `git worktree remove`, or `git worktree prune` afterwards.
- `git status` in the primary checkout will not show `.worktrees/` (it is
  ignored); use `git worktree list` to see what exists.
