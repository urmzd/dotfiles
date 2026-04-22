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
log "Installing chezmoi and applying dotfiles from github.com/${GITHUB_USER}/dotfiles..."
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply "$GITHUB_USER"

log "Done. Open a new terminal to pick up the new shell config."
