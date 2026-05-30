---
name: pr
description: >
  Open a pull request via gh pr create with an auto-generated title and summary
  derived from the commits on the branch, grouped by conventional-commit type.
  Use when the user says "create a pull request", "open a PR", "gh pr create",
  "raise a PR", or "make a PR for this branch". Assumes commits already exist and
  only opens the PR. Do NOT commit changes or watch CI (use ship); do NOT
  diagnose or fix a failing pipeline (use fix-and-retry / diagnose-ci).
allowed-tools: Bash(git *), Bash(gh *), Read, Grep, Glob
user-invocable: true
arguments:
  - name: title
    description: Optional PR title. If omitted, auto-generate from commits.
    required: false
---

# PR

Create a pull request with a well-structured summary.

## Steps

1. **Gather context**:
   - Detect the default branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
   - Get all commits since divergence: `git log <default>..HEAD --oneline`
   - Get the full diff: `git diff <default>...HEAD --stat`
   - Check if the branch is pushed: `git rev-list @{u}..HEAD --count 2>/dev/null`

2. **Push if needed**: If there are unpushed commits, run `git push -u origin HEAD`.

3. **Generate PR content**:
   - **Title** (if not provided): Derive from commits. If single commit, use its message. If multiple, summarize the theme (under 70 chars).
   - **Body**: Use this format:
     ```text
     ## Summary
     - <bullet points derived from commits, grouped by type>

     ## Test plan
     - [ ] <derived from what changed, e.g., "CI passes", "manual test of X">
     ```

4. **Create PR**: Run `gh pr create --title "<title>" --body "<body>"` using a HEREDOC for the body.

5. **Report**: Show the PR URL.

## Rules

- Never create a PR if there are no commits ahead of the default branch.
- If a PR already exists for this branch, show its URL instead of creating a duplicate.
- Keep the title under 70 characters.
- Group commits by type (feat, fix, chore, etc.) in the summary.

## Gotchas

- Refuse when `HEAD` is the default branch: a PR needs a non-default source branch. Detect the default with `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, compare to `git branch --show-current`, and if they match, stop and tell the user to create a feature branch first.
- For a fork-based PR, the head ref must be qualified as `owner:branch`. Pass it with `gh pr create --head <owner>:<branch>` (the owner is the fork's GitHub login), so the PR targets the upstream repo from your fork.
