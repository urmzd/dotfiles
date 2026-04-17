---
name: assess-quality
description: >
  Code quality assessment. Readability, onboarding ease, scalability without bloat,
  brand coherence across projects, and intentional design for developers and AI agents.
  The foundational "why" behind all conventions. Use when reviewing code quality,
  assessing project health, onboarding to a new project, or making architectural
  decisions about structure and consistency.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: Code Quality
  category: development
  order: 6
---

# Code Quality

## The Workshop Principle

Different writers, same pragma.

Every tool, library, and script should feel like it came from the same workshop. The way Microsoft tools feel consistent, the way Google tools share a coherent design language; our code should have that same unity. A developer who has used one of our CLIs should feel at home in any other. An AI agent that has parsed one project's JSON output should know what to expect from the next.

This is not about aesthetics. Consistency reduces cognitive load for both audiences:
- **Developers** spend less time learning conventions and more time solving problems
- **AI agents** parse structured output, consume skills-as-docs, and navigate codebases via AGENTS.md

Every convention in our skill system (JSON output, color semantics, commit style, file organization) traces back to this principle. If a decision doesn't serve consistency or intentionality, question it.

## The Dual Audience

We build for two consumers simultaneously:

**Developers** read source code, run CLIs, review PRs, and onboard to projects. They need readable code, obvious entry points, and one-command workflows.

**AI agents** parse JSON output, consume SKILL.md files as executable context, discover projects via llms.txt, and navigate architecture via AGENTS.md. They need structured interfaces, predictable patterns, and machine-readable output.

Every interface decision must answer both: *Can a human understand this? Can an agent parse this?*

This is why:
- **CLIs emit JSON** agents chain it, skills consume it, content persists
- **`docs/`** organizes project documentation by purpose (guides/, rfcs/, plans/, runbooks/). Skills provide executable agent context alongside
- **llms.txt exists** projects become AI-discoverable
- **AGENTS.md mirrors README** agents get the same onboarding humans do
- **Commit messages follow Angular** parseable by sr for automated releases

## Five Quality Questions

Every PR, every new file, every refactor should pass these five questions. They are ordered by priority; readability comes first because nothing else matters if the code can't be understood.

1. **Is it easy to read?**
2. **Is it easy to start?**
3. **Can it expand without bloat?**
4. **Does it feel consistent?**
5. **Is the design intentional?**

---

## 1. Is It Easy to Read?

Self-documenting code over comments. Names over documentation. Structure over explanation.

**File size:** 100-500 LOC is the sweet spot. Allow up to ~2000 for genuinely complex logic (release orchestration, template engines), but question anything larger. If a file has a table of contents comment, it's too long.

**Function size:** If it doesn't fit on a screen, split it. Each function should do one thing and name that thing clearly.

**Formatting is not debatable.** Tools enforce it: clippy, ruff, biome, golangci-lint. Formatting never appears in code review. Configure once, forget.

**Error messages explain two things:**
1. What went wrong
2. What to try next

```
error: no releasable commits since v1.2.0
hint: use conventional commit format (e.g., "feat: add feature")
```

**Public APIs are documented.** Every public trait, interface, or exported function gets a doc comment (Rust `///`, Go `//`, Python docstring). Internal code is self-documenting; if it needs a comment, rename it.

**The ui module is the readability benchmark.** Same API surface (`header`, `phase_ok`, `warn`, `info`, `error`), same color semantics, same 2-space indentation across every project. Predictable = readable.

## 2. Is It Easy to Start?

A junior developer should be productive within one hour. If they can't build and run the project in three commands, the onboarding has failed.

**Entry points are always obvious:**

| Language | Entry Point | Framework |
|----------|------------|-----------|
| Rust | `crates/*-cli/src/main.rs` | clap 4 (derive) |
| Go | `cmd/<name>/main.go` | cobra |
| Python | `src/<package>/cli.py` | typer |

Read the entry point → understand all commands → drill into any subcommand. No indirection, no factory-of-factories.

**One command per task:**

```
just init    # install hooks, download deps
just build   # compile
just test    # run all tests
just check   # fmt + lint + test
just run     # execute
```

**Environment setup is automated:**
- `direnv allow` activates the Nix shell (via `.envrc` → `use flake .#<shell>`)
- All dependencies are declared in `flake.nix`
- No "install X globally" instructions; Nix provides everything

**Documentation hierarchy:**
- **`README.md`** human-facing: what, install, usage, examples
- **`AGENTS.md`** AI-facing: architecture, interfaces, commands
- **`skills/<name>/SKILL.md`** agent instructions
- **`CONTRIBUTING.md`** contributor onboarding
- **`docs/`** all other documentation (guides/, rfcs/, plans/, runbooks/, architecture/): prerequisites, workflow

No hidden setup. No tribal knowledge. No "ask Sarah, she knows how to configure this."

## 3. Can It Expand Without Bloat?

New features add modules, not layers. The architecture should grow horizontally (more modules) not vertically (more abstraction).

**The crate/package pattern:**

| Language | Pattern | Example |
|----------|---------|---------|
| Rust | `{name}-core` (logic) + `{name}-cli` (presentation) | sr, oag, llmem, teasr |
| Go | `cmd/` (entry) + `internal/` (packages) | incipit, zoro |
| Python | `src/<package>/` with protocol-based interfaces | fight-analyzer, wealth-builder |

**Trait/interface boundaries between layers.** Core logic depends on abstractions (`trait VcsProvider`), not concrete implementations. New implementations (GitLab, Bitbucket) add a file; they don't modify existing code.

**When to split:** A module serves two distinct consumers with different needs → it's two modules.

**When NOT to split:** The `ui` module is 30-60 lines. Copying it per-project is cheaper than maintaining a shared dependency with cross-repo versioning. Not everything needs to be a library.

**Dependency injection without frameworks:**
- Rust: Generic type parameters + trait bounds on constructors
- Go: Explicit wiring in `wire.go`. No DI containers, every dependency visible
- Python: Factory methods on dataclasses (`ModelConfig.openai(...)`)

No global state. No service locators. No magic. Follow the constructor to see every dependency.

## 4. Does It Feel Consistent?

| Dimension | Convention | Enforced By |
|-----------|-----------|-------------|
| Commits | Angular Conventional (`type(scope): description`) | `ship` skill + CI lint |
| CI | `ci.yml` + `release.yml` | `setup-ci` skill |
| CLI output | Color semantics, symbols, 2-space indent | `build-cli` skill |
| Error handling | `thiserror`/`anyhow` (Rust), `fmt.Errorf` (Go), `typer.Exit` (Python) | `write-code` skill |
| File organization | `crates/` (Rust), `cmd/`+`internal/` (Go), `src/` (Python) | `scaffold-*` skills |
| README | Centered header, badges, demo, sections | `write-readme` skill |
| Testing | Contract-based, state coverage, per-language idioms | `test-code` skill |
| Release | `sr.yaml`, semantic versioning, multi-platform builds | `sync-release` skill |

A contributor who knows one project should feel at home in any other. The skill system is itself an example; every skill has the same frontmatter format, the same section structure, the same trigger phrasing. Different authors, same format.

## 5. Is the Design Intentional?

Every decision's "why" should be recoverable. If you can't explain why a choice was made, the choice is accidental, and accidental decisions compound into incoherent systems.

| Decision | Why |
|----------|-----|
| CLIs emit JSON | Agents parse structured output; enables chaining and skill consumption |
| No full-screen TUIs | Breaks piping, CI, screen readers, accessibility |
| `thiserror` in libraries, `anyhow` in apps | Libraries expose typed errors for callers; apps need readable chains |
| No coverage tools | State coverage philosophy. Percentage targets create false confidence |
| `docs/` with organized subdirectories | Documentation is well-structured (guides/, rfcs/, plans/, runbooks/). Skills complement with executable agent context |
| `sr` for releases, not semantic-release npm | Rust-native, faster, custom commit parsing, single binary |
| Apache-2.0 license | Permissive, patent grant, corporate-friendly |
| Nix over Docker for dev environments | Composable shells, no container overhead, reproducible on bare metal |

When reviewing code, ask: "Why this approach?" If the answer is "it's how we've always done it" without a reason, it's a broken window. Fix it or document the real reason.

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| God objects with many responsibilities | Small, focused modules with single purpose |
| Hidden setup requiring tribal knowledge | One-command onboarding via `just init` |
| Inconsistent CLI output across tools | Shared `ui` module pattern with color semantics |
| Undocumented architectural decisions | Commit body explains why; AGENTS.md captures architecture |
| Coverage percentage targets | State coverage. Test meaningful paths and edge cases |
| DI frameworks and service locators | Explicit wiring, visible dependency graphs |
| Flat `docs/` with unorganized markdown | Structured `docs/` subdirectories: `guides/`, `rfcs/`, `plans/`, `runbooks/` |
| Abstract base classes and deep inheritance | Traits (Rust), interfaces (Go), protocols (Python) |
| "Clever" code that saves lines | Boring code that a junior can read in 5 minutes |
| Premature extraction into shared libraries | Copy small modules (< 100 LOC); extract when three+ projects diverge |

## Assessment Checklist

Quick reference for code review:

- [ ] Can a junior understand this in 5 minutes?
- [ ] Can I build and run with `just build` and `just run`?
- [ ] Does the CLI output match color/symbol conventions?
- [ ] Is the "why" documented in the commit body or code?
- [ ] Would adding a feature require touching more than 2 files?
- [ ] Does the JSON output follow the same structure as other tools?
- [ ] Are error messages actionable (what went wrong + what to try)?
- [ ] Is the entry point obvious from the file structure?
