#!/bin/bash
# Smart tmux window naming based on current context

dir=$(basename "$PWD")

# Check for git repo
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    repo=$(basename "$(git rev-parse --show-toplevel)")
    branch=$(git branch --show-current 2>/dev/null || echo "HEAD")
    name="$repo:$branch"
else
    name="$dir"
fi

# Detect project type (check at repo root if in git repo)
root="${PWD}"
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    root=$(git rev-parse --show-toplevel)
fi

prefix=""
if [[ -f "$root/package.json" ]]; then
    prefix="js"
elif [[ -f "$root/Cargo.toml" ]]; then
    prefix="rs"
elif [[ -f "$root/pyproject.toml" ]] || [[ -f "$root/setup.py" ]]; then
    prefix="py"
elif [[ -f "$root/go.mod" ]]; then
    prefix="go"
elif [[ -f "$root/flake.nix" ]] || [[ -f "$root/shell.nix" ]]; then
    prefix="nix"
fi

if [[ -n "$prefix" ]]; then
    echo "[$prefix] $name"
else
    echo "$name"
fi
