---
name: land
description: >
  Take finished work all the way to the default branch in one pass: commit,
  push, open or update the PR, get CI green, squash-merge, then clean up the
  branch and worktree. Invoking it is the merge authorization, so do not ask
  again before merging. Use when the user says "commit and push and merge",
  "merge when green", "merge it when ready", "merge when CI is green", "get it
  merged", "land this", "merge them", "merge 142 and 133", or "wrap this up
  and merge". Do NOT use for a commit or push with no merge (use ship), for
  opening a PR only (use pr), for making a PR mergeable without merging it
  (use merge-ready), or for deploying (deploys always need their own ask).
allowed-tools: Bash(git *), Bash(gh *), Read, Grep, Glob, Edit
user-invocable: true
arguments:
  - name: prs
    description: Optional PR numbers or URLs, space separated. If omitted, land the current branch.
    required: false
---

# Land

One command for the whole path from "the work is done" to "it is on the
default branch and the workspace is clean". It chains the `ship`, `pr` and
`merge-ready` skills and adds the one step they refuse to do: the merge.

## Authority

The user asking to land is the approval to merge. Do not stop to confirm the
commit, the push, the PR, or the merge. Stop only at the conditions listed in
[Stop and report](#stop-and-report).

The approval covers the PRs named in the request, or the current branch when
none are named. It does not cover other open PRs, a deploy, a release, or a
tag.

## Steps

1. **Resolve targets**. With `prs`, use those. Without, use the current
   branch. If the current directory is the primary checkout on the default
   branch with uncommitted work, move that work to a worktree first (the
   `use-worktrees` skill): the default branch never takes direct commits.

2. **Commit and push** any uncommitted work on the branch, following the
   `ship` skill (conventional message, specific files, no secrets).

3. **Open or refresh the PR**, following the `pr` skill. A PR that changes
   anything a person looks at needs before and after screenshots in the body
   before it can merge. If they are missing, capture them now.

4. **Get it mergeable**, following the `merge-ready` skill: sync with the
   base, fix failing checks, address review threads. Verify with CI, not with
   a local full build, when the machine is already running other agents.

5. **Wait for green on the exact head**. Record `sha=$(git rev-parse HEAD)`
   after the last push and wait for the checks of that commit:

   ```bash
   gh pr checks <n> --watch --fail-fast --interval 20
   gh pr view <n> --json headRefOid,mergeStateStatus,reviewDecision,isDraft
   ```

   Proceed only when `headRefOid` equals `$sha`, every required check passed,
   and `mergeStateStatus` is `CLEAN` (or `UNSTABLE` from a non-required
   check that you have reported).

6. **Merge**, pinned to the head you verified:

   ```bash
   gh pr merge <n> --squash --delete-branch --match-head-commit "$sha"
   ```

   Use the repo's own method when squash is disallowed
   (`gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`).
   For a merge queue or a slow required check, `--auto` is fine: report that
   the merge is queued, not done.

7. **Several PRs**. Land them one at a time, in dependency order: for a
   stack, bottom first, and let each child retarget to the base before its
   own step 5. After each merge, update the next branch from the base and
   wait for its new run. Never merge a child into an unmerged parent.

8. **Clean up**:

   ```bash
   root=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
   git -C "$root" pull --ff-only
   git -C "$root" worktree remove .worktrees/<task>
   git -C "$root" branch -D <branch>
   git -C "$root" worktree prune
   ```

   Remove a worktree only when its branch is merged and it has no
   uncommitted files. If the repo keeps a ledger or tracking issue for the
   work, mark the item merged with the merge commit.

9. **Report** in this shape, nothing more:

   ```text
   Landed: #<n> <title> -> <base> at <merge sha>
   Checks: <passed>/<total> on <head sha>
   Cleaned: <worktree and branch removed | kept, with the reason>
   Not done: <deploy, release, or anything skipped>
   ```

## Stop and report

Stop and say exactly what is needed when:

- A required human review or CODEOWNERS approval is missing.
- A check fails and the cause is not clear from the logs after one fix
  attempt, or the fix needs a secret or a setting you cannot change.
- The merge command is refused by a permission rule or branch protection.
  Do not retry and do not look for another route. Give the user the exact
  command to run, for example `! gh pr merge 60 -R owner/repo --squash`.
- The PR head moved after you verified it (`--match-head-commit` fails).
  Re-run from step 5 once; if it moves again, another session is pushing to
  the branch, so report that.
- The diff includes a database migration that drops or rewrites data, or
  infrastructure that a plan shows as destroyed or replaced.

## Rules

- Never use `--admin`, never force-push, never bypass a required check, and
  never dismiss a review.
- Never merge a PR that was not named and is not the current branch.
- Never deploy, tag, or cut a release as part of landing.
- Never mark something landed while the merge is only queued.
- Do not open a second PR for a branch that already has one.

## Gotchas

- `gh pr checks --watch` exits non-zero when there are no checks yet. A run
  can take several seconds to register after a push: retry a few times
  before concluding the repo has no CI.
- `mergeStateStatus: BLOCKED` on a draft PR means nothing. Run
  `gh pr ready <n>` first, then read the state again.
- `--delete-branch` fails to delete the local branch while a worktree still
  has it checked out. That is expected: step 8 removes the worktree, then
  the branch.
- After a squash merge, `git branch -d` reports the branch as unmerged
  because the commits differ. Confirm the PR state is `MERGED`, then use
  `-D`.
- A stale approval can be dismissed by your own push. Read `reviewDecision`
  again after the last push, not before it.
