#!/usr/bin/env bash
# Check documentation hygiene for Markdown/TXT docs, skill metadata, and the
# agentspec registry. Designed for repo-local use and for the sync-docs skill.

set -euo pipefail

root="${1:-.}"
cd "$root"

failures=0

section() {
  printf '\n== %s ==\n' "$1"
}

record_failure() {
  failures=$((failures + 1))
}

have() {
  command -v "$1" >/dev/null 2>&1
}

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/doc-hygiene.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

section "document files"
if ! have rg; then
  echo "FAIL: ripgrep is required for documentation hygiene checks"
  exit 1
fi

rg --files \
  -g '*.md' \
  -g '*.mdx' \
  -g '*.txt' \
  -g '!**/.git/**' \
  -g '!**/node_modules/**' \
  -g '!**/.venv/**' \
  -g '!**/target/**' \
  > "$tmpdir/doc-files.txt"

doc_count="$(wc -l < "$tmpdir/doc-files.txt" | tr -d ' ')"
echo "checked_files=$doc_count"

section "text style"
em_dash="$(printf '\342\200\224')"
rg -n "$em_dash" . \
  -g '!**/.git/**' \
  -g '!**/node_modules/**' \
  -g '!**/.venv/**' \
  -g '!**/target/**' \
  -g '!**/.terraform/**' \
  > "$tmpdir/em-dashes.txt" || true

if [ -s "$tmpdir/em-dashes.txt" ]; then
  echo "FAIL: em dash characters found. Replace U+2014 with a period, colon, comma, or indexed bullets."
  cat "$tmpdir/em-dashes.txt"
  record_failure
else
  echo "PASS: no em dash characters in text files"
fi

section "embedded source drift"
if rg -l '<!--[[:space:]]*fsrc[[:space:]]+src=' . \
  -g '*.md' \
  -g '*.mdx' \
  -g '*.txt' \
  -g '!**/.git/**' \
  > "$tmpdir/fsrc-files.txt"; then
  if have fsrc; then
    if xargs fsrc run --verify < "$tmpdir/fsrc-files.txt"; then
      echo "PASS: fsrc embeds are current"
    else
      echo "FAIL: fsrc embeds are stale. Run: xargs fsrc run < $tmpdir/fsrc-files.txt"
      record_failure
    fi
  else
    echo "FAIL: fsrc markers exist but fsrc is not installed"
    record_failure
  fi
else
  echo "PASS: no fsrc markers found"
fi

section "agentspec validation"
if [ -d dot_agents ] && have agentspec; then
  validate_failures=0
  for path in dot_agents/skills/*/SKILL.md dot_agents/agents/*.md; do
    [ -e "$path" ] || continue
    if ! agentspec manage validate "$path" >/dev/null; then
      echo "FAIL: agentspec validation failed for $path"
      validate_failures=$((validate_failures + 1))
    fi
  done
  if [ "$validate_failures" -eq 0 ]; then
    echo "PASS: all local skills and agents validate"
  else
    record_failure
  fi
elif [ -d dot_agents ]; then
  echo "FAIL: dot_agents exists but agentspec is not installed"
  record_failure
else
  echo "SKIP: no dot_agents directory"
fi

section "agentspec registry"
if [ -d dot_agents ] && have agentspec && have jq; then
  {
    find dot_agents/skills -mindepth 2 -maxdepth 2 -name SKILL.md -print 2>/dev/null |
      sed 's#dot_agents/skills/##; s#/SKILL.md##; s#^#skill\t#'
    find dot_agents/agents -maxdepth 1 -name '*.md' -print 2>/dev/null |
      sed 's#dot_agents/agents/##; s#.md$##; s#^#agent\t#'
  } | LC_ALL=C sort > "$tmpdir/source-resources.tsv"

  agentspec --format json status > "$tmpdir/agentspec-status.json"
  jq -r '.managed[] | select(.kind=="skill" or .kind=="agent") | "\(.kind)\t\(.name)"' \
    "$tmpdir/agentspec-status.json" |
    LC_ALL=C sort > "$tmpdir/managed-resources.tsv"

  comm -23 "$tmpdir/source-resources.tsv" "$tmpdir/managed-resources.tsv" > "$tmpdir/unmanaged-source.tsv"
  if [ -s "$tmpdir/unmanaged-source.tsv" ]; then
    echo "FAIL: local source resources are deployed but not managed by agentspec"
    cat "$tmpdir/unmanaged-source.tsv"
    echo "Fix: agentspec manage add \"$(pwd)/dot_agents\" --all-tools"
    echo "If existing shared-store resources are skipped, adopt each listed name with: agentspec manage add <name> --all-tools"
    echo "Then run: agentspec sync --fast"
    record_failure
  else
    echo "PASS: all local source skills and agents are managed"
  fi

  agentspec manage verify --format json > "$tmpdir/agentspec-verify.json" 2>/dev/null || true
  jq -r --rawfile names "$tmpdir/source-resources.tsv" '
    ($names | split("\n") | map(split("\t")) | map(select(length == 2)) | map(.[1])) as $local |
    .[] | . as $issue | select($local | index($issue.name)) |
    "\($issue.kind)\t\($issue.name)\texpected=\($issue.expected)\tactual=\($issue.actual)"
  ' "$tmpdir/agentspec-verify.json" > "$tmpdir/local-integrity-issues.tsv"

  if [ -s "$tmpdir/local-integrity-issues.tsv" ]; then
    echo "FAIL: local source resources have stale agentspec integrity hashes"
    cat "$tmpdir/local-integrity-issues.tsv"
    echo "Fix: cut -f2 $tmpdir/source-resources.tsv | xargs -n1 agentspec manage verify --accept --name"
    record_failure
  else
    echo "PASS: local source agentspec integrity hashes are current"
  fi
elif [ -d dot_agents ]; then
  echo "SKIP: registry coverage needs agentspec and jq"
else
  echo "SKIP: no dot_agents directory"
fi

section "summary"
if [ "$failures" -eq 0 ]; then
  echo "PASS: documentation hygiene checks passed"
  exit 0
fi

echo "FAIL: $failures documentation hygiene check(s) failed"
exit 1
