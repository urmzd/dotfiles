---
name: ai-workflows
description: AI tools, Claude Code configuration, sr commits, AGENTS.md standard, skills-as-docs philosophy, and llms.txt. Use when setting up AI tooling, configuring projects for AI, or working with agent skills.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
metadata:
  title: AI Workflows
  category: ai
  order: 0
---

# AI Workflows

## Documentation-as-Skills Philosophy

- Skills replace conventional `docs/` directories
- Every repo should have: README.md (humans) + AGENTS.md (AI) + SKILL.md (agent instructions) + llms.txt (LLM discovery)
- No separate docs folder

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

## AGENTS.md Standard

Every repo MUST have `AGENTS.md` at root.

### Template Structure

1. **Identity** — project name, one-line description
2. **Architecture** — high-level component overview
3. **File Tables** — key files/directories with descriptions
4. **Key Interfaces** — important types, traits, functions
5. **Commands** — build, test, lint, run
6. **Code Style** — language-specific conventions
7. **Extension Guide** — how to add features

Reference: `adk/AGENTS.md` as canonical example.

## Skills Standard

Every repo with a CLI or library should have `skills/<name>/SKILL.md`:

- **Frontmatter:** `name`, `description`, `argument-hint` (for CLI tools)
- **Content:** step-by-step guidance for using or extending the project
- Skills are installable via `npx skills add urmzd/<repo-name>`

## AI-Powered Git Workflows (sr)

sr provides AI-powered git commands with multi-backend support (`--backend {claude|copilot|gemini}`):

| Command | Purpose |
|---------|---------|
| `sr commit` | Generate atomic conventional commits from staged/unstaged changes |
| `sr rebase` | AI-powered interactive rebase (reword, squash, reorder) |
| `sr review` | Code review of staged/branch changes with severity feedback |
| `sr pr` | Generate PR title + body from branch commits |
| `sr branch` | Suggest conventional branch name |
| `sr explain` | Explain recent commits |
| `sr ask` | Freeform Q&A about the repo |

```bash
# Stage changes, then generate commit
git add -p
sr commit

# Or commit all changes with context
sr commit -M "refactored auth flow"

# AI-powered rebase of last 5 commits
sr rebase --last 5
```

Global flags: `--backend`, `--model`, `--budget` (Claude only, default $0.50), `--debug`.
