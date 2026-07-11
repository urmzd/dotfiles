#!/usr/bin/env bash
# WorktreeCreate hook: force every Claude Code worktree into
# <repo-root>/.worktrees/<name> instead of the default .claude/worktrees/.
#
# Contract (https://code.claude.com/docs/en/hooks#worktreecreate):
#   stdin  = JSON with .name (slug) and .base_path (launch project dir)
#   stdout = absolute path of the created worktree
#   any non-zero exit aborts worktree creation
#
# Policy this enforces (see the use-worktrees skill):
#   1. Worktrees live at <repo-root>/.worktrees/, in the target repo's own
#      primary checkout, even when a session in one project spawns worktrees
#      for another.
#   2. .worktrees/ is always ignored (global gitignore on our machines; the
#      hook also writes .git/info/exclude so shared repos stay clean without
#      mutating their tracked .gitignore).
#   3. The primary checkout is never switched: new work branches from the
#      default branch into the worktree; main stays put.
set -euo pipefail

input="$(cat)"

json_field() {
    if command -v jq >/dev/null 2>&1; then
        jq -r --arg k "$1" '.[$k] // empty' <<<"$input"
    else
        python3 -c 'import json,sys; print(json.load(sys.stdin).get(sys.argv[1]) or "")' "$1" <<<"$input"
    fi
}

name="$(json_field name)"
base_path="$(json_field base_path)"

if [ -z "$name" ]; then
    echo "worktree-create: hook input has no worktree name" >&2
    exit 1
fi

cd "${base_path:-$PWD}"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "worktree-create: $PWD is not a git repository" >&2
    exit 1
fi

# Resolve the PRIMARY checkout root. If the session is already inside a
# worktree, the common git dir points back at the main checkout, so new
# worktrees never nest.
common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
root="$(dirname "$common_dir")"
wt_root="$root/.worktrees"
mkdir -p "$wt_root"

# Belt and braces on top of the global gitignore: mark .worktrees/ ignored in
# the repo-local exclude file (never the tracked .gitignore of a shared repo).
if ! git -C "$root" check-ignore -q .worktrees 2>/dev/null; then
    mkdir -p "$common_dir/info"
    printf '.worktrees/\n' >>"$common_dir/info/exclude"
fi

# Unique path + branch. Branch naming mirrors Claude Code's default
# (worktree-<name>) so cleanup tooling can recognize auto-created branches.
slug="$name"
i=2
while [ -e "$wt_root/$slug" ] || git -C "$root" show-ref --verify -q "refs/heads/worktree-$slug"; do
    slug="$name-$i"
    i=$((i + 1))
done
path="$wt_root/$slug"
branch="worktree-$slug"

# Base ref: honor worktree.baseRef ("fresh" default, "head" opt-in), matching
# the built-in semantics. "fresh" branches from the remote default branch so
# the primary checkout's branch is never involved, let alone switched.
base_ref="HEAD"
base_setting="fresh"
if command -v jq >/dev/null 2>&1 && [ -f "$HOME/.claude/settings.json" ]; then
    base_setting="$(jq -r '.worktree.baseRef // "fresh"' "$HOME/.claude/settings.json" 2>/dev/null || echo fresh)"
fi
if [ "$base_setting" != "head" ]; then
    default_ref="$(git -C "$root" symbolic-ref -q --short refs/remotes/origin/HEAD || true)"
    if [ -z "$default_ref" ]; then
        # origin/HEAD is unset on fresh clones of some remotes; derive it once.
        git -C "$root" remote set-head origin --auto >/dev/null 2>&1 || true
        default_ref="$(git -C "$root" symbolic-ref -q --short refs/remotes/origin/HEAD || true)"
    fi
    [ -n "$default_ref" ] && base_ref="$default_ref"
fi

git -C "$root" worktree add -b "$branch" "$path" "$base_ref" >&2

# With a WorktreeCreate hook, Claude Code skips .worktreeinclude processing,
# so replicate it: copy gitignored files matching the listed patterns.
if [ -f "$root/.worktreeinclude" ]; then
    while IFS= read -r pat || [ -n "$pat" ]; do
        case "$pat" in '' | '#'*) continue ;; esac
        git -C "$root" ls-files -z --others --ignored --exclude-standard \
            -- ":(glob)$pat" ":(glob)**/$pat" ":(exclude).worktrees" 2>/dev/null |
            sort -zu |
            while IFS= read -r -d '' f; do
                [ -f "$root/$f" ] || continue
                mkdir -p "$path/$(dirname "$f")"
                cp -p "$root/$f" "$path/$f"
            done
    done <"$root/.worktreeinclude"
fi

printf '%s\n' "$path"
