#!/usr/bin/env zsh

# Disk analysis utilities for identifying space usage

disk_analysis() {
  local target_dir="${1:-.}"

  echo "=== Disk Usage Analysis ==="
  echo

  echo "Overall disk capacity:"
  df -h "${target_dir}" | awk 'NR==1 || NR==2'
  echo

  echo "Total size of ${target_dir}:"
  du -sh "${target_dir}" 2>/dev/null
  echo

  echo "Top 20 directories by size:"
  du -sh "${target_dir}"/* 2>/dev/null | sort -rh | head -20
}

disk_analysis_hidden() {
  local target_dir="${1:-$HOME}"

  echo "=== Hidden Directory Analysis ==="
  echo

  echo "Top 20 hidden directories by size:"
  du -sh "${target_dir}"/.[!.]* 2>/dev/null | sort -rh | head -20
}

disk_analysis_breakdown() {
  local target_dir="${1:-.}"

  echo "=== Detailed Breakdown of ${target_dir} ==="
  echo

  for dir in "${target_dir}"/*/ "${target_dir}"/.[!.]*/; do
    if [[ -d "$dir" ]]; then
      local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
      echo "$size  $dir"
    fi
  done | sort -rh | head -30
}

disk_cleanup_suggestions() {
  echo "=== Common Cleanup Targets ==="
  echo

  # Docker
  if command -v docker &> /dev/null; then
    echo "Docker system usage:"
    docker system df 2>/dev/null | grep -E "(Images|Containers|Volumes|Build Cache)" || echo "  (Docker not running)"
    echo
  fi

  # Common cache directories
  local -a cache_dirs=(
    "$HOME/.cache/unstructured"
    "$HOME/.cache/huggingface"
    "$HOME/.cache/uv"
    "$HOME/.ollama/models"
    "$HOME/.qdrant-data"
    "$HOME/.npm"
    "$HOME/.cache/pre-commit"
  )

  echo "Cache directory sizes:"
  for dir in "${cache_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
      du -sh "$dir" 2>/dev/null
    fi
  done
  echo

  # Nix store
  if [[ -d "/nix/store" ]]; then
    echo "Nix store size:"
    du -sh /nix/store 2>/dev/null
    echo "  Cleanup: nix-collect-garbage -d"
    echo
  fi

  # Colima
  if [[ -d "$HOME/.colima" ]]; then
    echo "Colima VM size:"
    du -sh "$HOME/.colima" 2>/dev/null
    echo
  fi
}

# Quick alias for full home directory analysis
disk_home() {
  echo "Analyzing home directory: $HOME"
  echo
  disk_analysis "$HOME"
  echo
  disk_analysis_hidden "$HOME"
  echo
  disk_cleanup_suggestions
}
