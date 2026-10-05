# dotfiles CLI

`dotfiles` manages a machine set up from this repo: pick optional packages with a search-as-you-type list, run their sign-in setup, apply, and update. It lives here, next to the `catalog.toml` and `Brewfile.tmpl` it drives, and ships as binaries attached to every [release](https://github.com/urmzd/dotfiles/releases).

## Install

The first `chezmoi apply` installs it. By hand:

```bash
curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/cli/install.sh | sh
```

The installer downloads the binary for your platform from the newest release that has one (the latest can still be building, or its build can have failed) and verifies it against that release's `.sha256` file. If no binary can be downloaded (no release yet, GitHub down), it builds `cli/` from the dotfiles checkout with cargo. A pinned `DOTFILES_VERSION` never falls back, and a checksum mismatch always stops. `DOTFILES_VERSION` pins a release, `DOTFILES_INSTALL_DIR` changes the target (default `~/.local/bin`), and `DOTFILES_SHA256` overrides the expected checksum. `dotfiles self-update` uses the same assets and checksums.

## Usage

```bash
dotfiles packages            # search + toggle optional packages, then apply
dotfiles add acli twg        # select by id (no ids: pick from the unselected)
dotfiles remove cursor       # deselect (--uninstall also brew-uninstalls it)
dotfiles list --selected     # catalog with the current selection
dotfiles setup               # pending sign-in/installers, e.g. acli auth, twg
dotfiles identity            # gh sign-in, SSH + GPG keys created and uploaded, signing verified
dotfiles apply               # show pending changes, confirm, apply
dotfiles update [all|packages|ai]
dotfiles status              # machine, packages, pending setup, tool versions
dotfiles doctor              # chezmoi doctor + catalog/selection checks
dotfiles config              # re-run the setup questions, keep saved answers
dotfiles self-update
```

Global flags: `--format json|human` for data commands, `--dry-run` to show changes without writing. Exit codes: `0` ok, `1` error, `2` nothing changed, `130` cancelled.

## How it works

| Piece | Lives in | Role |
|---|---|---|
| Catalog | [`catalog.toml`](../catalog.toml) | Every optional package: Homebrew taps, formulae, casks, setup commands, preset defaults |
| Selection | `[data].packages` in `~/.config/chezmoi/chezmoi.toml` | Catalog ids chosen on this machine; local, never committed |
| Install | [`Brewfile.tmpl`](../Brewfile.tmpl) | Renders the selected packages; `chezmoi apply` runs `brew bundle` |
| Setup | `setup` and `check` in the catalog | Interactive steps (browser sign-in, TTY installers) that never run during apply |

To offer a new package, add a `[[package]]` entry to `catalog.toml`; no CLI change is needed. `DOTFILES_SOURCE` and `DOTFILES_CHEZMOI_CONFIG` override the chezmoi source directory and config file.

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

Rules: human output goes to stderr through `ui`, stdout is only `--format json` data; package data belongs in `catalog.toml`, not in code; interactive setup never runs during `chezmoi apply`; `update` is taken by content updates, so self-update is `self-update`. Not published to crates.io (`publish = false`): it only works with this repo.
