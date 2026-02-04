#!/bin/bash
input=$(cat)

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

if [ -n "$used" ]; then
  total=$((total_input + total_output))
  printf "Context: %s/%s (%.0f%%)" "$total" "$window_size" "$used"
else
  printf "Context: --"
fi
