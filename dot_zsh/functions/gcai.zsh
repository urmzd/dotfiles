# AI-powered git commit using Claude (unified gcai)
# Usage: gcai [--staged|-s] [--model|-m MODEL] [--dry-run|-n] [--debug|-d]

# --- Helpers ---

_gcai_display_plan() {
  local plan="$1"
  local commit_count=$(printf '%s\n' "$plan" | jq '.commits | length')

  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "                   COMMIT PLAN"
  echo "═══════════════════════════════════════════════════════"

  for i in $(seq 0 $((commit_count - 1))); do
    local order=$(printf '%s\n' "$plan" | jq -r ".commits[$i].order // $((i + 1))")
    local msg=$(printf '%s\n' "$plan" | jq -r ".commits[$i].message")
    local body=$(printf '%s\n' "$plan" | jq -r ".commits[$i].body // empty")
    local footer=$(printf '%s\n' "$plan" | jq -r ".commits[$i].footer // empty")
    local files=$(printf '%s\n' "$plan" | jq -r ".commits[$i].files[]")
    local fc=$(printf '%s\n' "$files" | grep -c . 2>/dev/null || echo "0")

    echo ""
    echo "  [$order] $msg"
    [[ -n "$body" ]] && echo "       $body"
    [[ -n "$footer" ]] && echo "       $footer"
    echo "       Files ($fc): $(printf '%s\n' "$files" | head -5 | tr '\n' ' ')$([ "$fc" -gt 5 ] && echo "...")"
  done

  echo ""
  echo "═══════════════════════════════════════════════════════"
}

_gcai_validate_plan() {
  local plan="$1"

  # Extract all files from all commits, find duplicates
  local dupes
  dupes=$(printf '%s\n' "$plan" | jq -r '.commits[].files[]' | sort | uniq -d)

  if [[ -z "$dupes" ]]; then
    # No shared files — plan is clean
    printf '%s\n' "$plan"
    return 0
  fi

  echo "" >&2
  echo "Notice: shared files detected across commits — merging affected commits." >&2
  echo "Shared files: $(echo "$dupes" | tr '\n' ' ')" >&2

  # Build a jq filter that partitions commits into tainted/clean, then merges tainted
  local merged
  merged=$(printf '%s\n' "$plan" | jq --arg dupes "$dupes" '
    # Split duplicate file list into an array
    ($dupes | split("\n") | map(select(. != ""))) as $dup_list |

    # Partition commits
    .commits | group_by(
      [.files[] | select(. as $f | $dup_list | any(. == $f))] | length > 0
    ) |

    # group_by produces [[false-group], [true-group]] sorted by key
    (map(select(.[0].files as $f |
      [$f[] | select(. as $ff | $dup_list | any(. == $ff))] | length == 0
    )) | flatten) as $clean |

    (map(select(.[0].files as $f |
      [$f[] | select(. as $ff | $dup_list | any(. == $ff))] | length > 0
    )) | flatten) as $tainted |

    # Merge all tainted commits into one
    ($tainted | {
      order: 1,
      message: (if length == 1 then .[0].message
                else .[0].message end),
      body: ([.[] | .body // empty] | join("\n\n")),
      footer: ([.[] | .footer // empty | select(. != "")] | join("\n")),
      files: ([.[] | .files[]] | unique)
    }) as $merged |

    # Re-number: merged first, then clean commits
    {
      commits: (
        [$merged] +
        [$clean[] | .order = null] |
        to_entries |
        map(.value.order = (.key + 1) | .value)
      )
    }
  ')

  if [[ $? -ne 0 ]] || [[ -z "$merged" ]]; then
    echo "Warning: plan merge failed, using original plan" >&2
    printf '%s\n' "$plan"
    return 0
  fi

  printf '%s\n' "$merged"
  return 2
}

_gcai_execute() {
  local plan="$1"
  local commit_count=$(printf '%s\n' "$plan" | jq '.commits | length')
  local git_root
  git_root=$(git rev-parse --show-toplevel)

  # Run from repo root so repo-relative paths resolve correctly
  pushd "$git_root" >/dev/null
  {
    # Unstage everything first
    git reset HEAD --quiet 2>/dev/null

    for i in $(seq 0 $((commit_count - 1))); do
      local msg=$(printf '%s\n' "$plan" | jq -r ".commits[$i].message")
      local body=$(printf '%s\n' "$plan" | jq -r ".commits[$i].body // empty")
      local footer=$(printf '%s\n' "$plan" | jq -r ".commits[$i].footer // empty")
      local files=$(printf '%s\n' "$plan" | jq -r ".commits[$i].files[]")

      echo ""
      echo "Creating commit $((i + 1))/$commit_count: $msg"

      # Stage files for this commit
      local staged_count=0
      while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        if [[ -e "$file" ]] || git ls-files --deleted 2>/dev/null | grep -q "^${file}$"; then
          git add -- "$file" 2>/dev/null && ((staged_count++))
        else
          echo "  Warning: file not found: $file"
        fi
      done <<< "$files"

      # Build full commit message
      local full_message="$msg"
      if [[ -n "$body" ]]; then
        full_message="${full_message}

${body}"
      fi
      if [[ -n "$footer" ]]; then
        full_message="${full_message}

${footer}"
      fi

      # Create commit
      if [[ -n "$(git diff --cached --name-only)" ]]; then
        printf '%s\n' "$full_message" | git commit -F -
      else
        echo "  Warning: no files staged for this commit (may already be committed or missing)"
      fi
    done

    echo ""
    echo "Done! Recent commits:"
    git --no-pager log --oneline "-${commit_count}"
  } always {
    popd >/dev/null 2>&1
  }
}

_gcai_call_claude() {
  local model="$1"
  local budget="$2"
  local staged_only="$3"
  local debug="$4"

  local git_root
  git_root=$(git rev-parse --show-toplevel)

  local schema='{
    "type": "object",
    "properties": {
      "commits": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "order": { "type": "integer" },
            "message": { "type": "string", "description": "Header: type(scope): subject — imperative, lowercase, no period, max 72 chars" },
            "body": { "type": "string", "description": "Body: explain WHY the change was made, wrap at 72 chars" },
            "footer": { "type": "string", "description": "Footer: BREAKING CHANGE notes, Closes/Fixes/Refs #issue, etc." },
            "files": { "type": "array", "items": { "type": "string" } }
          },
          "required": ["order", "message", "body", "files"]
        }
      }
    },
    "required": ["commits"]
  }'

  local system_prompt="You are an expert at analyzing git diffs and creating atomic, well-organized commits following the Angular Conventional Commits standard.

HEADER (\"message\" field):
- Must match this regex: (?s)(build|bump|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\\(\\S+\\))?!?: ([^\\n\\r]+)((\\n\\n.*)|(\\s*))?$
- Format: type(scope): subject
- Valid types ONLY: build, bump, chore, ci, docs, feat, fix, perf, refactor, revert, style, test
- NEVER invent types. Words like db, auth, api, etc. are scopes, not types. Use the semantically correct type for the change (e.g. feat(db): add user cache migration, fix(auth): resolve token expiry)
- scope is optional but recommended when applicable
- subject: imperative mood, lowercase first letter, no period at end, max 72 chars

BODY (\"body\" field — required):
- Explain WHY the change was made, not what changed (the diff shows that)
- Use imperative tense (\"add\" not \"added\")
- Wrap at 72 characters

FOOTER (\"footer\" field — optional):
- BREAKING CHANGE: description of what breaks and migration path
- Closes #N, Fixes #N, Refs #N for issue references
- Only include when relevant

COMMIT ORGANIZATION:
- Each commit must be atomic: one logical change per commit
- Every changed file must appear in exactly one commit
- CRITICAL: A file must NEVER appear in more than one commit. The execution engine stages entire files, not individual hunks. Splitting one file across commits will fail.
- If one file contains multiple logical changes, place it in the most fitting commit and note the secondary changes in that commit's body.
- Order: infrastructure/config -> core library -> features -> tests -> docs
- File paths must be relative to the repository root and match exactly as git reports them"

  local user_prompt
  if [[ "$staged_only" -eq 1 ]]; then
    user_prompt="Analyze the staged git changes and group them into atomic commits.
Use \`git diff --cached\` and \`git diff --cached --stat\` to inspect what's staged."
  else
    user_prompt="Analyze all git changes (staged, unstaged, and untracked) and group them into atomic commits.
Use \`git diff HEAD\`, \`git diff --cached\`, \`git diff\`, \`git status --porcelain\`, and \`git ls-files --others --exclude-standard\` to inspect changes."
  fi

  [[ "$debug" -eq 1 ]] && echo "[DEBUG] Calling Claude (model=$model, budget=$budget)..." >&2

  pushd "$git_root" >/dev/null
  local raw_response
  raw_response=$(claude \
    --model "$model" \
    --allowed-tools "Bash(git:*)" \
    --json-schema "$schema" \
    --output-format json \
    --max-budget-usd "$budget" \
    --system-prompt "$system_prompt" \
    -p "$user_prompt" 2>&1)

  local exit_code=$?
  popd >/dev/null

  if [[ "$debug" -eq 1 ]]; then
    echo "[DEBUG] Claude exit code: $exit_code" >&2
    echo "[DEBUG] Raw response (first 500 chars): ${raw_response:0:500}" >&2
  fi

  if [[ "$exit_code" -ne 0 ]]; then
    echo "error: Claude CLI failed (exit $exit_code)" >&2
    [[ "$debug" -eq 1 ]] && echo "[DEBUG] Full response: $raw_response" >&2
    return 1
  fi

  # With --json-schema + --output-format json, structured output is in .structured_output
  local parsed
  parsed=$(printf '%s\n' "$raw_response" | jq '.structured_output' 2>/dev/null)

  if [[ -z "$parsed" ]] || [[ "$parsed" == "null" ]]; then
    echo "error: empty structured_output from Claude" >&2
    [[ "$debug" -eq 1 ]] && echo "[DEBUG] Full response: $raw_response" >&2
    return 1
  fi

  printf '%s\n' "$parsed"
}

# --- Main function ---

gcai() {
  # Catch Ctrl-C for clean exit (zsh scopes this trap to the function call)
  trap 'echo "\nInterrupted"; return 130' INT

  local staged_only=0
  local model="${GCAI_MODEL:-haiku}"
  local budget="${GCAI_BUDGET:-0.50}"
  local debug="${GCAI_DEBUG:-0}"
  local dry_run=0

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --staged|-s)  staged_only=1; shift ;;
      --model|-m)   model="$2"; shift 2 ;;
      --dry-run|-n) dry_run=1; shift ;;
      --debug|-d)   debug=1; shift ;;
      --help|-h)
        echo "Usage: gcai [--staged|-s] [--model|-m MODEL] [--dry-run|-n] [--debug|-d]"
        echo ""
        echo "Options:"
        echo "  --staged, -s    Only analyze staged changes (default: all changes)"
        echo "  --model, -m     Claude model to use (default: haiku, env: GCAI_MODEL)"
        echo "  --dry-run, -n   Display plan without executing"
        echo "  --debug, -d     Show debug info (env: GCAI_DEBUG=1)"
        echo ""
        echo "Environment:"
        echo "  GCAI_MODEL      Default model (default: haiku)"
        echo "  GCAI_BUDGET     Max budget in USD (default: 0.50)"
        echo "  GCAI_DEBUG      Enable debug output (0/1)"
        return 0
        ;;
      *) echo "Unknown option: $1"; return 1 ;;
    esac
  done

  # Check we're in a git repo
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "Not in a git repository"
    return 1
  fi

  # Check for changes
  local has_changes=0
  if [[ "$staged_only" -eq 1 ]]; then
    [[ -n "$(git diff --cached --name-only)" ]] && has_changes=1
  else
    [[ -n "$(git status --porcelain)" ]] && has_changes=1
  fi

  if [[ "$has_changes" -eq 0 ]]; then
    echo "No changes to commit"
    return 1
  fi

  echo "Analyzing changes with Claude..."

  # Call Claude (it will inspect the repo itself via git tools)
  local plan
  plan=$(_gcai_call_claude "$model" "$budget" "$staged_only" "$debug")

  if [[ $? -ne 0 ]] || [[ -z "$plan" ]]; then
    echo "Failed to generate commit plan"
    return 1
  fi

  # Validate plan has commits
  local commit_count
  commit_count=$(printf '%s\n' "$plan" | jq '.commits | length' 2>/dev/null)
  if [[ -z "$commit_count" ]] || [[ "$commit_count" -eq 0 ]]; then
    echo "No commits in plan"
    return 1
  fi

  # Validate no shared files across commits; merge if needed
  plan=$(_gcai_validate_plan "$plan")

  # Display plan
  _gcai_display_plan "$plan"

  if [[ "$dry_run" -eq 1 ]]; then
    echo ""
    echo "(dry run - no commits created)"
    return 0
  fi

  # Confirm
  echo ""
  read "confirm?Execute this plan? [y/N] "
  if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "Cancelled"
    return 1
  fi

  # Execute
  _gcai_execute "$plan"
}
