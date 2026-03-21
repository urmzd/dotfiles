---
name: cli-ui
description: CLI terminal UI standard — colors, spinners, symbols, layout, and output hierarchy. The canonical reference for consistent, world-class CLI output across all tools. Use when building or reviewing CLI output code.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
metadata:
  title: CLI UI
  category: development
  order: 4
---

# CLI UI Standard

The reference implementation lives in `sr/crates/sr-ai/src/ui/mod.rs`. All CLI tools must match this visual language.

## Stack by Language

| Language | Styling | Spinners | CLI Parsing |
|----------|---------|----------|-------------|
| Rust | crossterm 0.28 | indicatif 0.17 | clap 4 (derive) |
| Go | lipgloss / termenv | spinner (charmbracelet) | cobra |
| Python | rich | rich.progress | typer |

## Color Semantics

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

## Symbol Set

Use these exact symbols. No substitutions.

| Symbol | Color | Purpose |
|--------|-------|---------|
| `✓` | green bold | Phase/step completion |
| `⚠` | yellow bold | Warning |
| `ℹ` | cyan | Informational note |
| `→` | green bold | Item created/produced |
| `−` | yellow | Skipped action |
| `▸` | cyan | Sub-action / tool call |
| `⊘` | dim | Usage/stats |

## Layout

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

## Header

```
println!();
println!("  {}", cmd.cyan().bold());
println!("  {}", "─".repeat(40).dim());
println!();
```

Always: cyan bold title, 40-char dim horizontal rule, blank lines above and below.

## Spinner

Braille animation, cyan, 80ms tick, 2-space indent:

```rust
ProgressStyle::default_spinner()
    .tick_chars("⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏")
    .template("  {spinner:.cyan} {msg}")
```

When done, replace with a `✓` checkmark line via `phase_ok()`.

## Phase Completion

```
  ✓ Phase name · optional detail
```

Checkmark is green+bold. Detail after `·` is dim. Always 2-space indent.

## Tree Visualization

For hierarchical output (files, dependencies, sections):

```
   │   dim vertical connector
   ├─  dim branch connector (non-last item)
   └─  dim last-item connector
```

Tree connectors are always dim. Content after connectors uses semantic colors.

## Progress Tracking

For multi-step operations:

```
  [1/3] Step description
    ✓ sub-item
    → result
```

Index is cyan+bold. Description is bold. Sub-items indented 4 spaces.

## Warnings and Info

```
  ⚠ Warning text          (yellow symbol, yellow text)
  ℹ Info text              (cyan symbol, dim text)
```

## Error Output

- Errors go to **stderr**
- Format: `eprintln!("error: {e:#}");` with anyhow/thiserror context
- Exit code `1` for errors, `2` for no-op/no-changes
- No-op errors omit the `error:` prefix

## Confirmation Prompts

```
  Prompt text? [y/N] _
```

Bold prompt, `[y/N]` suffix. Return `false` in non-TTY (CI-safe).

## Dry-Run Output

Prefix all hypothetical actions with `[dry-run]` to stderr:

```
[dry-run] Would create tag: v2.1.0
[dry-run] Would push tag: v2.1.0
```

## Token/Cost Usage

When applicable (AI-powered tools):

```
  ⊘ 1.2k in / 3.4k out · $0.0042
```

Dim symbol, dim counts, dim cost. Format: `>=1M` → `1.2M`, `>=1k` → `1.2k`, else raw number.

## Stdout vs Stderr

- **stdout**: Machine-readable data (JSON, generated content)
- **stderr**: All human-facing UI (headers, spinners, checkmarks, errors, progress)

This enables piping: `tool command | jq '.field'`

## Anti-Patterns

- ASCII box borders (`═══`, `***`, `---` as separators) — use dim `─` rules
- `println!` without indentation — always 2-space minimum
- Plain `info!()` / `warn!()` / `error!()` tracing macros for user-facing output — use styled crossterm output
- Mixing colors arbitrarily — follow the color semantics table
- Verbose banners or ASCII art — clean, minimal headers only
- Raw error dumps without context — use `{e:#}` with anyhow context chains
