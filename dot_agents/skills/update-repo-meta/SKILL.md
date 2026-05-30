---
name: update-repo-meta
description: >-
  Update GitHub repository metadata via the gh CLI: add or remove repo topics, set the
  description, set the homepage URL, and change visibility (public/private). Reads current
  state and shows before/after. Use when updating repo settings, retagging topics, fixing a
  repo description or homepage, or making a repo public or private. Do NOT use to edit local
  repo files, branch protection, or release metadata; this only touches repo-level settings
  exposed by gh repo edit.
allowed-tools: Read, Grep, Glob, Bash(gh *)
user-invocable: true
arguments:
  - name: args
    description: "Free-form instructions like 'add topic X' or 'set description to Y'"
    required: false
---

# Update Repo Meta

Update GitHub repository metadata.

## Steps

1. **Read current state**: `gh repo view --json name,description,homepageUrl,repositoryTopics,visibility`

2. **Determine changes**: Based on the user's argument or conversation context, figure out what to update. Common operations:
   - **Topics**: `gh repo edit --add-topic <topic>` or `--remove-topic <topic>`
   - **Description**: `gh repo edit --description "<text>"`
   - **Homepage**: `gh repo edit --homepage "<url>"`
   - **Visibility**: `gh repo edit --visibility public|private`

3. **Apply changes**: Run the appropriate `gh repo edit` commands.

4. **Verify**: Run `gh repo view --json name,description,homepageUrl,repositoryTopics,visibility` again and show the updated state.

## Rules

- Show the before/after so the user can confirm the changes.
- If no specific instructions are given, show the current metadata and ask what to change.
- Topics should be lowercase, hyphenated (e.g., `cli-tool`, `go`, `mcp-server`).

## Gotchas

- **Topic cap is 20.** GitHub caps a repo at 20 topics; `gh repo edit --add-topic` past
  that limit fails. Check the current count before adding in bulk.
- **Server-side normalization is authoritative.** GitHub lowercases topics and replaces
  spaces/invalid characters with hyphens on its end. Normalizing client-side first is only
  cosmetic; the server has the final say, so verify with `gh repo view` rather than assuming
  your input string was stored verbatim.
- **Visibility changes can be blocked.** `gh repo edit --visibility` may require an explicit
  consent flag (e.g. `--accept-visibility-change-consequences`), and an org policy can block
  going public or private entirely. If the command errors, surface the policy/consent reason
  to the user rather than retrying blindly.
