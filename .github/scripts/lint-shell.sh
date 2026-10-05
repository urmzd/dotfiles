#!/usr/bin/env bash
# Shell compatibility gate for every script this repo ships.
#
# Usage: lint-shell.sh <chezmoi-config>     (called by check.sh per machine)
#
# The floor is bash 3.2: `#!/usr/bin/env bash` resolves to macOS's /bin/bash
# on a fresh Mac, before Homebrew installs bash 5. .chezmoitemplates/
# bash-modern.sh switches to a newer bash when one exists, so every script
# must still work on 3.2 itself. This script enforces that:
#   1. parse each rendered script with the shell that will run it
#      (bash 3.2 floor + current bash, sh + dash, zsh)
#   2. reject bash-4-only constructs and $(...) heredocs, which 3.2 misparses
#   3. run every modify_ script under the floor (DOTFILES_BASH_FLOOR=1) on an
#      empty and an existing target, and require valid, key-preserving output
set -euo pipefail

cfg="${1:?usage: lint-shell.sh <chezmoi-config>}"
src="$(cd "$(dirname "$0")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

floor=bash
[ "$(uname -s)" = Darwin ] && floor=/bin/bash
failures=0
fail() { printf '  ✗ %s\n' "$*" >&2; failures=$((failures + 1)); }

render() { # <source file> <output>
    case "$1" in
        *.tmpl | run_*) chezmoi --config "$cfg" --source "$src" execute-template <"$src/$1" >"$2" ;;
        *) cp "$src/$1" "$2" ;;
    esac
}

# Constructs bash 3.2 lacks or misparses. Comment lines are skipped. The last
# pattern is a heredoc (<<EOF, not a <<< here-string) inside $(...).
bash4='(declare|local|typeset) -[A-Za-z]*[An]\b|\bmapfile\b|\breadarray\b|\$\{[A-Za-z_][A-Za-z0-9_]*(,,|\^\^|,|\^)\}|\|&|&>>|\[\[ -v |\bwait -n\b|\bcoproc\b|globstar|\$\([^)]*<<-?[[:space:]]*'"[\"']?"'[A-Za-z_]'

files=$(cd "$src" && git ls-files |
    grep -vE '^(cli|\.github)/' |
    grep -E '(^|/)(run_|modify_)|\.sh(\.tmpl)?$|\.zsh(\.tmpl)?$|(^|/)dot_z(shrc|shenv|profile)')

count=0
for f in $files; do
    out="$work/$(printf '%s' "$f" | tr '/' '_')"
    if ! render "$f" "$out" 2>"$out.err"; then
        fail "$f: render failed: $(head -1 "$out.err")"
        continue
    fi
    shebang=$(head -1 "$out")
    case "$f" in
        *.zsh | *.zsh.tmpl | dot_z*) kind=zsh ;;
        *) case "$shebang" in *zsh*) kind=zsh ;; '#!/bin/sh'*) kind=sh ;; *) kind=bash ;; esac ;;
    esac
    case "$kind" in
        bash)
            "$floor" -n "$out" 2>"$out.err" || fail "$f: bash 3.2 cannot parse: $(head -1 "$out.err")"
            bash -n "$out" 2>"$out.err" || fail "$f: bash cannot parse: $(head -1 "$out.err")"
            if hits=$(grep -nE "$bash4" "$out" | grep -vE '^[0-9]+:[[:space:]]*#'); then
                fail "$f: bash-4-only construct (3.2 floor): $(printf '%s' "$hits" | head -1)"
            fi
            ;;
        sh)
            sh -n "$out" 2>"$out.err" || fail "$f: sh cannot parse: $(head -1 "$out.err")"
            if command -v dash >/dev/null 2>&1; then
                dash -n "$out" 2>"$out.err" || fail "$f: dash cannot parse: $(head -1 "$out.err")"
            fi
            ;;
        zsh)
            if command -v zsh >/dev/null 2>&1; then
                zsh -n "$out" 2>"$out.err" || fail "$f: zsh cannot parse: $(head -1 "$out.err")"
            fi
            ;;
    esac
    count=$((count + 1))
done
echo "  ✓ $count scripts parse under their shells (bash floor: $("$floor" -c 'echo $BASH_VERSION'))"

# Run each modify_ script under the floor shell with the modern-bash switch
# disabled. Inputs: empty (first apply) and an existing file holding a key the
# script does not manage, which must survive the merge.
modify_count=0
for f in $(printf '%s\n' $files | grep -E '(^|/)modify_'); do
    script="$work/run.sh"
    render "$f" "$script"
    case "$f" in
        *.json*) existing='{"zz_live_key": 1}'
                 valid() { jq -e '.' >/dev/null 2>&1 <"$1"; }
                 kept() { jq -e '.zz_live_key == 1' >/dev/null 2>&1 <"$1"; } ;;
        *.toml*) existing=$'[zz_live_table]\nkept = true\n'
                 valid() { python3 -c 'import sys,tomllib; tomllib.load(open(sys.argv[1],"rb"))' "$1" 2>/dev/null; }
                 kept() { python3 -c 'import sys,tomllib; assert tomllib.load(open(sys.argv[1],"rb"))["zz_live_table"]["kept"]' "$1" 2>/dev/null; } ;;
        *) continue ;;
    esac
    before=$failures
    if ! printf '' | DOTFILES_BASH_FLOOR=1 "$floor" "$script" >"$work/empty.out" 2>"$work/err"; then
        fail "$f: failed on an empty target under bash 3.2: $(head -1 "$work/err")"
    elif ! valid "$work/empty.out"; then
        fail "$f: invalid output on an empty target"
    fi
    if ! printf '%s' "$existing" | DOTFILES_BASH_FLOOR=1 "$floor" "$script" >"$work/live.out" 2>"$work/err"; then
        fail "$f: failed on an existing target under bash 3.2: $(head -1 "$work/err")"
    elif ! valid "$work/live.out" || ! kept "$work/live.out"; then
        fail "$f: dropped or broke the live file's own keys"
    fi
    [ "$failures" -eq "$before" ] && modify_count=$((modify_count + 1))
done
echo "  ✓ $modify_count modify_ scripts merge correctly under bash 3.2"

if [ "$failures" -gt 0 ]; then
    echo "  ✗ $failures shell compatibility problem(s)" >&2
    exit 1
fi
