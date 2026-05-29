---
name: sync-ecosystem-to-chezmoi
description: >
  Take a drift report from sync-ecosystem and apply it to the chezmoi source
  directory, then run chezmoi apply so the canonical skill store and deployed
  copies stay in sync. Use when you maintain agent skills in chezmoi and have a
  pending drift report to merge back.
allowed-tools: Read Grep Glob Bash Edit Write
user-invocable: true
metadata:
  title: Sync Ecosystem to Chezmoi
  category: maintenance
  order: 31
---

# Sync Ecosystem to Chezmoi

This is the chezmoi-specific tail of the `sync-ecosystem` workflow. The base skill audits a repo against ecosystem conventions and emits a drift report. This skill takes that report and applies it to the chezmoi-managed canonical skill source, then redeploys.

## When to Use

- You ran `sync-ecosystem <repo>` and have a drift report to apply.
- You maintain your agent skills in a chezmoi source tree and need the deployed copies under `${CLAUDE_SKILL_DIR:-$HOME/.agents/skills}/` to follow.
- A new or stale skill needs to be promoted from a project repo into the canonical store.

If you don't use chezmoi, stop here. The portable audit lives in `sync-ecosystem`; you can substitute your own deploy step.

## Prerequisites

```sh
chezmoi --version          # CLI present
chezmoi source-path        # confirm the source dir, typically ~/.local/share/chezmoi
```

The canonical skill source lives under `<chezmoi-source>/dot_agents/skills/`. Deployed copies under `${CLAUDE_SKILL_DIR:-$HOME/.agents/skills}/` are overwritten on every `chezmoi apply`, so never edit them directly.

## Workflow

1. **Receive the drift report.** Typically produced by running `sync-ecosystem <repo-path>` first. The report lists missing artifacts, content drift, and canonical-store coverage issues per skill.

2. **For each finding, decide the target file.**

   | Finding type | Target |
   |--------------|--------|
   | Skill in repo but not in canonical store | New dir under `<chezmoi-source>/dot_agents/skills/<name>/` |
   | Stale canonical skill (frontmatter / body drift) | Existing `<chezmoi-source>/dot_agents/skills/<name>/SKILL.md` |
   | Asset / script drift inside a skill | Matching file under that skill's `assets/` or `scripts/` |
   | Required ecosystem doc missing | Owner skill in the chezmoi source (e.g. `community-health/assets/`) |

3. **Apply edits in the source, never in `~/.agents/skills/`.** Use `Edit` / `Write` against the chezmoi source paths. Preserve frontmatter formatting and the rest of the file.

4. **Redeploy.** After every batch of edits:

   ```sh
   chezmoi apply
   agentspec sync --fast    # if installed; refreshes the deployed skill index
   ```

5. **Verify.** Re-run the relevant `sync-ecosystem` audit against the original repo. The findings you just merged should now be clear.

## Gotchas

- **Edit the source, not the deployed copy.** `~/.agents/skills/<name>/SKILL.md` is the rendered output of the chezmoi template. Any edits there are lost on next `chezmoi apply`.
- **Frontmatter sensitivity.** Skill loaders are strict about YAML. After editing frontmatter, run `chezmoi apply` and reload your agent so the change actually takes effect.
- **Don't auto-promote drafts.** Skills that live only in a project repo because they're in-progress should stay there until the user signals they're ready for the canonical store.
- **One commit per logical change.** When the chezmoi source is itself a git repo, commit per skill batch so the change history matches the drift report.

## Hand-off Back

After applying the report, hand control back to the user with a short summary: which skills were created, which were edited, what `chezmoi apply` reported, and any items deferred for human review.
