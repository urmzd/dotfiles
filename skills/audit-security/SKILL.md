---
name: audit-security
description: Security auditing, threat detection, sensitive data leak prevention, and system diagnostics via Activity Monitor. Use when checking for security issues, investigating suspicious processes, preventing credential leaks, or hardening configurations.
allowed-tools: Read Grep Glob Bash
metadata:
  title: Security Audit
  category: security
  order: 0
---

# Security Audit

## Core Principle

Never read, echo, log, or surface secret values. All scanning is delegated to purpose-built tools that redact output by default. The agent's role is to orchestrate these tools and interpret their results, not to pattern-match secrets directly.

## On-Start Security Insights

When invoked, run these checks and present a prioritized report (CRITICAL > WARNING > INFO):

1. **Secret scan** run `gitleaks detect --no-banner` on the working directory
2. **File permissions** check SSH keys, `.env` files for overly broad access
3. **Git hygiene** verify `.gitignore` covers `.env*`, `*.pem`, `*.key`, `credentials.json`
4. **Open ports** flag unexpected listeners via `lsof -i -P -n | grep LISTEN`
5. **System posture** FileVault status, firewall state, SIP status

## Secret Scanning

Delegate entirely to external tools. Never grep for secret patterns directly.

| Tool | Usage |
|------|-------|
| [gitleaks](https://github.com/gitleaks/gitleaks) | `gitleaks detect`. Scan working tree; `gitleaks protect`. Pre-commit |
| [trufflehog](https://github.com/trufflesecurity/trufflehog) | `trufflehog filesystem .`. Deep entropy + pattern scan |
| git-secrets | `git secrets --scan`. AWS-focused pre-commit hook |

If none are installed, recommend installation and stop. Do not fall back to manual scanning.

### Handling Findings

- Report file path and line number only. Never the secret value
- Recommend rotation immediately for any confirmed leak
- Check git history: `gitleaks detect --log-opts="--all"` for historical exposure

## Git Safety

Verify before any commit:

- Run `gitleaks protect --staged` against staged changes
- Confirm `.gitignore` covers sensitive file patterns
- Flag large binaries or unexpected file types in staging

## File Permission Audit

| Target | Expected | Check |
|--------|----------|-------|
| SSH private keys | `600` | `stat -f '%Lp' ~/.ssh/id_*` |
| `~/.ssh/` directory | `700` | `stat -f '%Lp' ~/.ssh` |
| `.env` files | `600` | `stat -f '%Lp' .env*` |
| GPG keys | `600` | `stat -f '%Lp' ~/.gnupg/private-keys-v1.d/*` |

Report deviations. Offer to fix with `chmod` after user confirmation.

## Process Investigation

When the user asks to diagnose system issues:

| Task | Command |
|------|---------|
| Top CPU consumers | `ps aux --sort=-%cpu \| head -20` |
| Top memory consumers | `ps aux --sort=-%mem \| head -20` |
| Listening ports | `lsof -i -P -n \| grep LISTEN` |
| Network connections | `lsof -i -n` |
| Open files by process | `lsof -p <PID>` |
| Process detail | `ps -p <PID> -o pid,ppid,user,%cpu,%mem,start,command` |
| Launch daemons | `launchctl list` |
| Recent logins | `last -10` |

### Triage Flow

1. Identify symptom (high CPU, high memory, unexpected network, unknown process)
2. Isolate the process with `ps` / `lsof`
3. Check provenance. Signed? (`codesign -v <path>`) From a package manager?
4. Check network behavior. What IPs/domains is it contacting?
5. Recommend: ignore (benign), investigate further, or kill/remove

### macOS-Specific

- `lsof -i` over `netstat` for richer output
- Check `/Library/LaunchDaemons/` and `~/Library/LaunchAgents/` for persistence
- Code signatures: `codesign --verify --deep --strict <binary>`
- Gatekeeper: `spctl --assess --type execute <binary>`
- SIP status: `csrutil status`

## Configuration Hardening

Verify and recommend:

- SSH: `AddKeysToAgent yes`, `IdentitiesOnly yes`
- GPG agent configured for commit signing
- Firewall: `/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate`
- FileVault: `fdesetup status`
- Automatic updates enabled

## Safe Defaults

- Never echo, log, or print secret values. Not even partially
- Never store secrets in shell history. Use `op read`, `pass`, or similar
- Pipe sensitive values directly: `op read "op://vault/item" | command`
- Prefer env vars over file-based secrets where tooling supports it

## Output Format

```
## Security Audit Report

### CRITICAL
- [SECRET] gitleaks: finding in config/setup.sh:12 (rotate immediately)
- [PERMS] ~/.ssh/id_ed25519 has 644 (expected 600)

### WARNING
- [GIT] .env exists but not in .gitignore
- [PROCESS] Unknown process listening on port 8443

### INFO
- [OK] FileVault enabled
- [OK] SSH keys have correct permissions
- [OK] gitleaks: no findings in staged changes
```
