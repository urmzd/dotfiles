# Brewfile for dotfiles setup
# Install with: brew bundle
#
# ⚠️  IMPORTANT: This Brewfile is now MINIMAL
# Most tools are managed by Nix (see flake.nix) for automatic updates and reproducibility
#
# Nix-managed tools include:
# • AI: claude-code, gemini-cli
# • Cloud: google-cloud-sdk, colima, docker, docker-compose
# • CLI: git, gh, fzf, ripgrep, jq, yq, just, curl, wget, tree
# • Dev: neovim, tmux, direnv, chezmoi, age, gnupg
# • Python: python313, pipx, pip, virtualenv, black, flake8, mypy, pytest, ruff, uv
#
# To use these tools, ensure your Nix environment is activated:
#   - Default shell with all tools: `nix develop` or use direnv
#   - Specific environments: `nix develop .#python`, `.#node`, `.#devops`, etc.
#
# This Brewfile only contains GUI applications or tools that MUST be installed via Homebrew

# GUI Applications (not available in Nix or better via Homebrew)
# cask "docker"  # Docker Desktop - Optional, can use colima + docker CLI from Nix instead

# Note: Keep this file for macOS-specific GUI apps only
# Example casks you might want:
# cask "visual-studio-code"
# cask "iterm2"
# cask "rectangle"  # Window management
