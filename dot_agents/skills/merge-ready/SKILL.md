---
name: merge-ready
description: >
  Drive an existing pull request to a mergeable state: get CI green, resolve
  merge conflicts with the base branch, address and resolve review comments,
  trigger required bot reviews/approvals (e.g. commenting '@claude review'),
  link associated issues, and clean up the PR title and description. Ends with
  a readiness report listing any remaining human-only blockers (required
  reviewer approvals, CODEOWNERS). Uses the CLI matching the repo's forge:
  gh for GitHub, glab for GitLab merge requests, tea for Gitea/Forgejo. Use
  when the user says "get this PR ready to merge", "make this PR mergeable",
  "get the PR green", "address the review comments", "babysit this PR", "get
  this MR merged", or "why is this PR blocked". Do NOT merge the PR or enable
  auto-merge; do NOT open a new PR (use pr); do NOT use for a failing pipeline
  with no PR context (use fix-and-retry / diagnose-ci).
allowed-tools: Bash(git *), Bash(gh *), Bash(glab *), Bash(tea *), Read, Grep, Glob, Edit, Write
user-invocable: true
arguments:
  - name: pr
    description: Optional PR number or URL. If omitted, use the PR for the current branch.
    required: false
---

# Merge Ready

Take an open PR from wherever it is to "ready to merge", and report exactly
what still needs a human when automation can't finish the job.

## Steps

1. **Detect the forge and pick the CLI**: Read the remote
   (`git remote get-url origin`) and choose the matching CLI, verifying it is
   installed and authenticated before proceeding:

   | Host in remote URL | CLI | PR concept | Auth check |
   |---|---|---|---|
   | github.com / GHE | `gh` | pull request | `gh auth status` |
   | gitlab.com / self-hosted GitLab | `glab` | merge request (MR) | `glab auth status` |
   | Gitea / Forgejo / Codeberg | `tea` | pull request | `tea login list` |

   The steps below are written with `gh`; on another forge, translate each
   operation to the equivalent verb (`gh pr view` -> `glab mr view --output
   json` / `tea pr <n>`, `gh pr comment` -> `glab mr note`, `gh run
   view` -> `glab ci view`, `gh pr update-branch` -> `glab mr rebase`, review
   threads -> `glab api projects/:id/merge_requests/:iid/discussions`).
   Confirm exact flags with `--help` rather than guessing. If the forge has
   no CLI (e.g. Bitbucket), fall back to `git` plus the forge's REST API via
   `curl`, and list anything you cannot automate as a blocker in the report.

2. **Identify the PR**: Resolve the argument (number or URL) or the current
   branch's PR via `gh pr view`. If no PR exists, stop and suggest the `pr`
   skill. If it is a draft, continue fixing but only mark it ready
   (`gh pr ready`) at the end, once everything else passes.

3. **Assess**: Take one snapshot of the PR state:

   ```bash
   gh pr view <n> --json number,title,body,url,state,isDraft,mergeable,mergeStateStatus,reviewDecision,reviewRequests,latestReviews,statusCheckRollup,baseRefName,headRefName,maintainerCanModify,closingIssuesReferences
   ```

   Then fetch unresolved review threads (only GraphQL exposes resolution):

   ```bash
   gh api graphql -f owner=<owner> -f repo=<repo> -F pr=<n> -f query='
     query($owner:String!,$repo:String!,$pr:Int!){
       repository(owner:$owner,name:$repo){ pullRequest(number:$pr){
         reviewThreads(first:100){ nodes{
           id isResolved isOutdated path line
           comments(first:20){ nodes{ author{login} body } }
         }}
       }}
     }'
   ```

   Then discover the merge gates: `gh api repos/{owner}/{repo}/rules/branches/<base>`
   lists required status checks, required approving review count, and whether
   code-owner review is required (readable without admin). If that returns
   nothing, infer gates from `mergeStateStatus` and `reviewDecision`.

   Build a blocker list and split it in two: **fixable by automation**
   (conflicts, failing checks, unaddressed comments, stale description,
   missing bot trigger, draft state) vs **human-only** (required approving
   reviews from people or CODEOWNERS, org settings, missing secrets).

4. **Sync with base**: If `mergeStateStatus` is `BEHIND`, run
   `gh pr update-branch <n>`; if that fails, merge the base locally and push.
   If `DIRTY` (conflicts), check out the branch, `git fetch origin` and
   `git merge origin/<base>`, resolve each conflict by reading the surrounding
   code and preserving the intent of both sides (never resolve by blindly
   taking one side), then commit the merge and push. Never force-push.

5. **Get CI green**: For each failing entry in `statusCheckRollup`, pull the
   logs (`gh run view <id> --log-failed`), diagnose the root cause, fix it,
   commit conventionally, and push (the `fix-and-retry` workflow). If a
   failure is flaky or external (network, rate limit), re-run it instead:
   `gh run rerun <id> --failed`. For third-party bot checks that re-trigger
   via a comment command, find the documented phrase (step 7) rather than
   pushing an empty commit.

6. **Address review comments**: For each unresolved, non-outdated thread:
   - **Actionable code feedback**: apply the fix, commit, push, reply briefly
     to the thread stating what changed, then resolve it via GraphQL:

     ```bash
     gh api graphql -f id=<threadId> -f query='
       mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } } }'
     ```

   - **Question**: answer it in a reply; resolve only if fully answered.
   - **Disagreement or judgment call**: reply with your reasoning and leave
     the thread unresolved for the human to close.

7. **Bot approvals and re-reviews**: If a required check or review comes from
   a bot that is triggered by a comment (Claude, CodeRabbit, Copilot, CLA
   bots, `/retest`-style CI bots), find its exact trigger phrase from prior
   comments on this PR, recent merged PRs in the repo, or
   CONTRIBUTING/README, then post it: `gh pr comment <n> --body '@claude review'`.
   Never invent a trigger phrase; if none is discoverable, list the bot as a
   blocker in the report. If a bot approved before you pushed new commits,
   its approval may be stale; re-trigger it after your last push.

8. **Issues and description hygiene**:
   - **Linked issues**: check `closingIssuesReferences`; if empty, look for an
     issue number in the branch name, commit messages, or by searching open
     issues for the feature/bug. If the PR clearly fixes one, add
     `Closes #<n>` to the body.
   - **Title**: conventional-commit style, under 70 chars, describing the
     current diff (it may have drifted as commits were added).
   - **Body**: ensure a `## Summary` reflecting the full current diff and a
     `## Test plan`. Augment what a human wrote rather than rewriting it.
     Apply with `gh pr edit <n> --title ... --body ...` (HEREDOC for body).

9. **Re-assess and loop**: After pushes, repeat step 3. Wait for new CI runs
   by matching `headSha` to the new HEAD (see gotchas), not by watching the
   latest run. Loop until every fixable blocker is cleared or only human-only
   blockers remain. Then, if the PR is a draft and everything else is green,
   `gh pr ready <n>`.

10. **Report** using this template:

   ```text
   ## PR readiness: <url>

   **Ready to merge: YES | NO**

   Fixed this run:
   - <conflict resolved / check fixed / N threads addressed / description updated>

   Remaining blockers (need a human):
   - <e.g. 1 approving review required from CODEOWNERS: @alice or @bob>
   - <e.g. stale approval dismissed by my push; re-request from @carol>
   - <e.g. required check "license/cla" needs the author to sign the CLA>
   ```

## Rules

- Never merge the PR, enable auto-merge, force-push, amend, or rebase
  published commits.
- Never resolve a review thread you did not actually address, and never
  dismiss someone's review.
- Only fix what you can confidently diagnose from logs, diffs, or comments;
  otherwise report the diagnosis as a blocker instead of guessing.
- Do not ping or re-request human reviewers unless the user asked; list them
  in the report instead.
- If the fix needs secrets, repo settings, or permissions you lack, say
  exactly what is needed rather than attempting workarounds.

## Gotchas

- `mergeable: UNKNOWN` means GitHub is still computing it asynchronously;
  re-query after ~5 seconds, up to a few tries, before acting on it.
- `mergeStateStatus` decoder: `BEHIND` = needs base update, `DIRTY` =
  conflicts, `UNSTABLE` = a non-required check is failing (technically
  mergeable, still fix it), `BLOCKED` = required approvals or checks missing.
  Draft PRs show `BLOCKED` no matter what, so check `isDraft` first.
- REST comment endpoints do not expose thread resolution; only the GraphQL
  `reviewThreads` query has `isResolved`/`isOutdated`, and the
  `resolveReviewThread` mutation needs the **thread** node id from that
  query, not a comment id.
- Pushing new commits can auto-dismiss stale approvals (a branch-protection
  setting). Re-check `reviewDecision` after every push and surface any
  re-approvals needed in the final report.
- A new CI run is not registered the instant you push. Capture
  `git rev-parse HEAD`, then poll `gh run list --branch <head> --json
  databaseId,headSha,status,conclusion` and watch the run whose `headSha`
  matches; watching `--limit 1` blindly can latch onto the previous run.
- Fork PRs: if `maintainerCanModify` is false and you lack push access to the
  head branch, you cannot push fixes; describe the needed changes in a PR
  comment and list them as blockers instead.
- `gh pr update-branch` fails when the repo disallows the update-branch
  button or on some fork setups; fall back to the local
  `git merge origin/<base>` + push path.
