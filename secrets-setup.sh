#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_banner() {
    cat << "EOF"
   ____                     _
  / ___|  ___  ___ _ __ ___| |_ ___
  \___ \ / _ \/ __| '__/ _ \ __/ __|
   ___) |  __/ (__| | |  __/ |_\__ \
  |____/ \___|\___|_|  \___|\__|___/

Chezmoi Secrets Management Setup
EOF
}

# Install age encryption tool
install_age() {
    log_info "Installing age encryption tool..."

    if command -v age &> /dev/null; then
        log_success "age is already installed"
        return
    fi

    if command -v brew &> /dev/null; then
        brew install age
    elif command -v nix &> /dev/null; then
        nix profile install nixpkgs#age
    else
        log_error "Please install age manually: https://github.com/FiloSottile/age"
        exit 1
    fi

    log_success "age encryption tool installed"
}

# Generate age key pair
generate_age_key() {
    local age_config_dir="$HOME/.config/age"
    local age_key_file="$age_config_dir/key.txt"

    log_info "Setting up age encryption keys..."

    if [[ -f "$age_key_file" ]]; then
        log_warn "Age key already exists at $age_key_file"
        echo -n "Do you want to generate a new key? (y/N): "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY])
                ;;
            *)
                log_info "Using existing key"
                return
                ;;
        esac
    fi

    # Create age config directory
    mkdir -p "$age_config_dir"
    chmod 700 "$age_config_dir"

    # Generate new key
    age-keygen -o "$age_key_file"
    chmod 600 "$age_key_file"

    log_success "Age key generated at $age_key_file"
}

# Show public key and update instructions
show_public_key() {
    local age_key_file="$HOME/.config/age/key.txt"

    if [[ ! -f "$age_key_file" ]]; then
        log_error "Age key not found at $age_key_file"
        return 1
    fi

    local public_key
    public_key=$(age-keygen -y "$age_key_file")

    cat << EOF

${BLUE}========================================${NC}
${BLUE}Age Setup Complete${NC}
${BLUE}========================================${NC}

${GREEN}Your age public key is:${NC}
${YELLOW}${public_key}${NC}

${GREEN}Next steps:${NC}

1. Update your Chezmoi configuration:
   ${YELLOW}chezmoi edit-config${NC}

   Add this to the [age] section:
   ${YELLOW}[age]
   identity = "~/.config/age/key.txt"
   recipient = "${public_key}"${NC}

2. Encrypt your first secret file:
   ${YELLOW}chezmoi add --encrypt ~/.env.work${NC}
   ${YELLOW}chezmoi add --encrypt ~/.env.personal${NC}

3. Apply your configuration:
   ${YELLOW}chezmoi apply${NC}

${GREEN}Example encrypted files:${NC}
- Work secrets: ${YELLOW}~/.env.work${NC}
- Personal secrets: ${YELLOW}~/.env.personal${NC}
- SSH private keys: ${YELLOW}~/.ssh/id_ed25519${NC}
- API tokens and passwords

${BLUE}Security Notes:${NC}
- Keep your private key (${YELLOW}~/.config/age/key.txt${NC}) secure and backed up
- Your dotfiles repository can be public - encrypted files are safe
- The public key can be shared - it's only used for encryption

EOF
}

# Create example secret files
create_example_secrets() {
    log_info "Creating example secret files..."

    # Work environment
    if [[ ! -f "$HOME/.env.work" ]]; then
        cat > "$HOME/.env.work" << 'EOF'
# Work environment variables
export WORK_API_KEY="your-work-api-key-here" # pragma: allowlist secret
export COMPANY_VPN_PASSWORD="your-vpn-password" # pragma: allowlist secret
export AWS_SECRET_ACCESS_KEY="your-aws-secret-key" # pragma: allowlist secret
EOF
        log_success "Created example ~/.env.work"
    fi

    # Personal environment
    if [[ ! -f "$HOME/.env.personal" ]]; then
        cat > "$HOME/.env.personal" << 'EOF'
# Personal environment variables
export GITHUB_TOKEN="ghp_your-github-token" # pragma: allowlist secret
export OPENAI_API_KEY="sk-your-openai-key" # pragma: allowlist secret
export ANTHROPIC_API_KEY="your-anthropic-key" # pragma: allowlist secret
EOF
        log_success "Created example ~/.env.personal"
    fi
}

# Initialize chezmoi with encryption
init_chezmoi_encryption() {
    log_info "Initializing Chezmoi with encryption support..."

    # Check if chezmoi is installed
    if ! command -v chezmoi &> /dev/null; then
        log_warn "Chezmoi not found. Installing..."
        if command -v brew &> /dev/null; then
            brew install chezmoi
        else
            sh -c "$(curl -fsLS get.chezmoi.io)"
        fi
    fi

    # Initialize chezmoi if not already done
    if [[ ! -d "$HOME/.local/share/chezmoi" ]]; then
        log_info "Initializing chezmoi..."
        chezmoi init
    fi

    log_success "Chezmoi initialized with encryption support"
}

# Main setup function
main() {
    show_banner
    echo

    log_info "Setting up secrets management with Chezmoi and age..."

    install_age
    generate_age_key
    init_chezmoi_encryption
    create_example_secrets
    show_public_key

    cat << EOF

${GREEN}========================================${NC}
${GREEN}Setup Complete!${NC}
${GREEN}========================================${NC}

To start using encrypted secrets:

1. Edit your secret files:
   ${YELLOW}vim ~/.env.work${NC}
   ${YELLOW}vim ~/.env.personal${NC}

2. Add them to Chezmoi encrypted:
   ${YELLOW}chezmoi add --encrypt ~/.env.work${NC}
   ${YELLOW}chezmoi add --encrypt ~/.env.personal${NC}

3. Update Chezmoi config with your public key (shown above)

4. Apply configuration:
   ${YELLOW}chezmoi apply${NC}

Your secrets are now managed securely! 🔐

EOF
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
