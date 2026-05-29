---
name: setup-devenv-with-chezmoi
description: >
  Chezmoi-specific dev environment helpers: pinned-version installer scripts
  (run_onchange_after_install-<tool>.sh.tmpl) and the dot_envrc.project.example
  template tracked in the chezmoi source. Use when wiring a new pinned installer
  for the portfolio or scaffolding a chezmoi-tracked project envrc. Portable
  per-language patterns live in setup-devenv.
allowed-tools: Read Grep Glob Bash Edit Write
user-invocable: false
metadata:
  title: Dev Env with Chezmoi
  category: cli
  order: 1
---

# Dev Env with Chezmoi

Personal-portfolio extensions to `setup-devenv`. This skill assumes a chezmoi-managed home directory and stays focused on the chezmoi-specific plumbing the portable skill deliberately omits.

## When to Use

- Adding a pinned-version installer for a tool that ships only via a vendor script (gcloud, aws-cli, Snowflake Cortex, etc.).
- Updating the canonical `dot_envrc.project.example` template that new projects copy.
- Standardizing how `~/.local/bin` is wired up across projects.

If you're not on chezmoi, use `setup-devenv` directly. Substitute Brewfile / Nix / your own dotfile manager.

## Pinned Installer Pattern

```
~/.local/share/chezmoi/run_onchange_after_install-<tool>.sh.tmpl
```

Skeleton:

```sh
#!/usr/bin/env bash
set -euo pipefail

<TOOL>_VERSION="<pin>"
INSTALL_DIR="$HOME/.local/share/<tool>/${<TOOL>_VERSION}"
BIN_LINK="$HOME/.local/bin/<tool>"

if [ -x "${INSTALL_DIR}/bin/<tool>" ]; then
  exit 0
fi

mkdir -p "${INSTALL_DIR}"
curl -fsSL "<download-url>" -o "${INSTALL_DIR}/<tool>"
chmod +x "${INSTALL_DIR}/<tool>"

ln -sf "${INSTALL_DIR}/<tool>" "${BIN_LINK}"
```

Conventions:

- **Pin the version at the top in ALL_CAPS.** Bumping is a one-line diff.
- **Install to `~/.local/share/<tool>/<version>/`.** Versioned subdirs let you roll back without re-downloading.
- **Symlink into `~/.local/bin/<tool>`.** Keeps `$PATH` stable.
- **Mirror the structure of existing scripts** like `run_onchange_after_install-cloud-clis.sh.tmpl` or `run_onchange_after_install-cortex.sh.tmpl`. Consistency makes the directory scannable.

## Project envrc Template

The canonical project envrc lives at:

```
~/.local/share/chezmoi/dot_envrc.project.example
```

When a new project needs `.envrc`, copy this file into the project root, strip the per-language idioms that don't apply, and `direnv allow`. The portable patterns the file demonstrates (`layout python`, `use fnm`, `PATH_add bin`, `dotenv`, `source_up`) are documented in `setup-devenv`; this skill owns the file itself.

## Apply Loop

After editing any of the above:

```sh
chezmoi diff
chezmoi apply
```

Run `chezmoi diff` first so you can confirm the rendered output matches expectations before overwriting the home directory.

## Gotchas

- **Don't run installers eagerly.** `run_onchange_after_install-*.sh.tmpl` re-runs only when its content changes. If the version pin doesn't change, chezmoi will skip it; this is intentional.
- **No secrets in templates.** Use `manage-secrets` (1Password) or `.env` references. Templated installer scripts end up in git history.
- **Version subdirs over `latest` symlinks.** A `latest` symlink obscures which version a script actually saw.
