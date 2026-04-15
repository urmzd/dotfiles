---
name: build-cli
description: >
  CLI conventions. Output modes, TTY detection, JSON piping, stdout/stderr separation,
  interactivity, signal handling, visual style, and CI integration. Use when building
  or reviewing any CLI tool.
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
| Dual human + machine consumers (sr, oag) | `--format json\|human` | Default: human |
| CLI with optional machine output (llmem) | `--json` flag + TTY auto-detect | Default: human if TTY, JSON if piped |
| Human-only tool (teasr, fsrc) | Styled stderr only | No JSON mode |

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
| TOML | User-editable configs | Walk up from cwd (teasr, linear-gp) |
| YAML | Release/CI configs | Fixed name at repo root (`sr.yaml`) |

- Override: `--override key.path=value` (dot-notation)
- Env vars: `TOOL_CONFIG`, `TOOL_VERSION`, etc.

## Output Directories

- **`outputs/<name>/<YYYYMMDD_HHMMSS>/`** timestamped results (linear-gp)
- **`showcase/`** demo captures (teasr, default: `./teasr-output`)
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
- Go: `incipit/internal/ui/ui.go` (lipgloss-based)
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
- One-liner: `curl -fsSL https://raw.githubusercontent.com/urmzd/{repo}/main/install.sh | bash`

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
