
## Work never lives on one disk

Work that is only in a local worktree gets lost. Keep every branch on the remote and behind a pull request.

- **Push with the first commit.** The same turn a branch gets its first commit, push it and open a draft pull request.
- **Commit and push before you stop.** Do not end a turn with uncommitted or unpushed work in a worktree you are using. A work-in-progress commit is fine.
- **No detached work.** Create a branch before you commit. Review and "before" checkouts that gain files get a branch too.
- **Stack what builds on other work.** Base each pull request on the branch below it, not on the default branch.
- **Say what you left.** If you cannot push or open the pull request, name the worktree and the reason in your reply.
