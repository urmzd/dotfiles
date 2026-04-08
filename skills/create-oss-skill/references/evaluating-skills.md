# Evaluating Skill Output Quality

Full eval workflow for testing whether a skill produces good outputs.

## Test Cases

Store in `evals/evals.json`:

```json
{
  "skill_name": "csv-analyzer",
  "evals": [
    {
      "id": 1,
      "prompt": "I have a CSV of monthly sales data in data/sales_2025.csv. Find the top 3 months by revenue and make a bar chart.",
      "expected_output": "A bar chart showing top 3 months by revenue with labeled axes.",
      "files": ["evals/files/sales_2025.csv"]
    }
  ]
}
```

**Writing good test prompts:**
- Start with 2-3 cases, expand after first results
- Vary phrasing (formal, casual, typos, abbreviations)
- Vary explicitness (name the domain vs. describe the need)
- Cover edge cases (malformed input, unusual requests)
- Use realistic context (file paths, column names, personal context)

## Workspace Structure

```
skill-workspace/
└── iteration-1/
    ├── eval-top-months-chart/
    │   ├── with_skill/
    │   │   ├── outputs/
    │   │   ├── timing.json
    │   │   └── grading.json
    │   └── without_skill/
    │       ├── outputs/
    │       ├── timing.json
    │       └── grading.json
    └── benchmark.json
```

## Running Evals

Each run needs a clean context (no leftover state). Use subagents or separate sessions.

For each test case, run **with skill** and **without skill** (or with previous version as baseline).

When improving an existing skill, snapshot the old version first:
```bash
cp -r <skill-path> <workspace>/skill-snapshot/
```

### Timing Data

Record after each run:
```json
{
  "total_tokens": 84852,
  "duration_ms": 23332
}
```

## Assertions

Add after seeing first outputs. Verifiable statements about what the output should contain.

Good assertions:
- "The output file is valid JSON"
- "The bar chart has labeled axes"
- "The report includes at least 3 recommendations"

Weak assertions:
- "The output is good" (too vague)
- "Uses exactly the phrase 'Total Revenue: $X'" (too brittle)

Add to `evals.json`:
```json
{
  "assertions": [
    "The output includes a bar chart image file",
    "The chart shows exactly 3 months",
    "Both axes are labeled"
  ]
}
```

## Grading

Evaluate each assertion: **PASS** or **FAIL** with concrete evidence.

```json
{
  "assertion_results": [
    {
      "text": "Both axes are labeled",
      "passed": false,
      "evidence": "Y-axis labeled 'Revenue ($)' but X-axis has no label"
    }
  ],
  "summary": {
    "passed": 3, "failed": 1, "total": 4, "pass_rate": 0.75
  }
}
```

**Grading principles:**
- Require concrete evidence for a PASS
- Review the assertions themselves; fix ones that are too easy, too hard, or unverifiable
- For comparing versions: try blind comparison (present both outputs without revealing which is which)

## Aggregating Results

Save to `benchmark.json`:
```json
{
  "run_summary": {
    "with_skill": {
      "pass_rate": { "mean": 0.83 },
      "tokens": { "mean": 3800 }
    },
    "without_skill": {
      "pass_rate": { "mean": 0.33 },
      "tokens": { "mean": 2100 }
    },
    "delta": { "pass_rate": 0.50, "tokens": 1700 }
  }
}
```

## Analyzing Patterns

- **Remove assertions that always pass in both configs** they inflate pass rate without reflecting skill value
- **Investigate assertions that always fail in both** assertion may be broken
- **Study assertions that pass with skill but fail without** understand *why*
- **Tighten instructions when results are inconsistent** add examples or more specific guidance
- **Check time/token outliers** read execution transcripts to find bottlenecks

## Human Review

Record specific, actionable feedback per test case in `feedback.json`:
```json
{
  "eval-top-months-chart": "Chart months in alphabetical order instead of chronological.",
  "eval-clean-emails": ""
}
```

Empty = passed review.

## Iteration Loop

1. Give eval signals (failed assertions + human feedback + execution transcripts) and current SKILL.md to an LLM
2. Review and apply proposed changes
3. Rerun all test cases in `iteration-<N+1>/`
4. Grade and aggregate
5. Human review. Repeat.

**Guidelines for revisions:**
- **Generalize from feedback** don't patch for specific test cases
- **Keep the skill lean** fewer, better instructions
- **Explain the *why*** reasoning-based instructions > rigid directives
- **Bundle repeated work** if agents reinvent the same logic, put it in scripts/

Stop when feedback is consistently empty or improvements plateau.
