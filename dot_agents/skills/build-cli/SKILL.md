---
name: build-cli
description: >
  Design and audit CLI tools end-to-end: output modes, TTY detection, JSON piping,
  stderr/stdout separation, signal handling, install.sh, and portfolio-mandatory
  self-update / --format flags. Use when building, reviewing, or releasing any CLI.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: CLI Patterns
  category: development
  order: 3
---

# CLI Patterns

## Design Philosophy

A junior developer should understand any CLI tool's behavior from `--help` alone. Prefer obvious defaults. Machine output (JSON) enables composability. All human-facing output goes to stderr.

## Output Modes

### Decision Tree

| Scenario | Output Mode | Flag |
|----------|------------|------|
| Data/device API (zigbee-rest) | Always JSON on stdout | None needed |
| Dual human + machine consumers (e.g. release tools, agent orchestrators) | `--format json\|human` | Default: human |
| CLI with optional machine output (llmem) | `--json` flag + TTY auto-detect | Default: human if TTY, JSON if piped |
| Human-only tool (e.g. demo recorders, interactive wizards) | Styled stderr only | No JSON mode |

### TTY Auto-Detection

Standard behavior when no explicit format flag is given:

```
stdout.is_terminal() → human output (styled, colored)
!stdout.is_terminal() → JSON output (machine-readable)
```

Override flags:
- **`--json`** force JSON regardless of TTY
- **`--no-color`** / `NO_COLOR=1` env. Strip ANSI escape codes
- **`CI=true`** env. Treat as non-TTY (no spinners, no prompts, no color)

### JSON Conventions

- Rust: `serde_json::to_string_pretty()` to stdout
- Go: `json.MarshalIndent(v, "", "  ")` to stdout
- Python: `json.dumps(v, indent=2)` to stdout
- Errors in JSON mode: `{"error": "message"}` to stdout (not stderr), exit 1

## Stdout vs Stderr

| Stream | Content |
|--------|---------|
| **stdout** | Machine-readable data: JSON, generated content, completions |
| **stderr** | All human-facing UI: headers, spinners, checkmarks, errors, progress |

This enables piping: `tool command | jq '.field'` and `tool command 2>/dev/null`.

## Interactivity

### Prompts

```
  Prompt text? [y/N] _
```

Bold prompt, `[y/N]` suffix. Rules:
- Return `false` / skip in non-TTY (CI-safe)
- `--yes` / `-y` flag: auto-confirm all prompts
- Never block on stdin without checking `stdin.is_terminal()`

### Dry-Run

Prefix all hypothetical actions with `[dry-run]` to stderr:

```
[dry-run] Would create tag: v2.1.0
[dry-run] Would push tag: v2.1.0
```

### TUI Policy

Never use full-screen TUI frameworks (ratatui, bubbletea, textual, blessed). Reasons:
- Breaks piping and shell composition
- Breaks CI / non-interactive environments
- Breaks screen readers and accessibility tools
- Adds heavy dependencies for marginal UX gain

Use inline styled output (the ui module pattern below) for all interactive feedback. For selection, use a numbered list + prompt, not a TUI picker.

## Signal Handling

Trap SIGINT and SIGTERM. On signal: finish current atomic operation, clean up temp files, clear spinner line, exit with correct code.

| Language | Pattern |
|----------|---------|
| Rust | `ctrlc` crate or `tokio::signal`. Set `AtomicBool`, check in loops. |
| Go | `signal.NotifyContext(ctx, os.Interrupt, syscall.SIGTERM)`. Pass `ctx` to all long operations. |
| Python | `signal.signal(SIGINT, handler)` + `threading.Event` for cooperative cancellation. |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error |
| `2` | No-op / no changes (sr pattern) |
| `130` | Interrupted (SIGINT / Ctrl-C) |
| `143` | Terminated (SIGTERM) |

## Config Systems

| Format | Use | Discovery |
|--------|-----|-----------|
| TOML | User-editable configs | Walk up from cwd looking for `<tool>.toml` |
| YAML | Release/CI configs | Fixed name at repo root (`sr.yaml`) |

- Override: `--override key.path=value` (dot-notation)
- Env vars: `TOOL_CONFIG`, `TOOL_VERSION`, etc.

## Output Directories

- **`outputs/<name>/<YYYYMMDD_HHMMSS>/`** timestamped results (linear-gp)
- **`showcase/`** demo captures (default output dir for your demo recorder)
- **`bin/`** Go builds, **`target/`** Rust builds

## Visual Style

### Stack by Language

| Language | Styling | Spinners | CLI Parsing |
|----------|---------|----------|-------------|
| Rust | crossterm 0.28 | indicatif 0.17 | clap 4 (derive) |
| Go | lipgloss / termenv | spinner (braille) | cobra |
| Python | rich | rich.progress | typer |

### Color Semantics

Every color has exactly one meaning. Do not deviate.

| Color | Meaning | Used for |
|-------|---------|----------|
| Cyan + bold | Action / heading | Headers, section titles, spinner, indices `[1]` |
| Green + bold | Success | Checkmarks `✓`, file additions `A`, arrows `→` |
| Yellow + bold | Warning / caution | Warnings `⚠`, modifications `M`, skipped `−` |
| Red | Error / destructive | Deletions `D`, error messages |
| Blue | Informational alternate | Renames `R` |
| Dim | Secondary / supporting | Dividers, detail text, tree connectors, timestamps |
| Bold (no color) | Primary content | Commit messages, prompts, emphasis |

### Symbol Set

| Symbol | Color | Purpose |
|--------|-------|---------|
| `✓` | green bold | Phase/step completion |
| `⚠` | yellow bold | Warning |
| `ℹ` | cyan | Informational note |
| `→` | green bold | Item created/produced |
| `−` | yellow | Skipped action |
| `▸` | cyan | Sub-action / tool call |
| `⊘` | dim | Usage/stats |

### Layout

All output is indented **2 spaces** from the terminal edge. Nested content adds **2 more spaces**.

```
  header text
  ────────────────────────────────────────

  ✓ Phase completed · detail
  ⚠ Warning message
  ℹ Informational note

  SECTION TITLE · count
  ──────────────────────────────────────────────────

  [1] Primary content
   │  Secondary detail
   │
   ├─ A file_added.rs
   └─ M file_modified.rs

  ──────────────────────────────────────────────────
```

### Header

```
println!();  // blank line
eprintln!("  {}", cmd.cyan().bold());
eprintln!("  {}", "─".repeat(40).dim());
println!();
```

Cyan bold title, 40-char dim rule, blank lines above and below. All to stderr.

### Spinner

Braille animation, cyan, 80ms tick, 2-space indent:

```rust
ProgressStyle::default_spinner()
    .tick_chars("⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏")
    .template("  {spinner:.cyan} {msg}")
```

When done, replace with `✓` checkmark line via `phase_ok()`.

### Phase Completion

```
  ✓ Phase name · optional detail
```

Green+bold checkmark. Detail after `·` is dim. Always 2-space indent.

### Tree Visualization

```
   │   dim vertical connector
   ├─  dim branch connector (non-last item)
   └─  dim last-item connector
```

Tree connectors are always dim. Content after connectors uses semantic colors.

### Progress Tracking

```
  [1/3] Step description
    ✓ sub-item
    → result
```

Index is cyan+bold. Description is bold. Sub-items indented 4 spaces.

### Warnings, Info, Errors

```
  ⚠ Warning text          (yellow symbol, yellow text)
  ℹ Info text              (cyan symbol, dim text)
  error: message           (red, to stderr, with anyhow context chain)
```

### Token/Cost Usage

```
  ⊘ 1.2k in / 3.4k out · $0.0042
```

Dim symbol, dim counts, dim cost. Format: `>=1M` → `1.2M`, `>=1k` → `1.2k`, else raw.

## The ui Module Pattern

Every CLI project has a `ui` module exporting a consistent API. Do not extract a shared crate/library; the modules are 30-60 lines each, and copying is cheaper than cross-repo dependency management.

### Canonical API

| Function | Purpose |
|----------|---------|
| `header(title)` | Cyan bold title + dim rule to stderr |
| `phase_ok(msg, detail?)` | Green checkmark + message to stderr |
| `warn(msg)` | Yellow warning to stderr |
| `info(msg)` | Cyan info note to stderr |
| `error(msg)` | Red error to stderr |
| `spinner(msg) → handle` | Start braille spinner to stderr |
| `confirm(prompt) → bool` | TTY-safe y/N prompt (false in non-TTY) |

### Reference Implementations

- Rust: `sr/crates/sr-ai/src/ui/mod.rs`
- Go: a small `internal/ui/` package wrapping `lipgloss` with `IsTTY()`, `Info/Warn/Error` helpers, and an `output.Render(format, v)` switch on `--format`. ~50 lines.
- Python: `rich.Console(stderr=True)` with matching color semantics

### Rule

All ui output goes to stderr. Use `eprintln!` / `fmt.Fprintf(os.Stderr, ...)` / `Console(stderr=True)`. Never `println!` / `fmt.Println` for UI.

## Install Script Convention

Every CLI tool MUST have `install.sh` at repo root:

- Portable `#!/bin/sh`
- Platform detection: `uname -s` (OS) + `uname -m` (arch)
- Targets: GNU + musl for Linux, Darwin for macOS, MSVC for Windows
- Version override: `${BINARY_VERSION:-}`, fallback to latest release
- Install dir: `$HOME/.local/bin` (override: `${BINARY_INSTALL_DIR:-}`)
- PATH management: detect shell, update rc file
- One-liner: `curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/install.sh | bash`

## GitHub Action Pattern

For tools that benefit from CI integration:

- Composite actions (`using: composite`), not JavaScript
- Binary download: detect OS/arch, download from releases
- JSON stdout → `jq -r '.field'` → export as action outputs
- Inputs/outputs in `action.yml`
- Branding: `icon` + `color` for GitHub Marketplace

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| ASCII box borders (`═══`, `***`) | Dim `─` rules |
| `println!` without indentation | Always 2-space minimum |
| `info!()` / `warn!()` tracing macros for user output | Styled crossterm/lipgloss/rich output |
| Mixing colors arbitrarily | Follow color semantics table |
| Verbose banners or ASCII art | Clean, minimal headers |
| Raw error dumps | `{e:#}` with anyhow context chains |
| Full-screen TUI frameworks | Inline styled output (ui module) |
| Blocking on stdin without TTY check | Check `is_terminal()`, respect `--yes` |
| Ignoring SIGINT/SIGTERM | Trap signals, clean up, exit 130/143 |
| Swallowing errors in JSON mode | Output `{"error": "..."}` to stdout |

---

# Portfolio Requirements

The conventions above are portable design defaults. The rules below are **mandatory** for every CLI tool in this portfolio so every tool is independently installable, self-updating, and composable with scripts and CI pipelines.

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

### Rust . `agentspec_update` crate

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
    match agentspec_update::self_update("<owner>/<repo>", env!("CARGO_PKG_VERSION"), "<binary>")? {
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

### Go . GitHub Releases HTTP fetch

Implement `internal/updater/updater.go` with:
1. Fetch latest tag via `gh api repos/<owner>/<repo>/releases/latest` (works with github.com and GHES)
2. Compare against current version (injected via `-ldflags`)
3. Construct asset URL from the response's `assets[].browser_download_url` matching `BINARY-OS-ARCH`
4. Download to a temp file, `chmod +x`, then `os.Rename()` over `os.Executable()`
5. Wire as `cobra.Command` on root: `rootCmd.AddCommand(newUpdateCmd(version))`

### Node . npm self-install

```ts
// update command
.command('update')
.description('Update to latest release')
.action(async () => {
  const { execSync } = await import('child_process');
  execSync('npm install -g @<scope>/<package>@latest', { stdio: 'inherit' });
});
```

## Output Format Flag

**Rule: `--format json|human` (default: human) for any command that emits structured data.**

- Always-JSON CLIs (device/REST APIs like zigbee-skill): no flag needed . all output is JSON on stdout
- Never use `--json` (boolean) . use the enum form instead
- Never use `--export-json` . that's not composable

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
# install.sh . Installs BINARY from GitHub releases.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/install.sh | sh
#
# Environment variables:
#   PREFIX_VERSION     . version to install (default: latest)
#   PREFIX_INSTALL_DIR . installation directory (default: $HOME/.local/bin)
#   PREFIX_SHA256      . optional SHA256 checksum

set -eu
REPO="<owner>/<repo>"
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
- **fsrc exception**: uses `run <files>` subcommand to preserve positional-arg UX while still having `update` and `version` as peers

## Reference Implementations

| Pattern | Reference |
|---------|-----------|
| Self-update (Rust) | `sr/crates/sr-cli/src/main.rs` lines 343-356 |
| `--format json\|human` | `sr/crates/sr-cli/src/main.rs`, `oag/crates/oag-cli/src/main.rs` |
| install.sh | `sr/install.sh` |
| Cobra root setup | inline 20-line example below |
| Go self-update | `saige/internal/updater/updater.go` (after migration) |
