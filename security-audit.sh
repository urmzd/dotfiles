#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Counters
SECURITY_ISSUES=0
WARNINGS=0
PASSED_CHECKS=0

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASSED_CHECKS++)); }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; ((WARNINGS++)); }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; ((SECURITY_ISSUES++)); }
log_header() { echo -e "${PURPLE}[====]${NC} $1"; }

show_banner() {
    cat << "EOF"
   ____                      _ _
  / ___|  ___  ___ _   _ _ __(_) |_ _   _
  \___ \ / _ \/ __| | | | '__| | __| | | |
   ___) |  __/ (__| |_| | |  | | |_| |_| |
  |____/ \___|\___|\__,_|_|  |_|\__|\__, |
                                   |___/
      _             _ _ _
     / \  _   _  __| (_) |_
    / _ \| | | |/ _` | | __|
   / ___ \ |_| | (_| | | |_
  /_/   \_\__,_|\__,_|_|\__|

Dotfiles Security Audit Tool
EOF
}

# Check for sensitive files that shouldn't exist
check_sensitive_files() {
    log_header "Checking for accidentally committed sensitive files..."

    local sensitive_patterns=(
        "*.key"
        "*.pem"
        "*secret*"
        "*password*"
        "*credential*"
        ".env.*"
        "id_rsa"
        "id_ecdsa"
        "id_ed25519"
        "*.p8"
        "*.p12"
    )

    for pattern in "${sensitive_patterns[@]}"; do
        if find . -name "$pattern" -not -path "./.git/*" -not -name "*.tmpl" -not -name "*.example" | grep -q .; then
            log_error "Found potentially sensitive files matching: $pattern"
            find . -name "$pattern" -not -path "./.git/*" -not -name "*.tmpl" -not -name "*.example"
        fi
    done

    if [[ $SECURITY_ISSUES -eq 0 ]]; then
        log_success "No accidentally committed sensitive files found"
    fi
}

# Check git configuration
check_git_security() {
    log_header "Checking Git security configuration..."

    # Check if .gitignore exists and has sensitive patterns
    if [[ -f ".gitignore" ]]; then
        local required_patterns=(
            ".env"
            "*.key"
            "*.pem"
            "*secret*"
            "*password*"
        )

        local missing_patterns=()
        for pattern in "${required_patterns[@]}"; do
            if ! grep -q "$pattern" .gitignore; then
                missing_patterns+=("$pattern")
            fi
        done

        if [[ ${#missing_patterns[@]} -gt 0 ]]; then
            log_warn "Missing patterns in .gitignore: ${missing_patterns[*]}"
        else
            log_success ".gitignore has adequate sensitive file protection"
        fi
    else
        log_error ".gitignore file missing"
    fi

    # Check for .gitattributes
    if [[ -f ".gitattributes" ]]; then
        log_success ".gitattributes file exists for additional protection"
    else
        log_warn ".gitattributes file missing - consider adding for enhanced security"
    fi
}

# Check for secrets in templates
check_template_security() {
    log_header "Checking template files for hardcoded secrets..."

    local secret_patterns=(
        "sk-[a-zA-Z0-9]{32,}"      # OpenAI API keys
        "ghp_[a-zA-Z0-9]{36}"      # GitHub personal access tokens
        "xoxb-[a-zA-Z0-9\-]+"      # Slack bot tokens
        "AKIA[0-9A-Z]{16}"         # AWS access key IDs
        "ya29\.[a-zA-Z0-9\.\-_]+"  # Google OAuth tokens
    )

    local found_secrets=false

    for pattern in "${secret_patterns[@]}"; do
        if find . -name "*.tmpl" -exec grep -l "$pattern" {} \; 2>/dev/null | head -1; then
            log_error "Found potential secret pattern in templates: $pattern"
            found_secrets=true
        fi
    done

    if ! $found_secrets; then
        log_success "No hardcoded secrets found in templates"
    fi

    # Check for suspicious placeholder values
    if find . -name "*.tmpl" -exec grep -l "your-.*-key\|your-.*-token\|your-.*-secret" {} \; 2>/dev/null | head -1; then
        log_warn "Found placeholder values in templates - ensure they use proper template variables"
    fi
}

# Check encrypted files
check_encrypted_files() {
    log_header "Checking encrypted file integrity..."

    # Find .age files
    local age_files
    mapfile -t age_files < <(find . -name "*.age" 2>/dev/null)

    if [[ ${#age_files[@]} -eq 0 ]]; then
        log_warn "No .age encrypted files found"
        return
    fi

    for file in "${age_files[@]}"; do
        if [[ -s "$file" ]]; then
            # Check if it starts with age header or is a placeholder
            if head -c 4 "$file" | grep -q "age-" 2>/dev/null; then
                log_success "Encrypted file appears valid: $file"
            elif head -10 "$file" | grep -qi "placeholder\|example" 2>/dev/null; then
                log_success "Encrypted placeholder file: $file"
            else
                log_error "File may not be properly encrypted: $file"
            fi
        else
            log_warn "Empty encrypted file: $file"
        fi
    done
}

# Check for pre-commit hooks
check_precommit_setup() {
    log_header "Checking pre-commit security setup..."

    if [[ -f ".pre-commit-config.yaml" ]]; then
        log_success "Pre-commit configuration found"

        # Check if detect-secrets is configured
        if grep -q "detect-secrets" .pre-commit-config.yaml; then
            log_success "Secret detection configured in pre-commit"
        else
            log_warn "No secret detection in pre-commit hooks"
        fi

        # Check if hooks are installed
        if [[ -f ".git/hooks/pre-commit" ]]; then
            log_success "Pre-commit hooks are installed"
        else
            log_warn "Pre-commit hooks not installed - run 'pre-commit install'"
        fi
    else
        log_warn "No pre-commit configuration found"
    fi
}

# Check file permissions
check_file_permissions() {
    log_header "Checking file permissions for sensitive files..."

    # Check for overly permissive files
    local overly_permissive
    mapfile -t overly_permissive < <(find . -name "*.sh" -perm +022 2>/dev/null)

    if [[ ${#overly_permissive[@]} -gt 0 ]]; then
        log_warn "Found world-writable shell scripts:"
        printf '%s\n' "${overly_permissive[@]}"
    else
        log_success "No overly permissive shell scripts found"
    fi

    # Check SSH config permissions if it exists
    if [[ -f "chezmoi-config/private_dot_ssh/config.tmpl" ]]; then
        log_success "SSH config template properly located in private directory"
    fi
}

# Check for common security misconfigurations
check_security_misconfigurations() {
    log_header "Checking for security misconfigurations..."

    # Check for debug flags in scripts
    if grep -r "set -x\|set +x" . --exclude-dir=.git 2>/dev/null | head -1; then
        log_warn "Found debug flags in scripts - may expose sensitive data in logs"
    else
        log_success "No debug flags found in scripts"
    fi

    # Check for curl with -k (insecure)
    if grep -r "curl.*-k\|curl.*--insecure" . --exclude-dir=.git 2>/dev/null | head -1; then
        log_error "Found insecure curl commands"
    else
        log_success "No insecure curl commands found"
    fi

    # Check for wget with --no-check-certificate
    if grep -r "wget.*--no-check-certificate" . --exclude-dir=.git 2>/dev/null | head -1; then
        log_error "Found insecure wget commands"
    else
        log_success "No insecure wget commands found"
    fi
}

# Check environment variables in scripts
check_environment_variables() {
    log_header "Checking environment variable usage..."

    # Look for potential secret exposure in scripts
    local suspicious_vars=(
        "PASSWORD"
        "SECRET"
        "KEY"
        "TOKEN"
        "CREDENTIAL"
    )

    local found_issues=false
    for var in "${suspicious_vars[@]}"; do
        if grep -r "echo.*\$${var}\|printf.*\$${var}" . --exclude-dir=.git 2>/dev/null | head -1; then
            log_error "Found potential secret exposure via echo/printf: $var"
            found_issues=true
        fi
    done

    if ! $found_issues; then
        log_success "No obvious environment variable secret exposure found"
    fi
}

# Generate security report
generate_report() {
    log_header "Security Audit Summary"

    echo
    cat << EOF
${GREEN}✅ Passed Checks: ${PASSED_CHECKS}${NC}
${YELLOW}⚠️  Warnings: ${WARNINGS}${NC}
${RED}❌ Security Issues: ${SECURITY_ISSUES}${NC}

EOF

    if [[ $SECURITY_ISSUES -eq 0 ]]; then
        if [[ $WARNINGS -eq 0 ]]; then
            cat << EOF
${GREEN}🎉 EXCELLENT SECURITY POSTURE${NC}
Your dotfiles repository has no security issues and follows best practices!

EOF
        else
            cat << EOF
${YELLOW}✅ GOOD SECURITY POSTURE${NC}
Your dotfiles repository has no critical security issues.
Consider addressing the warnings above to further improve security.

EOF
        fi
    else
        cat << EOF
${RED}⚠️  SECURITY ISSUES DETECTED${NC}
Your dotfiles repository has ${SECURITY_ISSUES} security issue(s) that should be addressed immediately.

Recommended Actions:
1. Review and fix all FAIL items above
2. Run pre-commit hooks: pre-commit install && pre-commit run --all-files
3. Use encrypted files for secrets: ./secrets-setup.sh
4. Never commit real secrets to the repository

EOF
    fi

    cat << EOF
Security Best Practices:
• Use the secrets-setup.sh script for managing sensitive data
• Run this audit regularly: ./security-audit.sh
• Install pre-commit hooks: pre-commit install
• Keep your .gitignore and .gitattributes updated
• Review all changes before committing

For more information, see: SECURITY.md

EOF
}

# Main audit function
main() {
    show_banner
    echo
    log_info "Starting comprehensive security audit of dotfiles repository..."
    echo

    check_sensitive_files
    echo
    check_git_security
    echo
    check_template_security
    echo
    check_encrypted_files
    echo
    check_precommit_setup
    echo
    check_file_permissions
    echo
    check_security_misconfigurations
    echo
    check_environment_variables
    echo
    generate_report

    # Exit with appropriate code
    if [[ $SECURITY_ISSUES -gt 0 ]]; then
        exit 1
    elif [[ $WARNINGS -gt 0 ]]; then
        exit 2
    else
        exit 0
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
