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
    ____             __                
   / __ )____ ______/ /____  ______  
  / __  / __ `/ ___/ //_/ / / / __ \ 
 / /_/ / /_/ / /__/ ,< / /_/ / /_/ / 
/_____/\__,_/\___/_/|_|\__,_/ .___/  
                          /_/       
                                    
Configuration Backup Tool
EOF
}

# Create backup directory
create_backup_dir() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="$HOME/.dotfiles_backup_$timestamp"
    
    log_info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Create subdirectories
    mkdir -p "$BACKUP_DIR/config"
    mkdir -p "$BACKUP_DIR/home"
    mkdir -p "$BACKUP_DIR/ssh"
    mkdir -p "$BACKUP_DIR/git"
    
    log_success "Backup directory created"
}

# Backup shell configurations
backup_shell_configs() {
    log_info "Backing up shell configurations..."
    
    local configs=(
        ".zshrc"
        ".zprofile" 
        ".zshenv"
        ".bashrc"
        ".bash_profile"
        ".profile"
    )
    
    for config in "${configs[@]}"; do
        if [[ -f "$HOME/$config" ]]; then
            cp "$HOME/$config" "$BACKUP_DIR/home/" 2>/dev/null || true
            log_success "Backed up $config"
        fi
    done
}

# Backup configuration directories
backup_config_dirs() {
    log_info "Backing up configuration directories..."
    
    local config_dirs=(
        "nvim"
        "tmux"
        "alacritty"
        "kitty"
        "wezterm"
        "git"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [[ -d "$HOME/.config/$dir" ]]; then
            cp -r "$HOME/.config/$dir" "$BACKUP_DIR/config/" 2>/dev/null || true
            log_success "Backed up ~/.config/$dir"
        fi
    done
}

# Backup git configurations
backup_git_configs() {
    log_info "Backing up git configurations..."
    
    local git_files=(
        ".gitconfig"
        ".gitignore_global"
        ".gitmessage"
    )
    
    for file in "${git_files[@]}"; do
        if [[ -f "$HOME/$file" ]]; then
            cp "$HOME/$file" "$BACKUP_DIR/git/" 2>/dev/null || true
            log_success "Backed up $file"
        fi
    done
}

# Backup SSH configurations (excluding private keys)
backup_ssh_configs() {
    log_info "Backing up SSH configurations..."
    
    if [[ -d "$HOME/.ssh" ]]; then
        # Only backup config and public keys, not private keys
        if [[ -f "$HOME/.ssh/config" ]]; then
            cp "$HOME/.ssh/config" "$BACKUP_DIR/ssh/" 2>/dev/null || true
            log_success "Backed up SSH config"
        fi
        
        # Backup public keys only
        for pubkey in "$HOME/.ssh"/*.pub; do
            if [[ -f "$pubkey" ]]; then
                cp "$pubkey" "$BACKUP_DIR/ssh/" 2>/dev/null || true
                log_success "Backed up $(basename "$pubkey")"
            fi
        done
    else
        log_warn "No SSH directory found"
    fi
}

# Backup package manager files
backup_package_files() {
    log_info "Backing up package manager files..."
    
    local package_files=(
        "Brewfile"
        ".tool-versions"
        "requirements-pipx.txt"
        "package.json"
        "Pipfile"
        "requirements.txt"
        "Cargo.toml"
        "go.mod"
    )
    
    for file in "${package_files[@]}"; do
        # Check in home directory
        if [[ -f "$HOME/$file" ]]; then
            cp "$HOME/$file" "$BACKUP_DIR/home/" 2>/dev/null || true
            log_success "Backed up ~/$file"
        fi
        
        # Check in dotfiles directory
        if [[ -f "$HOME/.dotfiles/$file" ]]; then
            cp "$HOME/.dotfiles/$file" "$BACKUP_DIR/home/" 2>/dev/null || true
            log_success "Backed up ~/.dotfiles/$file"
        fi
    done
}

# Backup application-specific configurations
backup_app_configs() {
    log_info "Backing up application-specific configurations..."
    
    # VS Code settings
    if [[ -d "$HOME/Library/Application Support/Code/User" ]]; then
        mkdir -p "$BACKUP_DIR/vscode"
        cp "$HOME/Library/Application Support/Code/User/settings.json" "$BACKUP_DIR/vscode/" 2>/dev/null || true
        cp "$HOME/Library/Application Support/Code/User/keybindings.json" "$BACKUP_DIR/vscode/" 2>/dev/null || true
        log_success "Backed up VS Code settings"
    fi
    
    # Vim/Neovim
    if [[ -f "$HOME/.vimrc" ]]; then
        cp "$HOME/.vimrc" "$BACKUP_DIR/home/" 2>/dev/null || true
        log_success "Backed up .vimrc"
    fi
    
    # Tmux
    if [[ -f "$HOME/.tmux.conf" ]]; then
        cp "$HOME/.tmux.conf" "$BACKUP_DIR/home/" 2>/dev/null || true
        log_success "Backed up .tmux.conf"
    fi
}

# Create backup manifest
create_manifest() {
    log_info "Creating backup manifest..."
    
    local manifest="$BACKUP_DIR/BACKUP_MANIFEST.txt"
    
    cat > "$manifest" << EOF
Dotfiles Backup Manifest
========================
Backup Date: $(date)
Backup Location: $BACKUP_DIR
System: $(uname -a)
User: $(whoami)

Backed up files and directories:
EOF
    
    # List all backed up files
    find "$BACKUP_DIR" -type f -not -name "BACKUP_MANIFEST.txt" | sed "s|$BACKUP_DIR/||" | sort >> "$manifest"
    
    log_success "Backup manifest created"
}

# Create restore script
create_restore_script() {
    log_info "Creating restore script..."
    
    local restore_script="$BACKUP_DIR/restore.sh"
    
    cat > "$restore_script" << 'EOF'
#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

BACKUP_DIR=$(dirname "$(realpath "$0")")

log_info "Starting restore process from: $BACKUP_DIR"

# Confirm with user
echo -n "This will overwrite existing configurations. Continue? (y/N): "
read -r response
case "$response" in
    [yY][eE][sS]|[yY]) 
        ;;
    *)
        log_info "Restore cancelled"
        exit 0
        ;;
esac

# Restore home directory files
if [[ -d "$BACKUP_DIR/home" ]]; then
    for file in "$BACKUP_DIR/home"/*; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            if [[ -f "$HOME/$filename" ]]; then
                log_warn "Backing up existing $filename to $filename.restore-backup"
                mv "$HOME/$filename" "$HOME/$filename.restore-backup"
            fi
            cp "$file" "$HOME/"
            log_success "Restored $filename"
        fi
    done
fi

# Restore config directory
if [[ -d "$BACKUP_DIR/config" ]]; then
    for dir in "$BACKUP_DIR/config"/*; do
        if [[ -d "$dir" ]]; then
            dirname=$(basename "$dir")
            target="$HOME/.config/$dirname"
            if [[ -d "$target" ]]; then
                log_warn "Backing up existing $dirname to $dirname.restore-backup"
                mv "$target" "$target.restore-backup"
            fi
            mkdir -p "$HOME/.config"
            cp -r "$dir" "$HOME/.config/"
            log_success "Restored ~/.config/$dirname"
        fi
    done
fi

# Restore SSH config (not keys)
if [[ -d "$BACKUP_DIR/ssh" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    for file in "$BACKUP_DIR/ssh"/*; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            cp "$file" "$HOME/.ssh/"
            
            # Set appropriate permissions
            if [[ "$filename" == "config" ]]; then
                chmod 600 "$HOME/.ssh/config"
            elif [[ "$filename" == *.pub ]]; then
                chmod 644 "$HOME/.ssh/$filename"
            fi
            
            log_success "Restored SSH $filename"
        fi
    done
fi

log_success "Restore completed!"
log_info "Please restart your terminal or source your shell configuration"

EOF
    
    chmod +x "$restore_script"
    log_success "Restore script created: $restore_script"
}

# Compress backup
compress_backup() {
    log_info "Compressing backup..."
    
    local archive_name="$(basename "$BACKUP_DIR").tar.gz"
    local archive_path="$HOME/$archive_name"
    
    tar -czf "$archive_path" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"
    
    if [[ -f "$archive_path" ]]; then
        log_success "Backup compressed to: $archive_path"
        log_info "Original backup directory: $BACKUP_DIR"
        
        # Ask if user wants to remove uncompressed backup
        echo -n "Remove uncompressed backup directory? (y/N): "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY]) 
                rm -rf "$BACKUP_DIR"
                log_success "Uncompressed backup removed"
                ;;
            *)
                log_info "Keeping both compressed and uncompressed backups"
                ;;
        esac
    else
        log_error "Failed to create compressed backup"
    fi
}

# Show backup summary
show_summary() {
    cat << EOF

========================================
Backup Summary
========================================

Backup completed successfully!

Location: $BACKUP_DIR
Archive: $HOME/$(basename "$BACKUP_DIR").tar.gz (if compressed)

Backed up:
✓ Shell configurations (.zshrc, .bashrc, etc.)
✓ Application configs (~/.config/*)  
✓ Git configurations
✓ SSH configurations (public keys and config only)
✓ Package manager files (Brewfile, .tool-versions, etc.)
✓ Application-specific settings

To restore from this backup:
1. Extract the archive (if compressed)
2. Run: $BACKUP_DIR/restore.sh

EOF
}

# Main backup function
main() {
    show_banner
    echo
    
    log_info "Starting configuration backup process..."
    
    create_backup_dir
    backup_shell_configs
    backup_config_dirs
    backup_git_configs
    backup_ssh_configs
    backup_package_files
    backup_app_configs
    create_manifest
    create_restore_script
    
    # Ask if user wants to compress
    echo -n "Compress backup into tar.gz archive? (y/N): "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            compress_backup
            ;;
        *)
            log_info "Backup left uncompressed"
            ;;
    esac
    
    show_summary
    log_success "Backup process completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi