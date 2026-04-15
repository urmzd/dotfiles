---
name: style-brand
description: Terminal theme, font, teasr demo capture, asset conventions, and branding across README/demos. Use when configuring appearance, recording demos, or maintaining visual consistency.
allowed-tools: Read Grep Glob Bash Edit Write
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

Terminal demos are recorded with [teasr](https://github.com/urmzd/teasr) using a consistent template:

```toml
[output]
dir = "./showcase"
formats = [{ output_type = "gif" }, { output_type = "png" }]

[[scenes]]
type = "terminal"
name = "demo"
theme = "dracula"
cols = 100
rows = 24
frame_duration = 80

[[scenes.interactions]]
type = "type"
text = "export PS1='> '"
hidden = true

[[scenes.interactions]]
type = "key"
key = "enter"
hidden = true

[[scenes.interactions]]
type = "wait"
duration = 500
hidden = true

# Demo commands go here
[[scenes.interactions]]
type = "type"
text = "<command>"
speed = 50

[[scenes.interactions]]
type = "key"
key = "enter"

[[scenes.interactions]]
type = "wait"
duration = 2000
```

## teasr Demo Capture

teasr automates demo capture with `teasr.toml` config:

- **Scene types:** web (Chrome DevTools), terminal (PTY→SVG→PNG), screen (xcap)
- **Output formats:** png, gif
- **Standard output dir:** `showcase/` (default: `./teasr-output`)
- **Naming:** `demo.png`, `demo.gif`, `demo-<feature>.png`
- **CI integration:** `urmzd/teasr/.github/actions/teasr@main`

## Asset Directory Convention

`showcase/` directory: `demo.png` or `demo.gif` (hero, 80% width), `demo-<feature>.png` (feature captures), `example_results/` (gallery, 30% width each).

## Demo Priority

teasr (automated) > manual screenshots

## Branding Consistency

Cyberdream theme + MonaspiceNe font applied consistently across:
- Terminal demos (teasr)
- GitHub Actions branding (`icon` + `color`)
- github-metrics SVGs
