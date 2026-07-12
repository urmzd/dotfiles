# Contributing

Thanks for your interest in contributing to **dotfiles**.

## Environment Setup

See [Quick Start](README.md#quick-start) for environment setup (Homebrew/apt, chezmoi, `gh` auth). This document focuses on git workflow, commit conventions, and contributing skills/subagents.

## Development

```sh
git clone https://github.com/urmzd/dotfiles.git
cd dotfiles
```

| Command | What it does |
|---------|-------------|
| `chezmoi diff` | Preview pending changes |
| `chezmoi apply` | Apply dotfile changes |
| `dotfiles update` | `brew upgrade` + `chezmoi apply` |
| `dotfiles status` | Show installed AI tool versions |

For chezmoi file naming conventions (`dot_`, `private_`, `.tmpl`, `run_once_*`, `run_onchange_*`), see [AGENTS.md, File Naming Conventions](AGENTS.md#file-naming-conventions).

## Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/) enforced via [sr](https://github.com/urmzd/sr):

| Prefix | Purpose |
|--------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `refactor` | Refactoring |
| `chore` | Maintenance |
| `ci` | CI changes |

Format: `type(scope): description`. Scope by tool/area (e.g., `feat(nvim):`, `fix(zsh):`, `chore(brew):`).

## Pull Requests

1. Fork the repository
2. Create a feature branch (`feat/your-feature`)
3. Test with `chezmoi diff` before applying
4. Push to your fork and open a Pull Request
5. Keep PRs focused; one logical change per PR

## Contributing Skills and Subagents

Skills and subagents live in `dot_agents/skills/<name>/SKILL.md` and `dot_agents/agents/<name>.md` respectively. They are deployed to `~/.agents/skills/` and `~/.agents/agents/` on `chezmoi apply` and become available to every tool linked via [`agentspec`](https://github.com/urmzd/agentspec).

**Scaffolding**

```bash
agentspec manage create <name>     # Scaffold a new skill or subagent
```

**Frontmatter rules** (see [create-oss-skill](dot_agents/skills/create-oss-skill/SKILL.md) for the full spec):

- YAML between `---` markers
- Fields: `name`, `description` (one-line, ends with "Use when..."), optional `model`, optional `allowed-tools`
- Imperative mood ("Use when..." not "Can be used when...")

**Validation**

```bash
agentspec manage validate dot_agents/skills/<name>/SKILL.md
agentspec manage validate dot_agents/agents/<name>.md
```

**Testing**

1. `chezmoi apply` to deploy
2. `agentspec sync --fast` to link
3. Invoke from your tool of choice (for example, `/<name>` in Claude Code) and confirm the description triggers correctly
4. For documentation changes, run `/clean-docs` or `dot_agents/skills/sync-docs/scripts/executable_check-doc-hygiene.sh .`

**Style**

- No em dashes. Use bold indexing (**A**, **B**) or commas instead
- Tables over prose for matrices
- Cross-project: never hard-code paths into `~/.local/share/chezmoi`. Reference deployed locations (`~/.agents/skills/<name>/`) or `$AGENTSPEC_HOME`

## Code Style

- Shell scripts: POSIX-compatible where possible, bash/zsh when needed
- Templates: Use `{{ .chezmoi.os }}` guards for platform-specific blocks
- Never commit secrets, API keys, or tokens
