---
name: work-status
description: >
  Report where in-flight work stands in one read-only snapshot: open PRs with
  CI and review state, every worktree and whether it is merged, dirty or
  orphaned, whether the primary checkout is clean, what each tmux pane is
  doing, dev servers left running, and disk headroom. Ends with the next three
  actions. Use when the user says "what remains", "what work remains", "what's
  left", "how far out are we", "status update", "what PRs are open", "what
  worktrees are there", "is everything merged", "check the other panes",
  "what is each session doing", or "do a run down". Do NOT use to choose what
  to work on across a portfolio (use get-work), to act on what it finds (use
  land, merge-ready, use-worktrees), or to supervise a fleet over time (use
  orchestrate-agents).
allowed-tools: Bash, Read, Grep, Glob
user-invocable: true
arguments:
  - name: target
    description: Optional repo path, or a folder of repos. Defaults to the current repo.
    required: false
---

# Work Status

Answer "where are we" from the machine, not from memory. Session memory goes
stale the moment another pane merges something, so every answer starts with a
fresh snapshot.

## Steps

1. **Snapshot**. Run the bundled script. It only reads.

   ```bash
   status="${CLAUDE_SKILL_DIR:-$HOME/.agents/skills}/work-status/scripts/status.sh"
   "$status" <target>            # one repo
   "$status" ~/github            # every repo one level down
   ```

   It prints tab-separated sections: `PRIMARY`, `WORKTREES`, `OPEN PRS`,
   `PANES`, `LISTENERS`, `MACHINE`. Each row ends in a `flag` column.

2. **Read the ledger, if the work has one**. Look for a tracking issue, a
   `ledger` or `tracker` file, or a handoff folder the session already uses.
   Compare it with the snapshot. When they disagree, the snapshot wins: say
   which ledger rows are stale. Do not edit the ledger here.

3. **Report** in the format below. Leave out a section that has nothing in it.

## Flags

| Flag | Meaning | Next step |
|---|---|---|
| `LAND` | Open PR, checks green, mergeable | `land` it, if the user asked for merges |
| `FIX-CI` | Open PR with failing checks | `fix-and-retry` |
| `FIX-REVIEW` | Changes requested | `merge-ready` |
| `CONFLICT`, `UPDATE-BRANCH` | Out of date with the base | `merge-ready` |
| `NEEDS-HUMAN` | Green but blocked on an approval | The user |
| `REMOVE` | Worktree whose PR merged, no local changes | Remove worktree and branch |
| `MERGED-BUT-DIRTY` | PR merged, files still uncommitted | Look at the files before removing |
| `UNCOMMITTED` | Work that exists only on this disk | Commit it or discard it on purpose |
| `NO-PR` | Commits with no pull request | Open a PR or drop the branch |
| `EMPTY` | Worktree with no commits and no changes | Remove |
| `DIRTY-PRIMARY`, `OFF-DEFAULT` | The primary checkout holds work or left the default branch | Move the work to a worktree |
| `BEHIND` | Primary checkout is behind the remote | `git pull --ff-only` |

## Report format

Lead with one line, then tables, then the next actions. Keep it short enough
to read in one look.

```text
<repo>: <N> PRs open (<a> ready to land, <b> need fixes), <M> worktrees (<c> removable, <d> holding uncommitted work).

Open PRs
| PR | What | Checks | State | Next |

Needs a decision
| Item | Why it is stuck |

Cleanup
| Worktree | Flag | Age |

Sessions
| Pane | Doing | Waiting on |

Next
1. <the single most useful action>
2. <second>
3. <third>
```

Rules for the report:

- **Group, do not dump.** With more than eight worktrees under one flag,
  give the count and the three oldest, not every row.
- **"Sessions" says what a pane is waiting on.** A pane showing a question or
  a permission prompt is the most useful row in the report: put it first.
- **Name the owner of uncommitted work** when a pane's working directory is
  that worktree. Unowned uncommitted work older than a few days is the
  cleanup risk to call out.
- **Flag a hot machine.** Under 20 GB free, or a build cache over 20 GB, goes
  in the lead line.
- **"Next" is at most three actions**, ordered by what unblocks the most.

## Rules

- Read-only. Do not commit, push, merge, remove a worktree, stop a process,
  or send keys to a pane. Offer the action and let the user or the owning
  skill take it.
- Do not report from memory. If the script cannot run, say so and stop.
- Do not call work done because its PR merged. Merged is not deployed: say
  which, when a deploy is part of the goal.
- Another session's pane is context, not a task. Do not pick up its work
  unless the user asks.

## Gotchas

- The script does not fetch. Run `git fetch --all --prune` first when
  `BEHIND` or merge state matters to the answer.
- `NO-PR` on an old branch can be a PR beyond the newest 1000 or a branch
  renamed after its PR merged. Check `gh pr list --state all --search
  "head:<branch>"` before calling it abandoned.
- A detached worktree (`(detached)`) never matches a PR. Judge it by `dirty`
  and age, not by the missing PR.
- `checks` counts cancelled runs as failing. A superseded run that was
  cancelled by a newer push is not a real failure: confirm with
  `gh pr checks <n>` before reporting `FIX-CI`.
- `LISTENERS` shows only processes whose working directory is inside a
  scanned repo. A dev server started from elsewhere will not appear.
- Pane `last-line` is one line of screen text. Use
  `tmux capture-pane -p -t <id> -S -40` to read what a pane is really asking.
