---
name: review-design
description: Pragmatic Programmer principles — DRY, orthogonality, tracer bullets, prototyping, estimation, design by contract, and pragmatic paranoia. Use when writing, reviewing, or refactoring code.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: Pragmatic Programming
  category: development
  order: 1
---

# Pragmatic Programming

Principles from *The Pragmatic Programmer* (Hunt & Thomas) distilled into actionable rules for everyday development.

## Core Philosophy

- **Care about your craft** — why spend your life developing software unless you care about doing it well?
- **Think critically** — question assumptions, challenge "because we've always done it that way"
- **Be a catalyst for change** — show people a future they can rally around (stone soup)
- **Remember the big picture** — don't get so absorbed in details that you forget the system as a whole (boiling frog)
- **Good enough software** — know when to stop; perfect is the enemy of shipped

## ETC — Easy to Change

The fundamental design principle. Every decision should make future change easier.

- When choosing between approaches, pick the one that's easier to change later
- If you can't decide which path is more changeable, fall back on: make it replaceable
- Decoupled code is easier to change; single-responsibility code is easier to change; well-named code is easier to change — ETC is the *why* behind all of them

## DRY — Don't Repeat Yourself

> Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.

| Violation | Fix |
|-----------|-----|
| Copy-pasted logic | Extract shared function/module |
| Knowledge in code AND comments | Let code be the authority; remove redundant comments |
| Same validation in client and server | Single schema, generate both |
| Repeated config across environments | Template or derive from one source |
| Data structure duplicated across types | Single source type, derive others |

- DRY applies to **knowledge**, not text — two functions with identical code but representing different knowledge are not DRY violations
- Watch for DRY violations across: code, documentation, data schemas, API specs, build config

## Orthogonality

Keep components independent — changes in one should not affect others.

- **Test:** If I change X, how many other things must also change? Aim for zero
- Eliminate effects between unrelated things
- Avoid global/shared mutable state
- Prefer composition over inheritance
- Shy code: modules that don't reveal anything unnecessary and don't rely on other modules' implementations

## Reversibility

- Don't commit to a single vendor, platform, database, or architecture prematurely
- Abstract external dependencies behind interfaces
- Prefer configuration over hard-coding
- No critical decisions should be irreversible — if they must be, document and isolate them

## Tracer Bullets

Build thin, end-to-end slices that work, then iterate.

- First version connects all layers (UI to DB) with minimal functionality
- Proves the architecture works, reveals integration problems early
- Different from prototypes: tracer bullet code is kept and built upon
- Use when: requirements are vague, risk is high, or the team hasn't used the stack before

## Prototypes

- Prototype to **learn**, then throw away the code
- Prototypes can ignore: correctness, completeness, robustness, style
- Make it absolutely clear to stakeholders that prototype code is disposable
- Prototype when exploring: architecture, new libraries, UI design, performance approaches

## Estimation

| Duration | Quote in |
|----------|----------|
| 1-15 days | days |
| 3-6 weeks | weeks |
| 8-20 weeks | months |
| > 20 weeks | re-scope before estimating |

- Build a model of the system, identify driving parameters, calculate
- Track your estimates vs. actuals to improve over time
- When asked for an estimate you're not ready to give: "I'll get back to you"

## Design by Contract

- Define **preconditions** (what must be true before), **postconditions** (what's guaranteed after), and **class invariants**
- Crash early — a dead program does less damage than a crippled one
- Use assertions liberally for invariants; don't use them for normal error handling
- Lazy code: be strict in what you accept, promise as little as possible in return

## Pragmatic Paranoia

- **You can't write perfect software** — design assuming your code will fail
- Crash early rather than propagate bad state
- Use `try/finally` or equivalent to guarantee resource cleanup
- Assert aggressively — leave assertions on in production when cost is low
- Don't assume; prove it with assertions and tests

## Decoupling & the Law of Demeter

- **Tell, Don't Ask** — tell objects what to do, don't query state and decide for them
- **Law of Demeter:** a method should only call methods on: itself, its parameters, objects it creates, its direct fields
- Avoid train wrecks: `a.b().c().d()` — each dot is a coupling point
- Use events/pub-sub to decouple temporal and structural dependencies
- Prefer: pass in what you need (dependency injection) over reaching out to get it (service locator)

## Transforming Programming

- Think of programs as **data transformations**: input -> pipeline of steps -> output
- Prefer pipelines of small transforms over stateful methods that mutate objects
- `|>` thinking: each step takes data, returns transformed data
- Reduces coupling, improves testability, makes data flow visible

## Refactoring

- Refactor **early and often** — don't let technical debt compound
- Don't live with **broken windows** — fix bad code, bad design, and poor decisions as soon as you see them
- Refactor when you learn something new, not on a schedule
- Disciplined refactoring: keep behavior identical, test before and after, take small steps

## Testing

- **Test your software, or your users will**
- Test state coverage, not code coverage — exercise meaningful paths, not just lines
- Use **property-based testing** to discover edge cases you didn't think of
- Build a test window: logging, diagnostics, hot-key status that lets you peer inside running code
- Test against contract (what it should do), not implementation (how it does it)
- Unit tests are the first users of your API — if tests are hard to write, the design is wrong

## Naming

- A good name captures **intent**, not implementation (`processedItems` not `list2`)
- Name length should be proportional to scope — short in small lambdas, descriptive in public APIs
- Rename when the name no longer fits — outdated names are worse than no name
- Naming conventions are a team contract; follow them consistently

## Power of Plain Text

- Keep knowledge in plain text where possible — it outlives all applications
- Config, data formats, build scripts: prefer human-readable formats
- Plain text is self-describing, easier to test, easier to diff, and version-control friendly

## Domain Languages

- Write code in the vocabulary of the problem domain, not the solution domain
- Internal DSLs (fluent APIs, builder patterns) reduce the gap between spec and code
- When the same concept appears repeatedly in different forms, consider whether a mini-language would simplify things

## Pragmatic Teams

- **No broken windows** — quality is a team responsibility, not an individual one
- Automate everything: builds, tests, deployments, code formatting
- **Don't outrun your headlights** — take small steps, get frequent feedback
- Schedule time to work ON the project (tooling, process), not just IN it
