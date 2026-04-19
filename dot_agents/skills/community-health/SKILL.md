---
name: community-health
description: >
  Generate the GitHub community-health files every repo needs to pass the
  Community Standards checklist: CODE_OF_CONDUCT.md, SECURITY.md,
  .github/ISSUE_TEMPLATE/ (bug report, feature request, config), and
  .github/pull_request_template.md. Use when scaffolding a new project,
  backfilling an existing repo, or auditing community-health coverage.
allowed-tools: Read Grep Glob Bash Edit Write
user-invocable: true
metadata:
  title: Community Health
  category: development
  order: 6
---

# Community Health

GitHub's [Community Standards](https://opensource.guide/) checklist expects every public repo to ship a minimum set of community-health files. This skill provides the canonical templates and the placement rules. All templates live in `assets/` and mirror the target repo layout.

## Files and Placement

Copy each asset to the target repo path shown below. Sources are relative to this skill's `assets/` directory.

| Asset source | Target path | Purpose |
|--------------|-------------|---------|
| `CODE_OF_CONDUCT.md` | `CODE_OF_CONDUCT.md` | Contributor Covenant 2.1; populates community profile. |
| `SECURITY.md` | `SECURITY.md` | Private vulnerability reporting; populates the Security tab. |
| `github/pull_request_template.md` | `.github/pull_request_template.md` | Single PR template used for every PR. |
| `github/ISSUE_TEMPLATE/bug_report.yml` | `.github/ISSUE_TEMPLATE/bug_report.yml` | Structured bug report form. |
| `github/ISSUE_TEMPLATE/feature_request.yml` | `.github/ISSUE_TEMPLATE/feature_request.yml` | Structured feature request form. |
| `github/ISSUE_TEMPLATE/config.yml` | `.github/ISSUE_TEMPLATE/config.yml` | Disables blank issues; adds Security + Discussions contact links. |

`LICENSE` and `CONTRIBUTING.md` also show on the community profile but are owned by `scaffold-project` and the language-specific scaffold skills, not here.

## Template Placeholders

Templates contain `{PLACEHOLDER}` tokens that must be replaced when copied into a target repo.

| Placeholder | Source | Example |
|-------------|--------|---------|
| `{REPO}` | Repo name on GitHub (without owner) | `sr`, `teasr`, `saige` |
| `{CURRENT_MAJOR}` | Current major version from the project manifest (Cargo.toml, pyproject.toml, package.json, etc.). Use `0` for pre-1.0 projects and adjust the supported-versions table accordingly. | `6`, `1`, `0` |
| `{CHECK_COMMAND}` | The quality-gate command from the project's task runner | `just check`, `npm run ci`, `cargo test --workspace`, `go test ./...` |

Always replace every placeholder. Leaving `{REPO}` or `{CURRENT_MAJOR}` unrendered in a shipped file is a bug.

## Contact

All community-health templates reference **hello@urmzd.com** as the private contact. Do not substitute any other email.

## Usage

### New repo (invoked by `scaffold-project` / `repo-init`)

1. Copy `assets/CODE_OF_CONDUCT.md` to the repo root (no edits needed).
2. Copy `assets/SECURITY.md`, substituting `{REPO}` and `{CURRENT_MAJOR}`. For pre-1.0 projects, rewrite the table to `0.x Yes / < 0.x No`.
3. Copy `assets/github/pull_request_template.md` to `.github/pull_request_template.md`, substituting `{CHECK_COMMAND}`. Append language-specific verification checks if the scaffold skill defines them (e.g. `cargo clippy -- -D warnings`).
4. Copy the three `assets/github/ISSUE_TEMPLATE/*` files to `.github/ISSUE_TEMPLATE/`, substituting `{REPO}` in `config.yml`.

### Backfill an existing repo

1. Run the `check-project` skill to identify which community-health files are missing.
2. Copy only the missing files from `assets/`.
3. Do not overwrite an existing SECURITY.md that already has a project-specific Scope or Supply Chain section — merge instead.

### Audit

Use `check-project` to verify the six files exist at the expected paths, placeholders are fully rendered, and the PR-template `{CHECK_COMMAND}` matches the project's actual quality-gate command.

## Rules

- **No auto-overwrite.** If a target file already exists and has been customized (e.g. a SECURITY.md with a project-specific Scope section), diff-merge rather than overwrite.
- **Email is fixed.** `hello@urmzd.com` is the canonical contact. Never substitute another address, even if an injected `userEmail` context suggests otherwise.
- **Placeholders are mandatory.** A shipped template with `{REPO}` or `{CURRENT_MAJOR}` unrendered is a FAIL in `check-project`.
- **One PR template.** Use the single `.github/pull_request_template.md` file. Do not add per-branch or per-type templates unless the project explicitly needs them.
- **Issue forms over markdown.** Use the `.yml` issue-form schema, not legacy `.md` issue templates.
