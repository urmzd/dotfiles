# Shared body for VS Code-family settings.json modify_ scripts.
# Editors write this file themselves, so merge instead of overwriting. Unlike
# the agy baseline, managed keys WIN here: they are security policy, not
# defaults. Extension auto-update is off because a tampered Claude Code build
# (2.1.313, 2026-10-29) shipped through Cursor's Open VSX-based marketplace;
# manual updates give time for a bad release to be pulled first.
set -euo pipefail

current="$(cat)"
managed='{"extensions.autoUpdate":false}'

if ! command -v jq >/dev/null 2>&1; then
    if [ -z "${current//[[:space:]]/}" ]; then
        printf '%s\n' "$managed"
    else
        printf '%s' "$current"
    fi
    exit 0
fi

if [ -z "${current//[[:space:]]/}" ]; then
    current='{}'
fi

# settings.json may be JSONC (comments, trailing commas); jq can't round-trip
# that, so leave it untouched and say so.
if ! jq -e . >/dev/null 2>&1 <<<"$current"; then
    echo "editor settings.json is not strict JSON; set \"extensions.autoUpdate\": false by hand" >&2
    printf '%s' "$current"
    exit 0
fi

jq --indent 4 -n --argjson managed "$managed" --argjson current "$current" '$current * $managed'
