---
name: repo-init
description: >
  End-to-end repo bootstrap: creates the GitHub repo (gh repo create), adds an
  Apache-2.0 LICENSE, dispatches to scaffold-project for CI/release/config, invokes
  community-health, writes a README, sets topics/description, and makes the initial
  commit and push. Use when starting a brand-new project from zero and you need the
  GitHub repo, metadata, and first push handled, not just local files. Do NOT use to
  scaffold files inside an existing repo; invoke scaffold-project directly for that.
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(gh *), Edit, Write
user-invocable: true
arguments:
  - name: name
    description: Repository name
    required: true
  - name: lang
    description: "Language/type: rust, go, python, node, terraform"
    required: false
  - name: description
    description: One-line repo description
    required: false
  - name: visibility
    description: "public or private (default: public)"
    required: false
---

# Repo Init

Bootstrap a complete repository from zero to pushed.

## Steps

1. **Create GitHub repo**: `gh repo create <name> --<visibility> --description "<description>" --clone` (default public).

2. **Add LICENSE**: Create an Apache-2.0 LICENSE file in the repo root.

3. **Scaffold**: If a language is specified, invoke `scaffold-project` (which dispatches to `scaffold-<lang>`) to produce:
   - CI workflow (`.github/workflows/ci.yml`) and release workflow (`.github/workflows/release.yml`); see `setup-ci`.
   - `sr.yaml` for semantic release; see `sync-release`.
   - Task runner native to the language (npm scripts, Makefile, cargo, justfile for Python).
   - `.envrc` via the `setup-devenv` direnv pattern (vanilla direnv + per-language version manager, not a Nix dev shell).
   - Language-specific config (Cargo.toml, go.mod, pyproject.toml, package.json, etc.).

4. **Community health**: Invoke `community-health` to add `CODE_OF_CONDUCT.md`, `SECURITY.md`, `.github/pull_request_template.md`, and `.github/ISSUE_TEMPLATE/` (bug report, feature request, config). Substitute `{OWNER}`, `{REPO}`, `{CURRENT_MAJOR}`, and `{CHECK_COMMAND}` placeholders. For a brand-new pre-1.0 project, set `{CURRENT_MAJOR}` to `0` and rewrite the SECURITY.md supported-versions table to `0.x Yes / < 0.x No`.

5. **README**: Generate a README with the repo name, description, and standard badge layout.

6. **Set metadata**: `gh repo edit --add-topic <topics> --description "<description>"` with relevant topics for the language/type.

7. **Initial commit and push**:
   - `git add -A` (safe here since it's a brand new repo)
   - `git commit -m "chore: initial project scaffold"`
   - `git push -u origin main`

8. **Report**: Show the repo URL.

## Rules

- Default to Apache-2.0 license.
- Default to public visibility.
- If no language is specified, create a minimal repo with just LICENSE, README, and .gitignore.
- Use conventional commits for the initial commit.
