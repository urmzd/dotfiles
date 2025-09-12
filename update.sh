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
   __  __          __      __       
  / / / /___  ____/ /___ _/ /____   
 / / / / __ \/ __  / __ `/ __/ _ \  
/ /_/ / /_/ / /_/ / /_/ / /_/  __/  
\____/ .___/\__,_/\__,_/\__/\___/   
    /_/                            
                                   
Dotfiles Update & Maintenance Tool
EOF
}

# Update dotfiles repository
update_dotfiles_repo() {
    log_info "Updating dotfiles repository..."
    
    local current_dir=$(pwd)
    local dotfiles_dir="$HOME/.dotfiles"
    
    if [[ -d "$dotfiles_dir/.git" ]]; then
        cd "$dotfiles_dir"
        
        # Stash any local changes
        if ! git diff --quiet HEAD; then
            log_warn "Stashing local changes..."
            git stash push -m "Auto-stash before update $(date)"
        fi
        
        # Pull latest changes
        git pull origin main || {
            log_warn "Failed to pull latest changes from repository"
        }
        
        cd "$current_dir"
        log_success "Dotfiles repository updated"
    else
        log_warn "Not a git repository, skipping repository update"
    fi
}

# Update Homebrew and packages
update_homebrew() {
    log_info "Updating Homebrew..."
    
    if command -v brew &> /dev/null; then
        # Update Homebrew itself
        brew update
        
        # Upgrade installed packages
        brew upgrade
        
        # Update from Brewfile if it exists
        if [[ -f "Brewfile" ]]; then
            log_info "Installing/updating packages from Brewfile..."
            brew bundle --file=Brewfile
        fi
        
        # Cleanup old versions
        brew cleanup
        
        log_success "Homebrew updated"
    else
        log_warn "Homebrew not found, skipping brew updates"
    fi
}

# Update asdf and plugins
update_asdf() {
    log_info "Updating asdf and plugins..."
    
    if command -v asdf &> /dev/null; then
        # Source asdf
        if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
            source "$HOME/.asdf/asdf.sh"
        fi
        
        # Update asdf itself
        asdf update || log_warn "Failed to update asdf"
        
        # Update all plugins
        asdf plugin update --all
        
        # Update languages to latest versions if .tool-versions exists
        if [[ -f ".tool-versions" ]]; then
            log_info "Checking for newer versions in .tool-versions..."
            
            # For each tool, check if newer versions are available
            while IFS= read -r line || [[ -n "$line" ]]; do
                # Skip comments and empty lines
                [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]] && continue
                
                local tool=$(echo "$line" | awk '{print $1}')
                local version=$(echo "$line" | awk '{print $2}')
                
                if [[ "$version" == "latest" ]]; then
                    log_info "Installing/updating latest $tool..."
                    asdf install "$tool" latest
                    asdf global "$tool" latest
                elif [[ "$version" == "stable" ]]; then
                    log_info "Installing/updating stable $tool..."
                    asdf install "$tool" stable
                    asdf global "$tool" stable
                else
                    log_info "Installing/updating $tool $version..."
                    asdf install "$tool" "$version"
                fi
            done < ".tool-versions"
        fi
        
        # Reshim to ensure all binaries are available
        asdf reshim
        
        log_success "asdf updated"
    else
        log_warn "asdf not found, skipping asdf updates"
    fi
}

# Update pipx packages
update_pipx() {
    log_info "Updating pipx packages..."
    
    if command -v pipx &> /dev/null; then
        # Upgrade all pipx packages
        pipx upgrade-all
        
        # Install any missing packages from requirements-pipx.txt
        if [[ -f "requirements-pipx.txt" ]]; then
            while IFS= read -r package || [[ -n "$package" ]]; do
                # Skip comments and empty lines
                [[ "$package" =~ ^#.*$ ]] || [[ -z "$package" ]] && continue
                
                if ! pipx list | grep -q "package $package"; then
                    log_info "Installing missing pipx package: $package"
                    pipx install "$package"
                fi
            done < requirements-pipx.txt
        fi
        
        log_success "pipx packages updated"
    else
        log_warn "pipx not found, skipping pipx updates"
    fi
}

# Update npm global packages
update_npm() {
    log_info "Updating global npm packages..."
    
    # Source asdf to ensure npm is available
    if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
        source "$HOME/.asdf/asdf.sh"
    fi
    
    if command -v npm &> /dev/null; then
        # Update npm itself
        npm update -g npm
        
        # Update all global packages
        npm update -g
        
        log_success "npm packages updated"
    else
        log_warn "npm not found, skipping npm updates"
    fi
}

# Update oh-my-zsh
update_oh_my_zsh() {
    log_info "Updating oh-my-zsh..."
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        # Update oh-my-zsh
        cd "$HOME/.oh-my-zsh"
        git pull origin master || log_warn "Failed to update oh-my-zsh"
        
        # Update powerlevel10k theme if installed
        local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
        if [[ -d "$p10k_dir" ]]; then
            log_info "Updating powerlevel10k theme..."
            cd "$p10k_dir"
            git pull origin master || log_warn "Failed to update powerlevel10k"
        fi
        
        log_success "oh-my-zsh updated"
    else
        log_warn "oh-my-zsh not found, skipping oh-my-zsh update"
    fi
}

# Update tmux plugins
update_tmux_plugins() {
    log_info "Updating tmux plugins..."
    
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" ]]; then
        # Update TPM itself
        cd "$tpm_dir"
        git pull origin master || log_warn "Failed to update tpm"
        
        # Update all tmux plugins if tmux is running
        if pgrep -x "tmux" > /dev/null; then
            log_info "Updating tmux plugins..."
            "$tmp_dir/bin/update_plugins" all || log_warn "Failed to update tmux plugins automatically"
            log_info "You can also update tmux plugins manually with: prefix + U"
        else
            log_info "Tmux is not running. Start tmux and press prefix + U to update plugins"
        fi
        
        log_success "tmux plugins updated"
    else
        log_warn "TPM not found, skipping tmux plugin updates"
    fi
}

# Update Neovim plugins
update_nvim_plugins() {
    log_info "Updating Neovim plugins..."
    
    if command -v nvim &> /dev/null; then
        # Update Neovim plugins using lazy.nvim
        nvim --headless "+Lazy! sync" +qa
        log_success "Neovim plugins updated"
    else
        log_warn "Neovim not found, skipping plugin updates"
    fi
}

# Cleanup function
cleanup() {
    log_info "Performing cleanup..."
    
    # Clean Homebrew
    if command -v brew &> /dev/null; then
        brew cleanup
        brew doctor || true
    fi
    
    # Clean asdf
    if command -v asdf &> /dev/null && [[ -f "$HOME/.asdf/asdf.sh" ]]; then
        source "$HOME/.asdf/asdf.sh"
        # Remove unused versions (keep current and previous)
        # This is commented out as it can be destructive
        # asdf list all | head -n -2 | xargs -I {} asdf uninstall {} || true
    fi
    
    # Clean npm cache
    if command -v npm &> /dev/null; then
        npm cache clean --force
    fi
    
    log_success "Cleanup completed"
}

# Show update summary
show_summary() {
    cat << "EOF"

========================================
Update Summary
========================================

The following components were updated:
✓ Dotfiles repository
✓ Homebrew packages  
✓ asdf version manager and plugins
✓ pipx Python applications
✓ npm global packages
✓ oh-my-zsh and themes
✓ tmux plugins
✓ Neovim plugins

Next steps:
• Restart your terminal or run: source ~/.zshrc
• If tmux is running, press prefix + U to update plugins
• Check for any configuration changes in ~/.dotfiles

EOF
}

# Main update function
main() {
    show_banner
    echo
    
    log_info "Starting comprehensive update process..."
    
    # Change to dotfiles directory
    cd "$HOME/.dotfiles" || {
        log_error "Could not change to ~/.dotfiles directory"
        exit 1
    }
    
    update_dotfiles_repo
    update_homebrew
    update_asdf
    update_pipx
    update_npm
    update_oh_my_zsh
    update_tmux_plugins
    update_nvim_plugins
    cleanup
    
    show_summary
    log_success "Update process completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi