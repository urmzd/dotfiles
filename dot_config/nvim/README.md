# Neovim

Deployed to `~/.config/nvim`. Configured for **reviewing and running code that
an agent wrote**, which is a different job from typing code: the files change
underneath you, the interesting diff is a branch rather than a buffer, and the
work usually lives in a worktree that is not the checkout you are sitting in.

## Sidebar

One window on the left, three panels, one tab strip drawn in its `winbar`. The
tabs are clickable with the mouse and reachable by key, so no panel is hidden
behind a command you have to remember.

| Tab | Panel | Shown when |
|---|---|---|
| `󰉋 Files` | neo-tree filesystem | always |
| `󰊢 Changes` | neo-tree git status, the VS Code Source Control list | inside a git repository |
| `󰙨 Tests` | neotest summary | a neotest adapter claims the project |

| Key | Action |
|---|---|
| `<leader>1` / `<leader>2` / `<leader>3` | Files / Changes / Tests |
| `1` / `2` / `3` (inside a panel) | same, because `<leader>` is taken by neo-tree |
| `<leader>sf` / `<leader>sc` / `<leader>st` | same, spelled out |
| `<leader>ss` | reopen the last panel |
| `<leader>sq` | close the sidebar |
| `:Sidebar [files\|changes\|tests\|close]` | same, from the command line |
| click a tab | switch to it; clicking the active tab closes the sidebar |

The strip drops labels for inactive tabs, then for all tabs, as the window
narrows, so it never truncates.

## Worktrees

Agents work in `<repo-root>/.worktrees/<name>` so the primary checkout never
leaves its branch. Switching checkouts retargets the tab's working directory,
closes the buffers that belonged to the checkout you left, keeps and reports any
that are unsaved, and re-roots the sidebar.

| Key | Action |
|---|---|
| `<leader>ww` | pick a worktree (`<CR>` switches, `<C-d>` removes) |
| `<leader>wn` | create `.worktrees/<name>` on a new branch and switch into it |
| `<leader>wm` | back to the primary checkout |
| `:Worktree [list\|new [name] [base]\|main]` | same, from the command line |

`.worktrees/` is kept untracked through `.git/info/exclude`, never the
repository's own `.gitignore`. Removing a worktree that still has uncommitted
work is refused, and git's reason is reported rather than forced through.

The statusline names the current worktree whenever it is not the primary
checkout, so which copy of the repo you are reading is never a guess.

## Reviewing a diff

| Key | Action |
|---|---|
| `<leader>gd` | diff the working tree |
| `<leader>gD` | diff this branch against the merge base with the default branch |
| `<leader>gh` / `<leader>gH` | history of this file / of this repo |
| `<leader>gq` | close the diff view |
| `<leader>gs` | Neogit status |
| `<leader>gb` | toggle git blame |

## Files changing underneath you

`autoread` is on and buffers are re-stated on `FocusGained`, `BufEnter`,
`CursorHold`, and on leaving a terminal, so switching back from the pane an
agent is running in reloads what it changed. A reload announces itself, since a
buffer silently swapping out from under a review is worse than a message. The
file tree uses a libuv watcher rather than refreshing only on `:write`, so files
an agent creates or deletes appear without a nudge.

## Language servers

Servers are **not** installed up front. Opening a file installs what that
filetype needs, once, and only if this machine can actually build and run it.
mason installs npm packages with npm and Go packages with go, so the check is
against the backend each package declares; a server that needs a toolchain the
machine lacks is skipped with one message rather than failing on every startup.
Formatters follow the same path, derived from conform's own `formatters_by_ft`.

| Language | Server | Why this one |
|---|---|---|
| Lua | `lua_ls` | |
| Python | `ty` + `basedpyright` | ty type-checks; basedpyright has the completion and hover ty still lacks |
| Rust | `rust_analyzer` | |
| Go | `gopls` | |
| C / C++ | `clangd` | |
| TypeScript / JS | `vtsls` | wraps the same TypeScript service VS Code drives, unlike plain `ts_ls` |
| Kotlin | `kotlin_lsp` | JetBrains' own, built on IntelliJ; supersedes the community fwcd server |
| Scala | Metals v2 via `nvim-metals` | not in mason at all, so coursier fetches it |
| Java | `jdtls` via `nvim-jdtls` | Metals v2 also does Java, but two servers per buffer helps nobody |
| Terraform | `terraformls` | |
| Docker | `docker_language_server` | Docker's official one: Dockerfiles, Compose and Bake, where `dockerls` was Dockerfiles only |
| JSON / YAML | `jsonls` / `yamlls` | |
| Bash | `bashls` | |
| Markdown / MDX | `marksman` / `mdx_analyzer` | |
| Astro | `astro` | |
| Prose, LaTeX | `ltex_plus` | `ltex-ls` is unmaintained; `ltex-ls-plus` is the fork that still ships |

Scala needs `coursier` on PATH (`brew install coursier`, or the `install_alt_langs`
Brewfile preset). Metals v2 is pinned to a milestone build, `2.0.0-M17`, because
that is what v2 currently ships as; v1.6.x remains the stable line if you would
rather move back.

## Layout

| Path | Contents |
|---|---|
| `init.lua` | options, keymaps, and the full lazy.nvim plugin spec |
| `lua/sidebar.lua` | the panel switcher and its tab strip |
| `lua/worktree.lua` | worktree listing, switching, creation, removal |
| `lua/lsp.lua` | the server roster and on-demand install |
| `lua/debug_helpers.lua` | persistent DAP breakpoints |
| `after/lsp/*.lua` | per-server LSP settings |
| `ftplugin/*.lua` | per-filetype settings |
