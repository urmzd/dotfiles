<p align="center">
  <h1 align="center">dotfiles</h1>
  <p align="center">
    Cross-platform dev environment powered by Chezmoi + Nix. One command to a fully configured machine.
    <br /><br />
    <a href="#quick-start">Quick Start</a>
    &middot;
    <a href="https://github.com/urmzd/dotfiles/issues">Report Bug</a>
    &middot;
    <a href="#agent-skill">Agent Skill</a>
  </p>
</p>

## Features

- **Nix dev shell** with 15+ languages and 40+ tools
- **Zsh** with Oh My Zsh + Powerlevel10k and auto-completions for all Nix packages
- **Tmux** with `Ctrl+a` prefix, vim keys, Catppuccin cyberdream theme
- **Ghostty** terminal with cyberdream theme and MonaspiceNe Nerd Font
- **Neovim** (HEAD) with LSP for all included languages
- **AI agents** (Claude Code, Gemini, Codex, Copilot) with auto-install
- **36 portable agent skills** in [`dot_agents/skills/`](dot_agents/skills/)
- **Chezmoi automation** scripts that trigger on apply
- **macOS extras** via Homebrew (fonts, Android tooling, VHS for CLI recordings)
- **Docker cleanup** launchd agent running daily at 3 AM

## Quick Start

```bash
# One-command bootstrap (installs Nix + Chezmoi, then applies everything)
curl -fsSL https://raw.githubusercontent.com/urmzd/.dotfiles/main/bootstrap-nix-chezmoi.sh | bash

# Or, if chezmoi is already installed
chezmoi init --apply https://github.com/urmzd/.dotfiles.git
```

After bootstrap completes, open a new terminal. The Nix dev shell activates automatically via direnv.

## Usage

### Day-to-day

```bash
chezmoi diff          # Preview pending dotfile changes
chezmoi apply         # Apply dotfile changes to $HOME
chezmoi add <file>    # Start tracking a new file
chezmoi edit <file>   # Edit source, then apply
```

### Nix environment

```bash
nix develop              # Enter the dev shell (or use direnv)
dotfiles-update          # Update Nix flake inputs and rebuild
dotfiles-status          # Check flake age + AI tool versions
```

### What's in the shell

**Languages & runtimes**: Node 22, Deno, Python 3.13, Go, Rust (via rustup), Java 21, Lua 5.4, Haskell (GHC + Cabal), Ruby + Rails, Guile Scheme, Perl

**DevOps & cloud**: Terraform, kubectl, Helm, k9s, AWS CLI, GCloud SDK, Colima, Docker (+ buildx/compose), GoReleaser

**CLI essentials**: git, gh, fzf, ripgrep, jq, yq, just, tmux, direnv, chezmoi, curl, wget, tree, tldr, gnupg, tree-sitter, uv

### Adding a new tool

1. Add the package to `allPackages` in `flake.nix`
2. Run `chezmoi apply`. The `check-flake` script rebuilds automatically
3. Completions regenerate if the package exposes zsh site-functions

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
| `install-packages-v2` | run_once (before) | First apply only |
| `brewfile-install` | run_onchange (before) | Brewfile changes |
| `check-flake` | run_onchange (after) | flake.lock changes |
| `generate-completions` | run_onchange (after) | zshrc or flake.lock changes |
| `install-skills` | run_onchange (after) | Any SKILL.md changes (syncs to `~/.agents/skills/`) |
| `configure-terminal` | run_once (after) | First apply only |
| `load-docker-cleanup` | run_once (after) | First apply only |

### AI tools

AI coding agents are installed automatically when entering the Nix dev shell. Check versions with:

```bash
dotfiles-status
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
| choose-stack | Canonical tech stack reference by purpose |
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
| setup-devenv | Nix development shell guidance |
| setup-release | End-to-end release pipeline (sr.yaml, CI, multi-platform builds) |
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
| update-repo-meta | Update GitHub repo topics, description, homepage |

#### AI & documentation

| Skill | Purpose |
| ----- | ------- |
| configure-ai | AI-assisted workflow patterns |
| create-llms-txt | Generate LLM-friendly project summary files |
| create-oss-skill | Create portable agent skills |
| extend-oss-skills-to-claude | Extend skills with Claude Code-specific features |
| audit-security | Security auditing and threat detection |
| style-brand | Branding, themes, VHS demos, teasr integration |
| write-readme | README structure and section order |

#### Personas

Reasoning frameworks that adopt a specific mindset for different types of work:

| Skill | Purpose |
| ----- | ------- |
| persona-architect | Interface-first systems design with verbose, principle-driven reasoning |
| persona-curator | Prescriptive perfectionist for consistency, polish, and visual hierarchy |
| persona-debugger | Terse, empirical root-cause analysis |
| persona-ideator | Expansive, generative creative exploration |
| persona-strategist | Imperative orchestration across multiple systems and repos |
| persona-writer | Concise, outcome-focused technical documentation |

## License

MIT
