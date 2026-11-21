# AI workspace design

Use for interfaces where people direct, supervise and review agent work. Distilled
from public statements by designers at Anthropic, OpenAI (Codex), Linear, Figma,
Raycast, Dust and Harvey, checked 2026-10-26. **Source** lines paraphrase what the
designers said. **Apply** lines are our synthesis, not their claims.

## Core stance

An agent product is a structured workbench, not a chat box. Chat stays as the
flexible baseline. Add specialized UI only where it solves a concrete problem chat
cannot.

- **Source:** Saarinen (generic chat lacks structure for specialized workflows),
  Parrott (chat as baseline, specialized UI when it earns it).

## Principles

### 1. Organize around the work, not the conversation

- **Source:** Harvey II attaches documents, parties, tasks, permissions and history
  to a Space, and tasks move between lawyers and agents. Codex groups threads by
  project and carries CLI/IDE history into the app.
- **Apply:** the project is the home object. Threads, runs, files and permissions
  hang off it. One "New" action starts work from inside the project.

### 2. Make the next human decision obvious

- **Source:** Harvey's notifications hub links straight to the object needing
  attention. Codex returns scheduled work through a review queue. Ambrosino: opening
  the app for the next job should need no hesitation.
- **Apply:** separate running, awaiting review and done. Every notification
  deep-links to the decision, not to a list.

### 3. Supervision is the product

- **Source:** Codex is framed as a place to direct and supervise several agents,
  with in-context review and comments, isolated worktrees and sandbox defaults.
  Saarinen's workbench includes deploying agents, guidelines and human approval.
- **Apply:** give every output a route: output, evidence, decision. Let people
  comment on a change where the change is shown.

### 4. Strong defaults, fine-grained control

- **Source:** Bayes: fine-grained command approvals and meaningful modes on top of
  safe defaults. Harvey: reduce complexity without removing oversight.
- **Apply:** "calm" means people need not watch infrastructure. It does not mean
  hiding consequential choices.

### 5. Show the evidence

- **Source:** Harvey: citations and an inspectable trail let professionals verify
  output. Aupiais: tables for exact lookup, charts only when they clarify a
  relationship, meaning legible in a screenshot, consistent color semantics.
- **Apply:** runs show sources, tool calls and diffs. Cost and usage use exact
  numbers with a clear scope.

### 6. Reveal capability progressively

- **Source:** Bayes: the composer and model picker must reveal capability without
  an excess of options. Andersson (Figma): visible tools change with permission,
  selection and task. Parrott: explain unfamiliar capability with words and mental
  models. Polu (Dust): everyday language instead of prompting jargon.
- **Apply:** keep a stable shell and surface controls for the current object and
  role. Name capabilities in the user's terms.

### 7. Fast actions that stay visible

- **Source:** Raycast: "fast, simple, delightful"; contextual actions with visible
  shortcuts; avoid context switches and click chains.
- **Apply:** a command surface for start, stop, assign, inspect and approve. Print
  shortcuts beside actions so the UI teaches them. Never make an action
  keyboard-only.

### 8. Human and agent symmetry

- **Source:** Wautier (Dust): every capability is controllable by people and by
  agents; agents use text/API primitives, not UI navigation. Document the design
  system for the agents that build the product.
- **Apply:** each UI action maps to an API/tool an agent can call, with the same
  permissions and the same visible audit trail.

### 9. Every feature earns its place

- **Source:** Saarinen: cheap implementation does not remove maintenance,
  comprehension and support cost. Lewenstein: deciding what is worth making is
  design's core task. Silber: do less.
- **Apply:** before adding a panel, name the job it serves and what it replaces.

### 10. Design in working prototypes

- **Source:** Wautier: running prototypes expose transitions, errors, empty
  states, keyboard behavior and real content; settle behavior before polish. Bayes,
  Parrott and Choi work the same way. Lewenstein: speed does not replace final
  craft.
- **Apply:** prototype the full governed loop, including waiting, refusal,
  cancellation and recovery, with realistic content.

### 11. One vocabulary

- **Source:** Figma's 2019 refresh cut the pattern count, adopted WCAG contrast
  and kept information architecture that already worked. Harvey's design system
  names tokens by role, aligns Figma with code and migrates in component groups.
  Wen: design sharing and permissions as soon as collaboration exists.
- **Apply:** run view, approval, permission error and empty project share one set
  of components and states. Audit states before adding visual treatments.

## Review checklist

- [ ] The project, not the chat, is the home object.
- [ ] Running, awaiting review and done are visually distinct.
- [ ] Every notification opens the decision it refers to.
- [ ] Each agent output links to its evidence (sources, tool calls, diff).
- [ ] Approvals have safe defaults and a visible, fine-grained override.
- [ ] Controls change with role and selection; the shell does not.
- [ ] Frequent actions have visible shortcuts and a mouse path.
- [ ] Every UI action has an agent-callable equivalent with the same permissions.
- [ ] Waiting, refusal, cancellation, error and empty states are designed.
- [ ] Each new surface names the job it serves.

## Who to study

The designers and products behind these principles, with links, are in
[who to study](who-to-study.md). Open a source before you cite it, and follow
the study steps there.

## Avoid

- Copying a palette, dark theme or serif-on-beige look and calling it a principle.
- Treating third-party DESIGN.md scrapes or screenshot measurements as official
  specs.
- Crediting a whole product to one designer. Public credits cover specific work.
