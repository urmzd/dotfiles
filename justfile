# Default recipe - show available commands
default:
    @just --list

# ===========================================
# Nix management
# ===========================================

# One-command update: updates flake and rebuilds
update:
    @echo "Updating Nix flake inputs..."
    @nix flake update
    @echo ""
    @echo "Rebuilding environment..."
    @nix develop --command echo "Environment rebuilt successfully"
    @echo ""
    @echo "Run 'git add flake.lock && git commit -m \"chore: update flake\"' to persist"

# ===========================================
# Disk cleanup
# ===========================================

# Quick cleanup: remove build artifacts and caches (safe, reversible)
cleanup:
    @echo "Quick disk cleanup — removing regenerable build artifacts and caches..."
    @echo ""
    @echo "Before:"
    @df -h / | awk 'NR==1 || NR==2'
    @echo ""
    @echo "--- Rust target/ directories ---"
    @find $(HOME)/github -maxdepth 3 -name target -type d -exec rm -rf {} + 2>/dev/null; true
    @echo "--- node_modules/ directories ---"
    @find $(HOME)/github -maxdepth 3 -name node_modules -type d -exec rm -rf {} + 2>/dev/null; true
    @echo "--- Go build cache ---"
    @go clean -cache 2>/dev/null; true
    @echo "--- Python caches ---"
    @pip cache purge 2>/dev/null; true
    @uv cache clean 2>/dev/null; true
    @find $(HOME)/github -maxdepth 4 -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null; true
    @echo "--- Homebrew cache ---"
    @brew cleanup --prune=all -s 2>/dev/null; true
    @echo ""
    @echo "After:"
    @df -h / | awk 'NR==1 || NR==2'

# Deep cleanup: quick + Docker prune + Nix GC (slower, more aggressive)
cleanup-deep: cleanup
    @echo ""
    @echo "--- Miscellaneous caches ---"
    @rm -rf $(HOME)/.cache/huggingface $(HOME)/.cache/unstructured $(HOME)/.gradle/caches $(HOME)/.npm/_cacache $(HOME)/.pnpm-store 2>/dev/null; true
    @echo "--- Docker system prune ---"
    @docker system prune -af --volumes 2>/dev/null; true
    @echo "--- Nix garbage collection ---"
    @nix-collect-garbage -d 2>/dev/null; true
    @echo ""
    @echo "Final:"
    @df -h / | awk 'NR==1 || NR==2'

# Show environment status and flake age
status:
    @echo "=== Nix Environment Status ==="
    @if [ -f flake.lock ]; then \
        if [ "$$(uname)" = "Darwin" ]; then \
            AGE=$$(( ($$(date +%s) - $$(stat -f %m flake.lock)) / 86400 )); \
        else \
            AGE=$$(( ($$(date +%s) - $$(stat -c %Y flake.lock)) / 86400 )); \
        fi; \
        echo "flake.lock age: $$AGE days"; \
    fi
    @echo ""
    @echo "AI tool versions:"
    @echo -n "  claude: "; claude --version 2>/dev/null || echo "not installed (run: curl -fsSL https://claude.ai/install.sh | bash)"
    @echo -n "  codex: "; npm list -g @openai/codex 2>/dev/null | grep @openai/codex | awk '{print $$2}' || echo "not installed"
    @echo -n "  gemini: "; npm list -g @google/gemini-cli 2>/dev/null | grep @google/gemini-cli | awk '{print $$2}' || echo "not installed"
    @echo -n "  github-copilot: "; npm list -g @github/copilot 2>/dev/null | grep @githubnext/github-copilot-cli | awk '{print $$2}' || echo "not installed"
