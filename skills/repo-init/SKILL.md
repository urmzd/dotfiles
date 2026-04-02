---
name: repo-init
description: Full repo bootstrap — create GitHub repo, add license, scaffold CI/release, write README, set metadata, and push. Use when starting a new project from scratch.
allowed-tools: Bash Read Grep Glob Edit Write
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

3. **Scaffold**: If a language is specified, invoke the appropriate scaffold skill pattern:
   - Set up CI workflow (`.github/workflows/ci.yml`)
   - Set up release workflow (`.github/workflows/release.yml`)
   - Create `sr.yaml` for semantic release
   - Create `justfile` with common tasks
   - Create `.envrc` with appropriate Nix dev shell
   - Create language-specific config (Cargo.toml, go.mod, pyproject.toml, package.json, etc.)

4. **README**: Generate a README with the repo name, description, and standard badge layout.

5. **Set metadata**: `gh repo edit --add-topic <topics> --description "<description>"` with relevant topics for the language/type.

6. **Initial commit and push**:
   - `git add -A` (safe here since it's a brand new repo)
   - `git commit -m "chore: initial project scaffold"`
   - `git push -u origin main`

7. **Report**: Show the repo URL.

## Rules

- Default to Apache-2.0 license.
- Default to public visibility.
- If no language is specified, create a minimal repo with just LICENSE, README, and .gitignore.
- Use conventional commits for the initial commit.
