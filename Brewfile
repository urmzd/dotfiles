# Brewfile - macOS packages managed by Homebrew
# Run: brew bundle --file=Brewfile
#
# Source of truth on macOS for everything except:
#   - gcloud / aws-cli   -> run_onchange_after_install-cloud-clis.sh.tmpl (pinned upstream)
#   - cortex             -> run_onchange_after_install-cortex.sh.tmpl   (pinned upstream)
#   - claude/codex/...   -> run_once_after_install-ai-clis.sh.tmpl       (npm/curl)
#   - Python / Rust      -> uv / rustup (curl-installed in run_once_before_install-packages-v2.sh.tmpl)

# Core CLI
brew "git"
brew "gh"
brew "fzf"
brew "ripgrep"
brew "tree"
brew "jq"
brew "yq"
brew "just"
brew "direnv"
brew "chezmoi"
brew "tmux"
brew "gnupg"
brew "tree-sitter"
brew "uv"
brew "tealdeer"
brew "coreutils"  # Provides gls/gdircolors used in dot_zshrc.tmpl color setup
brew "reattach-to-user-namespace"  # tmux clipboard integration on macOS

# Cloud / infra
brew "terraform"
brew "colima"
brew "docker"
brew "docker-buildx"
brew "docker-compose"
brew "kubectl"
brew "helm"
brew "k9s"

# Runtimes / language tooling
brew "fnm"            # Node version manager
brew "deno"
brew "go"
brew "golangci-lint"
brew "lua"
brew "luarocks"
brew "luacheck"
brew "stylua"

# iOS/macOS Development
brew "cocoapods"  # Dependency manager for Swift and Objective-C projects

# Editor
brew "neovim", args: ["HEAD"]  # Extensible Vim-based text editor (0.12-dev)

# Build Tools
brew "cmake"    # Cross-platform build system generator
brew "gettext"  # GNU internationalization and localization support

# Android Development
cask "android-studio"         # Android IDE with SDK manager
cask "android-commandlinetools"  # Android SDK command-line tools

# Fonts
cask "font-monaspace-nerd-font"  # MonaspiceNe Nerd Font (Monaspace Neon)
cask "font-iosevka-nerd-font"    # Iosevka Nerd Font (https://typeof.net/Iosevka/)
# cask "font-meslo-lg-nerd-font" # MesloLGS Nerd Font (legacy, replaced by MonaspiceNe)

# Terminal
# Terminal: ghostty (installed outside Homebrew)
