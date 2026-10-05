# ---- Prefer a modern bash (.chezmoitemplates/bash-modern.sh) ---------------
# `#!/usr/bin/env bash` finds macOS's /bin/bash 3.2 on a fresh Mac and in any
# PATH without Homebrew. When a newer bash is installed, re-run under it; when
# not, keep going: every script must also work on 3.2, and CI enforces that
# floor (.github/scripts/lint-shell.sh) with DOTFILES_BASH_FLOOR=1 set to
# disable this switch. Must stay above any other command so stdin (the live
# file for modify_ scripts) is still unread when exec replaces the process.
if [ -n "${BASH_VERSION:-}" ] && [ "${BASH_VERSINFO[0]:-0}" -lt 4 ] && [ -z "${DOTFILES_BASH_FLOOR:-}" ]; then
    for _modern_bash in /opt/homebrew/bin/bash /usr/local/bin/bash /home/linuxbrew/.linuxbrew/bin/bash; do
        if [ -x "$_modern_bash" ]; then
            exec "$_modern_bash" "$0" "$@"
        fi
    done
fi
# ---------------------------------------------------------------------------
