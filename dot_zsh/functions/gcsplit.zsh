# AI-powered git commit splitting using Claude (optimized for long contexts)

# Helper: Get file stats (lines, words)
_gcsplit_file_stats() {
  local file="$1"
  if [ -f "$file" ]; then
    local lines=$(wc -l < "$file" 2>/dev/null | tr -d ' ')
    local words=$(wc -w < "$file" 2>/dev/null | tr -d ' ')
    echo "${lines}L ${words}W"
  else
    echo "deleted"
  fi
}

# Helper: Random sample N lines from diff (changed lines only)
_gcsplit_sample_diff() {
  local file="$1"
  local sample_size="${2:-15}"
  git diff HEAD -- "$file" 2>/dev/null | \
    grep -E '^[+-]' | \
    grep -v '^[+-]\{3\}' | \
    shuf -n "$sample_size" 2>/dev/null || \
    git diff HEAD -- "$file" 2>/dev/null | grep -E '^[+-]' | head -n "$sample_size"
}

# Helper: Get targeted diff excerpt
_gcsplit_targeted_diff() {
  local file="$1"
  local max_lines="${2:-100}"
  git diff HEAD -- "$file" 2>/dev/null | head -n "$max_lines"
}

gcsplit() {
  # Collect file lists
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

  # Deduplicate files
  all_files=$(echo -e "$all_files" | sort -u)
  local file_count=$(echo -e "$all_files" | wc -l | tr -d ' ')

  echo "═══════════════════════════════════════════════════════════════"
  echo "                    GCSPLIT - Context Optimized"
  echo "═══════════════════════════════════════════════════════════════"
  echo "Files to analyze: $file_count"
  echo ""

  # ═══════════════════════════════════════════════════════════════════
  # STAGE 1: Filename-only analysis
  # ═══════════════════════════════════════════════════════════════════
  echo "Stage 1/3: Analyzing file structure..."

  # Get change stats (lines added/deleted per file)
  local numstat=$(git diff --numstat HEAD 2>/dev/null)

  # Get directory structure
  local directories=$(echo -e "$all_files" | xargs -I{} dirname {} 2>/dev/null | sort -u)

  # Build Stage 1 input
  local stage1_input="FILES CHANGED:
$all_files

CHANGE STATS (added/deleted/filename):
$numstat

DIRECTORY STRUCTURE:
$directories"

  local stage1_result=$(echo "$stage1_input" | claude -p "Analyze these git changes based on file structure only.

INSTRUCTIONS:
1. Group files by directory, naming patterns, and file extensions
2. Identify obvious groupings (tests/, configs, feature folders, etc.)
3. Flag files that need content inspection to determine proper grouping
4. Use Angular Conventional Commits format (feat, fix, refactor, docs, chore, ci, test, perf, build)
5. Include scope when applicable

OUTPUT FORMAT (JSON only, no markdown):
{
  \"preliminary_commits\": [
    {\"order\": 1, \"message\": \"type(scope): description\", \"body\": \"optional why\", \"files\": [\"path/file1\"], \"confidence\": \"high\"}
  ],
  \"ambiguous_files\": [\"file_needing_content_review.py\"]
}

Return ONLY valid JSON.")

  if [ -z "$stage1_result" ] || ! echo "$stage1_result" | jq -e . >/dev/null 2>&1; then
    echo "Failed to parse Stage 1 response"
    echo "Raw: $stage1_result"
    return 1
  fi

  local ambiguous=$(echo "$stage1_result" | jq -r '.ambiguous_files[]?' 2>/dev/null)
  local ambiguous_count=$(echo "$ambiguous" | grep -c . 2>/dev/null || echo "0")

  echo "  ✓ Preliminary groupings created"
  [ "$ambiguous_count" -gt 0 ] && echo "  → $ambiguous_count files flagged for content review"

  # ═══════════════════════════════════════════════════════════════════
  # STAGE 2: Sample ambiguous files (if any)
  # ═══════════════════════════════════════════════════════════════════
  local final_result="$stage1_result"

  if [ -n "$ambiguous" ] && [ "$ambiguous_count" -gt 0 ]; then
    echo ""
    echo "Stage 2/3: Sampling $ambiguous_count ambiguous files..."

    # Build samples for ambiguous files
    local samples=""
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      local stats=$(_gcsplit_file_stats "$f")
      local sample=$(_gcsplit_sample_diff "$f" 15)
      samples+="=== $f ($stats) ===
$sample

"
    done <<< "$ambiguous"

    local stage2_input="STAGE 1 ANALYSIS:
$stage1_result

FILE SAMPLES (random lines from diff):
$samples"

    local stage2_result=$(echo "$stage2_input" | claude -p "Refine the commit groupings based on these file samples.

INSTRUCTIONS:
1. Assign each ambiguous file to the most appropriate commit
2. You may create new commits if samples reveal distinct features
3. Flag files that still cannot be classified (need full diff)

OUTPUT FORMAT (JSON only, no markdown):
{
  \"commits\": [
    {\"order\": 1, \"message\": \"type(scope): description\", \"body\": \"optional why\", \"files\": [\"path/file1\"]}
  ],
  \"needs_full_diff\": []
}

Return ONLY valid JSON.")

    if echo "$stage2_result" | jq -e . >/dev/null 2>&1; then
      final_result="$stage2_result"
      echo "  ✓ Ambiguous files assigned"

      local needs_full=$(echo "$stage2_result" | jq -r '.needs_full_diff[]?' 2>/dev/null)
      local needs_full_count=$(echo "$needs_full" | grep -c . 2>/dev/null || echo "0")

      # ═══════════════════════════════════════════════════════════════
      # STAGE 3: Full diff for stubborn files (if any)
      # ═══════════════════════════════════════════════════════════════
      if [ -n "$needs_full" ] && [ "$needs_full_count" -gt 0 ]; then
        echo ""
        echo "Stage 3/3: Deep analysis of $needs_full_count files..."

        local full_diffs=""
        while IFS= read -r f; do
          [ -z "$f" ] && continue
          full_diffs+="=== $f ===
$(_gcsplit_targeted_diff "$f" 100)

"
        done <<< "$needs_full"

        local stage3_input="STAGE 2 ANALYSIS:
$stage2_result

FULL DIFF EXCERPTS:
$full_diffs"

        local stage3_result=$(echo "$stage3_input" | claude -p "Finalize the commit plan with these full diff excerpts.

OUTPUT FORMAT (JSON only, no markdown):
{
  \"commits\": [
    {\"order\": 1, \"message\": \"type(scope): description\", \"body\": \"optional why\", \"files\": [\"path/file1\"]}
  ]
}

Return ONLY valid JSON.")

        if echo "$stage3_result" | jq -e . >/dev/null 2>&1; then
          final_result="$stage3_result"
          echo "  ✓ Deep analysis complete"
        fi
      else
        echo ""
        echo "Stage 3/3: Skipped (no files need full diff)"
      fi
    fi
  else
    echo ""
    echo "Stage 2/3: Skipped (no ambiguous files)"
    echo "Stage 3/3: Skipped"
  fi

  # ═══════════════════════════════════════════════════════════════════
  # Extract and display final plan
  # ═══════════════════════════════════════════════════════════════════
  local analysis=$(echo "$final_result" | jq -c '.commits // .preliminary_commits')

  if [ -z "$analysis" ] || [ "$analysis" = "null" ]; then
    echo ""
    echo "Failed to extract commit plan"
    return 1
  fi

  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "                    COMMIT SPLIT PLAN"
  echo "═══════════════════════════════════════════════════════════════"

  local commit_count=$(echo "$analysis" | jq 'length')

  for i in $(seq 0 $((commit_count - 1))); do
    local order=$(echo "$analysis" | jq -r ".[$i].order // $((i + 1))")
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
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      if [ -e "$file" ] || git ls-files --deleted | grep -q "^$file$"; then
        git add "$file" 2>/dev/null && ((staged_count++))
      fi
    done <<< "$files"

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
