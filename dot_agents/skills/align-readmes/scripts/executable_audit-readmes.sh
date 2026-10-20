#!/usr/bin/env bash
# Fleet README audit. Read-only. Prints one row per repo under ROOT.
# Usage: audit-readmes.sh [ROOT]   (default: ~/github)
set -euo pipefail

ROOT="${1:-$HOME/github}"

{
printf '%s\n' "repo status identity hdr badges em_dash tree toc_needed quick_start skill_2nd license_last"
for dir in "$ROOT"/*/; do
  dir="${dir%/}"
  name="$(basename "$dir")"
  readme="$dir/README.md"
  [ -d "$dir/.git" ] || continue

  remote="$(git -C "$dir" remote get-url origin 2>/dev/null | sed -E 's#.*[:/]([^/]+/[^/]+)$#\1#; s#\.git$##')"
  status="no-remote"; remote_ok="-"
  if [ -n "$remote" ]; then
    meta="$(gh repo view "$remote" --json nameWithOwner,isArchived --jq '"\(.nameWithOwner) \(.isArchived)"' 2>/dev/null || echo "missing missing")"
    canonical="${meta% *}"; archived="${meta#* }"
    case "$archived" in
      true) status="ARCHIVED" ;;
      false) status="active" ;;
      *) status="MISSING" ;;
    esac
    # gh follows rename redirects: a remote mismatch means a stale remote URL,
    # a dir mismatch means the checkout folder predates a rename.
    if [ "$canonical" != "$remote" ]; then remote_ok="stale-remote:$canonical"
    elif [ "${canonical#*/}" != "$name" ]; then remote_ok="dir-is:${canonical#*/}"
    else remote_ok="ok"; fi
  fi

  if [ ! -f "$readme" ]; then
    printf '%s\n' "$name $status $remote_ok NO-README - - - - - - -"
    continue
  fi

  lines="$(wc -l < "$readme" | tr -d ' ')"
  hdr="$(head -3 "$readme" | grep -c 'align="center"' || true)"
  badges="$(grep -cE '<img src=[^>]*(badge|shields)' "$readme" || true)"
  em="$(grep -c $'—' "$readme" || true)"
  tree="$(grep -cE '├──|└──' "$readme" || true)"
  toc="-"
  if [ "$lines" -ge 300 ]; then grep -q '^## Contents' "$readme" && toc="ok" || toc="MISSING"; fi
  qs="$(grep -q '^## Quick Start' "$readme" && echo ok || echo MISSING)"
  sections="$(grep '^## ' "$readme" || true)"
  skill="$(echo "$sections" | tail -2 | head -1 | grep -q 'Agent Skill' && echo ok || echo no)"
  lic="$(echo "$sections" | tail -1 | grep -q 'License' && echo ok || echo no)"

  printf '%s\n' "$name $status $remote_ok $hdr $badges $em $tree $toc $qs $skill $lic"
done
} | column -t
