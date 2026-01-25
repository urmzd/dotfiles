# AI-powered git commit using Gemini
gcai() {
  local diff=$(git diff --cached)

  if [ -z "$diff" ]; then
    echo "No staged changes to commit"
    return 1
  fi

  echo "Generating commit message with AI..."

  local message=$(echo "$diff" | gemini -p "Generate a concise, professional git commit message following the Conventional Commits format (feat:, fix:, refactor:, docs:, etc.) for these code changes. Return the commit message following the conventional commits spec, nothing else:")

  if [ -z "$message" ]; then
    echo "Failed to generate commit message"
    return 1
  fi

  echo "Generated message: $message"
  git commit -m "$message"
}
