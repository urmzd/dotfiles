#!/usr/bin/env bash
# One-shot bootstrap for this dotfiles repo.
# Idempotent: re-running is safe. Each step is gated on whether the tool is already installed.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/install.sh | bash
#   # or, with a specific GitHub username:
#   curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/install.sh | bash -s -- <github-user>
#   # with packs (repeatable; git URL, URL//folder, or local folder):
#   curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/install.sh | bash -s -- \
#       --pack git@github.com:acme/dev-setup.git//backend-engineer
#
# Private (SSH or HTTPS) pack repos work on a fresh laptop: when a pack cannot
# be fetched after the first apply, this runs `dotfiles identity` (gh sign-in,
# SSH key uploaded to GitHub), loads the key into ssh-agent, and applies again
# so the packs are cloned and their Brewfile, catalog, and AGENTS.md install.

set -euo pipefail

GITHUB_USER="urmzd"
PACKS=()
while [ $# -gt 0 ]; do
    case "$1" in
        --pack) PACKS+=("${2:?--pack needs a value}"); shift 2 ;;
        --pack=*) PACKS+=("${1#--pack=}"); shift ;;
        -h | --help) sed -n '2,16p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
        -*) printf 'unknown option: %s\n' "$1" >&2; exit 1 ;;
        *) GITHUB_USER="$1"; shift ;;
    esac
done

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
ui_warn()    { printf '  ! %s\n' "$*" >&2; }
ui_hint()    { printf '    %s%s%s\n' "$_d" "$*" "$_o" >&2; }

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
#
# When this script is piped (curl | bash), stdin is the script itself, so
# chezmoi's first-run prompts would read garbage. Reattach stdin to the
# terminal when one exists; otherwise run headless (promptOnce values are
# skipped anyway once a config exists).
has_tty=0
if [ -t 0 ]; then
    has_tty=1
elif { exec 3</dev/tty; } 2>/dev/null; then
    exec 3<&-
    has_tty=2
fi
interactive() { # <command...>: run with the terminal as stdin
    case "$has_tty" in
        1) "$@" ;;
        2) "$@" </dev/tty ;;
        *) return 1 ;;
    esac
}
chezmoi_run() { # <chezmoi args...>
    if [ "$has_tty" -ne 0 ]; then
        interactive chezmoi "$@"
    else
        chezmoi "$@" --no-tty </dev/null
    fi
}

# First init only: packs from --pack are saved without the packs question.
if [ "${#PACKS[@]}" -gt 0 ]; then
    DOTFILES_PACKS="$(IFS=,; printf '%s' ${PACKS[*]+"${PACKS[*]}"})"
    export DOTFILES_PACKS
fi

ui_step "applying github.com/${GITHUB_USER}/dotfiles"
[ "$has_tty" -ne 0 ] || ui_skip "no TTY; running without prompts"
apply_ok=1
chezmoi_run init --apply --keep-going "$GITHUB_USER" || apply_ok=0

if [ "$apply_ok" -eq 0 ]; then
    ui_skip "some steps failed (listed above); everything else was applied"
    ui_skip "they retry on the next: chezmoi apply --keep-going"
fi

# ---- 5. packs ---------------------------------------------------------------
# The first apply installs git, gh, gpg, and the dotfiles CLI, and tries to
# clone each pack. A private pack fails on a fresh laptop (gh signed out, no
# SSH key on GitHub), which only warns. Set up access once, then apply twice:
# the first apply clones, the second renders what the packs contain.
export PATH="$HOME/.local/bin:$PATH"

# Re-run on a machine that already had a config: --pack was not seeded by
# init, so add it now (a no-op when it is already in the list).
if [ "${#PACKS[@]}" -gt 0 ] && command -v dotfiles >/dev/null 2>&1; then
    rc=0
    if [ "$has_tty" -ne 0 ]; then
        interactive dotfiles pack add ${PACKS[@]+"${PACKS[@]}"} || rc=$?
    else
        dotfiles pack add ${PACKS[@]+"${PACKS[@]}"} </dev/null || rc=$?
    fi
    [ "$rc" -eq 0 ] || [ "$rc" -eq 2 ] || ui_warn "could not add packs: ${PACKS[*]}"
fi

# Git packs whose clone is missing, one URL per line.
missing_packs() {
    local line url dir
    { chezmoi execute-template '{{ range (includeTemplate "packs" . | fromJson) }}{{ if .url }}{{ .url }} {{ .repo_dir }}{{ "\n" }}{{ end }}{{ end }}' 2>/dev/null || true; } |
        while IFS= read -r line; do
            url="${line%% *}"
            dir="${line#* }"
            if [ -n "$url" ] && [ ! -d "$dir/.git" ]; then
                printf '%s\n' "$url"
            fi
        done
    return 0
}

# A passphrase-protected key is unusable in the BatchMode ssh the pack sync
# uses until ssh-agent holds it; on macOS --apple-use-keychain also saves the
# passphrase so later applies (and the daily pack update) need no prompt.
load_ssh_key() {
    local key="$HOME/.ssh/github" fpr
    [ -f "$key" ] && [ -f "$key.pub" ] || return 0
    if [ -z "${SSH_AUTH_SOCK:-}" ]; then
        eval "$(ssh-agent -s)" >/dev/null || return 0
        started_agent=1
    fi
    fpr="$(ssh-keygen -lf "$key.pub" 2>/dev/null | awk '{print $2}')" || fpr=""
    if [ -n "$fpr" ] && ssh-add -l 2>/dev/null | grep -qF "$fpr"; then
        return 0
    fi
    ui_step "loading $key into ssh-agent (enter its passphrase if asked)"
    if [ "$(uname -s)" = Darwin ]; then
        interactive ssh-add --apple-use-keychain "$key" || interactive ssh-add "$key" || true
    else
        interactive ssh-add "$key" || true
    fi
}

started_agent=0
missing="$(missing_packs)"
if [ -n "$missing" ]; then
    ui_section "Packs"
    printf '%s\n' "$missing" | while IFS= read -r url; do ui_step "not fetched yet: $url"; done
    if [ "$has_tty" -eq 0 ]; then
        ui_warn "packs need GitHub access, which needs a terminal"
        ui_hint "run in a terminal: dotfiles identity && chezmoi apply && chezmoi apply"
    elif ! command -v dotfiles >/dev/null 2>&1; then
        ui_warn "the dotfiles CLI is not installed, so access cannot be set up here"
        ui_hint "set up gh + an SSH key (gh auth login), then: chezmoi apply && chezmoi apply"
    else
        ui_step "setting up GitHub access for the packs (opens a browser to sign in)"
        rc=0
        interactive dotfiles identity || rc=$?
        if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
            ui_warn "dotfiles identity did not finish; trying the packs anyway"
        fi
        load_ssh_key
        ui_step "applying again to fetch and install the packs"
        chezmoi_run apply --keep-going || true
        chezmoi_run apply --keep-going || apply_ok=0
        still="$(missing_packs)"
        if [ -z "$still" ]; then
            ui_ok "packs fetched and applied"
        else
            printf '%s\n' "$still" | while IFS= read -r url; do ui_warn "still cannot fetch $url"; done
            ui_hint "check this account can read it: git ls-remote <url>"
            ui_hint "org with SAML SSO: authorize the SSH key at https://github.com/settings/keys (Configure SSO)"
            ui_hint "then: chezmoi apply && chezmoi apply"
        fi
    fi
    if [ "$started_agent" -eq 1 ]; then
        ssh-agent -k >/dev/null 2>&1 || true
    fi
fi

ui_ok "done; open a new terminal to load the new shell config"
ui_skip "next: dotfiles identity (GitHub sign-in, SSH + GPG keys), dotfiles package (optional apps), dotfiles doctor"
