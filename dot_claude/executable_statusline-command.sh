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
  @sh "plan_file=\(.plan_file // "")"
')"

if [ "$window_size" -le 0 ] 2>/dev/null; then
  printf "[....................] --%% | ?"
  exit 0
fi

fmt_k() {
  local n=$1
  if [ "$n" -ge 1000 ]; then
    printf "%sK" "$((n / 1000))"
  else
    printf "%s" "$n"
  fi
}

used_pct=$(awk 'BEGIN { printf "%d", int('"$used_pct"') }')
used_tokens=$((used_pct * window_size / 100))

# Progress bar (20 chars)
bar_w=20
filled=$((used_pct * bar_w / 100))
empty=$((bar_w - filled))
bar=$(printf '%*s' "$filled" '' | tr ' ' '#')$(printf '%*s' "$empty" '' | tr ' ' '.')

# Tip based on usage severity
if [ "$used_pct" -le 50 ]; then
  tip=""
elif [ "$used_pct" -le 75 ]; then
  tip=" | Summarize if stuck"
elif [ "$used_pct" -le 90 ]; then
  tip=" | ! Consider /compact"
else
  tip=" | !! /compact or /clear"
fi

# Format cost
cost_fmt=$(awk 'BEGIN { printf "$%.2f", '"$cost"' }')

# Format duration as Xh Ym or Ym Xs
total_s=$((duration_ms / 1000))
hrs=$((total_s / 3600))
mins=$(( (total_s % 3600) / 60 ))
if [ "$hrs" -gt 0 ]; then
  duration="${hrs}h${mins}m"
else
  duration="${mins}m"
fi

# Lines changed
diff_stat="+${lines_added}/-${lines_removed}"

# Plan (only if set)
plan=""
if [ -n "$plan_file" ]; then
  plan_name=$(basename "$plan_file")
  plan=" | plan:${plan_name}"
fi

printf "[%s] %s%% %s/%s%s | %s %s %s %s%s" \
  "$bar" \
  "$used_pct" \
  "$(fmt_k "$used_tokens")" \
  "$(fmt_k "$window_size")" \
  "$tip" \
  "$model" \
  "$cost_fmt" \
  "$duration" \
  "$diff_stat" \
  "$plan"
