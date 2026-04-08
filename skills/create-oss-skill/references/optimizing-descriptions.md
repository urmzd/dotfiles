# Optimizing Skill Descriptions

Systematic approach to testing and improving skill descriptions for triggering accuracy.

## How Triggering Works

Agents load only `name` + `description` at startup. The description carries the entire burden of deciding whether to activate. Agents typically only consult skills for tasks requiring knowledge beyond what they handle alone; specialized knowledge, unfamiliar APIs, domain-specific workflows.

## Designing Trigger Eval Queries

Create ~20 queries in `eval_queries.json`: ~10 should-trigger, ~10 should-not-trigger.

```json
[
  { "query": "I've got a spreadsheet with revenue in col C — can you add a profit margin column?", "should_trigger": true },
  { "query": "convert this json file to yaml", "should_trigger": false }
]
```

### Should-Trigger Queries

Vary along:
- **Phrasing**: formal, casual, typos, abbreviations
- **Explicitness**: name the domain vs. describe the need indirectly
- **Detail**: terse vs. context-heavy with file paths and column names
- **Complexity**: single-step vs. multi-step where the skill's task is buried

Most valuable: queries where the skill would help but the connection isn't obvious.

### Should-Not-Trigger Queries

Use **near-misses** queries sharing keywords but needing something different.

Weak: "Write a fibonacci function" (obviously irrelevant).
Strong: "write a python script that reads a csv and uploads rows to postgres" (involves CSV but the task is ETL, not analysis).

### Realism

Include file paths, personal context, specific details, casual language, typos.

## Testing Triggers

Run each query through the agent with the skill installed. Check if the agent loaded the SKILL.md.

### Running Multiple Times

Model behavior is nondeterministic. Run each query 3+ times. Compute trigger rate (fraction of runs where skill was invoked).

- Should-trigger passes if trigger rate > 0.5
- Should-not-trigger passes if trigger rate < 0.5

## Train/Validation Split

Split queries to avoid overfitting:
- **Train (~60%)**: guide improvements
- **Validation (~40%)**: check if improvements generalize

Keep both sets proportional in should/shouldn't-trigger queries. Keep split fixed across iterations.

## Optimization Loop

1. **Evaluate** on both train and validation sets
2. **Identify failures** in train set only
3. **Revise description:**
   - Failing should-trigger → broaden scope or add context
   - False-triggering should-not-trigger → add specificity, clarify boundaries
   - Don't add specific keywords from failed queries (overfitting); address the general category
   - If stuck, try structurally different framing
   - Stay under 1024 chars
4. **Repeat** until train set passes or improvements plateau
5. **Select best iteration** by validation pass rate (may not be the last one)

~5 iterations is usually enough.

## Before and After

```yaml
# Before
description: Process CSV files.

# After
description: >
  Analyze CSV and tabular data files — compute summary statistics,
  add derived columns, generate charts, and clean messy data. Use this
  skill when the user has a CSV, TSV, or Excel file and wants to
  explore, transform, or visualize the data, even if they don't
  explicitly mention "CSV" or "analysis."
```

## Final Verification

After selecting the best description:
1. Update `description` in SKILL.md frontmatter
2. Verify under 1024 chars
3. Write 5-10 fresh queries (never part of optimization) as a generalization check
