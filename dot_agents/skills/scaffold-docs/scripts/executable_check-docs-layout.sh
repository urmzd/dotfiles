#!/usr/bin/env bash
# Report documentation that sits outside the scaffold-docs layout.
# Usage: check-docs-layout.sh [repo-dir]. Exit 1 when there are findings.
set -euo pipefail
cd "${1:-.}"

allowed_root="README.md CONTRIBUTING.md USAGE.md CODEOWNERS LICENSE LICENSE.md CODE_OF_CONDUCT.md SECURITY.md SUPPORT.md NOTICE LICENSING.md CHANGELOG.md AGENTS.md CLAUDE.md GEMINI.md llms.txt"
allowed_dirs="architecture adrs rfcs guides reference runbooks plans assets internal"
found=0
report() { echo "$1"; found=1; }

for f in *.md *.markdown *.rst *.adoc; do
  [ -e "$f" ] || continue
  case " $allowed_root " in *" $f "*) ;; *) report "root: $f belongs in docs/" ;; esac
done

if [ -d docs ]; then
  [ -f docs/README.md ] || report "docs: missing docs/README.md index"
  for f in docs/*; do
    name=${f#docs/}
    if [ -d "$f" ]; then
      case " $allowed_dirs " in *" $name "*) ;; *) report "docs: unknown folder docs/$name/" ;; esac
    else
      case "$name" in
        README.md) ;;
        *.md) report "docs: loose file docs/$name, move it into a folder" ;;
        *) report "docs: non-prose file docs/$name, move it to docs/assets/ or next to the code that makes it" ;;
      esac
    fi
  done
  for f in $(find docs -type f ! -name '*.md' ! -path 'docs/assets/*' -mindepth 2 2>/dev/null); do
    report "docs: non-prose file $f, move it to docs/assets/ or next to the code that makes it"
  done
  for kind in adrs rfcs; do
    [ -d "docs/$kind" ] || continue
    for f in docs/$kind/*; do
      base=${f##*/}
      [ "$base" = README.md ] && continue
      [[ $base =~ ^[0-9]{4}-[a-z0-9-]+\.md$ ]] || report "docs: $f should be NNNN-slug.md"
    done
  done
  if [ -f docs/README.md ]; then
    while IFS= read -r f; do
      rel=${f#docs/}
      grep -qF "($rel" docs/README.md || report "docs: $f is not listed in docs/README.md"
    done < <(find docs -name '*.md' ! -path docs/README.md ! -path 'docs/assets/*' | sort)
  fi
fi

[ "$found" -eq 0 ] && echo "docs layout: ok"
exit "$found"
