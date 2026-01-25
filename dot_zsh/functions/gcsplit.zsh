# AI-powered git commit splitting using Claude
gcsplit() {
  local staged=$(git diff --cached --name-only)
  local unstaged=$(git diff --name-only)
  local untracked=$(git ls-files --others --exclude-standard)

  # Combine all changes
  local all_files=""
  [ -n "$staged" ] && all_files="$staged"
  [ -n "$unstaged" ] && all_files="${all_files:+$all_files\n}$unstaged"
  [ -n "$untracked" ] && all_files="${all_files:+$all_files\n}$untracked"

  if [ -z "$all_files" ]; then
    echo "No changes to commit"
    return 1
  fi

  # Get the full diff for context
  local full_diff=$(git diff HEAD 2>/dev/null || git diff --cached)
  [ -n "$untracked" ] && full_diff="${full_diff}\n\n$(echo "$untracked" | while read f; do echo "NEW FILE: $f"; head -50 "$f" 2>/dev/null; done)"

  echo "Analyzing changes with Claude..."
  echo "Files changed: $(echo -e "$all_files" | wc -l | tr -d ' ')"

  # Build the input data
  local input_data="FILES CHANGED:
$all_files

DIFF CONTENT:
$full_diff"

  # Get Claude's analysis - pipe data as stdin with instructions as prompt
  local analysis=$(echo "$input_data" | claude -p "Analyze these git changes and suggest how to split them into logical conventional commits.

INSTRUCTIONS:
1. Group files by logical feature/change
2. Order commits by dependencies (foundations first)
3. Use Angular Conventional Commits (feat, fix, refactor, docs, chore, ci, test, perf, build)
4. Include scope when applicable

OUTPUT FORMAT (JSON array):
[{\"order\": 1, \"message\": \"chore(db): add migrations for feature X\", \"body\": \"Optional body explaining why\", \"files\": [\"path/to/file1.py\", \"path/to/file2.py\"]}, ...]

Return ONLY valid JSON, no markdown or explanation.")

  if [ -z "$analysis" ] || ! echo "$analysis" | jq -e . >/dev/null 2>&1; then
    echo "Failed to parse Claude's response"
    echo "Raw response: $analysis"
    return 1
  fi

  # Show the plan
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "                    COMMIT SPLIT PLAN"
  echo "═══════════════════════════════════════════════════════════════"

  local commit_count=$(echo "$analysis" | jq 'length')

  for i in $(seq 0 $((commit_count - 1))); do
    local order=$(echo "$analysis" | jq -r ".[$i].order")
    local msg=$(echo "$analysis" | jq -r ".[$i].message")
    local body=$(echo "$analysis" | jq -r ".[$i].body // empty")
    local files=$(echo "$analysis" | jq -r ".[$i].files[]")
    local file_count=$(echo "$files" | wc -l | tr -d ' ')

    echo ""
    echo "[$order] $msg"
    [ -n "$body" ] && echo "    └─ $body"
    echo "    └─ Files ($file_count): $(echo "$files" | head -3 | tr '\n' ' ')$([ $file_count -gt 3 ] && echo "...")"
  done

  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo ""

  read "confirm?Execute this plan? [y/N/s(ave)] "
  case "$confirm" in
    [yY])
      _gcsplit_execute "$analysis"
      ;;
    [sS])
      local plan_file="/tmp/gcsplit_plan_$(date +%s).json"
      echo "$analysis" > "$plan_file"
      echo "Plan saved to: $plan_file"
      echo "To execute later: gcsplit_exec $plan_file"
      ;;
    *)
      echo "Cancelled"
      return 1
      ;;
  esac
}

# Execute a commit split plan
_gcsplit_execute() {
  local plan="$1"
  local commit_count=$(echo "$plan" | jq 'length')

  # Unstage everything first
  git reset HEAD >/dev/null 2>&1

  for i in $(seq 0 $((commit_count - 1))); do
    local msg=$(echo "$plan" | jq -r ".[$i].message")
    local body=$(echo "$plan" | jq -r ".[$i].body // empty")
    local files=$(echo "$plan" | jq -r ".[$i].files[]")

    echo ""
    echo "Creating commit $((i + 1))/$commit_count: $msg"

    # Stage files for this commit
    local staged_count=0
    echo "$files" | while read -r file; do
      if [ -e "$file" ] || git ls-files --deleted | grep -q "^$file$"; then
        git add "$file" 2>/dev/null && ((staged_count++))
      fi
    done

    # Create commit
    if [ -n "$(git diff --cached --name-only)" ]; then
      if [ -n "$body" ]; then
        git commit -m "$msg" -m "$body"
      else
        git commit -m "$msg"
      fi
      echo "  ✓ Committed"
    else
      echo "  ⚠ No files staged for this commit (may already be committed or missing)"
    fi
  done

  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "                    COMPLETE"
  echo "═══════════════════════════════════════════════════════════════"
  git log --oneline -$commit_count
}

# Execute a saved plan
gcsplit_exec() {
  local plan_file="$1"
  if [ ! -f "$plan_file" ]; then
    echo "Plan file not found: $plan_file"
    return 1
  fi
  _gcsplit_execute "$(cat "$plan_file")"
}
