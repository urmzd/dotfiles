---
name: ai-workflows
description: AI tools, Claude Code configuration, and AI-powered git commits. Use when setting up AI tooling, configuring CLAUDE.md files, or working with gitit/git-ai commits.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
metadata:
  title: AI Workflows
  category: ai
  order: 0
---

# AI Workflows

## AI Tools

| Tool | Usage |
|------|-------|
| Claude Code (opus) | Primary AI coding assistant — architecture, refactoring, multi-file edits |
| OpenAI Codex | Alternative AI assistant for code generation |
| Google Gemini CLI | Google's AI for research and code tasks |
| GitHub Copilot | Inline code completion in Neovim |

## Claude Code Configuration

Claude Code is configured per-project via `CLAUDE.md` files at the repository root. These files define:

- **Project context** — tech stack, directory structure, key patterns
- **Coding conventions** — naming, formatting, commit style
- **Behavioral rules** — what to avoid, how to handle edge cases
- **Memory** — persistent notes stored in `.claude/` directories

### Best Practices

- Keep `CLAUDE.md` concise — it's loaded into every conversation
- Use separate memory files for detailed topic notes
- Reference project-specific tools and commands
- Define verification steps (build, test, lint)

## AI-Powered Git Commits

Commit messages are generated via `gitit`, which analyzes staged changes and produces Angular Conventional Commit messages automatically.

```bash
# Stage changes, then generate commit
git add -p
gitit
```

The tool follows the same commit style conventions defined in the development-practices skill.
