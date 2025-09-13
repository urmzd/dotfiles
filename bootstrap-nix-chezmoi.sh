#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_banner() {
    cat << "EOF"
    ____        __  _____ __
   / __ \____  / /_/ __(_) /__  _____   _   __   ___  ____  ____
  / / / / __ \/ __/ /_/ / / _ \/ ___/  | | / /  |__ \/ __ \/ __ \
 / /_/ / /_/ / /_/ __/ / /  __(__  )   | |/ /   __/ / /_/ / /_/ /
/_____/\____/\__/_/ /_/_/\___/____/    |___/   /___/\____/\____/

Modern Development Environment with Nix + Chezmoi
EOF
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_warn "This script is optimized for macOS. Some features may not work on other systems."
        echo -n "Continue anyway? (y/N): "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY])
                log_info "Continuing on non-macOS system..."
                ;;
            *)
                log_info "Installation cancelled"
                exit 0
                ;;
        esac
    fi
}

# Install Nix package manager
install_nix() {
    log_info "Installing Nix package manager..."

    if command -v nix &> /dev/null; then
        log_success "Nix is already installed"
        return
    fi

    # Install Nix with flakes support (using official secure method)
    sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon

    # Enable flakes
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

    # Source Nix in current session
    if [[ -f '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi

    log_success "Nix installed with flakes support"
}

# Install Homebrew (for GUI apps and system integration)
install_homebrew() {
    log_info "Installing Homebrew..."

    if command -v brew &> /dev/null; then
        log_success "Homebrew is already installed"
        return
    fi

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for Apple Silicon Macs
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    log_success "Homebrew installed"
}

# Install Chezmoi
install_chezmoi() {
    log_info "Installing Chezmoi..."

    if command -v chezmoi &> /dev/null; then
        log_success "Chezmoi is already installed"
        return
    fi

    if command -v brew &> /dev/null; then
        brew install chezmoi
    elif command -v nix &> /dev/null; then
        nix profile install nixpkgs#chezmoi
    else
        sh -c "$(curl -fsLS get.chezmoi.io)"
    fi

    log_success "Chezmoi installed"
}

# Install direnv for automatic environment switching
install_direnv() {
    log_info "Installing direnv for automatic environment switching..."

    if command -v direnv &> /dev/null; then
        log_success "direnv is already installed"
        return
    fi

    if command -v brew &> /dev/null; then
        brew install direnv
    elif command -v nix &> /dev/null; then
        nix profile install nixpkgs#direnv nixpkgs#nix-direnv
    fi

    log_success "direnv installed"
}

# Install and setup pre-commit hooks
setup_precommit() {
    log_info "Setting up pre-commit hooks..."

    # Install pre-commit via pipx for isolation
    if ! command -v pre-commit &> /dev/null; then
        if command -v pipx &> /dev/null; then
            pipx install pre-commit
            log_success "pre-commit installed via pipx"
        else
            log_warn "pipx not available, skipping pre-commit installation"
            return
        fi
    else
        log_success "pre-commit is already installed"
    fi

    # Install pre-commit hooks in the dotfiles repository
    local dotfiles_dir="$HOME/.dotfiles"
    if [[ -f "$dotfiles_dir/.pre-commit-config.yaml" ]]; then
        cd "$dotfiles_dir"

        # Check if hooks are already installed
        local setup_complete_flag="$dotfiles_dir/.pre-commit-setup-complete"
        local config_hash
        config_hash=$(shasum -a 256 ".pre-commit-config.yaml" | cut -d' ' -f1)
        local needs_setup=true

        if [[ -f "$setup_complete_flag" ]]; then
            local stored_hash
            stored_hash=$(cat "$setup_complete_flag" 2>/dev/null || echo "")
            if [[ "$stored_hash" == "$config_hash" ]] && [[ -f ".git/hooks/pre-commit" ]]; then
                log_success "pre-commit hooks already installed and up-to-date"
                needs_setup=false
            fi
        fi

        if [[ "$needs_setup" == "true" ]]; then
            # Install the hooks atomically
            log_info "Installing pre-commit hooks..."
            if pre-commit install --install-hooks; then
                log_success "pre-commit hooks installed"

                # Run hooks on all files for initial validation
                log_info "Running pre-commit hooks on all files for validation..."
                if pre-commit run --all-files; then
                    log_success "All pre-commit hooks passed"
                    # Mark setup as complete with config hash
                    echo "$config_hash" > "$setup_complete_flag"
                else
                    log_warn "Some pre-commit hooks failed - review output above"
                    log_info "You can fix issues and run 'pre-commit run --all-files' again"
                    # Don't mark as complete if hooks failed
                fi
            else
                log_error "Failed to install pre-commit hooks"
                return 1
            fi
        fi
    else
        log_warn "No .pre-commit-config.yaml found, skipping hook installation"
    fi
}

# Setup dotfiles repository
setup_dotfiles_repo() {
    local dotfiles_dir="$HOME/.dotfiles"

    log_info "Setting up dotfiles repository..."

    if [[ -d "$dotfiles_dir" ]]; then
        log_info "Dotfiles directory exists, updating..."
        cd "$dotfiles_dir"
        git pull origin main || {
            log_warn "Failed to update repository, continuing with existing files"
        }
    else
        log_info "Cloning dotfiles repository..."
        git clone https://github.com/urmzd/dotfiles.git "$dotfiles_dir"
        cd "$dotfiles_dir"
    fi

    log_success "Dotfiles repository ready at $dotfiles_dir"
}

# Initialize Chezmoi with configuration
init_chezmoi() {
    log_info "Initializing Chezmoi..."

    local dotfiles_dir="$HOME/.dotfiles"

    # Initialize chezmoi with the chezmoi-config directory as source
    if [[ ! -d "$HOME/.local/share/chezmoi" ]]; then
        chezmoi init --source="$dotfiles_dir/chezmoi-config"
    fi

    # Apply the configuration template
    if [[ -f "$dotfiles_dir/.chezmoi.toml.tmpl" ]]; then
        log_info "Configuring Chezmoi settings..."
        mkdir -p "$HOME/.config/chezmoi"
        chezmoi execute-template --init --promptString "name=Urmzd" --promptString "email=urmzd.consulting@gmail.com" --promptString "github_username=urmzd" --promptBool "is_personal=true" --promptBool "is_work=false" --promptBool "use_secrets=false" --promptBool "use_nix=true" < "$dotfiles_dir/.chezmoi.toml.tmpl" > "$HOME/.config/chezmoi/chezmoi.toml"
    fi

    log_success "Chezmoi initialized"
}

# Setup Nix development environment
setup_nix_environment() {
    log_info "Setting up Nix development environment..."

    local dotfiles_dir="$HOME/.dotfiles"
    cd "$dotfiles_dir"

    # Enable direnv in the dotfiles directory
    if [[ -f ".envrc" ]]; then
        direnv allow
        log_success "Direnv enabled for dotfiles directory"
    fi

    # Test that Nix flake works
    if command -v nix &> /dev/null; then
        log_info "Testing Nix development environments..."

        # Run setup script from flake
        nix run .#setup

        log_success "Nix development environments configured"
    fi
}

# Setup shell integration
setup_shell_integration() {
    log_info "Setting up shell integration..."

    # Add direnv hook to shell if not already present
    local shell_config=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        shell_config="$HOME/.bashrc"
    fi

    if [[ -n "$shell_config" && -f "$shell_config" ]]; then
        if ! grep -q "direnv hook" "$shell_config"; then
            echo "eval \"\$(direnv hook \$(basename \$SHELL))\"" >> "$shell_config"
            log_success "Direnv hook added to $shell_config"
        fi

        # Add Nix daemon script if not present
        if ! grep -q "nix-daemon.sh" "$shell_config" && [[ -f '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]]; then
            cat >> "$shell_config" << 'EOF'

# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
EOF
            log_success "Nix daemon integration added to $shell_config"
        fi
    fi
}

# Install GUI applications via Homebrew
install_gui_apps() {
    log_info "Installing GUI applications via Homebrew..."

    if command -v brew &> /dev/null; then
        # Essential GUI apps
        local apps=(
            "visual-studio-code"
            "docker"
        )

        for app in "${apps[@]}"; do
            if ! brew list --cask "$app" &> /dev/null; then
                log_info "Installing $app..."
                brew install --cask "$app" || log_warn "Failed to install $app"
            fi
        done

        log_success "GUI applications installed"
    else
        log_warn "Homebrew not available, skipping GUI app installation"
    fi
}

# Show completion summary and next steps
show_completion_summary() {
    cat << EOF

${GREEN}========================================${NC}
${GREEN}🎉 Installation Complete!${NC}
${GREEN}========================================${NC}

${BLUE}What was installed:${NC}
✓ Nix package manager with flakes support
✓ Homebrew for GUI applications
✓ Chezmoi for dotfiles management
✓ direnv for automatic environment switching
✓ pre-commit hooks for code quality and security
✓ Your dotfiles repository and configurations

${BLUE}Development Environments Available:${NC}
• ${YELLOW}nix develop .#node${NC}     - Node.js development
• ${YELLOW}nix develop .#python${NC}   - Python development
• ${YELLOW}nix develop .#rust${NC}     - Rust development
• ${YELLOW}nix develop .#go${NC}       - Go development
• ${YELLOW}nix develop .#devops${NC}   - DevOps tools
• ${YELLOW}nix develop .#full${NC}     - All environments

${BLUE}Next Steps:${NC}

1. ${YELLOW}Restart your terminal${NC} or run:
   ${YELLOW}source ~/.zshrc${NC}

2. ${YELLOW}Configure Chezmoi${NC} for your machine:
   ${YELLOW}cd ~/.dotfiles && chezmoi apply${NC}

3. ${YELLOW}Set up secrets management${NC} (optional):
   ${YELLOW}./secrets-setup.sh${NC}

4. ${YELLOW}Test a development environment${NC}:
   ${YELLOW}cd ~/.dotfiles && nix develop .#node${NC}

5. ${YELLOW}Enable automatic environment switching${NC}:
   ${YELLOW}direnv allow${NC} (in any project with .envrc)

${BLUE}Documentation:${NC}
• Nix environments: ${YELLOW}cat ~/.dotfiles/nix-shells.md${NC}
• Chezmoi usage: ${YELLOW}chezmoi help${NC}
• direnv usage: ${YELLOW}direnv help${NC}

${PURPLE}Welcome to your new development environment!${NC} 🚀

EOF
}

# Main installation function
main() {
    show_banner
    echo

    log_info "Starting Nix + Chezmoi development environment setup..."

    check_macos
    install_nix
    install_homebrew
    install_chezmoi
    install_direnv
    setup_dotfiles_repo
    init_chezmoi
    setup_precommit
    setup_nix_environment
    setup_shell_integration
    install_gui_apps

    show_completion_summary

    log_success "Bootstrap completed successfully!"
    log_info "Please restart your terminal to ensure all changes take effect"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
