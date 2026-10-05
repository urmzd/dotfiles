---
name: manage-machine
description: >
  Operate a machine set up by urmzd/dotfiles through its `dotfiles` CLI:
  install or remove optional tools from the package catalog, diagnose a broken
  setup with `dotfiles doctor`, update the CLI, dotfiles, or packages, and add
  company tools to a work pack's catalog.toml. Use when the user says "install
  linear", "remove discord", "what can I install", "why is python broken",
  "update everything", "add our VPN for everyone at work", or "is this machine
  healthy". Do NOT use for editing the chezmoi source repo itself (templates,
  run_ scripts, naming; use dotfiles), for a project's own toolchain or .envrc
  (use setup-devenv), or for a known shell/nvim/gpg error signature (use
  triage-dotfiles-env).
allowed-tools: Read, Edit, Write, Bash(dotfiles *), Bash(command -v *), Bash(chezmoi source-path), Bash(chezmoi data *), Bash(git -C *)
---

# Manage a machine with the dotfiles CLI

Every action goes through `dotfiles`; it saves the selection to the local
chezmoi config and applies it. Never hand-edit `~/.config/chezmoi/chezmoi.toml`
or deployed files, and never run Homebrew or installers directly for catalog
packages: the next apply would not know about them.

Check the CLI first: `command -v dotfiles`. If missing, tell the user to run
`curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/cli/install.sh | sh`.

## Read before acting

| Need | Command |
|---|---|
| What is installable, and what is selected | `dotfiles package list --format json` (fields: id, name, category, selected, installs, setup, work_pack, required) |
| Machine health with fixes | `dotfiles doctor --format json` (fields: check, level ok/warn/fail, detail, fix) |
| Machine type, versions, selection | `dotfiles status` |
| Desired vs installed (missing, deselected, migrations, files) | `dotfiles plan --format json` (exit 2 = nothing to do) |
| Full file diff | `dotfiles diff` |

## Do

| Request | Run |
|---|---|
| Install a catalog tool | `dotfiles package add <id>...` (applies; resolve names to ids from the list) |
| Remove one | `dotfiles package remove <id>...` (add `--uninstall` only if the user wants the software gone, not just deselected) |
| Fix what doctor reports | run each finding's `fix`, then rerun `dotfiles doctor` |
| A selected tool is missing | `dotfiles plan`, then `dotfiles apply --yes` (installs are retried every apply; nothing is ever marked done) |
| Update everything | `dotfiles update` (CLI, then pull dotfiles and apply) |
| Update installed packages | `dotfiles package update` (`brew` or `ai` to narrow) |
| Make the machine match the plan | `dotfiles apply --yes` |
| Also uninstall deselected packages | `dotfiles apply --yes --prune` (only ones the CLI installed; confirm with the user first) |

Exit code 2 means nothing changed, not failure.

## Hand to the user (interactive)

These need a TTY, a browser, or a password. Do not run them; print the exact
command and say why:

- `dotfiles package setup [<id>]`: sign-ins listed in a package's `setup`
- `dotfiles identity`: GitHub login, SSH and GPG keys
- `dotfiles config`: re-asks the setup questions
- `dotfiles package` with no arguments: the interactive picker

## A tool that is not in the catalog

- **Personal, or useful to anyone:** add a `[[package]]` entry to
  `catalog.toml` in the source repo (`chezmoi source-path`), following the
  entries around it, then `dotfiles package add <id>`. That edits the repo, so
  the `dotfiles` skill's conventions apply.
- **Company-specific:** add it to the work pack's `catalog.toml` (folder:
  `work_pack` in `chezmoi data`, default `~/.config/work`), never to this
  repo. Same format. `required = true` installs it for everyone on the pack;
  leave it off to make it opt-in. Then run `dotfiles doctor`: it reports a bad
  file (ids must be new; id, name, description, category are required). If the
  pack is a git repo, commit and push there so teammates get it.

Entry fields: `brew`/`cask`/`tap` (macOS), `apt`/`dnf`/`pacman` (Linux),
`npm`, `uv`, or `script` (installer URL) with `check` (shell test that passes
once installed); `setup` for sign-in commands.

```toml
[[package]]
id = "internal-cli"
name = "internal-cli"
description = "Deploys and logs from the terminal"
category = "work"
script = "https://tools.example.com/internal-cli/install.sh"
check = "command -v internal-cli"
setup = ["internal-cli login"]
```

## Gotchas

- A new shell is needed after PATH changes (`exec zsh`); an old terminal can
  report a stale Python or a missing command after a successful apply.
- Work pack catalog changes reach templates on the apply after they are
  validated; `dotfiles package add` validates first, so it installs right away.
- Required work pack packages cannot be removed with `dotfiles package remove`;
  change the pack.
