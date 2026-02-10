#!/bin/bash
input=$(cat)

eval "$(echo "$input" | jq -r '
  @sh "used_pct=\(.context_window.used_percentage // 0)",
  @sh "window_size=\(.context_window.context_window_size // 0)",
  @sh "model=\(.model.display_name // "")",
  @sh "cost=\(.cost.total_cost_usd // 0)",
  @sh "duration_ms=\(.cost.total_duration_ms // 0)",
  @sh "lines_added=\(.cost.total_lines_added // 0)",
  @sh "lines_removed=\(.cost.total_lines_removed // 0)",
  @sh "project_dir=\(.workspace.project_dir // "")",
  @sh "transcript_path=\(.transcript_path // "")",
  @sh "vim_mode=\(.vim.mode // "")",
  @sh "agent_name=\(.agent.name // "")"
')"

# --- ANSI colors ---
RST=$'\033[0m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
DIM=$'\033[2m'
MAGENTA=$'\033[35m'
BLUE=$'\033[34m'
CYAN_UL=$'\033[36;4m'

# --- OSC 8 hyperlink helpers ---
LINK_OPEN=$'\033]8;;'
LINK_CLOSE=$'\033\\'

# --- Fallback ---
if [ "$window_size" -le 0 ] 2>/dev/null; then
  printf '%s\n' "[....................] --% | ?"
  exit 0
fi

# --- Helpers ---
fmt_k() {
  local n=$1
  if [ "$n" -ge 1000 ]; then
    printf "%sK" "$((n / 1000))"
  else
    printf "%s" "$n"
  fi
}

# --- Git caching ---
GIT_CACHE="/tmp/claude-statusline-git.cache"
GIT_TTL=5

file_is_fresh() {
  local file="$1" ttl="$2"
  [ -f "$file" ] || return 1
  local now file_mtime age
  now=$(date +%s)
  # macOS stat vs Linux stat
  if file_mtime=$(stat -f %m "$file" 2>/dev/null); then
    :
  else
    file_mtime=$(stat -c %Y "$file" 2>/dev/null) || return 1
  fi
  age=$((now - file_mtime))
  [ "$age" -lt "$ttl" ]
}

refresh_git_cache() {
  local dir="${project_dir:-.}"
  local branch="" staged=0 modified=0 remote=""

  if command -v git >/dev/null 2>&1 && git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null)
    staged=$(git -C "$dir" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    modified=$(git -C "$dir" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    remote=$(git -C "$dir" remote get-url origin 2>/dev/null)
  fi

  printf '%s\n%s\n%s\n%s\n' "$branch" "$staged" "$modified" "$remote" > "$GIT_CACHE"
}

if ! file_is_fresh "$GIT_CACHE" "$GIT_TTL"; then
  refresh_git_cache
fi

{
  IFS= read -r git_branch
  IFS= read -r git_staged
  IFS= read -r git_modified
  IFS= read -r git_remote
} < "$GIT_CACHE"

# --- Usage limit caching ---
USAGE_CACHE="/tmp/claude-statusline-usage.cache"
USAGE_TTL=60

refresh_usage_cache() {
  local creds token response five_hour seven_day
  creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null) || { echo "0 0" > "$USAGE_CACHE"; return; }
  token=$(echo "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null) || { echo "0 0" > "$USAGE_CACHE"; return; }
  [ -n "$token" ] || { echo "0 0" > "$USAGE_CACHE"; return; }
  response=$(curl -s --max-time 3 \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || { echo "0 0" > "$USAGE_CACHE"; return; }
  five_hour=$(echo "$response" | jq -r '.five_hour.utilization // 0' 2>/dev/null) || five_hour=0
  seven_day=$(echo "$response" | jq -r '.seven_day.utilization // 0' 2>/dev/null) || seven_day=0
  echo "$five_hour $seven_day" > "$USAGE_CACHE"
}

if ! file_is_fresh "$USAGE_CACHE" "$USAGE_TTL"; then
  refresh_usage_cache
fi

read -r usage_5h usage_7d < "$USAGE_CACHE" 2>/dev/null || { usage_5h=0; usage_7d=0; }

# --- Plan detection caching ---
PLAN_CACHE="/tmp/claude-statusline-plan.cache"
PLAN_TTL=10

refresh_plan_cache() {
  local plan_name=""
  if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    local match
    match=$(grep -o '\.claude/plans/[^"]*\.md' "$transcript_path" 2>/dev/null | tail -1)
    if [ -n "$match" ]; then
      plan_name=$(basename "$match" .md)
    fi
  fi
  echo "$transcript_path $plan_name" > "$PLAN_CACHE"
}

# Refresh if cache is stale or transcript_path changed
plan_name=""
if file_is_fresh "$PLAN_CACHE" "$PLAN_TTL"; then
  read -r cached_transcript cached_plan < "$PLAN_CACHE" 2>/dev/null
  if [ "$cached_transcript" = "$transcript_path" ]; then
    plan_name="$cached_plan"
  else
    refresh_plan_cache
    read -r _ plan_name < "$PLAN_CACHE" 2>/dev/null
  fi
else
  refresh_plan_cache
  read -r _ plan_name < "$PLAN_CACHE" 2>/dev/null
fi

# --- Convert SSH remote to HTTPS URL ---
github_url=""
if [ -n "$git_remote" ]; then
  if [[ "$git_remote" =~ ^git@([^:]+):(.+)\.git$ ]]; then
    github_url="https://${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  elif [[ "$git_remote" =~ ^git@([^:]+):(.+)$ ]]; then
    github_url="https://${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  elif [[ "$git_remote" =~ ^https?:// ]]; then
    github_url="${git_remote%.git}"
  fi
fi

# --- Line 1: Context ---
line1=""

# Model (cyan)
if [ -n "$model" ]; then
  line1="${CYAN}[${model}]${RST}"
fi

# Directory basename
if [ -n "$project_dir" ]; then
  dir_name=$(basename "$project_dir")
  line1="${line1} ${dir_name}"
fi

# Git branch + stats
if [ -n "$git_branch" ]; then
  line1="${line1} (${GREEN}${git_branch}${RST}"
  if [ "$git_staged" -gt 0 ] 2>/dev/null; then
    line1="${line1} ${YELLOW}+${git_staged}${RST}"
  fi
  if [ "$git_modified" -gt 0 ] 2>/dev/null; then
    line1="${line1} ${RED}~${git_modified}${RST}"
  fi
  line1="${line1})"
fi

# GitHub clickable link (OSC 8)
if [ -n "$github_url" ]; then
  line1="${line1} ${LINK_OPEN}${github_url}${LINK_CLOSE}${CYAN_UL}GitHub>${RST}${LINK_OPEN}${LINK_CLOSE}"
fi

# Plan status
if [ -n "$plan_name" ]; then
  line1="${line1} | ${GREEN}plan:${plan_name}${RST}"
else
  line1="${line1} | ${DIM}No plan${RST}"
fi

# Usage limits (color-coded)
color_for_pct() {
  local pct_int
  pct_int=$(awk "BEGIN { printf \"%d\", int($1 + 0.5) }")
  if [ "$pct_int" -ge 90 ]; then
    printf '%s' "$RED"
  elif [ "$pct_int" -ge 70 ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

five_hr_pct=$(awk "BEGIN { printf \"%d\", int(${usage_5h:-0} + 0.5) }")
seven_day_pct=$(awk "BEGIN { printf \"%d\", int(${usage_7d:-0} + 0.5) }")

if [ "$five_hr_pct" -gt 0 ] || [ "$seven_day_pct" -gt 0 ]; then
  c5=$(color_for_pct "${usage_5h:-0}")
  c7=$(color_for_pct "${usage_7d:-0}")
  line1="${line1} | ${c5}5h:${five_hr_pct}%${RST} ${c7}7d:${seven_day_pct}%${RST}"
fi

# --- Line 2: Metrics ---
used_pct=$(awk 'BEGIN { printf "%d", int('"$used_pct"') }')
used_tokens=$((used_pct * window_size / 100))

# Color-coded progress bar (20 chars)
bar_w=20
filled=$((used_pct * bar_w / 100))
empty=$((bar_w - filled))

if [ "$used_pct" -lt 70 ]; then
  bar_color="$GREEN"
elif [ "$used_pct" -lt 90 ]; then
  bar_color="$YELLOW"
else
  bar_color="$RED"
fi

bar_filled=$(printf "%${filled}s" '' | sed 's/ /█/g')
bar_empty=$(printf "%${empty}s" '' | sed 's/ /░/g')
bar="${bar_color}${bar_filled}${DIM}${bar_empty}${RST}"

# Cost (color-coded)
cost_val=$(awk 'BEGIN { printf "%.2f", '"$cost"' }')
cost_cmp=$(awk 'BEGIN { print ('"$cost"' > 5) ? "red" : ('"$cost"' >= 1) ? "yellow" : "green" }')
case "$cost_cmp" in
  red)    cost_fmt="${RED}\$${cost_val}${RST}" ;;
  yellow) cost_fmt="${YELLOW}\$${cost_val}${RST}" ;;
  *)      cost_fmt="${GREEN}\$${cost_val}${RST}" ;;
esac

# Duration
total_s=$((duration_ms / 1000))
hrs=$((total_s / 3600))
mins=$(( (total_s % 3600) / 60 ))
secs=$((total_s % 60))
if [ "$hrs" -gt 0 ]; then
  duration="${hrs}h${mins}m"
else
  duration="${mins}m${secs}s"
fi

# Lines changed
diff_stat="${GREEN}+${lines_added}${RST}/${RED}-${lines_removed}${RST}"

# Tip based on usage
tip=""
if [ "$used_pct" -gt 50 ] && [ "$used_pct" -le 75 ]; then
  tip=" | ${YELLOW}Summarize if stuck${RST}"
elif [ "$used_pct" -gt 75 ] && [ "$used_pct" -le 90 ]; then
  tip=" | ${YELLOW}! Consider /compact${RST}"
elif [ "$used_pct" -gt 90 ]; then
  tip=" | ${RED}!! /compact or /clear${RST}"
fi

# Vim mode
vim_indicator=""
if [ -n "$vim_mode" ]; then
  short_mode="${vim_mode:0:1}"
  vim_indicator=" | ${MAGENTA}vim:${short_mode}${RST}"
fi

# Agent name
agent_indicator=""
if [ -n "$agent_name" ]; then
  agent_indicator=" | ${BLUE}${agent_name}${RST}"
fi

line2="[${bar}] ${used_pct}% $(fmt_k "$used_tokens")/$(fmt_k "$window_size") | ${cost_fmt} ${duration} ${diff_stat}${tip}${vim_indicator}${agent_indicator}"

# --- Output ---
printf '%s\n%s\n' "$line1" "$line2"
