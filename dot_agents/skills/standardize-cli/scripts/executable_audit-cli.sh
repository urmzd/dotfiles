#!/bin/sh
# audit-cli.sh: check one CLI tool against the tool contract in standardize-cli.
#
# Usage:
#   audit-cli.sh <binary> [repo-dir] [--format human|json]
#
# It only runs the binary with `--help`, `--version`, `version` and `mcp tools`.
# It never runs init, update or bootstrap for real.
# Exit code: 0 when every required check passes, 1 otherwise, 2 on bad usage.

set -u

bin=""
repo=""
format="human"
while [ $# -gt 0 ]; do
    case "$1" in
        --format) format="${2:-}"; shift 2 ;;
        --format=*) format="${1#--format=}"; shift ;;
        -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) if [ -z "$bin" ]; then bin="$1"; elif [ -z "$repo" ]; then repo="$1"; else echo "unexpected argument: $1" >&2; exit 2; fi; shift ;;
    esac
done
[ -n "$bin" ] || { echo "usage: audit-cli.sh <binary> [repo-dir] [--format human|json]" >&2; exit 2; }
case "$format" in human|json) ;; *) echo "unknown format: $format (use human or json)" >&2; exit 2 ;; esac
command -v "$bin" >/dev/null 2>&1 || { echo "$bin is not on PATH" >&2; exit 2; }

name=$(basename "$bin")
failed=0
rows=""

# record <level> <id> <pass|fail|skip> <detail>
record() {
    [ "$1" = must ] && [ "$3" = fail ] && failed=1
    rows="${rows}$1	$2	$3	$4
"
}

# ok <command...>: true when the command exits 0. Output is discarded and
# stdin is closed, so a verb that waits for input cannot hang the audit.
ok() { "$@" </dev/null >/dev/null 2>&1; }

check() { # check <level> <id> <detail> <command...>
    level="$1"; id="$2"; detail="$3"; shift 3
    if ok "$@"; then record "$level" "$id" pass "$detail"; else record "$level" "$id" fail "$detail"; fi
}

is_json() { command -v jq >/dev/null 2>&1 && printf '%s' "$1" | jq -e . >/dev/null 2>&1; }

# --- verbs -----------------------------------------------------------------
check must version-flag "$name --version" "$bin" --version

out=$("$bin" version </dev/null 2>/dev/null | head -1)
if printf '%s' "$out" | grep -Eq "^$name v[0-9]"; then
    record must version-verb pass "$name version prints '$out'"
else
    record must version-verb fail "$name version must print '$name v<version>', got '${out:-nothing}'"
fi

out=$("$bin" version --format json </dev/null 2>/dev/null)
if is_json "$out"; then record must version-json pass "$name version --format json"; else record must version-json fail "$name version --format json must print one JSON document on stdout"; fi

check must update "$name update" "$bin" update --help
check must bootstrap "$name bootstrap" "$bin" bootstrap --help
# The MCP verbs are required only when the tool serves MCP. A tool whose `mcp`
# verb manages other servers (it has `mcp add`) is not a server.
serves=yes
if ok "$bin" mcp serve --help; then
    record must mcp-serve pass "$name mcp serve"
    out=$("$bin" mcp tools </dev/null 2>/dev/null)
    if is_json "$out" && printf '%s' "$out" | jq -e '.tools | type == "array"' >/dev/null 2>&1; then
        record must mcp-tools pass "$name mcp tools"
    else
        record must mcp-tools fail "$name mcp tools must print {\"tools\": [...]} on stdout"
    fi
elif ok "$bin" mcp --help && ! ok "$bin" mcp add --help; then
    record must mcp-serve fail "$name has 'mcp' but not 'mcp serve'"
elif command -v "$name-mcp" >/dev/null 2>&1; then
    record must mcp-serve fail "the server is a second binary, $name-mcp; make it '$name mcp serve'"
else
    serves=no
    record opt mcp-serve skip "$name mcp serve (needed when agents call the tool)"
fi

check opt init "$name init (needed when the tool reads a config file)" "$bin" init --help
check opt completions "$name completions" "$bin" completions --help
check opt doctor "$name doctor (needed when the tool depends on other programs)" "$bin" doctor --help

for wrong in setup upgrade completion; do
    if ok "$bin" "$wrong" --help; then record must "no-$wrong" fail "'$name $wrong' is a synonym of a standard verb"; fi
done

# --- repo ------------------------------------------------------------------
if [ -n "$repo" ]; then
    [ -d "$repo" ] || { echo "$repo is not a directory" >&2; exit 2; }
    for f in install.sh sr.yaml README.md; do
        if [ -f "$repo/$f" ]; then record must "file-$f" pass "$f"; else record must "file-$f" fail "$f is missing"; fi
    done
    if [ -f "$repo/skills/$name/SKILL.md" ]; then
        record must skill pass "skills/$name/SKILL.md"
    else
        others=$(find "$repo/skills" -maxdepth 2 -name SKILL.md 2>/dev/null | sed "s|$repo/||" | tr '\n' ' ')
        record must skill fail "skills/$name/SKILL.md is missing (found: ${others:-none})"
    fi
    if [ -f "$repo/README.md" ]; then
        if grep -q "$name bootstrap" "$repo/README.md"; then record must readme-bootstrap pass "README shows '$name bootstrap'"; else record must readme-bootstrap fail "README does not show '$name bootstrap', so there is no command to install the skill"; fi
        if [ "$serves" = yes ]; then
            if grep -Eq '^#+ MCP Server' "$repo/README.md"; then record must readme-mcp pass "README has an MCP Server section"; else record must readme-mcp fail "README has no MCP Server section"; fi
        fi
    fi
    if [ -f "$repo/action.yml" ]; then record opt action pass "action.yml"; else record opt action skip "action.yml (needed when CI uses the tool)"; fi
fi

# --- report ----------------------------------------------------------------
if [ "$format" = json ]; then
    printf '{"tool":"%s","conforms":%s,"checks":[' "$name" "$([ $failed -eq 0 ] && echo true || echo false)"
    first=1
    printf '%s' "$rows" | while IFS='	' read -r level id result detail; do
        [ -n "$id" ] || continue
        [ $first -eq 1 ] || printf ','
        first=0
        esc=$(printf '%s' "$detail" | sed 's/\\/\\\\/g; s/"/\\"/g')
        printf '{"id":"%s","required":%s,"result":"%s","detail":"%s"}' "$id" "$([ "$level" = must ] && echo true || echo false)" "$result" "$esc"
    done
    printf ']}\n'
else
    printf '%s\n' "$name" >&2
    printf '%s' "$rows" | while IFS='	' read -r level id result detail; do
        [ -n "$id" ] || continue
        case "$result" in pass) mark="ok  " ;; fail) mark="FAIL" ;; *) mark="-   " ;; esac
        [ "$level" = opt ] && [ "$result" = fail ] && mark="-   "
        printf '  %s %s\n' "$mark" "$detail" >&2
    done
    if [ $failed -eq 0 ]; then printf '  conforms\n' >&2; else printf '  does not conform\n' >&2; fi
fi
exit $failed
