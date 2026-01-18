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

# Install GPG for encryption and signing
install_gpg() {
    log_info "Installing GPG..."

    if command -v gpg &> /dev/null; then
        log_success "GPG is already installed"
        return
    fi

    if command -v brew &> /dev/null; then
        brew install gnupg pinentry-mac
    elif command -v nix &> /dev/null; then
        nix profile install nixpkgs#gnupg nixpkgs#pinentry-mac
    fi

    # Configure GPG agent for GUI password entry
    mkdir -p ~/.gnupg

    # Determine pinentry-mac path based on architecture
    local pinentry_path
    if [[ -f "/opt/homebrew/bin/pinentry-mac" ]]; then
        pinentry_path="/opt/homebrew/bin/pinentry-mac"  # Apple Silicon
    elif [[ -f "/usr/local/bin/pinentry-mac" ]]; then
        pinentry_path="/usr/local/bin/pinentry-mac"     # Intel
    else
        pinentry_path="/opt/homebrew/bin/pinentry-mac"  # Default to Apple Silicon
    fi

    cat > ~/.gnupg/gpg-agent.conf << EOF
pinentry-program $pinentry_path
default-cache-ttl 34560000
max-cache-ttl 34560000
EOF

    log_success "GPG installed and configured"
}

# Install system tools required by configurations
install_system_tools() {
    log_info "Installing required system tools..."

    if command -v brew &> /dev/null; then
        # Tools required by tmux and shell configurations
        local tools=(
            "reattach-to-user-namespace"  # Required for tmux clipboard integration
        )

        for tool in "${tools[@]}"; do
            if ! brew list "$tool" &> /dev/null 2>&1; then
                log_info "Installing $tool..."
                brew install "$tool" || log_warn "Failed to install $tool"
            else
                log_info "$tool already installed"
            fi
        done
    fi

    log_success "System tools installed"
}

# Install Oh My Zsh
install_oh_my_zsh() {
    log_info "Installing Oh My Zsh..."

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "Oh My Zsh already installed"
        return
    fi

    # Install Oh My Zsh without changing shell or running zsh
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    log_success "Oh My Zsh installed"
}

# Install Powerlevel10k theme
install_powerlevel10k() {
    log_info "Installing Powerlevel10k theme..."

    local p10k_path="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [[ -d "$p10k_path" ]]; then
        log_success "Powerlevel10k already installed"
        return
    fi

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_path"
        log_success "Powerlevel10k installed"
    else
        log_warn "Oh My Zsh not found, skipping Powerlevel10k installation"
    fi
}

# Install zsh-completions plugin
install_zsh_completions() {
    log_info "Installing zsh-completions plugin..."

    local plugin_path="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions"

    if [[ -d "$plugin_path" ]]; then
        log_success "zsh-completions already installed"
        return
    fi

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        git clone https://github.com/zsh-users/zsh-completions "$plugin_path"
        log_success "zsh-completions installed"
    else
        log_warn "Oh My Zsh not found, skipping zsh-completions installation"
    fi
}

# Install zsh-syntax-highlighting plugin
install_zsh_syntax_highlighting() {
    log_info "Installing zsh-syntax-highlighting plugin..."

    local plugin_path="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

    if [[ -d "$plugin_path" ]]; then
        log_success "zsh-syntax-highlighting already installed"
        return
    fi

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_path"
        log_success "zsh-syntax-highlighting installed"
    else
        log_warn "Oh My Zsh not found, skipping zsh-syntax-highlighting installation"
    fi
}

# Install TPM (Tmux Plugin Manager)
install_tpm() {
    log_info "Installing TPM (Tmux Plugin Manager)..."

    local tpm_path="$HOME/.config/tmux/plugins/tpm"

    if [[ -d "$tpm_path" ]]; then
        log_success "TPM already installed"
        return
    fi

    mkdir -p "$(dirname "$tpm_path")"
    git clone https://github.com/tmux-plugins/tpm "$tpm_path"
    chmod +x "$tpm_path/tpm"

    log_success "TPM installed"
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
    local dotfiles_dir=$(chezmoi source-path)
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

# Setup dotfiles repository via chezmoi
setup_dotfiles_repo() {
    log_info "Setting up dotfiles repository via chezmoi..."

    # Check if chezmoi is already initialized
    if chezmoi source-path >/dev/null 2>&1 && [[ -d "$(chezmoi source-path)" ]]; then
        log_info "Chezmoi already initialized, updating..."
        chezmoi update
    else
        log_info "Initializing chezmoi with GitHub repository..."
        # Use chezmoi init with GitHub username to clone and initialize
        chezmoi init urmzd
    fi

    log_success "Dotfiles repository ready via chezmoi"
}

# Setup GPG key for Git signing
setup_gpg_key() {
    log_info "Setting up GPG key for Git signing..."

    # Check if GPG key already exists
    local existing_keys=$(gpg --list-secret-keys --keyid-format=LONG 2>/dev/null | grep -E "^sec\s+[^\s]+/([A-F0-9]+)" | head -1)

    if [[ -n "$existing_keys" ]]; then
        GPG_KEY_ID=$(echo "$existing_keys" | sed -n 's/.*\/\([A-F0-9]\{16\}\).*/\1/p')
        log_success "Using existing GPG key: $GPG_KEY_ID"
    else
        log_info "No GPG key found. Generating new GPG key..."

        # Generate GPG key non-interactively
        cat > /tmp/gpg-key-spec << EOF
%echo Generating GPG key for Git signing
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Urmzd Mukhammadnaim
Name-Email: urmzd.consulting@gmail.com
Expire-Date: 1m
%no-protection
%commit
%echo Done
EOF

        gpg --batch --generate-key /tmp/gpg-key-spec
        rm /tmp/gpg-key-spec

        # Get the new key ID
        GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=LONG | grep -E "^sec\s+[^\s]+/([A-F0-9]+)" | head -1 | sed -n 's/.*\/\([A-F0-9]\{16\}\).*/\1/p')

        # Generate revocation certificate
        local revoke_dir="$HOME/.gnupg/revocation-certs"
        mkdir -p "$revoke_dir"
        chmod 700 "$revoke_dir"
        gpg --batch --yes --output "$revoke_dir/$GPG_KEY_ID-revoke.asc" --gen-revoke "$GPG_KEY_ID"
        chmod 600 "$revoke_dir/$GPG_KEY_ID-revoke.asc"
        log_success "Revocation certificate saved to $revoke_dir/$GPG_KEY_ID-revoke.asc"

        log_success "Generated new GPG key: $GPG_KEY_ID"
    fi

    # Export the key for GitHub (optional)
    log_info "GPG public key for GitHub (save this):"
    echo "----------------------------------------"
    gpg --armor --export "$GPG_KEY_ID"
    echo "----------------------------------------"
    log_info "Add this public key to GitHub: https://github.com/settings/keys"

    # Make key available globally for template processing
    export GPG_SIGNING_KEY="$GPG_KEY_ID"

    log_success "GPG key setup complete"
}

# Initialize Chezmoi configuration
init_chezmoi() {
    log_info "Configuring Chezmoi..."

    local chezmoi_source=$(chezmoi source-path)

    # Apply the configuration template if it exists
    if [[ -f "$chezmoi_source/.chezmoi.toml.tmpl" ]]; then
        log_info "Processing Chezmoi configuration template..."
        mkdir -p "$HOME/.config/chezmoi"

        # Process the template with proper values
        chezmoi execute-template \
            --init \
            --promptString "name=Urmzd Mukhammadnaim" \
            --promptString "email=urmzd.consulting@gmail.com" \
            --promptString "github_username=urmzd" \
            --promptString "ssh_signing_key=${SSH_SIGNING_KEY:-~/.ssh/github.pub}" \
            --promptBool "is_personal=true" \
            --promptBool "is_work=false" \
            --promptBool "use_secrets=false" \
            --promptBool "use_nix=true" \
            < "$chezmoi_source/.chezmoi.toml.tmpl" > "$HOME/.config/chezmoi/chezmoi.toml"
    fi

    log_success "Chezmoi configuration complete"
}

# Setup global direnv permissions
setup_global_direnv() {
    log_info "Setting up global development environment access..."

    # Allow global .envrc if it was created by chezmoi
    if [[ -f "$HOME/.envrc" ]]; then
        if direnv allow "$HOME/.envrc" 2>/dev/null; then
            log_success "Global .envrc enabled - development tools available everywhere"
        else
            log_warn "Failed to allow global .envrc, you may need to run 'direnv allow ~/.envrc' manually"
        fi
    fi

    # Allow chezmoi source directory .envrc
    local chezmoi_source=$(chezmoi source-path 2>/dev/null)
    if [[ -n "$chezmoi_source" && -f "$chezmoi_source/.envrc" ]]; then
        if direnv allow "$chezmoi_source/.envrc" 2>/dev/null; then
            log_success "Chezmoi source .envrc enabled"
        else
            log_warn "Failed to allow chezmoi .envrc, you may need to run 'direnv allow $chezmoi_source/.envrc' manually"
        fi
    fi
}

# Setup Nix development environment
setup_nix_environment() {
    log_info "Setting up Nix development environment..."

    local chezmoi_source=$(chezmoi source-path)
    cd "$chezmoi_source"

    # Test that Nix flake works
    if command -v nix &> /dev/null; then
        log_info "Testing Nix development environments..."

        # Run setup script from flake if it exists
        if nix flake show 2>/dev/null | grep -q "apps.*setup"; then
            nix run .#setup || log_warn "Nix setup app failed, continuing..."
        fi

        log_success "Nix development environments configured"
    fi
}

# Setup shell integration
setup_shell_integration() {
    log_info "Setting up shell integration..."

    # Ensure zsh is set as default shell
    if [[ "$SHELL" != "/bin/zsh" ]] && command -v zsh &> /dev/null; then
        log_info "Setting zsh as default shell..."
        # Check if zsh is in /etc/shells
        if ! grep -q "$(which zsh)" /etc/shells; then
            echo "$(which zsh)" | sudo tee -a /etc/shells
        fi
        # Change shell to zsh
        sudo chsh -s "$(which zsh)" "$USER"
        export SHELL="$(which zsh)"
        log_success "Default shell changed to zsh"
    fi

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

# Install Claude Code CLI
install_claude_code() {
    log_info "Installing Claude Code CLI..."

    if command -v claude &> /dev/null; then
        log_info "Claude Code CLI found, updating to latest..."
    fi

    log_info "Downloading and installing Claude Code from official source..."
    if curl -fsSL https://claude.ai/install.sh | bash; then
        log_success "Claude Code CLI installed successfully"
    else
        log_warn "Failed to install Claude Code CLI"
    fi
}

# Install OpenAI Codex CLI (optional, controlled by chezmoi config)
install_codex_cli() {
    log_info "Installing OpenAI Codex CLI..."
    if command -v codex &> /dev/null; then
        log_info "OpenAI Codex CLI found, updating to latest..."
    fi

    # Check if user wants to install codex (from chezmoi config)
    local chezmoi_source=$(chezmoi source-path 2>/dev/null || echo "")
    local install_codex=false

    if [[ -n "$chezmoi_source" ]] && command -v chezmoi &> /dev/null; then
        install_codex=$(chezmoi data 2>/dev/null | grep -q '"install_codex": true' && echo "true" || echo "false")
    fi

    if [[ "$install_codex" == "false" ]]; then
        log_info "Codex installation skipped (disabled in config or work machine)"
        return
    fi

    if command -v npm &> /dev/null; then
        log_info "Installing via npm..."
        if npm install -g @openai/codex@latest; then
            log_success "OpenAI Codex CLI installed successfully"
        else
            log_warn "Failed to install OpenAI Codex CLI"
        fi
    else
        log_warn "npm not available, skipping Codex installation"
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
✓ GPG for encryption, SSH for Git commit signing
✓ Oh My Zsh with Powerlevel10k theme
✓ zsh-completions and zsh-syntax-highlighting plugins
✓ TPM (Tmux Plugin Manager) with plugins
✓ System tools (reattach-to-user-namespace, etc.)
✓ Chezmoi for dotfiles management
✓ direnv for automatic environment switching
✓ pre-commit hooks for code quality and security
✓ AI CLI tools (Claude Code, Gemini CLI, and optionally Codex)
✓ Your dotfiles repository and configurations
✓ Global development environment access

${BLUE}Development Environments Available:${NC}
• ${YELLOW}nix develop .#node${NC}     - Node.js development
• ${YELLOW}nix develop .#python${NC}   - Python development
• ${YELLOW}nix develop .#rust${NC}     - Rust development
• ${YELLOW}nix develop .#go${NC}       - Go development
• ${YELLOW}nix develop .#devops${NC}   - DevOps tools
• ${YELLOW}nix develop .#full${NC}     - All environments

${BLUE}Next Steps:${NC}

1. ${YELLOW}Restart your terminal${NC} to activate all configurations:
   ${YELLOW}source ~/.zshrc${NC}

2. ${YELLOW}Your development tools are now globally available!${NC}
   Try: ${YELLOW}nvim${NC}, ${YELLOW}python${NC}, ${YELLOW}tmux${NC} from any directory

3. ${YELLOW}Add your SSH key to GitHub as a signing key${NC}:
   ${YELLOW}https://github.com/settings/keys${NC} (add under "Signing keys")

4. ${YELLOW}Test a development environment${NC}:
   ${YELLOW}cd $(chezmoi source-path) && nix develop .#node${NC}

${BLUE}Documentation:${NC}
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

    # Phase 1: System Preparation
    check_macos
    install_nix
    install_homebrew
    install_gpg
    install_system_tools

    # Phase 2: Development Environment Setup
    install_oh_my_zsh
    install_powerlevel10k
    install_zsh_completions
    install_zsh_syntax_highlighting
    install_tpm
    install_direnv
    install_chezmoi

    # Phase 3: Dotfiles Integration
    setup_dotfiles_repo
    init_chezmoi

    # Apply dotfiles configuration (includes global .envrc)
    log_info "Applying dotfiles configuration..."
    chezmoi apply

    setup_global_direnv
    setup_precommit
    setup_nix_environment
    setup_shell_integration
    install_gui_apps

    # Phase 5: AI CLI Tools
    install_claude_code
    install_codex_cli

    show_completion_summary

    log_success "Bootstrap completed successfully!"
    log_info "Please restart your terminal to ensure all changes take effect"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
