# dotfiles CLI

`dotfiles` manages a machine set up from this repo: pick optional packages with a search-as-you-type list, run their sign-in setup, apply, and update. It lives here, next to the `catalog.toml` and `Brewfile.tmpl` it drives, and ships as binaries attached to every [release](https://github.com/urmzd/dotfiles/releases).

## Install

The first `chezmoi apply` installs it. By hand:

```bash
curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/cli/install.sh | sh
```

The installer downloads the binary for your platform from the newest release that has one (the latest can still be building, or its build can have failed) and verifies it against that release's `.sha256` file. If no binary can be downloaded (no release yet, GitHub down), it builds `cli/` from the dotfiles checkout with cargo. A pinned `DOTFILES_VERSION` never falls back, and a checksum mismatch always stops. `DOTFILES_VERSION` pins a release, `DOTFILES_INSTALL_DIR` changes the target (default `~/.local/bin`), and `DOTFILES_SHA256` overrides the expected checksum. `dotfiles update` and `dotfiles self-update` use the same assets and checksums.

## Usage

```bash
dotfiles package                     # search + toggle optional packages, then apply
dotfiles package add acli twg        # select by id (no ids: pick from the unselected)
dotfiles package remove cursor       # deselect (--uninstall also brew-uninstalls it)
dotfiles package list --selected     # catalog with the current selection
dotfiles package setup               # pending sign-in/installers, e.g. acli auth, twg
dotfiles package update [all|brew|ai]
dotfiles identity                    # gh sign-in, SSH + GPG keys created and uploaded, signing verified
dotfiles identity --account <name>   # change the GitHub account this machine pushes as
dotfiles doctor                      # health check; every finding comes with its fix
dotfiles plan [--prune]              # desired vs installed: migrations, files, packages
dotfiles apply [--prune] [-y]        # make the machine match the plan
dotfiles status                      # machine, packages, pending setup, tool versions
dotfiles config                      # re-run the setup questions, keep saved answers
dotfiles update                      # update the CLI, pull the dotfiles, then apply
dotfiles self-update                 # update only this CLI
```

The old forms (`dotfiles packages`, `add`, `remove`, `list`, `setup`) still work as hidden aliases; `dotfiles update ai` now points at `dotfiles package update ai`.

Global flags: `--format json|human` for data commands, `--dry-run` to show changes without writing. Exit codes: `0` ok, `1` error, `2` nothing changed, `130` cancelled.

## How it works

| Piece | Lives in | Role |
|---|---|---|
| Catalog | [`catalog.toml`](../catalog.toml) | Every optional package: Homebrew taps, formulae, casks, setup commands, preset defaults |
| Selection | `[data].packages` in `~/.config/chezmoi/chezmoi.toml` | Catalog ids chosen on this machine; local, never committed |
| Install | [`Brewfile.tmpl`](../Brewfile.tmpl) | Renders the selected packages; `chezmoi apply` runs `brew bundle` |
| Setup | `setup` and `check` in the catalog | Interactive steps (browser sign-in, TTY installers) that never run during apply |
| Plan | [`src/state.rs`](src/state.rs) | Desired (selection + required work entries) vs observed (probed each run); installs what is missing, `--prune` removes deselected packages it owns (`~/.local/state/dotfiles/managed.json`) |
| Migrations | [`src/migrate.rs`](src/migrate.rs) | Selection changes shipped in a release, applied on the next `apply`/`update`; each decides from the config whether it already ran |

To offer a new package, add a `[[package]]` entry to `catalog.toml`; no CLI change is needed. A work pack can carry its own `catalog.toml` in the same format: its entries join the picker, `required = true` ones install without being picked (and cannot be removed), and the templates read a validated copy at `~/.local/share/dotfiles/work-catalog.toml`, so a broken company file is reported, never fatal. `DOTFILES_SOURCE` and `DOTFILES_CHEZMOI_CONFIG` override the chezmoi source directory and config file.

## Development

```bash
cd cli
cargo build
cargo test
cargo clippy --all-targets -- -D warnings
cargo fmt --all -- --check
```

| File | Role |
|---|---|
| `src/main.rs` | clap definitions, exit codes |
| `src/commands.rs` | one function per subcommand |
| `src/catalog.rs` | `catalog.toml` schema |
| `src/chezmoi.rs` | paths, running chezmoi, selection edits via `toml_edit` |
| `src/ui.rs` | human output; mirrors [`.chezmoitemplates/ui.sh`](../.chezmoitemplates/ui.sh) |

Rules: human output goes to stderr through `ui`, stdout is only `--format json` data; package data belongs in `catalog.toml`, not in code; interactive setup never runs during `chezmoi apply`; `update` updates the CLI plus the dotfiles; `self-update` is the binary alone. Not published to crates.io (`publish = false`): it only works with this repo.
