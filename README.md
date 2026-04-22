<p align="center">
  <h1 align="center">dotfiles</h1>
  <p align="center">
    Cross-platform dev environment powered by Chezmoi + Homebrew. One command to a fully configured machine.
    <br /><br />
    <a href="#quick-start">Quick Start</a>
    &middot;
    <a href="https://github.com/urmzd/dotfiles/issues">Report Bug</a>
    &middot;
    <a href="#agent-skill">Agent Skill</a>
  </p>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/urmzd/dotfiles" alt="License"></a>
</p>

## Features

- **Homebrew + apt** as source of truth for CLIs (git, gh, kubectl, terraform, ...)
- **Per-language version managers**: fnm (Node), uv (Python), rustup (Rust)
- **Pinned upstream installers** for tools that need it: gcloud, aws-cli, Snowflake Cortex
- **Zsh** with Oh My Zsh + Powerlevel10k and pre-generated completions
- **Tmux** with `Ctrl+a` prefix, vim keys, Catppuccin cyberdream theme
- **Ghostty** terminal with cyberdream theme and MonaspiceNe Nerd Font
- **Neovim** (HEAD) with LSP for all included languages
- **AI agents** (Claude Code, Gemini, Codex, Copilot) auto-installed via chezmoi
- **34 portable agent skills** in [`dot_agents/skills/`](dot_agents/skills/) + **7 subagents** in [`dot_agents/agents/`](dot_agents/agents/)
- **Chezmoi automation** scripts that trigger on apply
- **Docker cleanup** launchd agent running daily at 3 AM

## Quick Start

```bash
# 1. Install Homebrew (macOS) or your distro's package manager (Linux)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install chezmoi
sh -c "$(curl -fsSL get.chezmoi.io)"

# 3. Apply this repo
chezmoi init --apply urmzd
```

`chezmoi apply` installs Brewfile/apt packages, sets up gcloud/aws/cortex from upstream, and installs the AI CLIs. Open a new terminal afterwards.

## Usage

### Day-to-day

```bash
chezmoi diff          # Preview pending dotfile changes
chezmoi apply         # Apply dotfile changes to $HOME
chezmoi add <file>    # Start tracking a new file
chezmoi edit <file>   # Edit source, then apply
```

### Maintenance

```bash
dotfiles update          # brew upgrade && chezmoi apply
dotfiles status          # Show installed AI tool versions
dotfiles update-ai       # Re-install AI CLIs at pinned versions
dotfiles cleanup         # Prune build artifacts and caches
```

### What's installed

**CLI essentials** (Homebrew on macOS, apt/dnf/pacman on Linux): git, gh, fzf, ripgrep, jq, yq, just, tmux, direnv, chezmoi, tree-sitter, uv, tealdeer, terraform, kubectl, helm, k9s, colima, docker, fnm, deno, go, lua, ...see [`Brewfile`](Brewfile).

**Version managers** (per-language, best-in-class): fnm (Node), uv (Python), rustup (Rust).

**Upstream-pinned installers** (security/auth fixes ship faster than distro repos):
- gcloud + aws-cli — [`run_onchange_after_install-cloud-clis.sh.tmpl`](run_onchange_after_install-cloud-clis.sh.tmpl)
- Snowflake Cortex Code — [`run_onchange_after_install-cortex.sh.tmpl`](run_onchange_after_install-cortex.sh.tmpl) (gated on `install_cortex` feature flag)

**AI tools** (installed via [`run_once_after_install-ai-clis.sh.tmpl`](run_once_after_install-ai-clis.sh.tmpl), sentinel-gated): Claude Code, Codex, Gemini CLI, GitHub Copilot. Update with `dotfiles update-ai`.

### Adding a new tool

1. Homebrew: add to [`Brewfile`](Brewfile). Linux: add to the apt/dnf/pacman list in [`run_once_before_install-packages-v2.sh.tmpl`](run_once_before_install-packages-v2.sh.tmpl).
2. For tools needing version pinning: write a `run_onchange_after_install-<name>.sh.tmpl` mirroring the cortex / cloud-clis pattern.
3. Run `chezmoi apply`. Completions regenerate if the package exposes zsh site-functions.

### Adding a new dotfile

1. Create or edit the file in your home directory
2. Run `chezmoi add <file>` to start tracking it
3. Use `dot_` prefix naming, `private_` for sensitive files, `.tmpl` for templates
4. Platform-specific blocks use `{{ if eq .chezmoi.os "darwin" }}...{{ end }}`

## Configuration

### Chezmoi automation

These scripts run automatically on `chezmoi apply`:

| Script | Type | Trigger |
| ------ | ---- | ------- |
| `install-packages-v2` | run_once (before) | First apply (installs Homebrew + bootstrap Linux packages) |
| `brewfile-install` | run_onchange (before) | Brewfile changes |
| `install-cloud-clis` | run_onchange (after) | Script changes (re-pin gcloud/aws version) |
| `install-cortex` | run_onchange (after) | Script changes (gated on `install_cortex` flag) |
| `generate-completions` | run_onchange (after) | zshrc, Brewfile, or cloud-clis script changes |
| `install-ai-clis` | run_once (after) | First apply (sentinel-gated; clear via `dotfiles update-ai`) |
| `install-skills` | run_once (after) | First apply only (bootstraps `agentspec`, syncs skills to `~/.agents/skills/`) |
| `install-stack` | run_once (after) | First apply only (installs `sr`, `teasr`, `oag` CLIs) |
| `configure-terminal` | run_once (after) | First apply only |
| `load-docker-cleanup` | run_once (after) | First apply only |

### AI tools

AI coding agents are installed by `chezmoi apply` (sentinel-gated, no shell-startup cost). Check versions with:

```bash
dotfiles status
```

Claude Code config lives in `dot_claude/`. Includes settings, custom statusline, and project-scoped skills.

## Agent Skills

This repo's conventions are available as portable agent skills in [`dot_agents/skills/`](dot_agents/skills/), following the [Agent Skills Specification](https://agentskills.io/specification).

Related standards: [AGENTS.md](https://agents.md/) · [llms.txt](https://llmstxt.org/)

### Managing skills

All skills are installed automatically via `chezmoi apply`. The [`install-skills`](run_once_after_install-skills.sh.tmpl) script uses [`agentspec`](https://github.com/urmzd/agentspec) to install both local skills from [`dot_agents/skills/`](dot_agents/skills/) and third-party skills globally to all agents:

| Source | Skills |
| ------ | ------ |
| This repo (`dot_agents/skills/`) | All local skills |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | All |
| [vercel/ai-elements](https://github.com/vercel/ai-elements) | All |
| [vercel/streamdown](https://github.com/vercel/streamdown) | All |
| [google-gemini/gemini-skills](https://github.com/google-gemini/gemini-skills) | All |
| [better-auth/skills](https://github.com/better-auth/skills) | better-auth-best-practices |
| [vercel/ai](https://github.com/vercel/ai) | ai-sdk |
| [fastapi/fastapi](https://github.com/fastapi/fastapi) | fastapi |

To manage skills and agents manually:

```bash
agentspec manage list                          # List managed resources with tool linkage
agentspec manage add <source>                  # Add from local path, GitHub (owner/repo), or name
agentspec manage link <name> <tool>            # Link resource to a tool (claude-code, codex, etc.)
agentspec manage remove <name>                 # Remove a managed resource
agentspec manage create [name]                 # Scaffold a new resource
agentspec manage validate [path]               # Validate SKILL.md or agent definition
agentspec status                               # Show managed vs unmanaged inventory
agentspec sync --fast                          # Discover, adopt, link, and verify all resources
```

### All skills

#### Coding standards

| Skill | Purpose |
| ----- | ------- |
| assess-quality | Code quality assessment (readability, consistency, intentional design) |
| build-cli | CLI conventions (JSON piping, stdout/stderr, structured logging) |
| check-project | Validate project structure against scaffold conventions |
| choose-stack | Canonical tech stack reference by purpose |
| cli-standards | CLI patterns and conventions reference |
| review-design | Pragmatic programming principles |
| test-code | Testing philosophy and per-language conventions |
| write-code | Coding standards and practices |

#### Scaffolding & setup

| Skill | Purpose |
| ----- | ------- |
| scaffold-go | Scaffold Go projects |
| scaffold-node | Scaffold Node/TypeScript projects |
| scaffold-project | Project structure (.envrc, Cargo workspace, etc.) |
| scaffold-python | Scaffold Python projects |
| scaffold-rust | Scaffold Rust projects |
| scaffold-terraform | Scaffold Terraform projects |
| setup-ci | CI/CD pipeline conventions |
| setup-devenv | Per-language toolchain + direnv guidance |
| sync-release | End-to-end release pipeline (sr.yaml, CI, multi-platform builds) |
| repo-init | Full repo bootstrap (create, license, scaffold, push) |

#### Workflow automation

| Skill | Purpose |
| ----- | ------- |
| ship | Commit, push, and watch CI until pass/fail |
| pr | Create PRs with auto-generated summary from commits |
| diagnose-ci | Find failing pipelines, pull logs, identify root cause |
| fix-and-retry | Diagnose CI failure, apply fix, commit, push, re-run |
| status | Check active repos for recent activity and local state |
| release-audit | Audit releases, tags, and assets for health |
| sync-ecosystem | Sync project ecosystem (deps, configs, cross-repo consistency) |
| update-repo-meta | Update GitHub repo topics, description, homepage |

#### AI & documentation

| Skill | Purpose |
| ----- | ------- |
| configure-ai | AI-assisted workflow patterns |
| create-llms-txt | Generate LLM-friendly project summary files |
| create-oss-skill | Create portable agent skills |
| extend-oss-skills-to-claude | Extend skills with Claude Code-specific features |
| audit-security | Security auditing and threat detection |
| style-brand | Branding, themes, teasr demo capture, asset conventions |
| sync-docs | Audit and synchronize project documentation |
| write-readme | README structure and section order |

#### Subagents

Delegation targets in [`dot_agents/agents/`](dot_agents/agents/) that adopt a specific reasoning mode:

| Agent | Purpose |
| ----- | ------- |
| architect | Interface-first systems design with verbose, principle-driven reasoning |
| curator | Prescriptive perfectionist for consistency, polish, and visual hierarchy |
| debugger | Terse, empirical root-cause analysis |
| ideator | Expansive, generative creative exploration |
| strategist | Imperative orchestration across multiple systems and repos |
| technical-documentation-architect | Structured technical documentation and architecture docs |
| writer | Concise, outcome-focused technical documentation |

## License

[Apache-2.0](LICENSE)
