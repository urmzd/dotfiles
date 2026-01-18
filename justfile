# Default recipe - show available commands
default:
    @just --list

security-audit:
    ./security-audit.sh

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
    @echo -n "  claude-code: "; nix eval nixpkgs#claude-code.version 2>/dev/null || echo "checking..."
    @echo -n "  gemini-cli: "; nix eval nixpkgs#gemini-cli.version 2>/dev/null || echo "checking..."
    @echo -n "  codex: "; nix eval nixpkgs#codex.version 2>/dev/null || echo "checking..."
