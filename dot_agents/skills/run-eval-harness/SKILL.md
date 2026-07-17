---
name: run-eval-harness
description: >
  Run a project's own eval suite end to end without babysitting: locate the
  harness, launch it in the background, monitor to completion, parse the
  report into a normalized summary (pass rate, latency percentiles, tokens,
  cost), and diff against the previous run with per-case regressions
  explained. Use when asked to "run the evals", re-run after a change, or
  score a new dataset in any repo with an eval harness. Do NOT use for the
  GAP benchmark suite (use run-evals), SAIGE provider-boundary checks (use
  verify), or designing new eval sets (that is authoring work, not a run).
allowed-tools: Read, Grep, Glob, Bash
user-invocable: true
context: fork
agent: general-purpose
model: sonnet
metadata:
  title: Run Eval Harness
  category: ai
---

# Run Eval Harness

Own the whole run-monitor-parse-diff loop and return once with a complete
summary. The user should never have to ask "check the current state".

## 1. Locate the harness

Search in order; stop at the first hit:

1. Project docs: README, AGENTS.md, docs/ mentioning "eval".
2. Task runners: `justfile`, `Makefile`, `package.json` scripts, `pyproject`
   scripts with eval targets.
3. Convention paths: `evals/`, `eval/`, `benchmarks/`, files matching
   `*eval*.py|ts|go`.

If multiple harnesses exist, pick the one the user named; otherwise list
them and pick the default documented in the repo. Note the dataset in use
(golden set path) and where reports land (for example `eval_report*`,
`results/`, `run_log.jsonl`).

## 2. Launch in the background

- Run via the documented entry point with the repo's own defaults; do not
  invent flags.
- Use a background shell so the session stays free; capture stdout to a log
  file in the scratchpad.
- Record start time, git commit, model or provider config in effect.

## 3. Monitor without spamming

Poll the log at an interval matched to expected runtime (a 10 minute run
gets checks every 2 to 3 minutes, not every 15 seconds). Detect and report
early: crash, auth failure, rate limiting (429 or backoff messages), or a
stall with no new output for 3 poll cycles. On transient provider errors,
retry the run once before reporting failure.

## 4. Parse into the normalized summary

Extract whatever subset the report provides:

| Metric | Notes |
| ------ | ----- |
| Pass / total, pass rate | Per strictness level if the harness has them |
| Latency P50 and P95 | Report both; never substitute mean |
| Tokens in / out per case | And totals |
| Cost per run and per case | From real configured prices, never hardcoded guesses |
| Failures | Case id, expected vs actual, one-line cause each |

## 5. Diff against the previous run

Find the most recent prior report or run log. Report: metric deltas, newly
failing cases, newly passing cases, and whether config changed between runs
(model, dataset, prompt version, commit). If no prior run exists, say so and
record this one as the baseline.

## 6. Report once

Return a single summary: headline result, the metric table, the diff, and
failure explanations. State the exact command used, the commit, and the
report file path so every number is reproducible. If the harness itself is
broken, report the root cause and stop; do not silently fix eval logic, and
never edit the golden set or scoring code to make a run pass.
