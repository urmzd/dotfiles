#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS. Exiting."
        exit 1
    fi
}

# Install Homebrew if not present
install_homebrew() {
    log_info "Checking for Homebrew..."
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add brew to PATH for Apple Silicon Macs
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        log_success "Homebrew already installed"
    fi
}

# Install packages from Brewfile
install_brew_packages() {
    log_info "Installing packages from Brewfile..."
    if [[ -f "Brewfile" ]]; then
        brew bundle --file=Brewfile
        log_success "Homebrew packages installed"
    else
        log_error "Brewfile not found!"
        exit 1
    fi
}

# Install oh-my-zsh
install_oh_my_zsh() {
    log_info "Installing oh-my-zsh..."
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "oh-my-zsh installed"
    else
        log_success "oh-my-zsh already installed"
    fi
}

# Install powerlevel10k theme
install_powerlevel10k() {
    log_info "Installing powerlevel10k theme..."
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ ! -d "$p10k_dir" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
        log_success "powerlevel10k installed"
    else
        log_success "powerlevel10k already installed"
    fi
}

# Setup asdf
setup_asdf() {
    log_info "Setting up asdf..."
    
    # Source asdf if already installed
    if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
        source "$HOME/.asdf/asdf.sh"
    fi
    
    # Install asdf plugins
    local plugins=("nodejs" "python" "rust" "lua" "terraform" "neovim" "tmux")
    for plugin in "${plugins[@]}"; do
        if ! asdf plugin list | grep -q "^${plugin}$"; then
            log_info "Adding asdf plugin: $plugin"
            asdf plugin add "$plugin"
        fi
    done
    
    # Install versions from .tool-versions
    if [[ -f ".tool-versions" ]]; then
        log_info "Installing asdf packages from .tool-versions..."
        asdf install
        log_success "asdf packages installed"
    fi
    
    # Setup completions
    mkdir -p "${ASDF_DATA_DIR:-$HOME/.asdf}/completions"
    asdf completion zsh > "${ASDF_DATA_DIR:-$HOME/.asdf}/completions/_asdf"
}

# Install Python packages via pipx
install_pipx_packages() {
    log_info "Installing Python packages via pipx..."
    if [[ -f "requirements-pipx.txt" ]]; then
        while IFS= read -r package || [[ -n "$package" ]]; do
            # Skip comments and empty lines
            [[ "$package" =~ ^#.*$ ]] || [[ -z "$package" ]] && continue
            
            log_info "Installing $package via pipx"
            pipx install "$package"
        done < requirements-pipx.txt
        
        # Setup pipx completions
        pipx completions
        log_success "pipx packages installed"
    fi
}

# Install global npm packages
install_npm_packages() {
    log_info "Installing global npm packages..."
    
    # Source asdf to ensure npm is available
    if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
        source "$HOME/.asdf/asdf.sh"
    fi
    
    npm install -g @anthropic-ai/claude-code
    log_success "Global npm packages installed"
}

# Install tmux plugin manager
install_tpm() {
    log_info "Installing Tmux Plugin Manager (tpm)..."
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$tpm_dir" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
        log_success "tpm installed"
    else
        log_success "tpm already installed"
    fi
}

# Install fonts
install_fonts() {
    log_info "Installing MesloLGS Nerd Fonts..."
    if [[ -d "zsh/fonts" ]]; then
        cp -r zsh/fonts/* "$HOME/Library/Fonts/"
        log_success "Fonts installed"
    else
        log_warn "Font directory not found, skipping font installation"
    fi
}

# Create symbolic links
create_symlinks() {
    log_info "Creating symbolic links for configuration files..."
    
    local dotfiles_dir=$(pwd)
    
    # Backup existing files
    backup_if_exists() {
        local file=$1
        if [[ -f "$file" || -d "$file" ]] && [[ ! -L "$file" ]]; then
            log_warn "Backing up existing $file to $file.backup"
            mv "$file" "$file.backup"
        fi
    }
    
    # Create symlinks
    create_link() {
        local source=$1
        local target=$2
        local target_dir=$(dirname "$target")
        
        backup_if_exists "$target"
        mkdir -p "$target_dir"
        ln -sf "$source" "$target"
        log_success "Linked $source -> $target"
    }
    
    # ZSH configuration
    create_link "$dotfiles_dir/zsh/.zshrc" "$HOME/.zshrc"
    create_link "$dotfiles_dir/zsh/.zprofile" "$HOME/.zprofile"
    create_link "$dotfiles_dir/zsh/.zshenv" "$HOME/.zshenv"
    
    # Neovim configuration
    create_link "$dotfiles_dir/nvim" "$HOME/.config/nvim"
    
    # Tmux configuration
    create_link "$dotfiles_dir/tmux/.tmux.conf" "$HOME/.config/tmux/tmux.conf"
    
    # Git configuration
    create_link "$dotfiles_dir/.gitconfig" "$HOME/.gitconfig"
}

# Main installation function
main() {
    log_info "Starting dotfiles installation..."
    
    check_macos
    install_homebrew
    install_brew_packages
    install_oh_my_zsh
    install_powerlevel10k
    setup_asdf
    install_pipx_packages
    install_npm_packages
    install_tpm
    install_fonts
    create_symlinks
    
    log_success "Dotfiles installation completed!"
    log_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
    log_info "You may need to configure powerlevel10k by running 'p10k configure'"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
