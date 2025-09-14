# dotfiles

A modern, reproducible development environment setup featuring Nix for package management and Chezmoi for intelligent dotfiles management.

> **Architecture:** Nix → Homebrew (minimal) → Chezmoi → Complete Environment

## 🏗️ Setup Architecture

**Package Management Strategy:**
- **Nix**: Primary package manager for all development tools (git, fzf, ripgrep, nvim, etc.)
- **Homebrew**: Minimal macOS-specific tools only (Docker, colima, pipx)
- **Chezmoi**: Smart dotfiles management with templating and cross-platform support

**Configuration Management:**
- **Chezmoi templates** manage all dotfiles (`.zshrc`, `.tmux.conf`, `nvim/`)
- **Automatic linking** to proper locations (`~/.config/nvim/`, etc.)
- **Environment-aware** templates adapt to personal/work/system differences

## 🚀 Quick Start

### One-Command Setup (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/urmzd/.dotfiles/main/bootstrap-nix-chezmoi.sh | bash
```

**This automatically:**
1. ✅ Installs Nix package manager with flakes enabled
2. ✅ Installs minimal Homebrew packages (Docker, etc.)
3. ✅ Sets up Chezmoi with this repository
4. ✅ Links all configurations (zsh, nvim, tmux)
5. ✅ Enables direnv for automatic environment switching

**What you get:**
- 🎯 Reproducible development environments with Nix
- 🔧 Intelligent dotfiles with Chezmoi templating
- 🔒 Built-in secrets management with age encryption
- 🚀 Automatic environment switching with direnv
- 📖 [Full Setup Guide](NIX-CHEZMOI.md)

## 📋 Manual Setup

If you prefer step-by-step setup:

```bash
# 1. Clone repository
git clone https://github.com/urmzd/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Run bootstrap script
./bootstrap-nix-chezmoi.sh

# 3. Verify setup
just --version      # Task runner
gh --version         # GitHub CLI
nvim --version       # Neovim
chezmoi --version    # Dotfiles manager
```

## ✅ Post-Setup Verification

After setup, verify everything is working:

```bash
# Check Nix development environments
nix develop          # Default environment
nix develop .#node   # Node.js environment
nix develop .#python # Python environment

# Check dotfiles are linked correctly
ls -la ~/.zshrc      # Should link to chezmoi
ls -la ~/.config/nvim # Should exist and contain config
ls -la ~/.tmux.conf  # Should link to chezmoi

# Check package availability
which git fzf ripgrep tree jq just gh direnv nvim
```

## 🔧 Package Management

**What's managed by Nix** (`flake.nix`):
- Development tools: `git`, `fzf`, `ripgrep`, `tree`, `jq`, `yq`, `just`, `gh`
- Editors: `neovim`, `tmux`
- Environment: `direnv`, `nix-direnv`, `chezmoi`, `age`
- Language environments: Node.js, Python, Rust, Go, etc.

**What's managed by Homebrew** (`Brewfile`):
- macOS-specific: Docker Desktop, `colima`, `docker`
- Python tools: `pipx`
- AI tools: `gemini-cli`

## 🛠️ What's Included

### Package Managers
- **Homebrew** - macOS package manager
- **Nix** - Reproducible package manager with development shells
- **pipx** - Install Python applications in isolated environments

### Development Tools
- **git** - Version control with custom configuration
- **tree** - Directory structure visualization
- **fzf** - Fuzzy finder for files and command history
- **ripgrep** - Fast text search tool
- **ag** (the_silver_searcher) - Code search tool
- **Docker + Colima** - Containerization without Docker Desktop

### Programming Languages & Runtimes
- **Node.js** 23.9.0
- **Python** 3.13.5 (+ development tools)
- **Rust** (stable)
- **Lua** 5.4.7
- **Terraform** 1.12.2

### Terminal Environment
- **Zsh** with oh-my-zsh framework
- **Powerlevel10k** theme for beautiful prompts
- **Neovim** with comprehensive plugin ecosystem
- **Tmux** with plugin manager and custom keybindings
- **MesloLGS Nerd Font** for proper icon display

### AI & Productivity Tools
- **gemini-cli** - Google Gemini CLI interface
- **claude-code** - Anthropic Claude Code CLI
- **nox** - Python testing automation
- **argcomplete** - Command-line auto-completion

## 📁 Repository Structure

```
~/.dotfiles/
├── bootstrap-nix-chezmoi.sh # Modern Nix + Chezmoi setup script
├── Brewfile              # Homebrew packages
├── .tool-versions        # Deprecated - using nix flake.nix instead
├── requirements-pipx.txt # Python applications via pipx
├── zsh/                  # Zsh configuration
│   ├── .zshrc           # Main zsh configuration
│   ├── .zprofile        # Zsh profile settings
│   ├── .zshenv          # Environment variables
│   └── fonts/           # MesloLGS Nerd Fonts
├── nvim/                 # Neovim configuration
│   ├── init.lua         # Main Neovim config
│   ├── lazy-lock.json   # Plugin version lock file
│   └── lua/             # Lua configuration modules
├── tmux/                 # Tmux configuration
│   └── .tmux.conf       # Tmux settings and keybindings
└── .gitconfig           # Git global configuration
```

## 🔐 Encryption & Secrets Management

This dotfiles setup includes **age encryption** for securely storing sensitive configuration files like API keys, SSH configs, and environment variables.

### Age Encryption Setup

**Automatic Setup (Recommended):**
The bootstrap script automatically configures age encryption if you choose to enable secrets management.

**Manual Setup:**
```bash
# 1. Generate age key pair
age-keygen -o ~/.config/age/key.txt

# 2. The public key will be displayed - save it for later
# Example: age1g2gr4rddcar2335xdqu6l2t40dpmmulq9jh7ne5873wa03fcxsdqv5mrk2

# 3. Update chezmoi config to use the public key
# Edit ~/.config/chezmoi/chezmoi.toml and ensure:
encryption = "age"
[age]
    suffix = ".age"
    identity = "~/.config/age/key.txt" 
    recipient = "age1g2gr4rddcar2335xdqu6l2t40dpmmulq9jh7ne5873wa03fcxsdqv5mrk2"  # pragma: allowlist secret
```

### Adding Encrypted Files

```bash
# Add an encrypted file to chezmoi
chezmoi add --encrypt ~/.ssh/config
chezmoi add --encrypt ~/.env.personal

# Edit encrypted files (automatically decrypts/re-encrypts)
chezmoi edit ~/.ssh/config
```

### Template Variables

The setup includes these template variables for conditional configurations:
- `{{ .is_macos }}` - True on macOS systems
- `{{ .is_linux }}` - True on Linux systems  
- `{{ .is_personal }}` - True for personal machines
- `{{ .is_work }}` - True for work machines
- `{{ .use_nix }}` - True if Nix is enabled
- `{{ .has_homebrew }}` - True if Homebrew is installed

**Example usage in templates:**
```bash
{{- if .is_macos }}
# macOS-specific configuration
export BROWSER="open"
{{- else if .is_linux }}
# Linux-specific configuration
export BROWSER="firefox"
{{- end }}
```

## 🔧 Configuration Details

### Zsh Configuration
- **oh-my-zsh** framework with git plugin
- **Powerlevel10k** theme for enhanced prompts
- **Nix** integration for reproducible development environments
- **fzf** integration for fuzzy searching
- Custom aliases and environment variables

### Neovim Setup
- **Lazy.nvim** plugin manager for fast startup
- **LSP** configuration for multiple languages
- **Treesitter** for syntax highlighting
- **Telescope** for fuzzy finding
- **Git integration** with diffview and blame
- **Copilot** integration for AI-assisted coding

### Tmux Configuration
- **Vim-like keybindings** for navigation
- **Catppuccin theme** for beautiful aesthetics
- **TPM** (Tmux Plugin Manager) for plugin management
- **Mouse support** enabled
- **Prefix key** changed to `Ctrl-a`

## 📋 Manual Setup Steps

After running the installation, you may need to:

1. **Restart your terminal** or run `source ~/.zshrc`
2. **Configure Powerlevel10k**: Run `p10k configure`
3. **Install tmux plugins**: Press `prefix + I` in tmux
4. **Setup SSH keys** for GitHub (if needed):
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   cat ~/.ssh/id_ed25519.pub | pbcopy
   ```

## 🔄 Maintenance

### Update Everything
```bash
cd ~/.dotfiles
./update.sh
```

### Backup Existing Configurations
```bash
cd ~/.dotfiles
./backup.sh
```

### Add New Packages
- **Homebrew**: Edit `Brewfile` and run `brew bundle`
- **Nix**: Edit `flake.nix` and run `nix develop`
- **pipx**: Edit `requirements-pipx.txt` and install manually

## 🐛 Troubleshooting

### Common Issues

**Command not found after installation:**
```bash
source ~/.zshrc
# or restart terminal
```

**Nix development shell not working:**
```bash
# Enable flakes if not already enabled
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
# Enter development environment
nix develop .#go  # or .#python, .#rust, etc.
```

**Neovim plugins not loading:**
```bash
nvim --headless "+Lazy! sync" +qa
```

**tmux plugins not working:**
- Press `prefix + I` to install plugins
- Press `prefix + U` to update plugins

**Chezmoi template errors (`map has no entry for key "is_macos"`):**
```bash
# This error occurs when age encryption is not properly configured
# Solution: 
1. Check if ~/.config/chezmoi/chezmoi.toml exists and contains [data] section
2. Verify encryption is properly configured:
   chezmoi data | jq '.is_macos'  # Should return true/false, not null
3. If age encryption is configured but not working:
   # Check age key exists
   ls -la ~/.config/age/key.txt
   # Regenerate config if needed
   rm ~/.config/chezmoi/chezmoi.toml && chezmoi init
```

**Age encryption errors (`no encryption` or `failed to read header`):**
```bash
# Remove any placeholder encrypted files that aren't actually encrypted
find ~/.local/share/chezmoi -name "*.age" -exec file {} \; | grep -v "ASCII"
# If any files show as plain text, remove them:
rm ~/.local/share/chezmoi/path/to/plain-text-file.age

# Ensure encryption is properly configured
chezmoi data | grep -A5 "\[age\]"
```

### Getting Help

1. Check configuration files in `~/.config/`
2. Verify PATH includes all necessary directories
3. Restart terminal session
4. Re-run installation scripts if needed

## 🤝 Contributing

Feel free to fork this repository and customize it for your own needs. Pull requests for improvements are welcome!

## 📄 License

This project is licensed under the MIT License - see the repository for details.

---

*Last updated: September 2025*
