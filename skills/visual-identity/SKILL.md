---
name: visual-identity
description: Terminal theme, font choices, and VHS demo recording standards. Use when configuring terminal appearance, recording demos, or maintaining visual consistency.
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

## VHS Demo Template

Terminal demos are recorded with [VHS](https://github.com/charmbracelet/vhs) using a consistent template. Standard settings:

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
