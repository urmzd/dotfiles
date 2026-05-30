---
name: review-diff
description: >
  Standardized review of the CURRENT working-tree changes -- staged, unstaged, and
  untracked -- against an explicit five-dimension rubric (correctness, security,
  tests, scope-creep, conventions). Emits a prioritized findings list, each with
  file:line, severity, and a suggested fix. Read-only: it reviews and reports, it
  does not commit, push, or edit. Use when the user says "review my changes",
  "review the diff", "look over my staged changes before I commit", or "what's
  wrong with this PR locally". Do NOT use for red CI/pipeline failures (use
  diagnose-ci) or whole-repo quality-framework questions (use assess-quality);
  this reviews the working-tree diff only. assess-quality and review-design both
  EXCLUDE day-to-day review and name this skill as its home.
allowed-tools: Read, Grep, Glob, Bash(git *)
user-invocable: true
arguments:
  - name: scope
    description: Optional scope hint -- "staged" (default behavior reviews all working-tree changes), a path, or a base ref like "main" to diff against.
    required: false
metadata:
  title: Review Diff
  category: development
  order: 0
---

# Review Diff

Review the working-tree changes against a fixed rubric and emit prioritized,
actionable findings. This is the day-to-day review skill that [[assess-quality]]
(the quality framework) and [[review-design]] (the design "why" layer) both
explicitly hand off to. They set the bar; this skill checks one concrete diff
against it.

## Why a rubric is mandatory

A review with no rubric drifts into a vibe check and produces a near-empty,
low-confidence result (in one observed run, a rubric-less review emitted almost
nothing at 0.42 confidence). The five dimensions below are loaded **before**
reading the diff so every change is checked against the same axes. If you cannot
load the rubric, say so and stop -- do not emit a confident-looking empty review.

## Gather the diff

Review everything in the working tree, not just what is staged:

```bash
git status --short                 # the full picture: staged, unstaged, untracked
git diff --staged                  # staged changes
git diff                           # unstaged changes to tracked files
git ls-files --others --exclude-standard   # untracked files (read each in full)
```

If a `scope` base ref is given (e.g. `main`), use `git diff main...HEAD` plus the
working-tree diffs. Read untracked files in full with Read -- they have no "old"
side, so the entire file is the change.

## The rubric

Check every change against all five dimensions, in priority order:

| Dimension | Ask | Example findings |
| --- | --- | --- |
| **Correctness** | Does it do what it claims, including edge cases? | off-by-one, null/None deref, unhandled error path, wrong operator, race, resource leak |
| **Security** | Could this be abused or leak? | injected input in a query/shell, hardcoded secret, missing authz check, unsafe deserialization, path traversal |
| **Tests** | Is the new behavior covered? | new branch with no test, asserted-nothing test, deleted test, fixture not updated |
| **Scope-creep** | Does the diff match its stated intent? | unrelated refactor mixed in, drive-by rename, formatting churn that hides the real change, commented-out code |
| **Conventions** | Does it match the codebase's existing style? | naming, error-handling pattern, logging style, public-API shape, missing doc on an exported symbol |

Security and correctness findings outrank style. A real bug at `low` priority
buried under nits is a failed review.

## Severity

Assign one of three levels and order findings by it:

| Severity | Meaning | Examples |
| --- | --- | --- |
| **blocker** | Must fix before merge | correctness bug, security hole, deleted/disabled test, secret in the diff |
| **should-fix** | Fix unless there is a stated reason not to | missing test for new behavior, scope creep, error swallowed |
| **nit** | Optional polish | naming, wording, formatting the linter would catch anyway |

## Output

Emit a single prioritized list, blockers first. Every finding carries
`file:line`, a severity tag, what is wrong, and a concrete suggested fix:

```text
## Review: <branch> (<N> files, +<adds>/-<dels>)

### Blockers
- [blocker] src/auth.py:42 -- user-supplied `next` is passed to `redirect()`
  without an allowlist (open redirect). Fix: validate against a known set of
  paths, or strip to a relative path.

### Should-fix
- [should-fix] src/parser.rs:88 -- new `parse_header` branch has no test.
  Fix: add a case covering a header with no colon.
- [should-fix] src/app.ts:1-200 -- unrelated reformatting of the whole file
  obscures the 3-line behavior change (scope creep). Fix: revert the formatting
  or split it into its own commit.

### Nits
- [nit] src/util.go:12 -- exported `DoThing` lacks a doc comment.

### Summary
2 blockers, 1 should-fix, 1 nit. Recommend: do not merge until blockers resolved.
```

If the diff is clean, say so plainly and list the dimensions checked -- a clean
review is a real result, but only after the rubric was actually applied.

## Rules

- **Read changed files in full when context matters.** A diff hunk hides the
  function it lives in; a correctness call often needs the surrounding code.
- **Report only; do not edit, stage, or commit.** This skill recommends. For a
  failing pipeline, route to [[diagnose-ci]]; to set or arbitrate the project's
  quality bar rather than review one diff, route to [[assess-quality]].
- **Cite a real `file:line`.** A finding without a location is not actionable.
- **No empty confident reviews.** If nothing loaded or the diff is empty, say
  that explicitly instead of emitting a hollow pass.
