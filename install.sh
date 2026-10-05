#!/usr/bin/env bash
# One-shot bootstrap for this dotfiles repo.
# Idempotent: re-running is safe. Each step is gated on whether the tool is already installed.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/install.sh | bash
#   # or, with a specific GitHub username:
#   curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/install.sh | bash -s -- <github-user>

set -euo pipefail

GITHUB_USER="${1:-urmzd}"

# Same output vocabulary as .chezmoitemplates/ui.sh (inlined: this file is
# fetched alone with curl, before the repo exists locally).
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    _c=$'\033[36m'; _g=$'\033[32m'; _b=$'\033[1m'; _d=$'\033[2m'; _o=$'\033[0m'
else
    _c=''; _g=''; _b=''; _d=''; _o=''
fi
ui_section() { printf '%s==>%s %s%s%s\n' "$_c" "$_o" "$_b" "$*" "$_o"; }
ui_step()    { printf '  %s→%s %s\n' "$_c" "$_o" "$*"; }
ui_ok()      { printf '  %s✓%s %s\n' "$_g" "$_o" "$*"; }
ui_skip()    { printf '  %s· %s%s\n' "$_d" "$*" "$_o"; }

ui_section "Bootstrapping dotfiles"

# ---- 1. Homebrew (macOS only) ---------------------------------------------
if [[ "$(uname -s)" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
        ui_step "installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        ui_skip "Homebrew already installed"
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

ui_step "installing chezmoi, then applying github.com/${GITHUB_USER}/dotfiles"
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
    ui_skip "no TTY; running without prompts"
    sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$CHEZMOI_BIN_DIR" init --apply "$GITHUB_USER"
fi

ui_ok "done; open a new terminal to load the new shell config"
