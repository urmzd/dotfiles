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

for machine in personal work; do
    echo "==> $machine"
    cfg="$work/$machine.toml"
    # --config points at an empty file so init never reuses a real local config.
    chezmoi init --config "$work/empty.toml" --source "$src" --config-path "$cfg" \
        --persistent-state "$work/$machine.boltdb" \
        --no-tty --promptDefaults --promptChoice "Machine type=$machine" \
        --promptString "Personal email (commits in this repo and ~/personal)=ci@example.com"

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
done
