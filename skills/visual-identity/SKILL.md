---
name: visual-identity
description: Terminal theme, font, VHS demos, teasr integration, asset conventions, and branding across README/demos. Use when configuring appearance, recording demos, or maintaining visual consistency.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
metadata:
  title: Visual Identity
  category: visual
  order: 0
---

# Visual Identity

## Theme & Font

| Element | Choice |
|---------|--------|
| Theme | Cyberdream (256-color) |
| Font | MonaspiceNe Nerd Font (16pt) |

The Cyberdream color palette:

| Color | Hex |
|-------|-----|
| Background | `#16181a` |
| Foreground | `#ffffff` |
| Red | `#ff6e5e` |
| Green | `#5eff6c` |
| Yellow | `#f1ff5e` |
| Blue | `#5ea1ff` |
| Magenta | `#bd5eff` |
| Cyan | `#5ef1ff` |
| Selection | `#3c4048` |

## teasr Demo Template

Terminal demos are recorded with [teasr](https://github.com/urmzd/teasr) using a consistent template. Standard settings:

- **Resolution**: 1200x700
- **Padding**: 24px
- **Typing speed**: 50ms
- **Window bar**: Rings style
- **Cursor blink**: Disabled

### Template Structure

```tape
Output <output-path>

Set Shell "zsh"
Set FontFamily "MonaspiceNe Nerd Font"
Set FontSize 16
Set Width 1200
Set Height 700
Set Padding 24
Set Theme { "name": "Cyberdream", ... }
Set WindowBar "Rings"
Set TypingSpeed 50ms
Set CursorBlink false

# Setup (hidden from recording)
Hide
# Project-specific setup: PATH, env vars, build
Type "export PS1='> '"
Enter
Show

# Splash pause
Sleep 3s

# Demo commands go here
```

Each demo includes a branded splash card displaying the project name and links to `github.com/urmzd` and `urmzd.com`.

## teasr Demo Capture

teasr automates demo capture with `teasr.toml` config:

- **Scene types:** web (Chrome DevTools), terminal (PTY→SVG→PNG), screen (xcap)
- **Output formats:** png, gif
- **Standard output dir:** `showcase/` (default: `./teasr-output`)
- **Naming:** `demo.png`, `demo.gif`, `demo-<feature>.png`
- **CI integration:** `urmzd/teasr/.github/actions/teasr@main`

## Asset Directory Convention

```
showcase/
├── demo.png (or .gif)        — hero (80% width in README)
├── demo-<feature>.png        — feature captures
└── example_results/           — gallery (30% width each)
```

## Demo Priority

teasr (automated) > VHS (branded terminal GIF) > manual screenshots

## Branding Consistency

Cyberdream theme + MonaspiceNe font applied consistently across:
- Terminal demos (VHS/teasr)
- GitHub Actions branding (`icon` + `color`)
- github-metrics SVGs
