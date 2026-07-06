#!/usr/bin/env bash
# One-shot bootstrap for this dotfiles repo.
# Idempotent: re-running is safe — each step is gated on whether the tool is already installed.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/install.sh | bash
#   # or, with a specific GitHub username:
#   curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/install.sh | bash -s -- <github-user>

set -euo pipefail

GITHUB_USER="${1:-urmzd}"

log() { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }

# ---- 1. Homebrew (macOS only) ---------------------------------------------
if [[ "$(uname -s)" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log "Homebrew already installed."
    fi

    # Ensure brew is on PATH for the rest of this script.
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# ---- 2. chezmoi + apply (single shot via chezmoi's own installer) ---------
# Install the chezmoi binary somewhere stable instead of ./bin in a random cwd;
# the Brewfile later installs the brew-managed copy, which takes over on PATH.
CHEZMOI_BIN_DIR="${HOME}/.local/bin"
mkdir -p "$CHEZMOI_BIN_DIR"

log "Installing chezmoi and applying dotfiles from github.com/${GITHUB_USER}/dotfiles..."
# When this script is piped (curl | bash), stdin is the script itself, so
# chezmoi's first-run prompts would read garbage. Reattach stdin to the
# terminal when one exists; otherwise run headless (promptOnce values are
# skipped anyway once a config exists).
if [ -t 0 ]; then
    sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$CHEZMOI_BIN_DIR" init --apply "$GITHUB_USER"
elif { exec 3</dev/tty; } 2>/dev/null; then
    exec 3<&-
    sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$CHEZMOI_BIN_DIR" init --apply "$GITHUB_USER" </dev/tty
else
    log "No TTY detected; running non-interactively."
    sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$CHEZMOI_BIN_DIR" init --apply "$GITHUB_USER"
fi

log "Done. Open a new terminal to pick up the new shell config."
