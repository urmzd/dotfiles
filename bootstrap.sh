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

# Banner
show_banner() {
    cat << "EOF"
    ____        __  _____ __         
   / __ \____  / /_/ __(_) /__  _____
  / / / / __ \/ __/ /_/ / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / /  __(__  ) 
/_____/\____/\__/_/ /_/_/\___/____/  
                                    
Personal Development Environment Setup
EOF
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS. Exiting."
        exit 1
    fi
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        log_error "Git is required but not installed. Please install Xcode Command Line Tools first:"
        log_error "xcode-select --install"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Clone or update dotfiles repository
setup_dotfiles_repo() {
    local dotfiles_dir="$HOME/.dotfiles"
    
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

# Make scripts executable
make_executable() {
    log_info "Making scripts executable..."
    chmod +x install.sh update.sh backup.sh 2>/dev/null || true
    log_success "Scripts are now executable"
}

# Show pre-installation summary
show_summary() {
    cat << EOF

${BLUE}========================================${NC}
${BLUE}Dotfiles Installation Summary${NC}
${BLUE}========================================${NC}

This will install and configure:

${GREEN}Package Managers:${NC}
  • Homebrew (macOS package manager)
  • asdf (version manager for languages)
  • pipx (Python applications in isolation)

${GREEN}Development Tools:${NC}
  • git, tree, fzf, ripgrep, ag
  • Docker + Colima
  • gemini-cli, claude-code

${GREEN}Languages & Runtimes:${NC}
  • Node.js 23.9.0
  • Python 3.13.5
  • Rust (stable)
  • Lua 5.4.7
  • Terraform 1.12.2

${GREEN}Terminal Environment:${NC}
  • Zsh with oh-my-zsh
  • Powerlevel10k theme
  • Neovim (latest stable)
  • Tmux with plugin manager
  • MesloLGS Nerd Fonts

${GREEN}Configurations:${NC}
  • Zsh configuration with aliases and plugins
  • Neovim setup with extensive plugin ecosystem
  • Tmux configuration with vim-like keybindings
  • Git configuration

${YELLOW}Note:${NC} Existing configurations will be backed up with .backup extension

EOF
}

# Prompt for confirmation
confirm_installation() {
    echo -n "Do you want to proceed with the installation? (y/N): "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            log_info "Installation cancelled by user"
            exit 0
            ;;
    esac
}

# Run the main installation
run_installation() {
    log_info "Starting installation process..."
    
    # Run the main install script
    ./install.sh
    
    log_success "Bootstrap completed successfully!"
    
    cat << EOF

${GREEN}========================================${NC}
${GREEN}Installation Complete!${NC}
${GREEN}========================================${NC}

${BLUE}Next Steps:${NC}
1. Restart your terminal or run: ${YELLOW}source ~/.zshrc${NC}
2. Configure powerlevel10k theme: ${YELLOW}p10k configure${NC}
3. Install tmux plugins by pressing: ${YELLOW}prefix + I${NC} in tmux
4. Restart Neovim to install plugins automatically

${BLUE}Available Commands:${NC}
  • ${YELLOW}./update.sh${NC} - Update all tools and configurations  
  • ${YELLOW}./backup.sh${NC} - Backup existing configurations

${BLUE}Troubleshooting:${NC}
  • Check ~/.zshrc for shell configuration
  • Check ~/.config/nvim for Neovim configuration
  • Check ~/.config/tmux for Tmux configuration

Enjoy your new development environment! 🚀

EOF
}

# Main function
main() {
    show_banner
    echo
    check_prerequisites
    setup_dotfiles_repo
    make_executable
    show_summary
    confirm_installation
    run_installation
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi