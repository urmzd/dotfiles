-- Augroups.
require('nvim_utils')

local autocmds = {
  toggle_hi = { { "InsertEnter", "*", "setlocal nohlsearch" } },
  auto_format = { { "BufWritePre", "*", "lua vim.lsp.buf.formatting({}, 100)" } },
  markdown_hi = { { "BufWinEnter", "*.md", ":e" } }
}

nvim_create_augroups(autocmds)