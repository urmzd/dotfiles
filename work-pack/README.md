# Work pack template

A starting point for a company **work pack**: a small git repo of plain files that [urmzd/dotfiles](https://github.com/urmzd/dotfiles) loads from `~/.config/work/` on a work machine. Nothing here is specific to these dotfiles, so teammates can use the same repo with their own setup (source `env.zsh`, include `gitconfig`, and so on).

## Use it

```bash
cp -R work-pack ~/work-pack && cd ~/work-pack && rm README.md
git init && git add -A && git commit -m "feat: initial work pack"
gh repo create <company>/dev-setup --private --source . --push
```

Then on the work machine, give `chezmoi init` the repo URL when it asks for the work pack (or set `work_pack` in `~/.config/chezmoi/chezmoi.toml` and run `chezmoi apply`). It is cloned to `~/.config/work/` and fast-forwarded at most once a day. A clone that fails (for example a private repo before the machine's SSH key is on GitHub; run `dotfiles identity`) only warns; the next apply retries.

No repo? Set `work_pack` to a local folder (`~/acme-pack`) to use it in place, or leave it empty and put the files in `~/.config/work/` by hand.

## Files

Every file is optional; delete the ones you do not need. Each is a no-op until it has content.

| File | Loaded by | For |
|---|---|---|
| `env.zsh` | `~/.zshenv` (every shell, including agent tool calls) | proxies, registries, PATH, company env |
| `gitconfig` | `[include]` in `~/.gitconfig` | URL rewrites, company git settings |
| `ssh_config` | `Include` at the top of `~/.ssh/config` | bastions, internal hosts |
| `Brewfile` | appended to the dotfiles Brewfile at install time | VPN client, internal CLIs |
| `catalog.toml` | merged into the `dotfiles package` picker | internal tools people opt into, or `required = true` for everyone, with installer scripts, sign-in steps, and checks |
| `AGENTS.md` | appended to Claude Code, Codex, and OpenCode global instructions | company rules for AI coding tools |

Keep secrets out: no tokens or keys in any of these files. Personal signing keys belong in each person's local `chezmoi.toml`, never here.
