# AI-powered git commit using Claude
gcai() {
  local debug=${GCAI_DEBUG:-0}
  local git_root=$(git rev-parse --show-toplevel)
  local staged_files=$(git diff --cached --name-only)

  if [ -z "$staged_files" ]; then
    echo "No staged changes to commit"
    return 1
  fi

  echo "Analyzing staged changes..."

  if [ "$debug" -eq 1 ]; then
    echo "[DEBUG] Staged files: $(echo "$staged_files" | tr '\n' ', ' | sed 's/,$//')"
    echo "[DEBUG] Calling Claude CLI..."
  fi

  # Get structured commit plan from Claude
  local raw_response
  local plan

  raw_response=$(claude --model haiku --output-format json -p "Analyze the staged git changes (run git diff --cached). Return a JSON array of atomic commits.

Each commit object: {\"message\": \"conventional commit message\", \"files\": [\"file1.txt\", \"file2.txt\"]}

Return ONLY the JSON array, no explanation." 2>&1)

  local claude_exit_code=$?

  if [ "$debug" -eq 1 ]; then
    echo "[DEBUG] Claude CLI exit code: $claude_exit_code"
    echo "[DEBUG] Raw response (first 500 chars): ${raw_response:0:500}"
  fi

  if [ $claude_exit_code -ne 0 ]; then
    if [ "$debug" -eq 1 ]; then
      echo "[DEBUG] Claude CLI stderr: $raw_response"
    fi
    echo "Failed to generate commit plan"
    return 1
  fi

  if [ "$debug" -eq 1 ]; then
    local extracted=$(printf '%s\n' "$raw_response" | jq -r '.result')
    echo "[DEBUG] Extracted result before sed:"
    printf '%s\n' "$extracted" | head -n 20
    echo "[DEBUG] After sed (removing backticks):"
    printf '%s\n' "$extracted" | sed '/^```/d' | head -n 20
  fi

  plan=$(printf '%s\n' "$raw_response" | jq -r '.result' | sed '/^```/d' | jq '.')
  local jq_exit_code=$?

  if [ "$debug" -eq 1 ]; then
    echo "[DEBUG] jq exit code: $jq_exit_code"
    echo "[DEBUG] Plan after parsing (first 500 chars): ${plan:0:500}"
  fi

  if [ -z "$plan" ] || [ "$plan" = "null" ]; then
    echo "Failed to generate commit plan"
    return 1
  fi

  echo "Commit plan:"
  echo "$plan" | jq -r '.[] | "- \(.message)\n  Files: \(.files | join(", "))\n"'

  read "confirm?Proceed with commits? [y/N] "
  if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "Cancelled"
    return 1
  fi

  # Unstage everything first
  git reset HEAD --quiet

  # Process each commit
  local commits=("${(@f)$(echo "$plan" | jq -c '.[]')}")
  for commit in "${commits[@]}"; do
    local message=$(echo "$commit" | jq -r '.message')
    local files=("${(@f)$(echo "$commit" | jq -r '.files[]')}")

    for file in "${files[@]}"; do
      if ! git add "$git_root/$file"; then
        echo "Failed to stage file: $file"
        return 1
      fi
    done

    if ! git commit -m "$message"; then
      echo "Commit failed: $message"
      return 1
    fi
  done

  echo "Done!"
}
