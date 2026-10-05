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
- **Neovim** (HEAD) with LSP for all included languages, tuned for reviewing agent work: a clickable Files/Changes/Tests sidebar, worktree switching, and buffers that reload when an agent edits them. See [`dot_config/nvim/README.md`](dot_config/nvim/README.md).
- **AI agents** (Claude Code, Antigravity, Codex, Copilot, OpenCode) auto-installed via chezmoi
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

The bootstrap does not depend on our releases being healthy. chezmoi comes from get.chezmoi.io, falling back to Homebrew. The `dotfiles` CLI comes from the newest release that has a binary for your platform (the latest can be mid-build or failed), falling back to building `cli/` from the checkout with cargo. If both fail, the apply still finishes: the CLI is optional. Re-running the bootstrap fast-forwards an existing checkout before applying, and every third-party installer is downloaded and checked before it runs, so a network failure warns instead of passing silently.

`chezmoi init` asks only what it cannot derive: name (prefilled on macOS), machine type (`personal` or `work`), one email for commits, Cortex, package preset, which AI coding CLIs to install, and excludes. On a personal machine the GitHub user comes from the repo remote; the GPG key always comes from your keyring. A personal machine is asked for its email and about secrets management; a work machine is asked for its work email, its work GitHub account, and an optional [work pack](#work-pack) (git URL or local folder), and never for personal details. See [Setting up a machine's GitHub identity](#setting-up-a-machines-github-identity) for keys. Re-running `chezmoi init` reuses every saved answer.

## Usage

### Day-to-day

```bash
chezmoi diff          # Preview pending dotfile changes
chezmoi apply         # Apply dotfile changes to $HOME
chezmoi add <file>    # Start tracking a new file
chezmoi edit <file>   # Edit source, then apply
```

### Maintenance

The `dotfiles` command is a Rust CLI built from [`cli/`](cli/) in this repo. Every release attaches its binaries for macOS and Linux (x86_64 and arm64) with `.sha256` checksums; the first apply installs it, and `dotfiles update` keeps it current. To install it by hand: `curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/cli/install.sh | sh`.

```bash
dotfiles package                 # Search + toggle optional packages, then apply
dotfiles package add acli twg    # Select by id; `package remove` deselects (--uninstall to brew uninstall)
dotfiles package list --selected # The catalog with this machine's selection
dotfiles package setup           # Pending sign-in / interactive installers for selected packages
dotfiles package update          # brew upgrade + AI CLIs, then apply (or: brew | ai)
dotfiles identity                # This machine's GitHub identity: gh, SSH + GPG keys, signing check
dotfiles doctor                  # Health check, each finding with the command that fixes it
dotfiles apply                   # Show pending changes, confirm, then apply (-y skips confirm)
dotfiles diff                    # Full diff of pending changes
dotfiles config                  # Re-run the setup questions (saved answers kept), then apply
dotfiles status                  # Machine, packages, pending setup, tool versions
dotfiles update                  # Update the dotfiles CLI itself to the latest release
dotfiles edit                    # Open the dotfiles source in $EDITOR
dotfiles clean                   # Prune build artifacts and caches under ~/github
```

`dotfiles doctor` checks chezmoi, the catalog and selection, whether the CLI is the latest release, unapplied changes, Python (3.12+, gcloud pinned), that `gh` is signed in as this machine's account, that the commit signing key exists, AI CLIs installed twice (the first on PATH wins), and selected packages that are missing or waiting for sign-in. `--format json` prints the findings for scripts.

### What's installed

**CLI essentials** (Homebrew on macOS, apt/dnf/pacman on Linux): git, gh, fzf, ripgrep, jq, yq, just, tmux, direnv, chezmoi, tree-sitter, uv, tealdeer, fnm, deno, go, lua, ...see [`Brewfile.tmpl`](Brewfile.tmpl).

**Version managers** (per-language, best-in-class): fnm (Node), uv (Python), rustup (Rust).

**Default Python** is a uv-managed CPython 3.12 ([`run_before_install-python.sh.tmpl`](run_before_install-python.sh.tmpl)): `python`/`python3` link to it from `~/.local/share/dotfiles/python/bin`, which zsh puts ahead of Homebrew and `/usr/bin`, and gcloud uses it through `CLOUDSDK_PYTHON`. Without it, `python3` falls back to macOS's 3.9 (which breaks gcloud components) or to whatever `python@3.x` Homebrew pulled in. Bump `PYTHON_VERSION` in that script to change it; it re-checks on every apply, so a failed first install heals on the next.

**Upstream-pinned installers** (security/auth fixes ship faster than distro repos):
- gcloud + aws-cli, [`run_onchange_after_install-cloud-clis.sh.tmpl`](run_onchange_after_install-cloud-clis.sh.tmpl)
- Snowflake Cortex Code, [`run_onchange_after_install-cortex.sh.tmpl`](run_onchange_after_install-cortex.sh.tmpl) (gated on `install_cortex` feature flag)
- gh CLI extensions, [`run_onchange_after_install-gh-extensions.sh.tmpl`](run_onchange_after_install-gh-extensions.sh.tmpl) ([`github/gh-stack`](https://github.com/github/gh-stack) for stacked PRs)

**Optional packages** live in [`catalog.toml`](catalog.toml), grouped by category:

| Category | Packages |
| -------- | -------- |
| cloud | Docker + Colima, Kubernetes (kubectl, helm, k9s), Terraform, RunPod, Temporal |
| languages | Zig, Scala (scala-cli + coursier), mise |
| mobile | Android Studio + SDK, CocoaPods |
| fonts | Nerd Fonts (MonaspiceNe, Iosevka) |
| notes | Obsidian, Notion, Granola, Mintlify CLI (`mint`) |
| editors | Cursor, Visual Studio Code |
| chat | Slack, Slack CLI (`slack`), Discord, Zoom |
| productivity | 1Password, Raycast, Linear, Figma |
| ai | Claude, ChatGPT (desktop apps), Warp Agent CLI (`warp`, runs in Ghostty), Hugging Face CLI (`hf`) |
| media | Spotify |
| work | Atlassian CLI (`acli`), Teamwork Graph CLI (`twg`) |

Entries install through Homebrew (formulae and casks), `npm -g` into fnm's default Node, or `uv tool install` for Python CLIs. Each machine's selection is the list of ids at `packages` in its local `chezmoi.toml`. Change it with `dotfiles package`, a search-as-you-type multi-select list. [`Brewfile.tmpl`](Brewfile.tmpl) renders the selected entries on macOS; on Linux, [`run_onchange_after_install-catalog-linux.sh.tmpl`](run_onchange_after_install-catalog-linux.sh.tmpl) installs their `apt`/`dnf`/`pacman` names (entries without any are macOS-only). Packages that need sign-in (acli, twg) finish with `dotfiles package setup`, never during apply.

On first init, `package_preset` (`minimal` = core CLI + editor, `standard` = + cloud/infra + fonts, `full` = + mobile dev) seeds the selection from each entry's `presets`. Heavy toolchains (Temporal, Zig, Scala, mise) and the apps beyond Obsidian are never preset; pick them explicitly. `pkg_exclude` still drops individual core packages by name. To offer a new package, add a `[[package]]` entry to `catalog.toml`; no CLI release is needed.

The Brewfile installer continues past individual package failures, retries the remainder once, and prints categorized next steps (tap, permission, unknown formula, network, conflict) rather than aborting the whole apply.

**AI coding CLIs** are catalog packages (category **agents**): Claude Code, Codex, GitHub Copilot CLI, Antigravity (`agy`), OpenCode, Gemini CLI, Cursor Agent CLI, and Amp. The first `chezmoi init` asks which to install (multi-select, default Claude Code + Codex); change them any time with `dotfiles package`. Claude Code, agy, and OpenCode use their own installers, which keep them updated ([`run_after_install-catalog-scripts.sh.tmpl`](run_after_install-catalog-scripts.sh.tmpl), retried every apply until present); the rest come from Homebrew (npm on Linux). Codex runs with a workspace-write "Auto" default and `writer`/`reviewer`/`plan`/`guardian` profiles. `dotfiles package update ai` upgrades the selected ones.

### Adding a new tool

1. Homebrew: add to [`Brewfile.tmpl`](Brewfile.tmpl). Linux: add to the apt/dnf/pacman list in [`run_once_before_install-packages-v2.sh.tmpl`](run_once_before_install-packages-v2.sh.tmpl).
2. For tools needing version pinning: write a `run_onchange_after_install-<name>.sh.tmpl` mirroring the cortex / cloud-clis pattern.
3. Run `chezmoi apply`. Completions regenerate automatically, but check which of the three shapes the tool needs first:
   - Ships its own `_<tool>` into Homebrew's `share/zsh/site-functions`. Nothing to do, and [`run_onchange_after_z-generate-completions.sh.tmpl`](run_onchange_after_z-generate-completions.sh.tmpl) deliberately skips generating a rival copy, since Homebrew's tracks the installed formula version.
   - Has a `<tool> completion zsh` subcommand but no site-functions. Add a `generate_completion` line. Output goes to `~/.zsh/completions/` and is autoloaded lazily, so it costs nothing at shell startup.
   - Is bash-style (`complete -C` / `complete -F`, as with aws and npm) or otherwise needs `compdef`. It has to be appended to `~/.zsh/completions-post.zsh` instead, which `~/.zshrc` sources after `compinit`. A file placed in `fpath` without a leading `#compdef` line is never bound to any command and silently completes nothing.

### Adding a new dotfile

1. Create or edit the file in your home directory
2. Run `chezmoi add <file>` to start tracking it
3. Use `dot_` prefix naming, `private_` for sensitive files, `.tmpl` for templates
4. Platform-specific blocks use `{{ if eq .chezmoi.os "darwin" }}...{{ end }}`

## Configuration

### Work pack

Company-specific setup lives in an optional **work pack**: a folder of plain files, usually a company git repo shareable with teammates whether or not they use these dotfiles. On a work machine `chezmoi init` asks for `work_pack`, which can be:

| `work_pack` | Folder the hooks read | Fetching |
| ----------- | --------------------- | -------- |
| empty | `~/.config/work/` (create it by hand, or leave it absent) | none |
| a git URL | `~/.config/work/` | cloned on apply, then fast-forwarded at most daily by [`run_after_sync-work-pack.sh.tmpl`](run_after_sync-work-pack.sh.tmpl) |
| a local folder (`/path` or `~/path`) | that folder, in place | none |

Fetching never fails the apply: an unreachable or private repo (common on a new laptop before `dotfiles identity` adds its SSH key), a missing folder, or a non-git folder in the way only prints a warning with the next step. Only the setting is stored, in your local `chezmoi.toml`; nothing from the pack is tracked here. To start one, copy the [`work-pack/`](work-pack/) template into a new company repo; its README has the steps.

Every file is optional, and each hook is a no-op when its file is missing:

| File | Loaded by |
| ---- | --------- |
| `env.zsh` | `~/.zshenv` (all shells, including agent tool calls) |
| `gitconfig` | `[include]` in `~/.gitconfig` (company URL rewrites, extra settings) |
| `ssh_config` | `Include` at the top of `~/.ssh/config` |
| `Brewfile` | appended to the Brewfile at install time; excludes and failure reporting apply |
| `AGENTS.md` | appended to the global Claude Code, Codex, and OpenCode instructions on the next `chezmoi apply` |

A work machine also defaults git to the work email, skips personal apps (Obsidian) and secrets tooling, and leaves Codex on the default service tier.

**One identity per machine.** A work machine only pulls this repo (it is public, so no GitHub account is needed for that); edits happen on a personal machine. A work machine is asked for its work email and the **work GitHub account** it pushes as, signs with `work_signing_key`, and carries no personal email, key, or account. With no work key, work commits go unsigned rather than borrowing a personal one. `chezmoi init` finds each GPG key by its email, and the key stays in your local `chezmoi.toml`, never in the shared work pack.

#### Setting up a machine's GitHub identity

One command, run on the machine itself, safe to re-run:

```bash
dotfiles identity            # add --dry-run to see what it would do first
dotfiles identity --account urmzd-fwai   # change which GitHub account this machine pushes as
```

It reads the account and email from your chezmoi config (the work account and work email on a work laptop), then:

| Step | What happens | Skipped when |
| ---- | ------------ | ------------ |
| gh | signs in as that account in the browser (or switches to it), adds the `write:gpg_key`, `admin:public_key`, `user:email` scopes | already signed in with those scopes |
| SSH | creates `~/.ssh/github` (what `~/.ssh/config` uses for github.com) and uploads it | the key exists and GitHub has it |
| GPG | creates an ed25519 signing key for the email and uploads it | a usable key exists and GitHub has it |
| Email | warns if the email is not verified on the account (commits would show as unverified) | verified |
| Save | writes the key to `work_signing_key` / `gpg_signing_key` and re-applies `~/.gitconfig` | already saved |
| Check | makes a signed throwaway commit and requires "Good signature" | |

Passphrases are asked by `ssh-keygen` and by `pinentry-mac`'s dialog (managed on macOS, so signing also works from editors and agent sessions; tick "Save in Keychain"). `chezmoi init` also finds an existing key by its email, so creating one by hand works too: `gpg --quick-gen-key "Name <email>" ed25519 sign 2y`, then `gpg --armor --export <email> | gh gpg-key add -`.

### Chezmoi automation

These scripts run automatically on `chezmoi apply`. The bootstrap and every `dotfiles` command apply with `--keep-going`: a failing step no longer skips the steps after it, failures are listed at the end, and a failed one-time script is retried on the next apply. Run plain `chezmoi apply` as `chezmoi apply --keep-going` for the same behavior.

| Script | Type | Trigger |
| ------ | ---- | ------- |
| `install-packages-v2` | run_once (before) | First apply (installs Homebrew + bootstrap Linux packages) |
| `brewfile-install` | run_onchange (after) | Brewfile, `catalog.toml`, the `packages` selection, `pkg_exclude`, or the work pack Brewfile changes |
| `install-cloud-clis` | run_onchange (after) | Script changes (re-pin gcloud/aws version) |
| `install-cortex` | run_onchange (after) | Script changes (gated on `install_cortex` flag) |
| `install-gh-extensions` | run (after) | Every apply; silent once installed. Waits for `gh` sign-in (`dotfiles identity`) instead of failing |
| `install-catalog-linux` | run_onchange (after) | Linux only: the `packages` selection or `catalog.toml` changes |
| `generate-completions` | run_onchange (after) | zshrc, Brewfile, or cloud-clis script changes |
| `setup-node` | run (after) | Every apply; silent unless it installs Node LTS (fnm) or runs a one-time npm migration |
| `install-catalog-scripts` | run (after) | Every apply; installs selected installer-based packages (Claude Code, agy, OpenCode) that are missing |
| `install-python` | run (before) | every apply, silent once linked; installs the default Python with uv |
| `install-skills` | run_once (after) | First apply only (bootstraps `agentspec`, syncs skills to `~/.agents/skills/`) |
| `sync-agent-resources` | run (after) | Every apply (keeps new local skills and agents managed by `agentspec`) |
| `install-stack` | run_once (after) | First apply only (installs `sr`, `teasr`, `oag`, and the `dotfiles` CLI) |
| `configure-terminal` | run_once (after) | First apply only |
| `load-docker-cleanup` | run_once (after) | First apply only |

Every script prints through [`.chezmoitemplates/ui.sh`](.chezmoitemplates/ui.sh): one `==>` header per script, quiet when nothing changed, and a next step under every warning or failure.

### CI and releases

| Workflow | Runs on | What it does |
| -------- | ------- | ------------ |
| [`ci.yml`](.github/workflows/ci.yml) | pull requests, and before every release | [`.github/scripts/check.sh`](.github/scripts/check.sh) renders the full source state for a personal and a work machine on macOS and Linux, then runs the shell gate ([`lint-shell.sh`](.github/scripts/lint-shell.sh)): every script parses under the shell that runs it, with macOS's bash 3.2 as the floor, no bash-4-only constructs, and every `modify_` merge script produces valid, key-preserving output under 3.2; `cli/` gets rustfmt, clippy, and tests |
| [`release.yml`](.github/workflows/release.yml) | push to `main` | After CI passes, [sr](https://github.com/urmzd/sr) tags the release, bumps `cli/Cargo.toml`, and updates `CHANGELOG.md` from conventional commits; a build matrix then attaches `dotfiles-<target>` binaries and `.sha256` files to the release |

Run the same checks locally before pushing: `.github/scripts/check.sh`, plus `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, and `cargo test` in `cli/`. Release secrets are managed in `urmzd/infra`.

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
| Antigravity CLI (agy) | `dot_gemini/` | Legacy Gemini CLI settings kept as agy first-run migration seed; agy config lives in `~/.gemini/antigravity-cli/` (authored in-app via `/config` and `/permissions`) |
| GitHub Copilot | `dot_copilot/` | `settings.json` with model, `xhigh` effort, theme |
| OpenCode | `dot_config/opencode/` | Shared instructions; agentspec renders agents into `~/.config/opencode/agents/` with inherited models and provider-specific overrides |

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
| [github/gh-stack](https://github.com/github/gh-stack) | gh-stack |

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
| review-diff | Review staged, unstaged, and untracked changes using the assess-quality and review-design rubric |
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
| dotfiles | Chezmoi naming, templating, and agentspec resource management conventions |
| sync-release | End-to-end release pipeline (sr.yaml, CI, multi-platform builds) |
| repo-init | Full repo bootstrap (create, license, scaffold, push) |
| community-health | GitHub Community Standards (CODE_OF_CONDUCT, SECURITY, ISSUE_TEMPLATE) with `$COMMUNITY_HEALTH_CONTACT` |

#### Workflow automation

| Skill | Purpose |
| ----- | ------- |
| ship | Generate a conventional commit, then optionally push and watch CI until pass/fail |
| pr | Create PRs with auto-generated summary from commits |
| merge-ready | Drive an existing PR or MR to a mergeable state without merging it |
| diagnose-ci | Find failing remote CI pipelines, pull logs, identify root cause (local sibling: diagnose-runtime) |
| diagnose-runtime | Triage local runtime errors, hangs, slowness, and hardware/serial issues (the local counterpart to diagnose-ci) |
| triage-dotfiles-env | Playbook of known dotfiles-stack failure modes (pipx shims, gpg signing, nix shellHook, P10k, nvim Lua APIs) with mandatory verification |
| fix-and-retry | Diagnose CI failure, apply fix, commit, push, re-run |
| repo-status | Scan a folder of git repos and report recent activity, branch divergence, and uncommitted state (renamed from `status`) |
| release-audit | Audit releases, tags, and assets for health |
| sync-ecosystem | Audit one repository against ecosystem conventions and emit a drift report |
| sync-ecosystem-to-chezmoi | Apply a sync-ecosystem drift report back into the chezmoi source tree |
| update-repo-meta | Update GitHub repo topics, description, homepage |
| manage-secrets | 1Password-based secret workflow (vault layout, `1p://` references, `op run`) |
| orchestrate-agents | Survey-first orchestration of agent CLIs (Claude, Codex, Antigravity) over tmux: adopt and extend existing sessions, spawn only what is missing |
| use-worktrees | Create, enter, and clean up git worktrees under the standard `.worktrees/<name>` layout |

#### AI & documentation

`create-oss-skill` owns the base spec; `extend-oss-skills-to-claude` is a sequel covering only the Claude-specific deltas.

| Skill | Purpose |
| ----- | ------- |
| agent-design-doctrine | House doctrine for LLM agent systems: safety in the harness, tools return results, minimal loop code, deterministic evals, POC scope discipline |
| clean-docs | Slash-invocable documentation cleanup: no em dashes, current facts, readable formatting, user-focused guidance |
| configure-ai | AI tooling configuration, AGENTS.md, skills standard |
| create-llms-txt | Generate llms.txt files |
| create-oss-skill | Create portable agent skills (canonical spec) |
| extend-oss-skills-to-claude | Claude-specific skill deltas (invocation control, subagent execution, model overrides) |
| audit-security | Security auditing and threat detection |
| run-eval-harness | Run a project's eval suite end to end: launch, monitor, parse the report, diff against the previous run (forks to a sonnet subagent) |
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
