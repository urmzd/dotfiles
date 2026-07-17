---
name: manage-detect-secrets
description: >
  Operate the detect-secrets pre-commit hook correctly: update the baseline
  with the right flags, break the "baseline file was updated, please git add"
  commit loop, allowlist false positives, and audit real findings. Use when a
  commit fails on detect-secrets, the .secrets.baseline keeps changing, or a
  false positive blocks a push. Do NOT use for storing or injecting secrets
  via 1Password (use manage-secrets) or repo-wide leak scanning with gitleaks
  and trufflehog (use audit-security).
allowed-tools: Read, Edit, Grep, Glob, Bash(detect-secrets *), Bash(git *), Bash(pre-commit *)
user-invocable: true
metadata:
  title: Manage detect-secrets
  category: workflow
---

# Manage detect-secrets

Baseline mechanics for the `detect-secrets` pre-commit hook. The CLI is easy
to get wrong; use exactly these commands.

## Command reference

There is **no `--update` flag**. The verbs are:

| Task | Command |
| ---- | ------- |
| Create baseline | `detect-secrets scan > .secrets.baseline` |
| Update baseline in place | `detect-secrets scan --baseline .secrets.baseline` |
| Review findings interactively | `detect-secrets audit .secrets.baseline` |
| One-off scan of a file | `detect-secrets scan <path>` |

`scan --baseline` rewrites the baseline file in place: new candidates are
added, resolved ones removed, line numbers refreshed.

## Breaking the commit loop

Symptom: every commit fails with "The baseline file was updated ... Please
`git add .secrets.baseline`", and adding it just fails again on the next
commit.

The loop exists because the hook rewrites the baseline during the commit,
so the staged copy is always one generation behind. Break it in one shot:

```sh
detect-secrets scan --baseline .secrets.baseline
git add .secrets.baseline
git commit
```

Run the scan yourself first, stage the result, then commit; the hook now
sees a baseline identical to the one it regenerates and passes. If it still
loops, the hook args in `.pre-commit-config.yaml` differ from your manual
invocation (compare `exclude` patterns and plugin flags; they must match, or
each side keeps rewriting the other's output).

Line-number churn alone can also dirty the baseline on unrelated commits.
That is normal; stage the refreshed baseline with the commit that moved the
lines.

## False positives

Prefer inline allowlisting over baseline hand-editing:

```python
API_EXAMPLE = "sk-not-a-real-key"  # pragma: allowlist secret
```

For whole paths (fixtures, lockfiles), add an exclude to the hook config:

```yaml
- repo: https://github.com/Yelp/detect-secrets
  rev: v1.5.0
  hooks:
    - id: detect-secrets
      args: ["--baseline", ".secrets.baseline"]
      exclude: package-lock.json|tests/fixtures/
```

After adding an exclude, regenerate the baseline (the update command above)
so stale entries under the excluded path drop out.

## Real findings

If `audit` marks a finding as a true secret: rotate the credential first,
remove it from the code (move to 1Password via manage-secrets), then scrub
history only if the secret ever reached a remote (`git filter-repo`), and
regenerate the baseline last.

## Do not

- Do not delete the hook to unblock a commit; fix the baseline instead. If
  the team decides to drop detect-secrets, remove the hook, the baseline
  file, and the CI check together in one commit.
- Do not hand-edit JSON entries in `.secrets.baseline` when a regenerate or
  an inline pragma does the job.
- Do not commit a baseline generated with different exclude flags than the
  hook uses.
