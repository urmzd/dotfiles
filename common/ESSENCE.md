# Essence

The `common/` directory holds shared, project-agnostic reference material and templates used across repositories.

## Patterns

### Shared templates over copy-paste
Reusable scaffolding (like the VHS demo tape) lives here once and gets adapted per-project, avoiding drift between repos.

### Tech stack as documentation
`tools.md` serves as a canonical record of preferred languages, frameworks, and CLI tools — a quick-reference contract for what to reach for in new projects.

### Consistent visual identity
The VHS demo template enforces a uniform look across project demos: Cyberdream theme, MonaspiceNe Nerd Font, `zsh` shell, and a branded splash card linking to `github.com/urmzd` and `urmzd.com`.

### Convention over configuration
Templates use placeholder comments (`<project>`, `<output-path>`) rather than complex templating engines. The structure is the documentation.

## Contents

| File | Purpose |
|------|---------|
| `tools.md` | Canonical tech stack: languages, build tools, and key libraries |
| `vhs/demo-template.tape` | Starter VHS tape for recording terminal demos with consistent branding |

## 2026-02-22

- **Plan**: Plan: Replace Rust AEGP Plugin with CEP Extension
- **Source**: `effervescent-petting-newell.md`
