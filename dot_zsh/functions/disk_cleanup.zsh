#!/usr/bin/env zsh

# Disk cleanup utilities for freeing space
# Companion to disk_analysis.zsh (analysis) — this file does the actual cleanup

_cleanup_header() { echo "\n\033[0;36m=== $1 ===\033[0m" }
_cleanup_skip()   { echo "\033[0;33m  skipped\033[0m ($1)" }
_cleanup_done()   { echo "\033[0;32m  done\033[0m" }

# ---------------------------------------------------------------------------
# Individual cleaners
# ---------------------------------------------------------------------------

_cleanup_rust_targets() {
  _cleanup_header "Rust build artifacts (target/)"
  local search_dir="${1:-$HOME/github}"
  [[ -d "$search_dir" ]] || { _cleanup_skip "no $search_dir"; return 1; }

  local dirs=()
  while IFS= read -r d; do dirs+=("$d"); done < <(find "$search_dir" -maxdepth 3 -name target -type d 2>/dev/null)
  (( ${#dirs} == 0 )) && { _cleanup_skip "none found"; return 1; }

  local total=0
  for d in "${dirs[@]}"; do
    local size_kb=$(du -sk "$d" 2>/dev/null | cut -f1)
    total=$(( total + size_kb ))
    echo "  removing $d ($(du -sh "$d" 2>/dev/null | cut -f1))"
    rm -rf "$d"
  done
  echo "\033[0;32m  freed ~$(( total / 1024 ))M\033[0m"
}

_cleanup_node_modules() {
  _cleanup_header "Node modules"
  local search_dir="${1:-$HOME/github}"
  [[ -d "$search_dir" ]] || { _cleanup_skip "no $search_dir"; return 1; }

  local dirs=()
  while IFS= read -r d; do dirs+=("$d"); done < <(find "$search_dir" -maxdepth 3 -name node_modules -type d 2>/dev/null)
  (( ${#dirs} == 0 )) && { _cleanup_skip "none found"; return 1; }

  local total=0
  for d in "${dirs[@]}"; do
    local size_kb=$(du -sk "$d" 2>/dev/null | cut -f1)
    total=$(( total + size_kb ))
    echo "  removing $d ($(du -sh "$d" 2>/dev/null | cut -f1))"
    rm -rf "$d"
  done
  echo "\033[0;32m  freed ~$(( total / 1024 ))M\033[0m"
}

_cleanup_go_cache() {
  _cleanup_header "Go build cache"
  command -v go &>/dev/null || { _cleanup_skip "go not installed"; return 1; }
  go clean -cache 2>/dev/null
  _cleanup_done
}

_cleanup_nix_gc() {
  _cleanup_header "Nix garbage collection"
  command -v nix-collect-garbage &>/dev/null || { _cleanup_skip "nix not installed"; return 1; }
  nix-collect-garbage -d 2>/dev/null
  _cleanup_done
}

_cleanup_docker() {
  _cleanup_header "Docker system prune"
  command -v docker &>/dev/null || { _cleanup_skip "docker not installed"; return 1; }
  docker info &>/dev/null || { _cleanup_skip "docker not running"; return 1; }
  docker system prune -af --volumes 2>/dev/null
  _cleanup_done
}

_cleanup_pip_cache() {
  _cleanup_header "Python caches (pip, uv, __pycache__)"
  command -v pip &>/dev/null && pip cache purge 2>/dev/null
  command -v uv &>/dev/null && uv cache clean 2>/dev/null

  local search_dir="${1:-$HOME/github}"
  [[ -d "$search_dir" ]] && find "$search_dir" -maxdepth 4 -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null
  _cleanup_done
}

_cleanup_homebrew() {
  _cleanup_header "Homebrew cache"
  command -v brew &>/dev/null || { _cleanup_skip "brew not installed"; return 1; }
  brew cleanup --prune=all -s 2>/dev/null
  _cleanup_done
}

_cleanup_misc_caches() {
  _cleanup_header "Miscellaneous caches"
  local -a dirs=(
    "$HOME/.cache/huggingface"
    "$HOME/.cache/unstructured"
    "$HOME/.gradle/caches"
    "$HOME/.npm/_cacache"
    "$HOME/.pnpm-store"
  )
  for d in "${dirs[@]}"; do
    if [[ -d "$d" ]]; then
      echo "  removing $d ($(du -sh "$d" 2>/dev/null | cut -f1))"
      rm -rf "$d"
    fi
  done
  _cleanup_done
}

# ---------------------------------------------------------------------------
# Main entry points
# ---------------------------------------------------------------------------

disk_cleanup_quick() {
  echo "\033[0;36mQuick disk cleanup (safe, reversible targets)\033[0m"
  local before=$(df -k / | awk 'NR==2 {print $4}')

  _cleanup_rust_targets "$@"
  _cleanup_node_modules "$@"
  _cleanup_go_cache
  _cleanup_pip_cache "$@"
  _cleanup_homebrew

  local after=$(df -k / | awk 'NR==2 {print $4}')
  echo "\n\033[0;32m=== Total freed: ~$(( (after - before) / 1024 ))M ===\033[0m"
}

disk_cleanup_deep() {
  echo "\033[0;36mDeep disk cleanup (includes Docker prune + Nix GC)\033[0m"
  echo "\033[0;33mThis will remove Docker images/volumes and old Nix generations.\033[0m"
  echo -n "Continue? [y/N] "
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]] || { echo "Aborted."; return 1; }

  local before=$(df -k / | awk 'NR==2 {print $4}')

  _cleanup_rust_targets "$@"
  _cleanup_node_modules "$@"
  _cleanup_go_cache
  _cleanup_pip_cache "$@"
  _cleanup_homebrew
  _cleanup_misc_caches
  _cleanup_docker
  _cleanup_nix_gc

  local after=$(df -k / | awk 'NR==2 {print $4}')
  echo "\n\033[0;32m=== Total freed: ~$(( (after - before) / 1024 ))M ===\033[0m"
}

disk_cleanup() {
  case "${1:-quick}" in
    quick)   shift 2>/dev/null; disk_cleanup_quick "$@" ;;
    deep)    shift 2>/dev/null; disk_cleanup_deep "$@" ;;
    rust)    shift 2>/dev/null; _cleanup_rust_targets "${1:-$HOME/github}" ;;
    node)    shift 2>/dev/null; _cleanup_node_modules "${1:-$HOME/github}" ;;
    go)      _cleanup_go_cache ;;
    nix)     _cleanup_nix_gc ;;
    docker)  _cleanup_docker ;;
    pip)     shift 2>/dev/null; _cleanup_pip_cache "${1:-$HOME/github}" ;;
    brew)    _cleanup_homebrew ;;
    caches)  _cleanup_misc_caches ;;
    -h|--help|help)
      echo "Usage: disk_cleanup [quick|deep|rust|node|go|nix|docker|pip|brew|caches] [search_dir]"
      echo
      echo "Modes:"
      echo "  quick   — Rust targets, node_modules, Go/pip/brew caches (default)"
      echo "  deep    — Everything in quick + Docker prune + Nix GC + misc caches"
      echo "  rust    — Only Rust target/ directories"
      echo "  node    — Only node_modules/ directories"
      echo "  go      — Only Go build cache"
      echo "  nix     — Only Nix garbage collection"
      echo "  docker  — Only Docker system prune"
      echo "  pip     — Only Python caches (pip, uv, __pycache__)"
      echo "  brew    — Only Homebrew cache cleanup"
      echo "  caches  — Only miscellaneous caches (huggingface, gradle, npm, pnpm)"
      echo
      echo "Optional search_dir defaults to ~/github"
      ;;
    *)
      echo "\033[0;31mUnknown mode: $1\033[0m"
      disk_cleanup help
      return 1
      ;;
  esac
}
