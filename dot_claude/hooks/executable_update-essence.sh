#!/usr/bin/env bash
set -euo pipefail

ESSENCE_FILE="$HOME/.local/share/chezmoi/common/ESSENCE.md"
PLANS_DIR="$HOME/.claude/plans"

# Find the most recently modified plan file
LATEST_PLAN=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)
[ -z "$LATEST_PLAN" ] && exit 0

# Extract the plan title (first H1)
TITLE=$(grep -m1 '^# ' "$LATEST_PLAN" | sed 's/^# //')
[ -z "$TITLE" ] && exit 0

DATE=$(date -u +%Y-%m-%d)

# Append if not already recorded
if ! grep -qF "$TITLE" "$ESSENCE_FILE" 2>/dev/null; then
  printf '\n## %s\n\n- **Plan**: %s\n- **Source**: `%s`\n' "$DATE" "$TITLE" "$(basename "$LATEST_PLAN")" >> "$ESSENCE_FILE"
fi
