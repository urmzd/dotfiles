---
name: pr
description: >
  Open a pull request via gh pr create with a reviewer-ready body: What, Why,
  How, Verification with real evidence, and a Demo (screenshot, GIF, terminal
  capture, or plan output). Follows the repo's pull_request_template.md when one
  exists. Use when the user says "create a pull request", "open a PR", "gh pr
  create", "raise a PR", or "make a PR for this branch", and whenever an agent
  opens a PR as part of a larger task. Also use to rewrite the body of a thin
  existing PR (gh pr edit). Assumes commits already exist and only opens the PR.
  Do NOT commit changes or watch CI (use ship); do NOT diagnose or fix a
  failing pipeline (use fix-and-retry / diagnose-ci).
allowed-tools: Bash(git *), Bash(gh *), Read, Grep, Glob
user-invocable: true
arguments:
  - name: title
    description: Optional PR title. If omitted, auto-generate from commits.
    required: false
---

# PR

A PR body is for a reviewer who has not seen the session. It must answer, in
order: what changed, why, how, how we know it works, and what it looks like.
The commit log alone never does that.

## Steps

1. **Gather context**:
   - Default branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
   - Commits: `git log <default>..HEAD --format='%h %s%n%b'`
   - Diff: `git diff <default>...HEAD --stat`, then read the diff itself
   - Pushed? `git rev-list @{u}..HEAD --count 2>/dev/null`
   - Template: `.github/pull_request_template.md` (or `.github/PULL_REQUEST_TEMPLATE/`)
   - Linked issues: any issue named in commits, or `gh issue list --search "<keywords>"`

2. **Collect evidence** before writing. Run or reuse the checks that prove the
   change, and keep their actual output:
   - Tests or build: the command and its pass line (`ok`, test counts)
   - Infrastructure: the `terraform plan` summary (`Plan: 1 to add, 0 to change, 0 to destroy`) and the resource addresses
   - Bug fix: the failing output before, the passing output after
   - Never claim a check you did not run. Unrun checks are unchecked boxes.

3. **Make the demo** (see Demo rules). `gh` cannot upload images, so use a
   capture that is already hosted (teasr output, a release asset, a CI
   artifact, a committed showcase image) or a fenced terminal block. Do not
   commit screenshots just for the PR.

4. **Push if needed**: `git push -u origin HEAD`.

5. **Write the body**. If the repo has a template, fill its headings and fold
   these sections into them; otherwise use this:

   ```markdown
   ## What
   <1 to 3 sentences: the change, in user-visible terms.>

   ## Why
   <The problem or goal. Link the issue (Closes #N) or quote the failure it fixes.>

   ## How
   - <Approach and key decisions, one bullet each, naming files or components.>
   - <Alternatives rejected, only if a reviewer would ask.>

   ## Verification
   - [x] <check run>: `<command>` gives `<result line>`
   - [ ] <check not yet run, e.g. "deploy after merge">

   ## Demo
   <Screenshot, GIF, terminal capture, or plan excerpt. "None: <reason>" only when nothing is observable.>

   ## Notes
   <Breaking changes, follow-ups, rollout order, what the reviewer must do. Omit if empty.>
   ```

6. **Create**: `gh pr create --title "<title>" --body-file <file>` (or a quoted
   HEREDOC). Never `--fill`: it copies the commit message and skips all of the above.

7. **Report**: the PR URL.

## Demo rules

| Change | Demo |
|--------|------|
| UI, console, site | Screenshot or GIF (teasr, or a browser capture) of the changed screen |
| CLI or tool output | Fenced block of the real command and its output |
| Infrastructure | The plan summary plus the resource addresses it creates or changes |
| Build, CI, Docker | The failing line before and the passing line after |
| Docs only | Link to the rendered file on the branch |
| Refactor, no behavior change | "None: no behavior change" plus the test result |

## Rules

- Never create a PR if there are no commits ahead of the default branch.
- If a PR already exists for this branch, improve its body with `gh pr edit --body-file` instead of opening a duplicate.
- Title: conventional-commit style, under 70 characters.
- No em dashes. No secrets or tokens.
- Write for someone with no session context: name the system, the symptom, and the fix.

## Gotchas

- Refuse when `HEAD` is the default branch: compare `git branch --show-current` to the default and stop if they match.
- For a fork-based PR, qualify the head: `gh pr create --head <owner>:<branch>`.
- `gh pr create --fill` and `--fill-first` produce commit-message bodies. Do not use them, even inside a larger task that is in a hurry.
- A merged PR's body can still be edited with `gh pr edit`: fix thin bodies after the fact rather than leaving them.
