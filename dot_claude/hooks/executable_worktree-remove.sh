#!/usr/bin/env bash
# WorktreeRemove hook: clean up worktrees created by worktree-create.sh.
#
# Contract (https://code.claude.com/docs/en/hooks#worktreeremove):
#   stdin = JSON with .worktree_path; exit codes are non-blocking.
#
# Removal was already decided upstream (user prompt or auto-clean of an
# unchanged worktree), so this mirrors the built-in behavior: remove the
# worktree directory and its auto-created branch.
set -uo pipefail

input="$(cat)"

if command -v jq >/dev/null 2>&1; then
    path="$(jq -r '.worktree_path // empty' <<<"$input")"
else
    path="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("worktree_path") or "")' <<<"$input")"
fi

[ -n "$path" ] && [ -d "$path" ] || exit 0

# Only touch worktrees under a .worktrees/ directory; anything else was not
# created by our WorktreeCreate hook, so leave it to the default logic.
case "$path" in
*/.worktrees/*) ;;
*) exit 0 ;;
esac

branch="$(git -C "$path" branch --show-current 2>/dev/null || true)"
root="$(dirname "$(git -C "$path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" 2>/dev/null || true)"
[ -n "$root" ] || exit 0

git -C "$root" worktree remove --force "$path" >&2 || exit 0
# Delete only auto-created worktree-* branches, never user-named ones.
case "$branch" in
worktree-*) git -C "$root" branch -D "$branch" >&2 || true ;;
esac
exit 0
