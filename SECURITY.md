# 🔒 Security Best Practices Guide

This document outlines the security measures implemented in this dotfiles repository and provides guidelines for safe usage of sensitive data.

## 🚨 Critical Security Notice

**This is a PUBLIC repository.** Never commit real secrets, passwords, or sensitive data directly to this repository, even temporarily.

## 🛡️ Security Features Implemented

### Multiple Layers of Protection

1. **Comprehensive .gitignore** - Blocks sensitive file patterns
2. **Git Attributes Protection** - Treats sensitive files as binary
3. **Pre-commit Hooks** - Automatic secret detection before commits
4. **Age Encryption** - Military-grade encryption for secrets
5. **Template Sanitization** - No hardcoded secrets in templates
6. **Security Auditing** - Automated security validation

## 🔐 Secrets Management

### Encrypted Files with Age

This repository uses [age encryption](https://github.com/FiloSottile/age) for secure secret management:

```bash
# Setup encryption (one-time)
./secrets-setup.sh

# Add encrypted secrets
chezmoi add --encrypt ~/.env.work
chezmoi add --encrypt ~/.ssh/id_ed25519
```

### Supported Secret Types

- **Environment Variables**: API keys, tokens, passwords
- **SSH Private Keys**: Authentication keys for servers
- **Cloud Credentials**: AWS, GCP, Azure configurations  
- **Application Configs**: Database URLs, service endpoints
- **Certificates**: TLS/SSL certificates and private keys

### File Organization

```
chezmoi-config/
├── encrypted_dot_env.work.age         # Work secrets (encrypted)
├── encrypted_dot_env.personal.age     # Personal secrets (encrypted)
├── private_dot_ssh/
│   ├── config.tmpl                    # SSH config (template)
│   └── encrypted_private_key.age      # SSH keys (encrypted)
└── encrypted_credentials.age          # Other credentials
```

## 🔍 Secret Detection

### Pre-commit Hooks

Automatic detection prevents accidental commits:

```yaml
# Install and activate
pip install pre-commit
pre-commit install

# Manual check
pre-commit run --all-files
```

**Detected Patterns:**
- API keys (OpenAI: `sk-*`, GitHub: `ghp_*`, AWS: `AKIA*`)
- Slack tokens (`xoxb-*`)
- Private SSH keys
- Database URLs with credentials
- Generic secrets (password, secret, key patterns)

### Security Audit Tool

Run comprehensive security checks:

```bash
./security-audit.sh
```

**Audit Coverage:**
- ✅ Accidentally committed sensitive files
- ✅ Git security configuration  
- ✅ Template file safety
- ✅ Encrypted file integrity
- ✅ Pre-commit hook setup
- ✅ File permission analysis
- ✅ Security misconfigurations

## 🎭 Template Security

### Safe Template Practices

**✅ Do This:**
```bash
# Use template variables
[user]
    name = {{ .name | quote }}
    email = {{ .email | quote }}

# Use conditional logic
{{- if .use_secrets }}
    signingkey = "configure-manually"
{{- end }}
```

**❌ Never Do This:**
```bash
# Hardcoded secrets
export API_KEY="sk-1234567890abcdef"
export PASSWORD="mysecretpassword"
```

### Template Variables

Safe variables to use in templates:
- `{{ .name }}` - User's full name
- `{{ .email }}` - Email address  
- `{{ .github_username }}` - GitHub username
- `{{ .is_work }}` - Work machine flag
- `{{ .is_personal }}` - Personal machine flag
- `{{ .has_homebrew }}` - Homebrew availability

## 🚦 Security Workflow

### Before Committing

1. **Run Security Audit**:
   ```bash
   ./security-audit.sh
   ```

2. **Pre-commit Checks**: 
   Hooks run automatically, but manually check with:
   ```bash
   pre-commit run --all-files
   ```

3. **Review Changes**:
   ```bash
   git diff --cached
   ```

4. **Verify No Secrets**:
   ```bash
   git show --name-only
   ```

### Setting Up Secrets

1. **Initialize Age Encryption**:
   ```bash
   ./secrets-setup.sh
   ```

2. **Create Secret Files**:
   ```bash
   # Edit your actual secrets
   vim ~/.env.work
   vim ~/.env.personal
   ```

3. **Encrypt and Add to Chezmoi**:
   ```bash
   chezmoi add --encrypt ~/.env.work
   chezmoi add --encrypt ~/.env.personal
   ```

4. **Apply to System**:
   ```bash
   chezmoi apply
   ```

## 🔒 Age Encryption Details

### Key Management

- **Private Key**: `~/.config/age/key.txt` (keep secure, backup safely)
- **Public Key**: Used in `.chezmoi.toml` (safe to share)
- **Encrypted Files**: `.age` extension, safe for public repositories

### Security Properties

- **Algorithm**: ChaCha20-Poly1305 + X25519
- **Key Size**: 256-bit encryption keys
- **Authentication**: Built-in authenticity verification
- **Forward Secrecy**: Each file encrypted independently

### Best Practices

1. **Backup Your Key**: Store private key securely offline
2. **Rotate Regularly**: Generate new keys periodically
3. **Access Control**: Limit key file permissions (600)
4. **Verification**: Always verify encrypted files decrypt correctly

## 🚨 Incident Response

### If Secrets Are Accidentally Committed

1. **Immediate Actions**:
   ```bash
   # Remove from history
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch SENSITIVE_FILE' \
     --prune-empty --tag-name-filter cat -- --all
   
   # Force push (if safe to do so)
   git push --force-with-lease --all
   ```

2. **Rotate Compromised Secrets**:
   - Change all exposed passwords
   - Regenerate API keys
   - Update service credentials
   - Notify relevant parties

3. **Review and Improve**:
   - Update security measures
   - Enhance detection rules
   - Document lessons learned

### If Age Key Is Compromised

1. **Generate New Key**:
   ```bash
   age-keygen -o ~/.config/age/new_key.txt
   ```

2. **Re-encrypt All Files**:
   ```bash
   # Decrypt with old key, encrypt with new key
   for file in ~/.local/share/chezmoi/encrypted_*; do
     chezmoi decrypt "$file" | age -e -i ~/.config/age/new_key.txt > "${file}.new"
     mv "${file}.new" "$file"
   done
   ```

3. **Update Configuration**:
   ```bash
   # Update .chezmoi.toml with new public key
   chezmoi edit-config
   ```

## 🛠️ Security Tools

### Required Tools

```bash
# Install security tools
pip install pre-commit detect-secrets
brew install age

# Optional but recommended
pip install gitguardian
```

### Recommended VS Code Extensions

- **GitLens**: Git history and blame
- **Secret Lens**: Inline secret detection
- **Age Encryption**: Age file support

## 📋 Security Checklist

### Initial Setup
- [ ] Run `./secrets-setup.sh`
- [ ] Install pre-commit hooks: `pre-commit install`
- [ ] Run initial audit: `./security-audit.sh`
- [ ] Backup age private key securely

### Before Each Commit
- [ ] Run `./security-audit.sh`
- [ ] Check `git diff --cached` for secrets
- [ ] Verify pre-commit hooks pass
- [ ] Test encrypted files decrypt correctly

### Monthly Maintenance
- [ ] Run full security audit
- [ ] Review and update .gitignore
- [ ] Check for new secret patterns
- [ ] Update security tools
- [ ] Verify backup integrity

### Key Rotation (Quarterly)
- [ ] Generate new age key
- [ ] Re-encrypt all secret files  
- [ ] Update Chezmoi configuration
- [ ] Test full deployment
- [ ] Securely dispose of old key

## 🆘 Getting Help

### Security Issues

If you discover a security vulnerability:

1. **Do NOT** create a public issue
2. Email security concerns privately
3. Provide detailed reproduction steps
4. Allow time for fix before disclosure

### Questions

- **General**: Create GitHub issue with `question` label
- **Security**: Use private communication channels
- **Documentation**: Suggest improvements via PR

## 📚 Additional Resources

- [Age Encryption Documentation](https://github.com/FiloSottile/age)
- [Chezmoi Security Guide](https://www.chezmoi.io/user-guide/encryption/)
- [Git Security Best Practices](https://git-scm.com/docs/gitattributes)
- [Pre-commit Hooks Documentation](https://pre-commit.com/)

---

**Remember**: Security is everyone's responsibility. When in doubt, err on the side of caution and ask for help.