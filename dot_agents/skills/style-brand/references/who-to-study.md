# Who to study

The designers and sites we track, and how to use them. Use this file when you
need precedent for a design decision, or when the user shares a design,
portfolio or product link.

## How to study a reference

A reference is something to learn from, not a template. In one past session the
agent opened a shared link and started matching it. The user had to say that
they did not want that site, they wanted consistent branding.

1. **Find out what the user likes about it.** Use their words. If they did not
   say, ask once, or state your guess and carry on.
2. **Open it and look.** Load the page in a browser and capture it at a phone
   width and a desktop width. A fetched summary or the HTML alone is not
   looking. Check both color schemes if the site has them.
3. **Write down examples and mishaps.** Examples are what works, stated as a
   principle with the measurement that makes it work. Mishaps are what fails.
   Every site has both, including the ones we admire. Do not inherit a mishap
   because it came with a look you like.
4. **Translate, do not copy.** Take the principle into this project's own
   fonts, palette and components. Never lift a palette, typeface, layout or
   copy.
5. **Report it.** Tell the user the two or three things you are taking and
   what you are leaving behind.

Date every study. Sites change. Re-open the page before you rely on a
measurement recorded here.

## Sites and portfolios

| Reference | Study for | Start here |
|---|---|---|
| Joseph Zhang (leads design at Cognition; earlier Notion, Cursor, Skiff, Apple) | Restraint: a tiny type system, one accent, real work shown first | https://joseph.cv, https://joseph.cv/cursor, https://joseph.cv/reading |

### Joseph Zhang, joseph.cv

Checked 2026-11-21 at 1440 and 390 wide, dark and light preference. The home
page and one case study (`/cursor`) were opened. Measurements are computed
styles from the live page.

**Examples**

- **No hero.** The first screen holds name, role, city, one paragraph, the
  teams he worked on and his links. Work starts directly under it. There is no
  call-to-action button. "Get in touch" is a link inside the paragraph.
- **Two typefaces, three sizes.** A sans at 15px (14px on phones), weight 500,
  for everything you read. A mono at 11.5px, uppercase and letterspaced, for
  labels. 10px for small marks. Hierarchy comes from case and color, not from
  bigger headings.
- **One accent, one meaning.** Yellow marks only two things: the arrow that
  says a link leaves the site, and footnote numbers. Nothing else is yellow.
- **A plain grid.** Twelve columns, 12px gaps, 12px page margin. Work sits in
  three columns of uneven-height tiles, and becomes one column on a phone with
  no sideways scroll.
- **The real thing in every tile.** Each tile shows the actual product: a
  screenshot or a short video on its own background. The caption is a title
  and one category label. No description, tags, dates or buttons.
- **A case study in one screen.** One large image, two short paragraphs, then
  facts as label and value pairs (role, collaborators, duration) and two plain
  link rows. Collaborators are credited by name.
- **A version in the footer.** The site shows a version number and a
  last-updated date, like a product that is maintained.

**Mishaps**

- **Labels are too faint.** The gray category labels are 11.5px at 3.91:1
  against the page. The footer date is 2.20:1. Both are under 4.5:1.
- **Dark only.** A light color-scheme preference gets the same dark page.
- **Weak document structure.** Every project title is an `h1` (14 on the home
  page). The `html` element has no `lang`. Every page has the same `<title>`.
  Every image has the same alt text, "project hero".
- **Tight targets.** The stacked Teams and Links rows are 20px apart on a
  phone, under the 24px minimum target size.
- **Scripts carry the media.** The raw HTML says "Loading..." in every tile
  until scripts run. Four videos autoplay on the home page.

**Take:** cut type sizes before you add one. Give the accent color a single
meaning. Show the real product and let a title and one label caption it.
**Leave:** the faint labels, the dark-only theme and the heading structure.
Keep the restraint and meet [the shared standard](web-design.md) for contrast,
structure and targets.

## AI workspaces and agent products

The principles drawn from these are in
[the AI workspace design reference](ai-workspace-design.md). The links were
checked on 2026-10-26.

| Reference | Study for | Start here |
|---|---|---|
| Harvey II | Project workspace, reviewable agent output, evidence | https://www.harvey.ai/blog/introducing-harvey-ii, https://www.harvey.ai/blog/how-we-approach-design-at-harvey |
| Codex app (Ed Bayes, Andrew Ambrosino) | Supervising parallel agents, approvals, review queue | https://openai.com/index/introducing-the-codex-app/, https://softwareengineeringdaily.com/wp-content/uploads/2026/01/SED1898-OpenAI.txt |
| Linear (Karri Saarinen) | Work navigation, hierarchy, AI workbench model | https://linear.app/now/design-for-the-ai-age, https://karrisaarinen.com/posts/every-feature-should-earn-its-place/ |
| Figma (Rasmus Andersson) | Role- and selection-sensitive UI, pattern reduction | https://rsms.me/work/figma/, https://www.figma.com/blog/ui-refresh/ |
| Raycast | Fast, discoverable actions | https://www.raycast.com/blog/a-fresh-look-and-feel, https://www.raycast.com/why |
| Dust (Édouard Wautier, Clément Aupiais) | Human/agent symmetry, prototype-first, trustworthy data display | https://dust.tt/blog/field-study-prototypes-over-mockups, https://medium.com/algolia-design/building-trust-with-data-visualisation-13321b44b819 |
| Anthropic (Nate Parrott, Meaghan Choi, Jenny Wen, Joel Lewenstein) | Chat plus specialized UI, mental models, deciding what to build | https://www.aidesignfieldguide.com/articles/nate-parrott, https://designerfund.com/blog/ai-design-anthropic, https://www.linkedin.com/pulse/whats-worth-making-joel-lewenstein-xcgqc/ |
| Geist (Anthropic, Harvey brand) | Values expressed through type, palette and components | https://geist.co/work/anthropic |

## Adding a reference

Add a row to the table that fits. For a site you studied, add a dated section
with examples and mishaps like the one above. Keep only what you saw on the
page. Do not credit a whole product to one designer; public credits cover
specific work.
