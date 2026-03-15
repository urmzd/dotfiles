---
name: cli-patterns
description: CLI conventions — JSON piping, stdout/stderr separation, structured logging, config discovery, install scripts, exit codes, and GitHub Action integration. Use when building or reviewing CLI tools.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
metadata:
  title: CLI Patterns
  category: development
  order: 3
---

# CLI Patterns

## Design Philosophy

A junior developer should be able to understand any CLI tool's behavior from `--help` alone. Prefer obvious defaults. Machine output (JSON) enables composability.

## Structured Output

- Data/results → stdout (JSON)
- Logs/progress/errors → stderr
- Enables: `tool command | jq '.field'`, `tool command 2>/dev/null`

## JSON Output Patterns

| Pattern | When | Reference |
|---------|------|-----------|
| Always JSON | Device/data APIs | homai: every command outputs JSON |
| Format flag | Dual human/machine consumers | sr: `--format json\|human`, oag: `--format json\|yaml` |
| Structured logging | Debug/tracing | linear-gp: `--log-format json\|compact\|pretty` + `--log-file` |

- Rust: `serde_json::to_string_pretty()` to stdout
- Go: `json.MarshalIndent(v, "", "  ")` to stdout

## Config Systems

| Format | Use | Discovery |
|--------|-----|-----------|
| TOML | User-editable configs | Walk up from cwd (teasr, linear-gp) |
| YAML | Release/CI configs | Fixed name at repo root (`sr.yaml`) |

- Override: `--override key.path=value` (dot-notation)
- Env vars: `TOOL_CONFIG`, `TOOL_VERSION`, etc.

## Output Directories

- `outputs/<name>/<YYYYMMDD_HHMMSS>/` — timestamped results (linear-gp)
- `assets/` — demo captures (teasr)
- `bin/` — Go builds, `target/` — Rust builds

## Exit Codes

- `0` — success
- `1` — error
- `2` — no-op/no changes (sr pattern)

## Install Script Convention

Every CLI tool MUST have `install.sh` at repo root:

- Portable `#!/bin/sh`
- Platform detection: `uname -s` (OS) + `uname -m` (arch)
- Targets: GNU + musl for Linux, Darwin for macOS, MSVC for Windows
- Version override: `${BINARY_VERSION:-}`, fallback to latest release
- Install dir: `$HOME/.local/bin` (override: `${BINARY_INSTALL_DIR:-}`)
- PATH management: detect shell → update rc file
- One-liner: `curl -fsSL https://raw.githubusercontent.com/urmzd/{repo}/main/install.sh | bash`

## GitHub Action Pattern

For tools that benefit from CI integration:

- Composite actions (`using: composite`), not JavaScript
- Binary download: detect OS/arch → download from releases
- JSON stdout → `jq -r '.field'` → export as action outputs
- Inputs/outputs in `action.yml`
- Branding: `icon` + `color` for GitHub Marketplace
