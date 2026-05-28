---
name: manage-secrets
description: >-
  Manage project secrets with 1Password as the source of truth. Store values via
  the `op` CLI, commit `op://vault/item/field` references instead of plaintext,
  and run commands with `op run --env-file=.env --` (or `op inject` for config
  files). Use when adding a new secret, finding plaintext credentials in `.env`
  or config files, migrating a project off committed secrets, wiring secrets
  into CI, or whenever the user mentions 1Password, `op`, `op://`, `op run`, or
  `op inject`.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: Secrets with 1Password
  category: cli
  order: 0
---

# Secrets with 1Password

## Philosophy

Secrets never sit in plaintext in the repo, in shell history, or in long-lived
shell env. 1Password is the only source of truth. Files commit **references**
(`op://vault/item/field`); resolution happens at command time, in the child
process only, via `op run` or `op inject`. Scanning and leak response stay in
[[audit-security]]; this skill owns the storage and injection workflow.

## Prerequisites

```bash
op --version             # CLI present (installed via Brewfile: cask "1password-cli")
op whoami                # signed in; if not: `op signin` (or unlock via the 1Password desktop app)
op vault list            # confirm the target vault exists
```

The 1Password **desktop app** unlocks biometric integration and enables the `op`
shell plugins (`op plugin init aws|gh|...`). For headless / CI, use a service
account token instead (see CI section).

## The reference format

```
op://<vault>/<item>/[<section>/]<field>
```

Examples: `op://Dev/aws/access_key_id`, `op://Dev/snowflake/credentials/password`.
Vaults and items can be addressed by **name or UUID**; UUIDs survive renames and
are preferred in committed files for projects with churn.

## Store a secret

For ad-hoc storage, prefer creating a typed item over stashing things in a Secure
Note (typed items get the right field names, masking, and shell-plugin support):

```bash
# API token / opaque credential
op item create --vault Dev --category "API Credential" --title myservice \
  credential="$(pbpaste)"                      # never type the value on the command line

# Login (username + password + URL)
op item create --vault Dev --category login --title github-bot \
  username=ci-bot password=- url=https://github.com    # `=-` reads value from stdin

# Add or update a field on an existing item
op item edit myservice --vault Dev "credential[concealed]=$(pbpaste)"
```

After creation, get the reference (do not echo the value):

```bash
op item get myservice --vault Dev --format json | jq -r '.fields[] | "\(.label) -> op://Dev/myservice/\(.id)"'
```

**Never** paste a secret value as a literal argument. Use `=-` to read from
stdin, or `$(pbpaste)` immediately after copying from 1Password, so the value
does not enter shell history. Pair with `setopt HIST_IGNORE_SPACE` and prefix
the command with a space when in doubt.

## Migrate a project off plaintext secrets

When you find committed secrets (or a plaintext `.env`):

1. **Scan first** (delegated to [[audit-security]]): `gitleaks detect --no-banner`.
2. **For each finding**, store the value in 1Password (typed item, correct vault),
   then **replace the plaintext in the file with its `op://` reference**:

   ```diff
   - AWS_ACCESS_KEY_ID=AKIA...
   - AWS_SECRET_ACCESS_KEY=wJalrXUt...
   + AWS_ACCESS_KEY_ID=op://Dev/aws/access_key_id
   + AWS_SECRET_ACCESS_KEY=op://Dev/aws/secret_access_key
   ```

3. **Rotate** every secret that was ever committed. A reference in the current
   file does not undo the past leak. Rotation is mandatory, not optional.
4. **Decide what stays gitignored.** A `.env` containing only `op://` references
   is safe to commit and helps onboarding. A `.env` with any plaintext stays
   gitignored (`.gitignore`: `.env`, `.env.local`, `*.pem`, `*.key`).
5. **Verify** the new file resolves end-to-end:
   ```bash
   op run --env-file=.env -- env | grep -E 'AWS_|DB_' | sed 's/=.*/=<resolved>/'
   ```

## Run commands with secrets injected

The default for invoking any command that needs secrets:

```bash
op run --env-file=.env -- <command>
```

`op run` resolves `op://` refs in the env file, exports them to the child
process only, and masks them in stdout/stderr by default. Examples:

```bash
op run --env-file=.env -- terraform apply
op run --env-file=.env -- pytest -q
op run --env-file=.env -- node scripts/migrate.js
```

For a **single secret** without a file: `op read "op://Dev/aws/access_key_id"`.
Prefer `op run` over `op read | export` because `op read` puts the value in the
shell's environment (and potentially history) for the rest of the session.

## Config files with embedded refs

For YAML/JSON/INI/dotfile templates that need secrets baked in (a generated
config, a kubeconfig, a `~/.npmrc`), use `op inject`:

```bash
# template.yaml contains:  password: "{{ op://Dev/db/password }}"
op inject -i template.yaml -o config.yaml
chmod 600 config.yaml
```

Add the resolved output to `.gitignore`. Re-run `op inject` whenever the
template changes; never edit the resolved file directly.

## direnv

`direnv` is for non-secret, per-project shell config (paths, profile names,
flags). See [[setup-devenv]] for the .envrc patterns. **Do not** put `op read`
into `.envrc`: it resolves at `cd` time, caches the secret in the shell session,
and defeats the point. Pattern:

```bash
# .envrc -- non-secret config only
export APP_ENV=development
export AWS_PROFILE=dev
PATH_add bin

# .env -- op:// refs only, run via:  op run --env-file=.env -- <cmd>
```

If a command needs both direnv'd config and resolved secrets, wrap it:

```bash
# bin/dev (project-local, on PATH via PATH_add bin)
#!/usr/bin/env bash
exec op run --env-file=.env -- "$@"
```

Then `dev terraform apply` does the right thing.

## CI / non-interactive

GitHub Actions: use
[`1password/load-secrets-action@v2`](https://github.com/1Password/load-secrets-action)
with a service account token stored as `OP_SERVICE_ACCOUNT_TOKEN` in the
repository's GitHub Actions secrets. Map each needed `op://` ref to a job-scoped
env var; never echo the resolved values, never set `continue-on-error` on the
load step. For other CI providers, set `OP_SERVICE_ACCOUNT_TOKEN` and run
`op run`/`op read` the same way as locally.

## Safety rules

- **Never echo, log, or print resolved secrets.** Not even partially. Mask before
  logging (`sed 's/=.*/=<redacted>/'`).
- **Never bake resolved values into committed files.** Only `op://` references.
- **Always rotate** a secret that ever existed as plaintext in git history, even
  briefly. A force-push does not erase forks, clones, or caches.
- **Prefer typed items** (API Credential, Login, Database) over Secure Notes so
  fields are masked, structured, and discoverable via shell plugins.
- **One vault per trust boundary** (Dev, Prod, Shared, Personal). Do not store
  prod secrets in the Dev vault to save a click.
- For leak scanning, response, and `.gitignore` hygiene, see [[audit-security]].
