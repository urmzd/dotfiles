---
name: style-brand
description: >
  Design, refine or critique anything a person looks at: websites, product UI,
  agent workspaces, single screens and components, and brand identity. Holds
  the shared design standard, the mishaps to check for, and the designers we
  study. Use when building or changing a page or screen, reviewing a UI or a
  screenshot, fixing alignment, spacing, clutter or inconsistent controls,
  keeping several sites on one brand, or when the user shares a design or
  portfolio link as a reference. Also covers terminal themes and demo assets.
metadata:
  title: Visual Identity
  category: visual
  order: 0
---

# Visual Identity

## Which reference to read

| The work | Read |
|---|---|
| A website, landing page or docs site | [Shared web design standard](references/web-design.md) |
| Product UI: an app screen, dashboard, panel or component | [Shared web design standard](references/web-design.md) |
| An interface where people direct and review agent work | The standard, then [AI workspace design](references/ai-workspace-design.md) |
| The user shared a link, or you need precedent | [Who to study](references/who-to-study.md) |
| A terminal theme or a demo capture | The sections at the end of this file |

The web design standard applies to every screen, product UI included. Do not
read only the AI workspace reference for product UI. It adds to the standard
and does not replace it.

## Order of work

1. **Find the project's own design first.** Look for design notes, a brand
   guide, a tokens file and the logo files. If the project belongs to a family
   of sites or apps, open a sibling and match its palette, type, stroke weight,
   logo and tone before you draw anything new. Reuse the logo file. Do not
   redraw it.
2. **Read the reference** from the table above.
3. **Name the job of the screen** and the person's next action. List the text
   and controls you plan to put on it, each with what the person does or
   learns from it. Drop the ones with no answer.
4. **Build within the brief** and the project's existing architecture.
5. **Look at it.** Run the real thing and capture it at a phone width and a
   desktop width, in light and dark when both exist. Check the screenshot
   against the mishap list below.
6. **Report with the screenshots.** Name any state you did not see.

Keep project-specific fonts, palette, content decisions and approved
exceptions in that project's design notes. Standardize the method and quality
bar, not the appearance of every brand.

## Mishaps to check for

These are corrections people gave on real work, most frequent first. Check
each one on the screenshot, not in the code.

- **Unearned text and controls.** Extra labels, helper lines, tags, badges and
  buttons that nobody asked for. Ask of every element: what does the person do
  or learn with this? If there is no answer, remove it. Do not swap it for a
  different element.
- **Words where a familiar icon would do.** Use a well-known icon for a
  well-known action, with an accessible name. Use one icon set at one size per
  context. Never put two icons that mean the same thing side by side.
- **Missing structure.** Comparable records belong in a table. One object with
  its actions belongs in a card. Nothing should float without a container or
  an alignment line it shares with its neighbors.
- **Sibling sites that drift.** Different colors, logo, stroke weights or tone
  across products of one brand. Match the existing tokens and assets.
- **Animation ahead of clarity.** A clean, static page beats a moving one. Fix
  blur and legibility before adding motion. Logos and icons are vector files.
- **Fonts that silently fall back.** Check the computed font family in the
  browser. A correct stylesheet does not prove the font loaded.
- **Inconsistent controls.** Chevrons, icon sizes and button heights that
  differ between similar controls, or content that overflows its button.
- **Copying a reference.** A link the user shares is something to study. See
  [who to study](references/who-to-study.md) for how.

The theme and terminal examples below are optional examples, not website
defaults.

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
