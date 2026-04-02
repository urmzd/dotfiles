---
name: pr
description: Create a pull request with auto-generated summary from commits, following conventional commit conventions. Use when creating PRs.
allowed-tools: Bash
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
     ```
     ## Summary
     - <bullet points derived from commits, grouped by type>

     ## Test plan
     - [ ] <derived from what changed — e.g., "CI passes", "manual test of X">
     ```

4. **Create PR**: Run `gh pr create --title "<title>" --body "<body>"` using a HEREDOC for the body.

5. **Report**: Show the PR URL.

## Rules

- Never create a PR if there are no commits ahead of the default branch.
- If a PR already exists for this branch, show its URL instead of creating a duplicate.
- Keep the title under 70 characters.
- Group commits by type (feat, fix, chore, etc.) in the summary.
