#!/usr/bin/env bash
# Finds work that exists only on this disk: uncommitted files, commits that no
# remote has, and commits on a detached HEAD. No network, never writes.
#
#   work-at-risk.sh stop          Stop hook. If the session's own worktree
#                                 holds such work, block the stop once and
#                                 tell the agent to commit and push it.
#   work-at-risk.sh start         SessionStart hook. Print what is at risk in
#                                 this repo, or under the scan roots when the
#                                 session did not start inside a repo.
#   work-at-risk.sh scan [dir..]  Same report for the given repos or folders.
#
# Scan roots: $WORK_AT_RISK_ROOTS (colon-separated), default ~/github.
# Contract: https://code.claude.com/docs/en/hooks
#   Stop: stdin JSON has .cwd and .stop_hook_active; exit 2 blocks the stop
#   and hands stderr to the agent. SessionStart: stdout joins the context.
# A check that cannot run exits 0, so it can never trap a session.
set -uo pipefail

mode="${1:-scan}"
[ $# -gt 0 ] && shift

# One checkout -> "path<TAB>branch<TAB>uncommitted<TAB>unpushed", only if at risk.
one() {
    local d="$1" dirty unpushed branch
    git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
    # No remote means nowhere to push; that is a choice, not lost work.
    [ -n "$(git -C "$d" remote 2>/dev/null)" ] || return 0
    dirty=$(git -C "$d" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    unpushed=$(git -C "$d" rev-list --count HEAD --not --remotes 2>/dev/null || echo 0)
    [ "$dirty" = 0 ] && [ "$unpushed" = 0 ] && return 0
    branch=$(git -C "$d" branch --show-current 2>/dev/null)
    printf '%s\t%s\t%s\t%s\n' "$d" "${branch:-detached}" "$dirty" "$unpushed"
}

# Every checkout (primary and worktrees) of the repo that holds $1.
checkouts() {
    git -C "$1" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'
}

scan() {
    local arg d
    for arg in "$@"; do
        if git -C "$arg" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            checkouts "$arg"
        else
            for d in "$arg"/*/; do
                [ -e "$d/.git" ] && checkouts "$d"
            done
        fi
    done | sort -u | tr '\n' '\0' | xargs -0 -n 1 -P 8 "$0" one 2>/dev/null | sort
}

describe() {
    awk -F'\t' '{
        what = ""
        if ($3 != 0) what = $3 " uncommitted"
        if ($4 != 0) what = what (what == "" ? "" : ", ") $4 " unpushed"
        printf "- %s [%s]: %s\n", $1, $2, what
    }'
}

json_field() {
    command -v jq >/dev/null 2>&1 || return 0
    jq -r "$1 // empty" 2>/dev/null <<<"$input"
}

case "$mode" in
    one)
        one "$1"
        ;;

    scan)
        [ $# -eq 0 ] && set -- "$PWD"
        scan "$@" | describe
        ;;

    start)
        input="$(cat 2>/dev/null || true)"
        cwd="$(json_field .cwd)"
        cwd="${cwd:-$PWD}"
        if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            found="$(scan "$cwd")"
        else
            IFS=: read -r -a roots <<<"${WORK_AT_RISK_ROOTS:-$HOME/github}"
            found="$(scan "${roots[@]}")"
        fi
        [ -n "$found" ] || exit 0
        total=$(printf '%s\n' "$found" | wc -l | tr -d ' ')
        echo "Work that exists only on this disk ($total checkouts):"
        printf '%s\n' "$found" | describe | head -20
        [ "$total" -gt 20 ] && echo "- and $((total - 20)) more: ~/.claude/hooks/work-at-risk.sh scan <dir>"
        echo "Tell the user about these when they ask what is open. Commit and push your own; do not touch a worktree another session is using."
        ;;

    stop)
        input="$(cat 2>/dev/null || true)"
        # Already nudged this stop: let the agent finish.
        [ "$(json_field .stop_hook_active)" = "true" ] && exit 0
        cwd="$(json_field .cwd)"
        cwd="${cwd:-$PWD}"
        git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
        # Only a linked worktree: that is where sessions do branch work. The
        # primary checkout and plain folders are left alone.
        git_dir=$(git -C "$cwd" rev-parse --path-format=absolute --git-dir 2>/dev/null)
        common_dir=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
        [ -n "$git_dir" ] && [ "$git_dir" != "$common_dir" ] || exit 0
        top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
        found="$(one "$top")"
        [ -n "$found" ] || exit 0
        {
            echo "This worktree holds work that exists only on this disk:"
            printf '%s\n' "$found" | describe
            echo "Before you stop: commit it (a work-in-progress commit is fine), push the branch, and open a draft pull request if the branch has none. On a detached HEAD, create a branch first. If you cannot, say so and why in your reply."
        } >&2
        exit 2
        ;;

    *)
        echo "usage: work-at-risk.sh stop | start | scan [dir ...]" >&2
        exit 0
        ;;
esac
exit 0
