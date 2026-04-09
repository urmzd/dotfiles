---
name: cli-standards
description: >
  Mandatory CLI standards for all urmzd/* tools: argument parser selection, self-update
  requirement, output format flag, global flags, and install.sh. Use when building,
  reviewing, or auditing any CLI tool in this portfolio. These rules override build-cli
  where they conflict.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: CLI Standards
  category: development
  order: 2
---

# CLI Standards

These are **mandatory** conventions for every CLI tool in this portfolio. They exist to ensure every tool is independently installable, self-updating, and composable with scripts and CI pipelines.

## Argument Parser Selection

| Language | Framework | Notes |
|----------|-----------|-------|
| Rust | clap v4 (derive macros) | `#[derive(Parser)]`, `#[derive(Subcommand)]` |
| Go | Cobra | `rootCmd.AddCommand()`, persistent flags on root |
| Node | Commander v14 | `.command()`, `.option()`, `.addOption()` |
| Python | typer | Decorator-based, consistent with Rust mental model |

Never use stdlib flag parsing (`flag` package in Go, `argparse` in Python) for new tools.

## Self-Update (Mandatory)

**Every CLI tool must have a `update` subcommand** (or `self-update` if `update` is already taken for content management) that replaces the running binary with the latest GitHub release.

### Rust — `agentspec_update` crate

```toml
# workspace Cargo.toml
agentspec-update = "0.6.0"

# CLI crate Cargo.toml
agentspec-update = { workspace = true }
```

```rust
// In Commands enum
/// Self-update to the latest release
Update,

// Handler
Commands::Update => {
    eprintln!("current version: {}", env!("CARGO_PKG_VERSION"));
    match agentspec_update::self_update("urmzd/REPO", env!("CARGO_PKG_VERSION"), "BINARY")? {
        agentspec_update::UpdateResult::AlreadyUpToDate => {
            eprintln!("already up to date");
        }
        agentspec_update::UpdateResult::Updated { from, to } => {
            eprintln!("updated: {from} → {to}");
        }
    }
    Ok(())
}
```

### Go — GitHub Releases HTTP fetch

Implement `internal/updater/updater.go` with:
1. Fetch latest tag from `https://api.github.com/repos/urmzd/REPO/releases/latest`
2. Compare against current version (injected via `-ldflags`)
3. Construct asset URL: `https://github.com/urmzd/REPO/releases/download/TAG/BINARY-OS-ARCH`
4. Download to a temp file, `chmod +x`, then `os.Rename()` over `os.Executable()`
5. Wire as `cobra.Command` on root: `rootCmd.AddCommand(newUpdateCmd(version))`

### Node — npm self-install

```ts
// update command
.command('update')
.description('Update to latest release')
.action(async () => {
  const { execSync } = await import('child_process');
  execSync('npm install -g @urmzd/PACKAGE@latest', { stdio: 'inherit' });
});
```

## Output Format Flag

**Rule: `--format json|human` (default: human) for any command that emits structured data.**

- Always-JSON CLIs (device/REST APIs like zigbee-skill): no flag needed — all output is JSON on stdout
- Never use `--json` (boolean) — use the enum form instead
- Never use `--export-json` — that's not composable

### Rust

```rust
#[derive(Clone, clap::ValueEnum)]
enum OutputFormat {
    Human,
    Json,
}

// In Cli struct (global):
#[arg(long, global = true, default_value = "human", value_enum)]
format: OutputFormat,

// In command handler:
match cli.format {
    OutputFormat::Json => println!("{}", serde_json::to_string_pretty(&data)?),
    OutputFormat::Human => { /* styled output to stderr */ }
}
```

### Go

```go
var format string
rootCmd.PersistentFlags().StringVar(&format, "format", "human", "Output format: json|human")

// In command:
if format == "json" {
    enc := json.NewEncoder(os.Stdout)
    enc.SetIndent("", "  ")
    enc.Encode(data)
} else {
    // human output to stderr
}
```

### Node

```ts
.addOption(new Option('--format <fmt>', 'Output format').choices(['json', 'human']).default('human'))
```

## Standard Global Flags

| Flag | Type | When to include |
|------|------|-----------------|
| `--format json\|human` | enum | Any tool with structured data output |
| `--verbose` / `-v` | bool | Tools with meaningful progress output |
| `--dry-run` | bool | Mutating tools (release, file modification) |

Do NOT add `--verbose` to always-JSON tools (no human output to make verbose).

## install.sh (Mandatory)

**Every CLI tool must have `install.sh` at the repo root.**

Template (copy from `sr/install.sh`, substitute binary name and prefix):

```sh
#!/bin/sh
# install.sh — Installs BINARY from GitHub releases.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/urmzd/REPO/main/install.sh | sh
#
# Environment variables:
#   PREFIX_VERSION     — version to install (default: latest)
#   PREFIX_INSTALL_DIR — installation directory (default: $HOME/.local/bin)
#   PREFIX_SHA256      — optional SHA256 checksum

set -eu
REPO="urmzd/REPO"
# ... (full template in sr/install.sh)
```

Prefix naming: `SR_` → `TEASR_`, `AGENTSPEC_`, `OAG_`, `MNEMONIST_`, `LGP_`, `EMBED_SRC_`, etc.

Platform targets (Rust musl): `x86_64-unknown-linux-musl`, `aarch64-unknown-linux-musl`, `x86_64-apple-darwin`, `aarch64-apple-darwin`.

## Subcommand Conventions

- Max 2 levels of nesting: `tool command subcommand`
- Binary name matches the `[[bin]]` name in `Cargo.toml` or `"bin"` in `package.json`
- Every CLI **must** have both:
  - `--version` flag (auto-provided by clap/cobra/commander)
  - `version` subcommand that prints `<name> v<version>` to stdout
  - `update` subcommand for self-update (see above; use `self-update` only if `update` is taken at top level for content management)
- **embed-src exception**: uses `run <files>` subcommand to preserve positional-arg UX while still having `update` and `version` as peers

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error |
| `2` | No-op / no changes |
| `130` | Interrupted (SIGINT) |

## Reference Implementations

| Pattern | Reference |
|---------|-----------|
| Self-update (Rust) | `sr/crates/sr-cli/src/main.rs` lines 343–356 |
| `--format json\|human` | `sr/crates/sr-cli/src/main.rs`, `oag/crates/oag-cli/src/main.rs` |
| install.sh | `sr/install.sh` |
| Cobra root setup | `incipit/internal/cli/root.go` |
| Go self-update | `saige/internal/updater/updater.go` (after migration) |
