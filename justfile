# Detect-secrets management recipes

# Default recipe - show available commands
default:
    @just --list

# Scan for secrets and update baseline
secrets-scan:
    detect-secrets scan --baseline .secrets.baseline

# Audit baseline to mark secrets as real/false positives
secrets-audit:
    detect-secrets audit .secrets.baseline

# Verify no new secrets since baseline
secrets-check:
    detect-secrets scan --baseline .secrets.baseline --fail-on-verified-secrets

# Generate a fresh baseline (use with caution)
secrets-baseline:
    detect-secrets scan --update .secrets.baseline

# View current baseline status
secrets-status:
    @echo "Baseline file: .secrets.baseline"
    @echo "Generated: $(jq -r '.generated_at' .secrets.baseline)"
    @echo "Total findings: $(jq '.results | to_entries | length' .secrets.baseline)"
    @echo ""
    @echo "Findings by file:"
    @jq -r '.results | to_entries[] | "\(.key): \(.value | length) findings"' .secrets.baseline

# Clean up baseline - remove verified secrets
secrets-clean:
    detect-secrets scan --baseline .secrets.baseline --exclude-files '.*\.lock$|node_modules/.*'

# Pre-commit check - fail if new secrets found
secrets-precommit:
    detect-secrets-hook --baseline .secrets.baseline --force-use-all-plugins

# Install detect-secrets if not present
secrets-install:
    pip install detect-secrets

# Full security audit including detect-secrets
security-audit: secrets-check
    ./security-audit.sh
