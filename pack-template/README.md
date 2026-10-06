# Pack template

A starting point for a **pack**: a folder of plain files (env, git and SSH config, Homebrew packages, a package catalog, AI agent rules) that [urmzd/dotfiles](https://github.com/urmzd/dotfiles) layers onto a machine. A machine stacks any number of packs in order, for example a company pack, then a team or role pack, then personal overrides. Nothing here is specific to these dotfiles, so teammates can use the same files with their own setup (source `env.zsh`, include `gitconfig`, and so on).

## One repo, many roles

A company repo can hold one folder per role; people pick the folders that fit them:

```text
dev-setup/
├── base/              # everyone: VPN, proxies, git URL rewrites
├── engineer/          # all engineers: internal CLI, registries
├── backend-engineer/  # backend: databases, cloud tools
└── frontend-engineer/
```

Copy this template into each folder and keep the files that role needs. Then on a machine:

```bash
dotfiles pack add git@github.com:acme/dev-setup.git//base \
                  git@github.com:acme/dev-setup.git//engineer \
                  git@github.com:acme/dev-setup.git//backend-engineer
dotfiles pack list
```

`<url>//<folder>` (Terraform's module syntax) reads one folder of a repo; the repo is cloned once to `~/.config/packs/<repo>` and fast-forwarded at most daily. A plain git URL makes the whole repo one pack, and a local folder (`~/my-overrides`) is used in place. `chezmoi init` also asks for the list on a work machine.

## Create the repo

```bash
cp -R pack-template ~/dev-setup/base && rm ~/dev-setup/base/README.md
cd ~/dev-setup && git init && git add -A && git commit -m "feat: initial pack"
gh repo create <company>/dev-setup --private --source . --push
```

A clone that fails (for example a private repo before the machine's SSH key is on GitHub; run `dotfiles identity`) only warns; the next apply retries.

## How packs stack

| File | Loaded by | With several packs |
|---|---|---|
| `env.zsh` | `~/.zshenv` (every shell, including agent tool calls) | sourced in order; later packs override earlier ones |
| `gitconfig` | `[include]` in `~/.gitconfig` | one include per pack, in order; later settings win |
| `ssh_config` | `Include` at the top of `~/.ssh/config` | one Include per pack, in order |
| `Brewfile` | appended to the dotfiles Brewfile at install time | all appended |
| `catalog.toml` | merged into the `dotfiles package` picker | merged; an id already taken (dotfiles catalog or an earlier pack) is skipped and reported by `dotfiles doctor` |
| `AGENTS.md` | appended to Claude Code, Codex, and OpenCode global instructions | concatenated, one block per pack |
| `theme.toml` | the color theme for Ghostty, Neovim, tmux, and dotfiles output ([format](../themes/README.md)) | the last pack with a theme applies when the machine sets none; any pack theme can be picked by name |

Every file is optional; delete the ones a pack does not need. Each is a no-op until it has content. In `catalog.toml`, `required = true` installs a package for everyone on that pack; without it, people opt in with `dotfiles package add <id>`.

Keep secrets out: no tokens or keys in any of these files. Personal signing keys belong in each person's local `chezmoi.toml`, never here.
