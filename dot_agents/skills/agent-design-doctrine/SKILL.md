---
name: agent-design-doctrine
description: >
  House doctrine for designing LLM agent systems: safety enforced by the
  harness and tools rather than model goodwill, tools that execute and return
  results, minimal loop code, interface-first component seams, typed config,
  deterministic evals over LLM judges, and POC scope discipline. Use when
  designing or reviewing any agent, tool-use loop, eval harness, or
  agent-backed CLI, in any framework. Do NOT use for Pydantic AI framework
  mechanics (use building-pydantic-ai-agents), generic design principles (use
  review-design), or Go agent-loop implementation details (use agent).
allowed-tools: Read, Grep, Glob
user-invocable: true
metadata:
  title: Agent Design Doctrine
  category: ai
---

# Agent Design Doctrine

Stable architectural positions for agent systems. Apply these before writing
code and cite the violated rule when reviewing.

## 1. Safety lives in the harness, never the model

The model is a planner, not a guard. Enforce every safety property at a layer
the model cannot talk its way past.

| Layer | Enforcement |
| ----- | ----------- |
| Database | Read-only role, statement timeout, row limits |
| Tool implementation | Validate and sanitize inputs, allowlist operations, cap output size |
| Harness | Turn limits, budget caps, kill switches |
| Prompt | Guidance only. Never the sole control for anything destructive |

If a safety rule is only stated in the system prompt, it does not exist.

## 2. Tools execute and return results

A tool call does the work and returns the outcome. The model decides what to
do with a failure; the tool never defers execution back to the loop or leaks
partial state into context.

- Wrong: tool returns SQL for the loop to run later.
- Right: tool runs the SQL (under harness limits) and returns rows or a
  structured error the model can react to.

## 3. Minimal loop code

The framework owns the agent loop. If you are writing retry logic, tool
dispatch, or message threading by hand, stop and check what the framework
already does. Your code should be: tool definitions, config, and the harness
guards from rule 1.

## 4. Interface-first seams

Every swappable component (provider, storage, embedder, renderer) sits behind
a small interface defined before the first implementation. One protocol, N
implementations, zero conditionals on vendor names in call sites.

## 5. Typed config, no raw env access

Read configuration once at startup into a typed settings object
(pydantic-settings or the language equivalent). No `os.environ` scattered
through the codebase, no hardcoded model IDs or prices; anything that can
change per deployment is a setting.

## 6. Human-in-the-loop is a mechanism, not a hardcode

Approval gates are a generic interrupt the harness exposes (pause, surface
context, resume on decision), not an if-statement for one specific tool.

## 7. Deterministic evals beat LLM judges

When a golden set exists, score with deterministic comparison (exact match,
normalized AST, execution result equality) and reserve LLM judging for cases
with no computable ground truth. Every reported metric must be reproducible
from a committed artifact.

## 8. POC scope discipline

For prototypes and take-homes, build the thinnest thing that proves the
claim:

- No speculative abstraction beyond rule 4's seams.
- No test that duplicates another test's failure mode; test behavior at the
  public boundary, not internals.
- Prefer updating a prompt over adding a clarification subsystem.
- Before adding anything, ask: does this change the demo or the measured
  result? If not, cut it.

## Review checklist

When reviewing an agent system, check in order:

1. Can the model cause harm if it ignores every instruction? (rule 1)
2. Does any tool return instructions instead of results? (rule 2)
3. How many lines of loop code exist that the framework provides? (rule 3)
4. Can each vendor dependency be swapped behind its seam? (rules 4, 5)
5. Are metrics reproducible from committed artifacts? (rule 7)
6. What could be deleted without changing the demo? (rule 8)
