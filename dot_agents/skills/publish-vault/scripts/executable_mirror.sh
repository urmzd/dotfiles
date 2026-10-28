#!/usr/bin/env bash
# One-way mirror of top-level files with one extension from SRC into DST.
# Copies new/changed files, removes DST files missing from SRC.
# Usage: mirror.sh --src DIR --dst DIR [--ext md] [--dry-run]
set -euo pipefail

src="" dst="" ext="md" dry=0
while [ $# -gt 0 ]; do
  case "$1" in
    --src) src="$2"; shift 2 ;;
    --dst) dst="$2"; shift 2 ;;
    --ext) ext="${2#.}"; shift 2 ;;
    --dry-run) dry=1; shift ;;
    -h|--help) sed -n 2,4p "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
[ -d "$src" ] || { echo "src not a directory: $src" >&2; exit 2; }
[ -d "$dst" ] || { echo "dst not a directory: $dst" >&2; exit 2; }

shopt -s nullglob
src_files=("$src"/*."$ext")
[ ${#src_files[@]} -gt 0 ] || { echo "no .$ext files in $src; refusing to empty $dst" >&2; exit 1; }
placeholders=("$src"/.*."$ext".icloud)
[ ${#placeholders[@]} -eq 0 ] || { echo "cloud placeholders not downloaded: ${placeholders[*]}" >&2; exit 1; }

run() { if [ "$dry" -eq 1 ]; then echo "would: $*"; else "$@"; fi; }
added=0 updated=0 removed=0
for f in "${src_files[@]}"; do
  name="$(basename "$f")" target="$dst/$name"
  if [ ! -e "$target" ]; then echo "add     $name"; run cp "$f" "$target"; added=$((added+1))
  elif ! cmp -s "$f" "$target"; then echo "update  $name"; run cp "$f" "$target"; updated=$((updated+1)); fi
done
for t in "$dst"/*."$ext"; do
  name="$(basename "$t")"
  [ -e "$src/$name" ] || { echo "remove  $name"; run rm "$t"; removed=$((removed+1)); }
done
echo "$added added, $updated updated, $removed removed$([ "$dry" -eq 1 ] && echo ' (dry run)')"
