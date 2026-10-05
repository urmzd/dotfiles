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
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    _ui_bold=$'\033[1m'; _ui_dim=$'\033[2m'; _ui_red=$'\033[31m'
    _ui_green=$'\033[32m'; _ui_yellow=$'\033[33m'; _ui_cyan=$'\033[36m'; _ui_off=$'\033[0m'
else
    _ui_bold=''; _ui_dim=''; _ui_red=''; _ui_green=''; _ui_yellow=''; _ui_cyan=''; _ui_off=''
fi
ui_section() { printf '%s==>%s %s%s%s\n' "$_ui_cyan" "$_ui_off" "$_ui_bold" "$*" "$_ui_off"; }
ui_step()    { printf '  %s→%s %s\n' "$_ui_cyan" "$_ui_off" "$*"; }
ui_ok()      { printf '  %s✓%s %s\n' "$_ui_green" "$_ui_off" "$*"; }
ui_skip()    { printf '  %s· %s%s\n' "$_ui_dim" "$*" "$_ui_off"; }
ui_warn()    { printf '  %s!%s %s\n' "$_ui_yellow" "$_ui_off" "$*" >&2; }
ui_fail()    { printf '  %s✗%s %s\n' "$_ui_red" "$_ui_off" "$*" >&2; }
ui_hint()    { printf '    %s%s%s\n' "$_ui_dim" "$*" "$_ui_off" >&2; }
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
# ---------------------------------------------------------------------------
