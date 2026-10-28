---
name: publish-vault
description: >
  Publish notes from an Obsidian vault folder into another folder (usually a
  repo's content directory) by one-way mirroring top-level Markdown files
  (add, update, remove). Discovers vaults and likely targets, asks the user
  where to publish from and to, previews, then mirrors with a bundled script.
  Use when the user says "publish the blog", "sync the vault to the repo",
  "push my Obsidian posts", or "publish-vault". Do NOT commit or push (use
  ship); do NOT edit note content.
allowed-tools: Bash, Read
user-invocable: true
arguments:
  - name: src
    description: Vault folder to publish from. If omitted, discover and ask.
    required: false
  - name: dst
    description: Folder to publish into. If omitted, discover and ask.
    required: false
---

# Publish Vault

Mirror one vault folder into one target folder. The source wins every conflict; the target is output only. Paths are never assumed: vaults and repos move, so discover them each run and confirm with the user.

## Steps

1. **Find vaults.** Read Obsidian's registry and list every vault path that still exists:

   ```sh
   python3 -I -c 'import json,os;r=json.load(open(os.path.expanduser("~/Library/Application Support/obsidian/obsidian.json")));[print(v["path"]) for v in r["vaults"].values() if os.path.isdir(v["path"])]'
   ```

   On Linux the registry is `~/.config/obsidian/obsidian.json`. Note any registered path that no longer exists: the vault moved, so ask the user where it went.

2. **Ask for the source.** If `src` was not given, show the vaults and their top-level folders that contain `.md` files, and ask which folder to publish. Accept any path the user types.

3. **Find targets.** Look for content folders in nearby git repos that already hold the same filenames as the source (strong match), or directories named `blog`, `posts`, `content`, `notes`:

   ```sh
   for f in "<src>"/*.md; do echo "$(basename "$f")"; done > /tmp/names
   find ~/github ~/code ~/src -maxdepth 4 -type d \( -name blog -o -name posts -o -name content -o -name notes \) -not -path '*/node_modules/*' 2>/dev/null
   ```

   Rank folders with overlapping filenames first.

4. **Ask for the target.** If `dst` was not given, show the ranked candidates and ask. Accept any path. If the target does not exist, ask before creating it.

5. **Check for repo-side edits.** If the target is in a git repo, run `git -C <dst> status --porcelain .`. Any modified file that also differs from the source will be overwritten: show the diff and ask before continuing.

6. **Dry run** and show the add/update/remove list:

   ```sh
   ~/.agents/skills/publish-vault/scripts/mirror.sh --src <src> --dst <dst> --dry-run
   ```

7. **Mirror.** Rerun without `--dry-run`. If the dry run listed removals, get explicit approval first.

8. **Report** the summary line and `git -C <dst> status --short .`. Offer `ship` to commit.

## Rules

- One-way only: never copy target files back into the vault.
- Only top-level files with the chosen extension (`--ext`, default `md`) are touched. Subfolders and `.obsidian` are ignored.
- The script refuses to run if the source is empty or has undownloaded iCloud placeholders.
- Never hard-code paths in this skill. Confirm source and target with the user every run.
