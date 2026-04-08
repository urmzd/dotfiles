---
name: release-audit
description: Audit releases, tags, and assets for a repo or all repos in a directory. Finds orphaned tags, missing assets, and sr config issues. Use when checking release health.
allowed-tools: Bash Read Grep Glob
user-invocable: true
arguments:
  - name: scope
    description: "Path to a single repo or a directory of repos. Defaults to current directory."
    required: false
---

# Release Audit

Audit releases, tags, and assets for consistency.

## Steps

1. **Determine scope**: If a directory of repos is given, discover all git repos one level deep. Otherwise use the current repo.

2. **For each repo**, gather:
   - All tags: `git tag -l`
   - All releases: `gh release list --limit 50 --json tagName,name,isDraft,isPrerelease,assets`
   - sr.yaml config (if present): read `sr.yaml` to understand expected release behavior
   - Floating tags: tags like `v1`, `v2` that point to the same commit as a full semver tag

3. **Check for issues**:
   - **Orphaned tags**: tags with no corresponding GitHub release
   - **Releases without assets**: releases that should have binaries/checksums but don't
   - **Draft releases**: releases stuck in draft state
   - **Floating tag drift**: major version tags (e.g., `v1`) not pointing to the latest patch
   - **sr.yaml issues**: missing config, misconfigured plugins, version file mismatches
   - **Pre-release remnants**: old pre-release versions that were never promoted

4. **Report**: For each repo, show:
   ```
   ## repo-name
   - Latest release: v1.2.3 (2024-01-15)
   - Total releases: 12 | Tags: 15
   - Issues:
     - ⚠ 3 orphaned tags: v0.1.0, v0.2.0, v0.3.0
     - ⚠ Floating tag v1 behind latest (points to v1.1.0, latest is v1.2.3)
     - ✓ All releases have assets
   ```

5. **Summary**: One-line-per-repo table at the end with issue counts.

## Rules

- Don't delete or modify tags/releases. This is read-only audit.
- If `gh` isn't authenticated, fall back to git-only checks (tags, sr.yaml).
- For multi-repo scans, run checks in parallel where possible.
