---
name: style-brand
description: >
  Establish a project's visual identity and apply the shared website design
  approach: readable typography, mobile navigation, clear visitor journeys,
  accessible interactions and consistent content. Use when designing or refining
  a website, interface, agent workspace or brand. Also covers terminal themes
  and demo assets.
allowed-tools: Read, Grep, Glob
metadata:
  title: Visual Identity
  category: visual
  order: 0
---

# Visual Identity

## Websites and interfaces

Read [the shared web design standard](references/web-design.md) for website or
interface work. Apply it within the user's brief and the project's existing
architecture. Keep project-specific fonts, palette, content decisions and
approved exceptions in that project's design notes. Standardize the method and
quality bar, not the appearance of every brand.

For interfaces where people direct and review agent work, also read
[the AI workspace design reference](references/ai-workspace-design.md).

The theme and terminal examples below are optional examples, not website defaults.

## Theme & Font

| Element | Choice |
|---------|--------|
| Theme | <your theme> (example: Cyberdream, 256-color) |
| Font | <your font> (example: MonaspiceNe Nerd Font, 16pt) |

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
