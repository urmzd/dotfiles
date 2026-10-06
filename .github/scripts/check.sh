#!/usr/bin/env bash
# Render the whole source state for each machine type without touching $HOME,
# then syntax-check every rendered run_ script. Catches template errors (bad
# keys, catalog.toml typos, missingkey=error) before they reach a machine.
#
# Usage: .github/scripts/check.sh            (from the repo root)
set -euo pipefail

src="$(cd "$(dirname "$0")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
: > "$work/empty.toml"

# Parse with the oldest bash a script can meet: macOS's /bin/bash 3.2 runs
# every `env bash` script on a fresh Mac before Homebrew installs bash 5.
shell=bash
[ "$(uname -s)" = Darwin ] && shell=/bin/bash

# Render with the floor shell too: put a `bash` that is /bin/bash first on PATH
# (what `#!/usr/bin/env bash` finds on a fresh Mac) and disable the switch to a
# newer bash, so modify_ scripts run under 3.2 during the render.
export DOTFILES_BASH_FLOOR=1
if [ "$(uname -s)" = Darwin ]; then
    mkdir -p "$work/floor-bin"
    ln -sf /bin/bash "$work/floor-bin/bash"
    export PATH="$work/floor-bin:$PATH"
fi

for machine in personal work; do
    echo "==> $machine"
    cfg="$work/$machine.toml"
    # --config points at an empty file so init never reuses a real local config.
    chezmoi init --config "$work/empty.toml" --source "$src" --config-path "$cfg" \
        --persistent-state "$work/$machine.boltdb" \
        --no-tty --promptDefaults --promptChoice "Machine type=$machine" \
        --promptString "Email for git commits=ci@example.com" \
        --promptString "Work email for git commits=ci@work.example.com" \
        --promptString "Work GitHub username (the account this machine pushes as)=ci-work"

    common=(--config "$cfg" --source "$src" --destination "$work/home-$machine"
            --persistent-state "$work/$machine.boltdb" --no-tty)

    # Render every target (files, templates, modify_ scripts, run_ scripts).
    chezmoi "${common[@]}" archive --format tar --output "$work/$machine.tar"
    echo "  ✓ rendered $(tar -tf "$work/$machine.tar" | wc -l | tr -d ' ') targets"

    # Syntax-check the rendered run_ scripts (archive ignores --include, so
    # pick the script entries out of the full archive by name).
    mkdir -p "$work/$machine-files"
    tar -xf "$work/$machine.tar" -C "$work/$machine-files"
    count=0
    while IFS= read -r script; do
        "$shell" -n "$work/$machine-files/$script"
        count=$((count + 1))
    done < <(chezmoi "${common[@]}" managed --include scripts)
    echo "  ✓ $count scripts parse"

    "$src/.github/scripts/lint-shell.sh" "$cfg"
done

# Packs: render once more with a stacked list (a repo folder, a whole repo,
# and a local folder), so every pack loop in the templates is exercised.
echo "==> work + packs"
packs='{"packs":["git@github.com:acme/dev-setup.git//backend-engineer","https://github.com/acme/team.git","~/my-overrides"]}'
chezmoi --config "$work/work.toml" --source "$src" --destination "$work/home-packs" \
    --persistent-state "$work/work.boltdb" --no-tty --override-data "$packs" \
    archive --format tar --output "$work/packs.tar"
tar -xOf "$work/packs.tar" ./.gitconfig 2>/dev/null | grep -q 'packs/dev-setup/backend-engineer/gitconfig' ||
    tar -xOf "$work/packs.tar" .gitconfig | grep -q 'packs/dev-setup/backend-engineer/gitconfig'
echo "  ✓ rendered with 3 packs"

# Themes: render every built-in theme, so a theme file that breaks a template
# (Ghostty, tmux, Neovim, ui.sh) fails here instead of on a machine.
echo "==> themes"
for theme_file in "$src"/themes/*.toml; do
    theme="$(basename "$theme_file" .toml)"
    chezmoi --config "$work/personal.toml" --source "$src" --destination "$work/home-theme" \
        --persistent-state "$work/personal.boltdb" --no-tty --override-data "{\"theme\":\"$theme\"}" \
        archive --format tar --output "$work/theme.tar"
    tar -xOf "$work/theme.tar" .config/dotfiles/theme.toml 2>/dev/null | grep -q "name = \"$theme\"" ||
        tar -xOf "$work/theme.tar" ./.config/dotfiles/theme.toml | grep -q "name = \"$theme\""
    echo "  ✓ $theme renders"
done
