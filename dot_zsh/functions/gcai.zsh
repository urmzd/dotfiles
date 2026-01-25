# AI-powered git commit using Claude
gcai() {
  local diff=$(git diff --cached)

  if [ -z "$diff" ]; then
    echo "No staged changes to commit"
    return 1
  fi

  echo "Generating commit message with Claude..."

  local message=$(echo "$diff" | claude -p "Generate a concise, professional git commit message following the Angular Conventional Commits format (feat:, fix:, refactor:, docs:, chore:, etc.) for these code changes.

Rules:
- Use imperative mood in subject line
- Subject line max 72 characters
- Add body if changes are complex (separated by blank line)
- Body should explain WHY, not WHAT
- Include scope in parentheses if applicable (e.g., feat(api): ...)

Return ONLY the commit message, nothing else:")

  if [ -z "$message" ]; then
    echo "Failed to generate commit message"
    return 1
  fi

  echo "Generated message:"
  echo "---"
  echo "$message"
  echo "---"

  read "confirm?Commit with this message? [y/N/e(dit)] "
  case "$confirm" in
    [yY])
      git commit -m "$message"
      ;;
    [eE])
      git commit -e -m "$message"
      ;;
    *)
      echo "Commit cancelled"
      return 1
      ;;
  esac
}
