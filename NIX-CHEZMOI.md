# Nix + Chezmoi Integration Guide

This guide explains how to use the enhanced dotfiles setup with Nix and Chezmoi for a modern, reproducible development environment.

## 🚀 Quick Start

### One-Command Setup

```bash
curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/bootstrap-nix-chezmoi.sh | bash
```

### Manual Setup

```bash
git clone https://github.com/urmzd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap-nix-chezmoi.sh
```

## 🏗️ Architecture Overview

This setup combines the best of both worlds with a clear separation of responsibilities:

**Nix** (`flake.nix`):
- Primary package manager for all development tools
- Reproducible development environments
- Language-specific toolchains (Node.js, Python, Rust, Go, etc.)

**Homebrew** (`Brewfile`):
- Minimal macOS-specific packages only
- Docker ecosystem (`colima`, `docker`, Docker Desktop)
- System utilities (`pipx`, `gemini-cli`)

**Chezmoi**:
- Intelligent dotfiles management with templating
- Cross-platform configuration adaptation
- Encrypted secrets management
- Automatic symlinking to proper locations

```
~/.dotfiles/
├── flake.nix                    # Nix development environments
├── flake.lock                   # Pinned dependencies
├── Brewfile                     # Minimal macOS-specific packages
├── .envrc                       # direnv configuration
├── .chezmoi.toml.tmpl          # Chezmoi configuration template
├── bootstrap-nix-chezmoi.sh    # Unified setup script
├── secrets-setup.sh            # Secrets management setup
│
├── dot_zshrc.tmpl              # Zsh configuration template
├── dot_zshenv.tmpl             # Zsh environment template
├── dot_zprofile.tmpl           # Zsh profile template
├── dot_gitconfig.tmpl          # Git configuration template
├── dot_tmux.conf.tmpl          # Tmux configuration template
├── dot_config/                 # XDG config directory
│   └── nvim/                   # Neovim configuration
│       ├── init.lua            # Main Neovim config
│       ├── lua/                # Lua modules
│       └── ftplugin/           # File type plugins
├── private_dot_ssh/            # SSH configurations
│   └── encrypted_*.age         # Encrypted secret files
└── scripts/                    # Utility scripts
    └── security-audit.sh
```

## 🔗 Configuration Linking Process

Chezmoi automatically links dotfiles from the repository to your home directory:

### File Mapping
```bash
# Chezmoi source → Target location
~/.dotfiles/dot_zshrc.tmpl        → ~/.zshrc
~/.dotfiles/dot_zshenv.tmpl       → ~/.zshenv
~/.dotfiles/dot_zprofile.tmpl     → ~/.zprofile
~/.dotfiles/dot_gitconfig.tmpl    → ~/.gitconfig
~/.dotfiles/dot_tmux.conf.tmpl    → ~/.tmux.conf
~/.dotfiles/dot_config/nvim/      → ~/.config/nvim/
~/.dotfiles/private_dot_ssh/      → ~/.ssh/
```

### Template Processing
Templates (`.tmpl` files) are processed with context from `.chezmoi.toml`:

```bash
# Variables available in templates:
{{ .name }}                    # Your full name
{{ .email }}                   # Your email address
{{ .github_username }}         # Your GitHub username
{{ .is_personal }}             # Personal machine flag
{{ .is_work }}                 # Work machine flag
{{ .use_nix }}                 # Nix usage flag
{{ .is_macos }}                # macOS detection
{{ .is_linux }}                # Linux detection
{{ lookPath "command" }}       # Check if command exists
```

### Setup Flow
1. **Bootstrap script** installs Nix + minimal Homebrew packages
2. **Chezmoi init <repo>** clones repository to ~/.local/share/chezmoi and processes templates
3. **Chezmoi apply** creates symlinks and copies files to target locations
4. **Direnv** automatically activates Nix environments per directory

### ⚠️ Critical Setup Notes for New Users

**After running the bootstrap script, you MUST initialize chezmoi:**

```bash
# Initialize chezmoi with this repository (REQUIRED for new users)
chezmoi init https://github.com/urmzd/.dotfiles.git

# This will:
# - Clone the repository to ~/.local/share/chezmoi
# - Prompt for your personal configuration (name, email, etc.)
# - Set up template variables for intelligent dotfile generation

# Apply the configuration
chezmoi apply
```

**Required Dependencies:**
The setup script now automatically installs:
- `reattach-to-user-namespace` - Required for tmux clipboard integration on macOS
- Oh My Zsh and Powerlevel10k theme
- TPM (Tmux Plugin Manager)

### 🌍 Global Development Tools Access

**New Feature:** Nix development tools (nvim, python, etc.) are now available globally by default!

The setup creates a global `~/.envrc` that provides access to all Nix development tools from any directory:

```bash
# Works from anywhere now:
cd ~/Documents        # ✅ nvim, python, etc. available
cd ~/projects/work    # ✅ Tools available here too
cd /tmp              # ✅ And here as well
```

**How it works:**
- Chezmoi creates `~/.envrc` that references the main Nix flake
- Direnv automatically loads the environment in any directory
- All development tools become globally accessible
- Project-specific `.envrc` files can still override for specialized environments

## 🎯 Key Features

### Reproducible Development Environments

- **Language-specific shells**: Node.js, Python, Rust, Go, Lua
- **Pinned dependencies**: Exact versions via flake.lock
- **Instant activation**: direnv automatically switches environments
- **Cross-platform**: Works on macOS, Linux, and WSL

### Intelligent Configuration Management

- **Machine-aware templates**: Different configs for work/personal
- **Secrets management**: Encrypted files with age
- **Cross-platform detection**: Automatic OS/package manager detection
- **Version control friendly**: Public repo with private secrets

## 📚 Usage Guide

### Development Environments

#### Automatic Activation (Recommended)

```bash
cd ~/.dotfiles
# Environment automatically activates via direnv
```

#### Manual Activation

```bash
# Enter specific development shells
nix develop .#node      # Node.js environment
nix develop .#python    # Python environment
nix develop .#rust      # Rust environment
nix develop .#go        # Go environment
nix develop .#devops    # DevOps tools
nix develop .#full      # All environments
```

#### Project-Specific Environments

```bash
# In any project directory
echo "use flake ~/.dotfiles#node" > .envrc
direnv allow
# Now this project uses Node.js environment automatically
```

### Configuration Management

#### Apply Configurations

```bash
chezmoi apply
```

#### Edit Templates

```bash
chezmoi edit ~/.gitconfig    # Edit templated git config
chezmoi edit ~/.zshrc        # Edit templated zsh config
```

#### View Differences

```bash
chezmoi diff                 # See what would change
chezmoi diff ~/.gitconfig    # Check specific file
```

#### Machine Configuration

```bash
chezmoi data                 # View current template variables
chezmoi edit-config          # Edit chezmoi configuration
```

### Secrets Management

#### Setup Encryption

```bash
./secrets-setup.sh
```

#### Add Encrypted Files

```bash
chezmoi add --encrypt ~/.env.work
chezmoi add --encrypt ~/.ssh/id_ed25519
chezmoi add --encrypt ~/.aws/credentials
```

#### Edit Encrypted Files

```bash
chezmoi edit --apply ~/.env.work
```

## 🔧 Advanced Configuration

### Template Variables

Templates can use these variables:

- `{{ .name }}` - Your full name
- `{{ .email }}` - Your email address
- `{{ .is_personal }}` - Personal machine flag
- `{{ .is_work }}` - Work machine flag
- `{{ .is_macos }}` - Running on macOS
- `{{ .has_homebrew }}` - Homebrew available
- `{{ .has_nix }}` - Nix available
- `{{ .use_secrets }}` - Secrets management enabled

### Example Template Usage

```bash
# In dot_gitconfig.tmpl
[user]
    name = {{ .name | quote }}
    email = {{ .email | quote }}
{{- if .is_work }}
    signingkey = "work-gpg-key"
{{- else }}
    signingkey = "personal-gpg-key"
{{- end }}

{{- if .has_homebrew }}
# Homebrew-specific settings
[difftool "sourcetree"]
    cmd = opendiff "$LOCAL" "$REMOTE"
{{- end }}
```

### Custom Development Shells

Add to `flake.nix`:

```nix
# Custom project shell
myproject = pkgs.mkShell {
  name = "myproject-shell";
  buildInputs = commonTools ++ [
    pkgs.postgresql
    pkgs.redis
    pkgs.nodejs_20
  ];

  shellHook = ''
    echo "🚀 MyProject Development Environment"
    export DATABASE_URL="postgresql://localhost/myproject"
  '';
};
```

## 🔄 Migration Guide

### From Existing Shell Setup

The legacy shell-based setup has been removed in favor of the modern Nix + Chezmoi approach.

**Updates:** Use `nix flake update` to update dependencies
**Backups:** Chezmoi provides built-in backup functionality via `chezmoi diff` and version control

### From asdf to Nix

**Before:**

```bash
asdf install nodejs 23.9.0
asdf global nodejs 23.9.0
```

**After:**

```bash
nix develop .#node
# or with direnv: just cd into directory with .envrc
```

### From Manual Dotfiles to Chezmoi

**Before:**

```bash
ln -s ~/.dotfiles/zsh/.zshrc ~/.zshrc
```

**After:**

```bash
chezmoi add ~/.zshrc
chezmoi apply
```

## 🛠️ Maintenance

### Update All Systems

```bash
cd ~/.dotfiles

# Update Nix packages
nix flake update

# Update Homebrew (GUI apps)
brew update && brew upgrade

# Update Chezmoi templates
chezmoi apply

# Update dotfiles repo
git pull origin main
```

### Add New Tools

#### Add to Nix Environment

Edit `flake.nix` and add to appropriate environment:

```nix
pythonEnv = with pkgs; [
  python313
  python313Packages.requests
  python313Packages.your-new-package  # Add here
];
```

#### Add Homebrew GUI App

```bash
brew install --cask your-new-app
```

### Troubleshooting

#### Nix Issues

```bash
# Rebuild environment
nix develop .#node --rebuild

# Clear cache
nix-collect-garbage

# Check flake
nix flake check
```

#### Chezmoi Issues

```bash
# Verify templates
chezmoi execute-template --init --promptString name=test < ~/.dotfiles/.chezmoi.toml.tmpl

# Reset configuration
chezmoi init --force

# Debug template
chezmoi execute-template < file.tmpl
```

#### Tmux Exits with "[exited]" Status

Common on macOS when `reattach-to-user-namespace` is missing:

```bash
# Install the required dependency
brew install reattach-to-user-namespace

# Test tmux
tmux new-session -d -s test 'echo "test"'
tmux list-sessions  # Should show the session
tmux kill-session -t test
```

#### Chezmoi Init Not Prompting

If `chezmoi init` exits immediately without prompting:

```bash
# Use explicit prompts if TTY access fails
chezmoi init --promptString name="Your Name" \
           --promptString email="your@email.com" \
           --promptString github_username="yourusername" \
           --promptBool is_personal=true \
           --promptBool use_nix=true

# Or manually create config and then apply
chezmoi edit-config  # Edit with system editor
chezmoi apply        # Apply with new config
```

#### Template Variable Errors (`map has no entry for key "is_macos"`)

This error occurs when the chezmoi configuration isn't properly loaded, usually due to encryption configuration issues:

```bash
# Check if template variables are available
chezmoi data | jq '.is_macos'  # Should return true/false, not null

# If null, check chezmoi config
cat ~/.config/chezmoi/chezmoi.toml | grep -A 10 "\[data\]"

# Verify age encryption is properly configured
ls -la ~/.config/age/key.txt  # Should exist
chezmoi data | grep -A 5 "age"  # Should show age configuration

# Fix: Regenerate config if needed
rm ~/.config/chezmoi/chezmoi.toml
chezmoi init https://github.com/urmzd/.dotfiles.git  # Will prompt for configuration
```

#### Age Encryption Issues (`no encryption` or `failed to read header`)

```bash
# Check for improperly encrypted files (plain text with .age extension)
find ~/.local/share/chezmoi -name "*.age" -exec file {} \; | grep -v "ASCII"

# Remove any plain text files masquerading as encrypted
rm ~/.local/share/chezmoi/path/to/plain-text.age

# Ensure encryption config is at top level of chezmoi.toml
head -10 ~/.config/chezmoi/chezmoi.toml  # Should show 'encryption = "age"'

# Re-encrypt files properly if needed
chezmoi add --encrypt ~/.env.personal
```

#### direnv Issues

```bash
# Reload environment
direnv reload

# Check status
direnv status

# Allow new .envrc
direnv allow
```

## 🌟 Benefits Over Traditional Approaches

### vs. Shell Scripts Only

- ✅ Reproducible environments (Nix)
- ✅ Intelligent templating (Chezmoi)
- ✅ Secrets management built-in
- ✅ Cross-platform compatibility

### vs. Ansible

- ✅ Faster iteration (no YAML complexity)
- ✅ Better for personal use
- ✅ Reproducible package versions
- ✅ Development-focused

### vs. Docker

- ✅ Native performance
- ✅ Host system integration
- ✅ Persistent environments
- ✅ Better for interactive development

## 📖 Further Reading

- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)
- [Chezmoi User Guide](https://www.chezmoi.io/user-guide/setup/)
- [direnv Documentation](https://direnv.net/)
- [Age Encryption](https://github.com/FiloSottile/age)

---

_This modern approach combines the power of Nix's reproducible environments with Chezmoi's intelligent configuration management for a truly next-generation dotfiles experience._
