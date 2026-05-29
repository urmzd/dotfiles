---
name: style-brand
description: >
  Frame and document a project's visual identity: terminal theme, font, demo
  capture pipeline, asset conventions. Use when establishing or maintaining brand
  consistency. Ships an example brand (Cyberdream + MonaspiceNe + teasr) as a
  template, not a mandate.
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
| Theme | $BRAND_THEME (example: Cyberdream, 256-color) |
| Font | $BRAND_FONT (example: MonaspiceNe Nerd Font, 16pt) |

Example palette (Cyberdream -- substitute your own):

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

Terminal demos are recorded with a consistent template using whatever recorder you prefer (this portfolio uses [teasr](https://github.com/urmzd/teasr)):

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
- **CI integration:** invoke your recorder via a reusable action (this portfolio uses `urmzd/teasr/.github/actions/teasr@main`)

## Asset Directory Convention

`showcase/` directory: `demo.png` or `demo.gif` (hero, 80% width), `demo-<feature>.png` (feature captures), `example_results/` (gallery, 30% width each).

## Demo Priority

teasr (automated) > manual screenshots

## Branding Consistency

Your chosen theme + font applied consistently across (example: Cyberdream + MonaspiceNe):
- Terminal demos (teasr)
- GitHub Actions branding (`icon` + `color`)
- github-metrics SVGs
