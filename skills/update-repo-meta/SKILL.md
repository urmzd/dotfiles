---
name: update-repo-meta
description: Update GitHub repo metadata — topics, description, homepage, and visibility via gh CLI. Use when updating repo settings.
allowed-tools: Bash
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
