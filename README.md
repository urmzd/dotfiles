# dotfiles

A comprehensive development environment setup for macOS, featuring modern tools and configurations for a productive development workflow.

> **Note:** This setup is optimized for macOS and includes configurations for zsh, Nix, Neovim, tmux, and various development tools.

## 🚀 Quick Start

### Modern Nix + Chezmoi Setup (Recommended)
**One-command setup:**
```bash
curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/bootstrap-nix-chezmoi.sh | bash
```

**Features:**
- 🎯 Reproducible development environments with Nix
- 🔧 Intelligent dotfiles with Chezmoi templating  
- 🔒 Built-in secrets management with encryption
- 🚀 Automatic environment switching with direnv
- 📖 [Full Nix + Chezmoi Guide](NIX-CHEZMOI.md)

### Setup
**One-command setup:**
```bash
curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/bootstrap-nix-chezmoi.sh | bash
```

**Manual setup:**
```bash
git clone https://github.com/urmzd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x bootstrap-nix-chezmoi.sh
./bootstrap-nix-chezmoi.sh
```

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
