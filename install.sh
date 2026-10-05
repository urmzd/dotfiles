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
        # Download first (`bash -c "$(curl ...)"` runs an empty script when the
        # download fails) and give it the terminal: under `curl | bash` our
        # stdin is the rest of this script, which the installer must not read.
        brew_installer="$(mktemp)"
        if curl -fsSL --retry 2 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$brew_installer" &&
            [ -s "$brew_installer" ]; then
            if { exec 3</dev/tty; } 2>/dev/null; then
                exec 3<&-
                /bin/bash "$brew_installer" </dev/tty || ui_skip "Homebrew install failed; chezmoi falls back to its own installer"
            else
                NONINTERACTIVE=1 /bin/bash "$brew_installer" </dev/null || ui_skip "Homebrew install failed; chezmoi falls back to its own installer"
            fi
        else
            ui_skip "could not download the Homebrew installer; continuing without it"
        fi
        rm -f "$brew_installer"
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

# ---- 2. Bring an existing checkout up to date --------------------------------
# `chezmoi init --apply` reuses an existing source directory as-is and does not
# pull, so re-running this on a machine bootstrapped earlier applied stale
# scripts (an old Codex merge script failed under bash 3.2 with "line 207:
# unexpected EOF"). Fast-forward first; stop rather than apply stale code.
SOURCE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
if [ -d "$SOURCE_DIR/.git" ]; then
    if git -C "$SOURCE_DIR" -c advice.diverging=false pull --ff-only --quiet; then
        ui_ok "updated the existing dotfiles checkout to $(git -C "$SOURCE_DIR" rev-parse --short HEAD)"
    else
        printf '  ✗ could not fast-forward %s (local changes or diverged history)\n' "$SOURCE_DIR" >&2
        printf '    resolve it with: git -C %s status, then rerun this installer\n' "$SOURCE_DIR" >&2
        exit 1
    fi
fi

# ---- 3. chezmoi: chezmoi's own installer, else Homebrew ----------------------
# Reuse a chezmoi already on PATH. Otherwise download chezmoi's installer
# (checked separately: `sh -c "$(curl ...)"` succeeds on an EMPTY script when
# the download fails) and fall back to Homebrew if get.chezmoi.io or its
# GitHub release is unavailable.
CHEZMOI_BIN_DIR="${HOME}/.local/bin"
mkdir -p "$CHEZMOI_BIN_DIR"
export PATH="$CHEZMOI_BIN_DIR:$PATH"
if command -v chezmoi >/dev/null 2>&1; then
    ui_skip "chezmoi already installed ($(command -v chezmoi))"
elif chezmoi_installer="$(curl -fsLS https://get.chezmoi.io)" && [ -n "$chezmoi_installer" ] &&
    sh -c "$chezmoi_installer" -- -b "$CHEZMOI_BIN_DIR" >/dev/null; then
    ui_ok "installed chezmoi into $CHEZMOI_BIN_DIR"
elif command -v brew >/dev/null 2>&1 && brew install chezmoi; then
    ui_ok "installed chezmoi with Homebrew (get.chezmoi.io unavailable)"
else
    printf '  ✗ could not install chezmoi (get.chezmoi.io and Homebrew both failed)\n' >&2
    printf '    check the network, then rerun this installer\n' >&2
    exit 1
fi

# ---- 4. apply ---------------------------------------------------------------
# --keep-going: chezmoi otherwise stops at the first failing script and skips
# every later one. With it, all steps run, failures are listed at the end, and
# a failed run_once/run_onchange script is not recorded, so the next apply
# retries it.
ui_step "applying github.com/${GITHUB_USER}/dotfiles"
apply_ok=1
# When this script is piped (curl | bash), stdin is the script itself, so
# chezmoi's first-run prompts would read garbage. Reattach stdin to the
# terminal when one exists; otherwise run headless (promptOnce values are
# skipped anyway once a config exists).
if [ -t 0 ]; then
    chezmoi init --apply --keep-going "$GITHUB_USER" || apply_ok=0
elif { exec 3</dev/tty; } 2>/dev/null; then
    exec 3<&-
    chezmoi init --apply --keep-going "$GITHUB_USER" </dev/tty || apply_ok=0
else
    ui_skip "no TTY; running without prompts"
    chezmoi init --apply --keep-going --no-tty "$GITHUB_USER" </dev/null || apply_ok=0
fi

if [ "$apply_ok" -eq 0 ]; then
    ui_skip "some steps failed (listed above); everything else was applied"
    ui_skip "they retry on the next: chezmoi apply --keep-going"
fi

ui_ok "done; open a new terminal to load the new shell config"
ui_skip "next: dotfiles identity (GitHub sign-in, SSH + GPG keys), dotfiles package (optional apps), dotfiles doctor"
