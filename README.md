<p align="center">
  <h1 align="center">dotfiles</h1>
  <p align="center">
    Cross-platform dev environment powered by Chezmoi + Homebrew. One command to a fully configured machine.
    <br /><br />
    <a href="#quick-start">Quick Start</a>
    &middot;
    <a href="https://github.com/urmzd/dotfiles/issues">Report Bug</a>
    &middot;
    <a href="#agent-skills">Agent Skills</a>
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
- **A portable agent skills catalog** in [`dot_agents/skills/`](dot_agents/skills/) and subagents in [`dot_agents/agents/`](dot_agents/agents/), installable into any tool via [`agentspec`](https://github.com/urmzd/agentspec). See [Agent Skills](#agent-skills) for the full list.
- **Chezmoi automation** scripts that trigger on apply
- **Docker cleanup** launchd agent running daily at 3 AM

## Quick Start

One-liner (installs Homebrew + chezmoi, then runs `chezmoi init --apply`):

```bash
curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/install.sh | bash
```

Or step by step:

```bash
# 1. Install Homebrew (macOS) or your distro's package manager (Linux)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install chezmoi and apply this repo in one shot
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply urmzd
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
- gcloud + aws-cli, [`run_onchange_after_install-cloud-clis.sh.tmpl`](run_onchange_after_install-cloud-clis.sh.tmpl)
- Snowflake Cortex Code, [`run_onchange_after_install-cortex.sh.tmpl`](run_onchange_after_install-cortex.sh.tmpl) (gated on `install_cortex` feature flag)

**AI tools** (installed via [`run_once_after_install-ai-clis.sh.tmpl`](run_once_after_install-ai-clis.sh.tmpl), sentinel-gated): Claude Code, Codex (workspace-write "Auto" default with `writer`/`reviewer`/`plan`/`guardian` profiles), Gemini CLI, GitHub Copilot. Update with `dotfiles update-ai`.

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

Per-tool AI config is tracked and deployed by chezmoi:

| Tool | Source | Default posture |
| ---- | ------ | --------------- |
| Claude Code | `dot_claude/` | Settings, custom statusline, project-scoped skills |
| Codex | `dot_codex/` | Workspace-write "Auto" base (auto-run safe ops, guardian auto-reviewer vets escalations) + `writer`/`reviewer`/`plan`/`guardian` profile overlays and `/agent` subagents |
| Gemini CLI | `dot_gemini/` | OAuth, `auto_edit` approval, read-only shell auto-approve allowlist, telemetry off |
| GitHub Copilot | `dot_copilot/` | `settings.json` with model, `xhigh` effort, theme |

Codex runs OpenAI's documented "Auto" preset by default: `sandbox_mode = "workspace-write"` + `approval_policy = "on-request"`, with the guardian auto-reviewer (`approvals_reviewer = "auto_review"`) classifying every escalation before it reaches you. Drop to `codex --profile reviewer` or `--profile plan` for read-only work; the `guardian` profile supervises `orchestrate-agents` fleets.

## Agent Skills

Skills and subagents in this repo are **cross-project**: once installed via [`agentspec`](https://github.com/urmzd/agentspec), they are available to any tool (claude-code, codex, gemini, copilot) from any project. The source-of-truth lives in [`dot_agents/skills/`](dot_agents/skills/) and [`dot_agents/agents/`](dot_agents/agents/), following the [Agent Skills Specification](https://agentskills.io/specification).

Related standards: [AGENTS.md](https://agents.md/) and [llms.txt](https://llmstxt.org/)

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

#### Quality & design (framework -> principles -> operational)

| Skill | Purpose |
| ----- | ------- |
| assess-quality | Foundational quality framework. The "why" layer above review-design and write-code |
| review-design | Pragmatic Programmer principles (DRY, orthogonality, design by contract) |
| review-diff | Review the current staged/unstaged/untracked changes against a five-dimension rubric (the home assess-quality and review-design hand day-to-day review to) |
| write-code | Operational picks: error handling, testing strategy, commit conventions, interface design |
| write-code-portfolio | Personal portfolio specifics (Nix Flakes, chezmoi machine polymorphism, Powerlevel10k, Neovim) |
| test-code | Testing philosophy and per-language conventions |
| build-cli | Design and audit CLI tools end-to-end (output modes, TTY, JSON piping, install.sh, portfolio self-update / `--format` requirements) |
| check-project | Validate project structure against scaffold conventions |
| choose-stack | Canonical tech stack reference by purpose |

#### Scaffolding & setup

`scaffold-project` is the canonical source for standard files; each `scaffold-<lang>` adds only language-specific deltas.

| Skill | Purpose |
| ----- | ------- |
| scaffold-project | Project structure and standard files (canonical) |
| scaffold-go | Go-specific deltas (toolchain, CI matrix, release publisher) |
| scaffold-node | Node/TypeScript deltas |
| scaffold-python | Python deltas |
| scaffold-rust | Rust deltas |
| scaffold-terraform | Terraform infra deltas |
| setup-ci | CI/CD pipeline conventions |
| setup-devenv | Per-language version manager + direnv pattern (portable) |
| setup-devenv-with-chezmoi | Chezmoi-specific helpers for pinned installers and tracked `.envrc` |
| sync-release | End-to-end release pipeline (sr.yaml, CI, multi-platform builds) |
| repo-init | Full repo bootstrap (create, license, scaffold, push) |
| community-health | GitHub Community Standards (CODE_OF_CONDUCT, SECURITY, ISSUE_TEMPLATE) with `$COMMUNITY_HEALTH_CONTACT` |

#### Workflow automation

| Skill | Purpose |
| ----- | ------- |
| ship | Generate a conventional commit, then optionally push and watch CI until pass/fail |
| pr | Create PRs with auto-generated summary from commits |
| diagnose-ci | Find failing remote CI pipelines, pull logs, identify root cause (local sibling: diagnose-runtime) |
| diagnose-runtime | Triage local runtime errors, hangs, slowness, and hardware/serial issues (the local counterpart to diagnose-ci) |
| fix-and-retry | Diagnose CI failure, apply fix, commit, push, re-run |
| repo-status | Scan a folder of git repos and report recent activity, branch divergence, and uncommitted state (renamed from `status`) |
| release-audit | Audit releases, tags, and assets for health |
| sync-ecosystem | Audit one repository against ecosystem conventions and emit a drift report |
| sync-ecosystem-to-chezmoi | Apply a sync-ecosystem drift report back into the chezmoi source tree |
| update-repo-meta | Update GitHub repo topics, description, homepage |
| manage-secrets | 1Password-based secret workflow (vault layout, `1p://` references, `op run`) |
| orchestrate-agents | Drive multiple agent CLIs (Claude, Codex, Gemini) over tmux with a shared fleet store |

#### AI & documentation

`create-oss-skill` owns the base spec; `extend-oss-skills-to-claude` is a sequel covering only the Claude-specific deltas.

| Skill | Purpose |
| ----- | ------- |
| configure-ai | AI tooling configuration, AGENTS.md, skills standard |
| create-llms-txt | Generate llms.txt files |
| create-oss-skill | Create portable agent skills (canonical spec) |
| extend-oss-skills-to-claude | Claude-specific skill deltas (invocation control, subagent execution, model overrides) |
| audit-security | Security auditing and threat detection |
| style-brand | Frame and document a project's visual identity. Ships Cyberdream + MonaspiceNe + teasr as a template, not a mandate |
| sync-docs | Audit and synchronize project documentation (canonical doc-drift skill) |
| write-readme | README structure and section order |

#### Subagents

Delegation targets in [`dot_agents/agents/`](dot_agents/agents/) that adopt a specific reasoning mode. Installable into any tool via `agentspec manage link <name> <tool>`.

| Agent | Purpose |
| ----- | ------- |
| architect | Interface-first systems design with verbose, principle-driven reasoning |
| curator | Prescriptive perfectionist for consistency, polish, and visual hierarchy |
| debugger | Terse, empirical root-cause analysis |
| guardian | Supervises orchestrated agent fleets driven by the `orchestrate-agents` skill (also installed as a Codex profile) |
| ideator | Expansive, generative creative exploration |
| strategist | Imperative orchestration across multiple systems and repos |
| technical-documentation-architect | Structured technical documentation and architecture docs |
| writer | Concise, outcome-focused technical documentation |

## License

[Apache-2.0](LICENSE)
