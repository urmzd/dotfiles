#!/bin/bash
input=$(cat)

total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

if [ "$window_size" -gt 0 ] 2>/dev/null; then
  total=$((total_input + total_output))
  pct=$(awk "BEGIN { printf \"%.0f\", ($total / $window_size) * 100 }")

  if [ "$pct" -le 50 ]; then
    level="HIGH"
  elif [ "$pct" -le 80 ]; then
    level="MED"
  else
    level="LOW"
  fi

  status="Context: ${total}/${window_size} (${pct}%) [${level}]"

  if [ "$level" = "LOW" ]; then
    status="${status} ⚠ Consider /clear"
    plan_file=$(echo "$input" | jq -r '.plan_file // empty')
    if [ -n "$plan_file" ]; then
      status="${status} | Plan: ${plan_file}"
    fi
  fi

  printf "%s" "$status"
else
  printf "Context: --"
fi
