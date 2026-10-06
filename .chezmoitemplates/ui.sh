# ---- Shared terminal output (.chezmoitemplates/ui.sh) ----------------------
# One vocabulary for every run_ script and the `dotfiles` shell command, so a
# `chezmoi apply` reads as one program instead of a dozen. Works in bash and zsh.
#
#   ui_section "Homebrew"    ==> Homebrew      one per script, before any work
#   ui_step    "msg"           → msg           slow work starting
#   ui_ok      "msg"           ✓ msg           changed, or verified
#   ui_skip    "msg"           · msg           nothing to do (dim)
#   ui_warn    "msg"           ! msg           degraded, continuing (stderr)
#   ui_fail    "msg"           ✗ msg           failed (stderr)
#   ui_hint    "msg"             msg           next step under warn/fail (dim)
#   ui_run "label" cmd...    runs cmd quietly; ✓ label, or ✗ label + output tail
#
# Rules: quiet when nothing changed, one line per outcome, and every warning or
# failure says what to do next. Color only on a TTY and never with NO_COLOR.
#
# Symbols and colors come from the machine's theme ([ui] in themes/*.toml or
# a pack's theme.toml; see `dotfiles theme`), read at run time from
# ~/.config/dotfiles/theme.sh so a theme switch does not re-run every script.
# Per-shell overrides, also read by the dotfiles CLI:
# DOTFILES_UI_THEME=default|ascii|plain, and DOTFILES_UI_<ROLE> /
# DOTFILES_UI_COLOR_<ROLE> (ROLE: SECTION STEP OK SKIP WARN FAIL DIM). A color
# is an ANSI SGR code ("1;36") or a hex "#5ea1ff".
_ui_t_preset=default
_ui_t_s_section='==>'; _ui_t_s_step='→'; _ui_t_s_ok='✓'; _ui_t_s_skip='·'; _ui_t_s_warn='!'; _ui_t_s_fail='✗'
_ui_t_c_section=36; _ui_t_c_step=36; _ui_t_c_ok=32; _ui_t_c_skip=2; _ui_t_c_warn=33; _ui_t_c_fail=31; _ui_t_c_dim=2
# shellcheck disable=SC1091
[ -r "$HOME/.config/dotfiles/theme.sh" ] && . "$HOME/.config/dotfiles/theme.sh"
_ui_preset="${DOTFILES_UI_THEME:-$_ui_t_preset}"
_ui_sgr() { # <code or #rrggbb> -> escape sequence ("" when color is off)
    [ -n "$_ui_color_on" ] && [ -n "$1" ] || return 0
    case "$1" in
        \#??????) printf '\033[38;2;%d;%d;%dm' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}" ;;
        *) printf '\033[%sm' "$1" ;;
    esac
}
_ui_color_on=''
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "$_ui_preset" != plain ]; then _ui_color_on=1; fi
if [ "$_ui_preset" = default ]; then
    _ui_s_section="$_ui_t_s_section"; _ui_s_step="$_ui_t_s_step"; _ui_s_ok="$_ui_t_s_ok"
    _ui_s_skip="$_ui_t_s_skip"; _ui_s_warn="$_ui_t_s_warn"; _ui_s_fail="$_ui_t_s_fail"
else
    _ui_s_section='==>'; _ui_s_step='->'; _ui_s_ok='ok'; _ui_s_skip='..'; _ui_s_warn='!'; _ui_s_fail='x'
fi
_ui_s_section="${DOTFILES_UI_SECTION:-$_ui_s_section}"; _ui_s_step="${DOTFILES_UI_STEP:-$_ui_s_step}"
_ui_s_ok="${DOTFILES_UI_OK:-$_ui_s_ok}"; _ui_s_skip="${DOTFILES_UI_SKIP:-$_ui_s_skip}"
_ui_s_warn="${DOTFILES_UI_WARN:-$_ui_s_warn}"; _ui_s_fail="${DOTFILES_UI_FAIL:-$_ui_s_fail}"
_ui_bold="$(_ui_sgr 1)"; _ui_off="$(_ui_sgr 0)"
_ui_c_section="$(_ui_sgr "${DOTFILES_UI_COLOR_SECTION:-$_ui_t_c_section}")"
_ui_c_step="$(_ui_sgr "${DOTFILES_UI_COLOR_STEP:-$_ui_t_c_step}")"
_ui_c_ok="$(_ui_sgr "${DOTFILES_UI_COLOR_OK:-$_ui_t_c_ok}")"
_ui_c_skip="$(_ui_sgr "${DOTFILES_UI_COLOR_SKIP:-$_ui_t_c_skip}")"
_ui_c_warn="$(_ui_sgr "${DOTFILES_UI_COLOR_WARN:-$_ui_t_c_warn}")"
_ui_c_fail="$(_ui_sgr "${DOTFILES_UI_COLOR_FAIL:-$_ui_t_c_fail}")"
_ui_c_dim="$(_ui_sgr "${DOTFILES_UI_COLOR_DIM:-$_ui_t_c_dim}")"
ui_section() { printf '%s%s%s %s%s%s\n' "$_ui_c_section" "$_ui_s_section" "$_ui_off" "$_ui_bold" "$*" "$_ui_off"; }
ui_step()    { printf '  %s%s%s %s\n' "$_ui_c_step" "$_ui_s_step" "$_ui_off" "$*"; }
ui_ok()      { printf '  %s%s%s %s\n' "$_ui_c_ok" "$_ui_s_ok" "$_ui_off" "$*"; }
ui_skip()    { printf '  %s%s %s%s\n' "$_ui_c_skip" "$_ui_s_skip" "$*" "$_ui_off"; }
ui_warn()    { printf '  %s%s%s %s\n' "$_ui_c_warn" "$_ui_s_warn" "$_ui_off" "$*" >&2; }
ui_fail()    { printf '  %s%s%s %s\n' "$_ui_c_fail" "$_ui_s_fail" "$_ui_off" "$*" >&2; }
ui_hint()    { printf '    %s%s%s\n' "$_ui_c_dim" "$*" "$_ui_off" >&2; }
ui_run() {
    local label="$1" log rc=0
    shift
    log="$(mktemp "${TMPDIR:-/tmp}/ui-run.XXXXXX")"
    "$@" >"$log" 2>&1 || rc=$?
    if [ "$rc" -eq 0 ]; then
        ui_ok "$label"
    else
        ui_fail "$label (exit $rc)"
        tail -n 12 "$log" | sed 's/^/      /' >&2
    fi
    rm -f "$log"
    return "$rc"
}

# fetch_and_run <url> <interpreter> [args...]: download an installer to a temp
# file (with retries) and run it. Unlike `curl ... | sh`, a failed or empty
# download returns non-zero instead of running an empty script that "succeeds".
fetch_and_run() {
    local url="$1" interp="$2" tmp rc=0
    shift 2
    tmp="$(mktemp "${TMPDIR:-/tmp}/installer.XXXXXX")"
    if ! curl -fsSL --retry 2 --connect-timeout 15 "$url" -o "$tmp" || [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        echo "download failed: $url" >&2
        return 1
    fi
    "$interp" "$tmp" "$@" || rc=$?
    rm -f "$tmp"
    return "$rc"
}
# ---------------------------------------------------------------------------
