# Dotfiles Usage & Testing Guide

This guide provides comprehensive instructions for testing and using all features of this modern dotfiles repository, including security enhancements, Nix + Chezmoi integration, and cross-platform compatibility.

## 🚀 Quick Testing Overview

### Prerequisites Check
```bash
# Verify your system is ready
cd ~/.dotfiles
./cross-platform-test.sh
```

### Security Pre-flight Check
```bash
# Run comprehensive security audit
./security-audit.sh

# Check git repository security
git status --ignored
```

## 🔒 Security Features Testing

### 1. Pre-commit Hooks Validation
```bash
# Install pre-commit hooks
pre-commit install

# Test secret detection
echo "export API_KEY=sk-1234567890abcdef" > test-secret.env
git add test-secret.env
git commit -m "test commit"
# Should FAIL and show security warning

# Clean up test
rm test-secret.env
git reset HEAD~1
```

### 2. Security Audit Script
```bash
# Run full security scan
./security-audit.sh

# Expected output should show:
# ✓ No secrets found in tracked files
# ✓ Sensitive patterns in .gitignore
# ✓ Git attributes configured
# ✓ Pre-commit hooks active
```

### 3. Secrets Management Testing
```bash
# Setup age encryption (follow prompts)
./secrets-setup.sh

# Test encrypted file creation
echo "export WORK_API_KEY=test-key" > ~/.env.work
chezmoi add --encrypt ~/.env.work

# Verify encryption worked
file ~/.local/share/chezmoi/encrypted_dot_env.work.age
# Should show: "age encrypted file"

# Test decryption
chezmoi apply
# Should create ~/.env.work with decrypted content
```

## 🎯 Modern Nix + Chezmoi Workflow Testing

### 1. Fresh Installation Test
```bash
# Test complete modern setup (use test VM/container)
curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/bootstrap-nix-chezmoi.sh | bash

# Verify components installed
command -v nix
command -v chezmoi
command -v direnv
command -v age
```

### 2. Development Environment Testing
```bash
cd ~/.dotfiles

# Test each development environment
nix develop .#node
# In new shell: node --version, npm --version

nix develop .#python  
# In new shell: python --version, pip --version

nix develop .#rust
# In new shell: rustc --version, cargo --version

nix develop .#go
# In new shell: go version

nix develop .#devops
# In new shell: terraform --version, kubectl version --client
```

### 3. Automatic Environment Switching
```bash
cd ~/.dotfiles

# Test direnv integration
echo 'use flake .#node' > .envrc
direnv allow

# cd out and back in - should auto-load Node.js environment
cd .. && cd ~/.dotfiles
# Should see: "direnv: loading ~/.dotfiles/.envrc"
node --version  # Should work without manual activation
```

### 4. Cross-platform Testing
```bash
# Run comprehensive platform tests
./cross-platform-test.sh

# Expected output:
# ✓ Platform detection (macOS/Linux/WSL)
# ✓ Package managers available
# ✓ All tools accessible
# ✓ Nix environments validated
# ✓ Chezmoi templates rendered
```

## 🔄 Template System Validation

### 1. Chezmoi Configuration Testing
```bash
# Test template rendering with different configurations
chezmoi execute-template --init \
  --promptString name="Test User" \
  --promptString email="test@example.com" \
  --promptString github_username="testuser" \
  --promptBool is_personal=true \
  --promptBool is_work=false \
  --promptBool use_secrets=true \
  --promptBool use_nix=true \
  < .chezmoi.toml.tmpl

# Verify git config templating
chezmoi execute-template < chezmoi-config/dot_gitconfig.tmpl
```

### 2. Multi-machine Configuration Testing
```bash
# Test work machine configuration
chezmoi init --data '{"is_work": true, "is_personal": false}'

# Test personal machine configuration  
chezmoi init --data '{"is_work": false, "is_personal": true}'

# Verify different templates are applied
chezmoi diff
```

### 3. Encrypted Templates Testing
```bash
# Add secret template
chezmoi add --encrypt --template ~/.env.personal

# Edit encrypted template
chezmoi edit ~/.env.personal

# Apply with decryption
chezmoi apply

# Verify file was decrypted properly
cat ~/.env.personal
```

## 📊 Feature Comparison Testing

### Legacy vs Modern Comparison
```bash
# Modern setup (only option)
./bootstrap-nix-chezmoi.sh
source ~/.zshrc

# Compare features:
# Legacy: asdf, brew, manual configs
# Modern: nix, chezmoi, encrypted secrets, direnv
```

### Performance Benchmarking
```bash
# Time modern setup
time nix develop .#full --command echo "ready"

# Compare shell startup times
time zsh -c "exit"
```

## 🧪 Advanced Feature Testing

### 1. Nix Flake Validation
```bash
cd ~/.dotfiles

# Validate flake syntax
nix flake check

# List all available environments
nix flake show

# Test flake evaluation
nix eval .#devShells.x86_64-darwin.default.name
```

### 2. Chezmoi Advanced Features
```bash
# Test ignore patterns
echo "ignored-file" > ~/.ignored-test
chezmoi add ~/.ignored-test
# Should respect .chezmoiignore patterns

# Test remove operations
chezmoi remove ~/.env.work
chezmoi apply

# Test state management
chezmoi status
chezmoi diff
```

### 3. Security Integration Testing
```bash
# Test pre-commit with real commits
echo "# Safe comment" >> README.md
git add README.md
git commit -m "safe change"
# Should succeed

# Test secret detection sensitivity
echo "password = 'secret123'" > temp.py
git add temp.py
git commit -m "test"
# Should fail with security warning
rm temp.py
```

## 🔍 Validation Commands & Expected Outputs

### Essential Validation Commands
```bash
# 1. Security validation
./security-audit.sh
# Expected: All checks pass, no secrets detected

# 2. Cross-platform compatibility
./cross-platform-test.sh  
# Expected: Platform detected, tools available

# 3. Development environment check
nix develop .#full --command which node python3 cargo go
# Expected: All tools found

# 4. Chezmoi status
chezmoi status
# Expected: No differences (clean state)

# 5. Pre-commit validation
pre-commit run --all-files
# Expected: All hooks pass

# 6. Encrypted secrets test
chezmoi execute-template --init < .chezmoi.toml.tmpl >/dev/null
echo $?
# Expected: 0 (success)
```

### Health Check Script
```bash
#!/bin/bash
# Create this as health-check.sh

echo "🔍 Running comprehensive health check..."

# Test each major component
tests=(
    "nix --version"
    "chezmoi --version" 
    "direnv --version"
    "age --version"
    "pre-commit --version"
)

for test in "${tests[@]}"; do
    if $test >/dev/null 2>&1; then
        echo "✅ $test"
    else
        echo "❌ $test"
    fi
done

echo "🎯 Health check complete!"
```

## 🚨 Troubleshooting & Debugging

### Common Issues & Solutions

**1. Nix environment not loading:**
```bash
# Verify Nix installation
ls -la /nix
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Reinstall if needed
curl -L https://nixos.org/nix/install | sh
```

**2. Chezmoi templates failing:**
```bash
# Check template syntax
chezmoi execute-template --init --dry-run < .chezmoi.toml.tmpl

# Reset configuration
rm -rf ~/.config/chezmoi ~/.local/share/chezmoi
chezmoi init
```

**3. direnv not auto-loading:**
```bash
# Add to shell profile
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
source ~/.zshrc

# Allow current directory
direnv allow .
```

**4. Pre-commit hooks not running:**
```bash
# Reinstall hooks
pre-commit uninstall
pre-commit install

# Test manually
pre-commit run --all-files
```

**5. Secrets decryption failing:**
```bash
# Check age key
ls -la ~/.config/age/key.txt

# Verify public key in chezmoi config
chezmoi edit-config

# Test decryption manually
age --decrypt -i ~/.config/age/key.txt encrypted_file.age
```

### Debug Mode Testing
```bash
# Enable verbose output for troubleshooting
export CHEZMOI_DEBUG=1
export DIRENV_LOG_FORMAT=""

# Run with debug information
chezmoi apply --verbose --dry-run
direnv status
```

### Log Analysis
```bash
# Check installation logs
tail -f /tmp/dotfiles-install.log

# Check Nix operation logs
nix show-derivation .#devShells.default

# Check git security logs
git log --oneline --decorate
```

## 🎯 Success Criteria

Your dotfiles setup is successful when:

- ✅ All security audits pass
- ✅ Cross-platform tests complete successfully  
- ✅ All development environments load properly
- ✅ Templates render without errors
- ✅ Secrets are encrypted and decrypt correctly
- ✅ Pre-commit hooks block sensitive data
- ✅ direnv automatically switches environments
- ✅ No plain-text secrets in repository
- ✅ All tools accessible across sessions
- ✅ Configuration adapts to different machine types

## 📚 Additional Resources

- **Security Documentation**: [SECURITY.md](SECURITY.md)
- **Nix + Chezmoi Guide**: [NIX-CHEZMOI.md](NIX-CHEZMOI.md) 
- **Architecture Overview**: [README.md](README.md)
- **Cross-platform Testing**: `./cross-platform-test.sh --help`
- **Security Auditing**: `./security-audit.sh --help`

---

**Need Help?** Run any script with `--help` flag for detailed usage information.