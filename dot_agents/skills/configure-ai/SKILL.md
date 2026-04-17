---
name: configure-ai
description: AI tools, Claude Code configuration, AGENTS.md standard, skills-as-docs philosophy, and llms.txt. Use when setting up AI tooling, configuring projects for AI, or working with agent skills.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: AI Workflows
  category: ai
  order: 0
---

# AI Workflows

## Specifications

| Convention | Spec |
|------------|------|
| SKILL.md | [Agent Skills Specification](https://agentskills.io/specification) |
| AGENTS.md | [agents.md Standard](https://agents.md/) |
| llms.txt | [llms.txt Specification](https://llmstxt.org/) |

## Skills vs Docs

- **Skills** (`skills/<name>/SKILL.md`) = executable agent instructions. *How to do things* (conventions, workflows, tool usage)
- **Docs** (`docs/`) = project documentation. *What was decided and why* (rfcs/, guides/, plans/, runbooks/, architecture/)
- Both exist in every project; neither replaces the other
- Every repo should also have: README.md (humans) + AGENTS.md (AI) + llms.txt (LLM discovery)
- Root-level standard files (README, AGENTS.md, CONTRIBUTING, LICENSE, CODEOWNERS, llms.txt) stay at root; everything else goes in `docs/`

## AI Tools

| Tool | Usage |
|------|-------|
| Claude Code (opus) | Primary AI coding assistant. Architecture, refactoring, multi-file edits |
| OpenAI Codex | Alternative AI assistant for code generation |
| Google Gemini CLI | Google's AI for research and code tasks |
| GitHub Copilot | Inline code completion in Neovim |

## Claude Code Configuration

Claude Code is configured per-project via `CLAUDE.md` files at the repository root. These files define:

- **Project context** tech stack, directory structure, key patterns
- **Coding conventions** naming, formatting, commit style
- **Behavioral rules** what to avoid, how to handle edge cases
- **Memory** persistent notes stored in `.claude/` directories

### Best Practices

- Keep `CLAUDE.md` concise; it's loaded into every conversation
- Use separate memory files for detailed topic notes
- Reference project-specific tools and commands
- Define verification steps (build, test, lint)

## AGENTS.md Standard

Every repo MUST have `AGENTS.md` at root.

### Template Structure

1. **Identity** project name, one-line description
2. **Architecture** high-level component overview
3. **Commands** build, test, lint, run
4. **Code Style** language-specific conventions
5. **Extension Guide** how to add features

Do NOT include static directory trees or file tables; structure goes stale. Instead, instruct agents to use `tree` and `ripgrep`/`ag` to discover project layout on the fly.

## Skills Standard

Every repo with a CLI or library should have `skills/<name>/SKILL.md`:

- **Frontmatter:** `name`, `description`, `argument-hint` (for CLI tools)
- **Content:** step-by-step guidance for using or extending the project
- Skills live in `skills/<name>/SKILL.md` within each repo

## Git Workflows

AI-assisted commit, review, and PR authoring live in dedicated agent skills (`ship`, `pr`, `review`), not in the release tool. The release tool (`sr`) is release-engineering only as of v7: `release`, `status`, `config`, `init`, `migrate`, `completions`, `update`. See `sync-release` for release conventions and `sr migrate` for the upgrade guide from older versions.
