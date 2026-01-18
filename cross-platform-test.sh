#!/usr/bin/env bash

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Test cross-platform detection
test_platform_detection() {
    log_info "Testing platform detection..."

    echo "Detected OS: $OSTYPE"
    echo "Architecture: $(uname -m)"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_success "macOS detected"
        if command -v brew &> /dev/null; then
            log_success "Homebrew available"
        else
            log_warn "Homebrew not found"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_success "Linux detected"
        if command -v apt &> /dev/null; then
            log_success "apt package manager available"
        elif command -v dnf &> /dev/null; then
            log_success "dnf package manager available"
        elif command -v pacman &> /dev/null; then
            log_success "pacman package manager available"
        else
            log_warn "No supported package manager found"
        fi
    elif [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        log_success "WSL detected: $WSL_DISTRO_NAME"
    else
        log_warn "Unknown platform: $OSTYPE"
    fi
}

# Test tool availability
test_tools() {
    log_info "Testing tool availability..."

    local tools=(
        "git"
        "nix"
        "chezmoi"
        "direnv"
        "fzf"
        "rg"
        "tree"
        "jq"
    )

    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "$tool is available"
        else
            log_warn "$tool is not available"
        fi
    done
}

# Test Nix environments
test_nix_environments() {
    log_info "Testing Nix development environments..."

    if ! command -v nix &> /dev/null; then
        log_warn "Nix not available, skipping environment tests"
        return
    fi

    local environments=(
        "default"
        "node"
        "python"
        "rust"
        "go"
    )

    for env in "${environments[@]}"; do
        if nix flake show 2>/dev/null | grep -q "$env"; then
            log_success "Environment '$env' is defined"
        else
            log_warn "Environment '$env' not found"
        fi
    done

    # Test that flake is valid
    if nix flake check 2>/dev/null; then
        log_success "Nix flake validation passed"
    else
        log_error "Nix flake validation failed"
    fi
}

# Test Chezmoi configuration
test_chezmoi_config() {
    log_info "Testing Chezmoi configuration..."

    if ! command -v chezmoi &> /dev/null; then
        log_warn "Chezmoi not available, skipping configuration tests"
        return
    fi

    # Test template execution
    if [[ -f .chezmoi.toml.tmpl ]]; then
        if chezmoi execute-template --init \
           --promptString name="Test User" \
           --promptString email="test@example.com" \
           --promptString github_username="testuser" \
           --promptBool is_personal=true \
           --promptBool is_work=false \
           --promptBool use_secrets=false \
           --promptBool use_nix=true \
           < .chezmoi.toml.tmpl > /dev/null; then
            log_success "Chezmoi template validation passed"
        else
            log_error "Chezmoi template validation failed"
        fi
    else
        log_warn "Chezmoi template not found"
    fi

    # Test templates in repo root
    local templates
    templates=$(find . -name "*.tmpl" -not -path "./.git/*" | wc -l)
    log_info "Found $templates template files"

}

# Test cross-platform file paths
test_file_paths() {
    log_info "Testing cross-platform file paths..."

    local expected_files=(
        "dot_gitconfig.tmpl"
        "dot_zshrc.tmpl"
        "dot_config/tmux/tmux.conf.tmpl"
        "private_dot_ssh/config.tmpl"
    )

    for file in "${expected_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "Template file exists: $file"
        else
            log_warn "Template file missing: $file"
        fi
    done
}

# Main test function
main() {
    cat << "EOF"
   ____                       ____  _       _    __
  / ___|_ __ ___  ___ ___    |  _ \| | __ _| |_ / _| ___  _ __ _ __ ___
 | |   | '__/ _ \/ __/ __|   | |_) | |/ _` | __| |_ / _ \| '__| '_ ` _ \
 | |___| | | (_) \__ \__ \   |  __/| | (_| | |_|  _| (_) | |  | | | | |
  \____|_|  \___/|___/___/   |_|   |_|\__,_|\__|_|  \___/|_|  |_| |_| |

Cross-Platform Configuration Test
EOF

    echo
    log_info "Running cross-platform compatibility tests..."
    echo

    test_platform_detection
    echo
    test_tools
    echo
    test_nix_environments
    echo
    test_chezmoi_config
    echo
    test_file_paths
    echo
    # No secrets tooling checks for this repository

    echo
    log_info "Cross-platform test completed!"

    cat << EOF

${BLUE}Summary:${NC}
This test validates that the dotfiles work across:
• macOS (Intel and Apple Silicon)
• Linux (Ubuntu, Fedora, Arch)
• Windows Subsystem for Linux (WSL)

Key compatibility features:
• Platform-specific package managers
• Conditional template logic
• Cross-platform tool detection
• Adaptive file paths and configurations

EOF
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
