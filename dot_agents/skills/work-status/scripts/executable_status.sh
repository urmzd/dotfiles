#!/usr/bin/env bash
# work-status: one read-only snapshot of in-flight work.
# Usage: status.sh [repo-or-folder ...]   (default: current directory)
# A folder that is not a git repo is scanned one level deep for repos.
# Prints tab-separated sections. Never writes, fetches, commits, or pushes.
set -uo pipefail

have() { command -v "$1" >/dev/null 2>&1; }

repos=()
add_repo() {
    local top
    top=$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
    top=$(dirname "$top")
    local r
    for r in ${repos[@]+"${repos[@]}"}; do [ "$r" = "$top" ] && return 0; done
    repos+=("$top")
}

[ $# -eq 0 ] && set -- "$PWD"
for arg in "$@"; do
    if ! add_repo "$arg"; then
        for d in "$arg"/*/; do
            [ -e "$d/.git" ] && add_repo "$d"
        done
    fi
done

if [ ${#repos[@]} -eq 0 ]; then
    echo "no git repositories found in: $*"
    exit 0
fi

echo "## PRIMARY"
printf 'repo\tbranch\tdefault\tdirty\tbehind\tflag\n'
for root in "${repos[@]}"; do
    name=$(basename "$root")
    branch=$(git -C "$root" branch --show-current 2>/dev/null)
    default=$(git -C "$root" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
    [ -n "$default" ] || default="?"
    dirty=$(git -C "$root" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    behind=$(git -C "$root" rev-list --count "HEAD..origin/$default" 2>/dev/null || echo "?")
    flag=""
    [ "$branch" != "$default" ] && [ "$default" != "?" ] && flag="OFF-DEFAULT"
    [ "$dirty" != "0" ] && flag="${flag:+$flag,}DIRTY-PRIMARY"
    [ "$behind" != "0" ] && [ "$behind" != "?" ] && flag="${flag:+$flag,}BEHIND"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "${branch:-detached}" "$default" "$dirty" "$behind" "${flag:-ok}"
done

echo
echo "## WORKTREES"
printf 'repo\tworktree\tbranch\tdirty\tahead\tlast-commit\tpr\tflag\n'
for root in "${repos[@]}"; do
    name=$(basename "$root")
    default=$(git -C "$root" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
    [ -n "$default" ] || default="HEAD"
    prs=""
    if have gh; then
        prs=$(cd "$root" && gh pr list --state all --limit 1000 \
            --json number,headRefName,state \
            --jq '.[] | "\(.headRefName)\t\(.number)\t\(.state)"' 2>/dev/null)
    fi
    git -C "$root" worktree list --porcelain 2>/dev/null |
        awk '/^worktree /{p=substr($0,10)} /^branch /{print p "\t" substr($0,19)} /^detached/{print p "\t(detached)"}' |
        while IFS=$'\t' read -r path br; do
            [ "$path" = "$root" ] && continue
            if [ ! -d "$path" ]; then
                printf '%s\t%s\t%s\t-\t-\t-\t-\tMISSING-DIR\n' "$name" "${path#"$root"/}" "$br"
                continue
            fi
            dirty=$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
            ahead=$(git -C "$path" rev-list --count "$default..HEAD" 2>/dev/null || echo "?")
            last=$(git -C "$path" log -1 --format=%cr 2>/dev/null)
            pr=$(printf '%s\n' "$prs" | awk -F'\t' -v b="$br" '$1==b{print "#" $2 " " $3; exit}')
            flag="ok"
            case "$pr" in
                *MERGED) if [ "$dirty" = "0" ]; then flag="REMOVE"; else flag="MERGED-BUT-DIRTY"; fi ;;
                *CLOSED) flag="PR-CLOSED" ;;
                "")
                    if [ "$ahead" = "0" ] && [ "$dirty" = "0" ]; then flag="EMPTY"
                    elif [ "$dirty" != "0" ]; then flag="UNCOMMITTED"
                    else flag="NO-PR"; fi ;;
                *) [ "$dirty" != "0" ] && flag="UNCOMMITTED" ;;
            esac
            printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "${path#"$root"/}" "$br" "$dirty" "$ahead" "$last" "${pr:--}" "$flag"
        done
done

echo
echo "## OPEN PRS"
if have gh; then
    printf 'repo\tpr\ttitle\tbranch\tdraft\tchecks\treview\tmerge-state\tflag\n'
    for root in "${repos[@]}"; do
        name=$(basename "$root")
        (cd "$root" && gh pr list --state open --limit 100 \
            --json number,title,headRefName,isDraft,reviewDecision,mergeStateStatus,statusCheckRollup \
            --jq '.[] | [
                "#\(.number)",
                (.title | .[0:60]),
                .headRefName,
                (if .isDraft then "draft" else "-" end),
                ((.statusCheckRollup // []) as $c
                    | ($c | map(select((.conclusion // .state // "") | test("FAILURE|ERROR|TIMED_OUT|CANCELLED"))) | length) as $f
                    | ($c | map(select(((.status // "") | test("IN_PROGRESS|QUEUED|PENDING")) or ((.state // "") == "PENDING"))) | length) as $p
                    | if ($c | length) == 0 then "none"
                      elif $f > 0 then "\($f) failing"
                      elif $p > 0 then "\($p) running"
                      else "green" end),
                (.reviewDecision // "" | if . == "" then "-" else . end),
                .mergeStateStatus
              ] | @tsv' 2>&1 || echo "$name	gh query failed") |
            while IFS=$'\t' read -r num title br draft checks review state; do
                flag="wait"
                if [ "$draft" = "draft" ]; then flag="DRAFT"
                elif [ "$state" = "DIRTY" ]; then flag="CONFLICT"
                elif [ "${checks#* }" = "failing" ]; then flag="FIX-CI"
                elif [ "$review" = "CHANGES_REQUESTED" ]; then flag="FIX-REVIEW"
                elif [ "$state" = "BEHIND" ]; then flag="UPDATE-BRANCH"
                elif [ "$checks" = "green" ] && [ "$state" = "CLEAN" ]; then flag="LAND"
                elif [ "$state" = "BLOCKED" ] && [ "$checks" = "green" ]; then flag="NEEDS-HUMAN"
                fi
                printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$num" "$title" "$br" "$draft" "$checks" "$review" "$state" "$flag"
            done
    done
else
    echo "gh not installed: skipped"
fi

echo
echo "## PANES"
if have tmux && tmux list-panes -a >/dev/null 2>&1; then
    printf 'pane\tid\tcommand\tcwd\tactive\tlast-line\n'
    tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}	#{pane_id}	#{pane_current_command}	#{pane_current_path}	#{?pane_active,*,}' |
        while IFS=$'\t' read -r pane id cmd cwd active; do
            last=$(tmux capture-pane -p -t "$id" 2>/dev/null | awk 'NF{l=$0} END{print substr(l,1,90)}')
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$pane" "$id" "$cmd" "${cwd/#$HOME/~}" "${active:--}" "$last"
        done
else
    echo "no tmux server: skipped"
fi

echo
echo "## LISTENERS"
if have lsof; then
    printf 'port\tpid\tcommand\tcwd\n'
    lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR>1{print $2 "\t" $1 "\t" $9}' | sort -u |
        while IFS=$'\t' read -r pid cmd addr; do
            port=${addr##*:}
            cwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | awk '/^n/{print substr($0,2)}')
            keep=""
            for root in "${repos[@]}"; do
                case "$cwd" in "$root"*) keep=1 ;; esac
            done
            [ -n "$keep" ] && printf '%s\t%s\t%s\t%s\n' "$port" "$pid" "$cmd" "${cwd/#$HOME/~}"
        done
else
    echo "lsof not installed: skipped"
fi

echo
echo "## MACHINE"
df -h "$HOME" 2>/dev/null | awk 'NR==2{print "disk free\t" $4 " (" $5 " used)"}'
if have go; then
    cache=$(go env GOCACHE 2>/dev/null)
    [ -d "$cache" ] && echo "go build cache	$(du -sh "$cache" 2>/dev/null | cut -f1)"
fi
if have docker && docker info >/dev/null 2>&1; then
    echo "containers running	$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')"
fi
