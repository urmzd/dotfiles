---
name: triage-dotfiles-env
description: >
  Playbook of known failure modes in this dotfiles stack: pipx "bad
  interpreter" after Python rebuilds, gpg commit-signing failures, direnv/nix
  shellHook running bash instead of zsh, Powerlevel10k instant-prompt
  warnings, and Neovim plugin errors from removed Lua APIs. Use when a shell
  startup error, git signing failure, broken CLI shim, or nvim stack trace
  appears on this machine. Do NOT use for generic runtime debugging in
  projects (use diagnose-runtime), chezmoi naming and templating conventions
  (use dotfiles), or authoring pinned installers (use
  setup-devenv-with-chezmoi).
allowed-tools: Read, Grep, Glob, Bash
user-invocable: true
metadata:
  title: Triage Dotfiles Environment
  category: workflow
---

# Triage Dotfiles Environment

Look the symptom up here before debugging from scratch. Every fix ends with
its verification step; a fix without verification is not done.

## Known failure modes

### pipx shims: "bad interpreter: no such file or directory"

Seen repeatedly in `.zshrc` completions (`register-python-argcomplete: bad
interpreter`).

- **Cause**: a Homebrew or uv Python upgrade rebuilt the interpreter path;
  every pipx venv shebang now points at a deleted Python.
- **Fix**: `pipx reinstall-all`. If pipx itself is broken:
  `brew reinstall pipx && pipx reinstall-all`.
- **Verify**: open a fresh `zsh -l` and confirm zero startup errors, then run
  the failing shim directly.

### gpg: "cannot run gpg: No such file or directory" on commit

- **Cause**: git config points at a gpg binary that moved (brew relink,
  new machine), or `GPG_TTY` is unset in a non-login context.
- **Fix**: `git config --global gpg.program "$(command -v gpg)"`, ensure the
  zshrc exports `GPG_TTY=$(tty)`, and confirm `user.signingkey` matches
  `gpg --list-secret-keys --keyid-format long`.
- **Verify**: `git commit --allow-empty -m "test: signing" && git log
  --show-signature -1`, then drop the test commit.

### direnv + nix: shellHook runs bash, not zsh

Symptoms: aliases and functions missing inside a nix shell, prompts wrong,
zsh-only syntax errors from hooks.

- **Cause**: nix shellHook always executes in bash. zsh config never runs.
- **Fix**: keep shellHook to environment exports only; put interactive setup
  in zsh init guarded by `IN_NIX_SHELL`. Never source zsh files from
  shellHook.
- **Verify**: `direnv exec . zsh -ic 'echo $SHELL; alias | head'`.

### Powerlevel10k instant-prompt warnings

- **Cause**: something in `.zshrc` prints output before the instant-prompt
  block (installer scripts, completion generators, version managers).
- **Fix**: move the offending line below the instant-prompt block or silence
  its output; keep the instant-prompt block first.
- **Verify**: fresh `zsh -l` shows no warning banner.

### Neovim: plugin errors from removed Lua APIs

Example: `E5108 ... attempt to call field 'buf_get_clients' (a nil value)`
(API removed; modern equivalent `vim.lsp.get_clients`).

- **Cause**: plugin pinned by lazy.nvim lockfile predates a Neovim HEAD API
  removal, or an abandoned plugin needs replacement.
- **Fix**: `:Lazy update` the plugin first; if abandoned, patch the call or
  swap the plugin. Check `~/.local/state/nvim/log` for the full trace.
- **Verify**: `nvim --headless "+lua print('ok')" +q` exits clean, then open
  a file that previously triggered the error. A pasted-twice error means the
  first fix was never verified; always run this step.

### Completions stale after adding or removing CLIs

- **Cause**: generated completions in the chezmoi-managed dir lag the
  installed tool set.
- **Fix**: re-run the completion generation script via
  `chezmoi apply` (it is an `run_onchange` script keyed to the Brewfile and
  zshrc).
- **Verify**: `zsh -ic 'compdef | grep <tool>'`.

## Method for anything not listed

1. Reproduce in a fresh shell (`zsh -l` or `zsh -ic '<cmd>'`), never only in
   the current polluted session.
2. Bisect the init chain: `zsh -df` (clean), then add zshrc, then direnv,
   then nix. The first layer that reproduces owns the bug.
3. Fix in the chezmoi source (`chezmoi edit`), apply, and re-verify from a
   fresh shell.
4. Add the new failure mode to this skill so it is a lookup next time.
