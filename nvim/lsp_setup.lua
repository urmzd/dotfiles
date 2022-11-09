-- -- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local diagnostic_opts = { noremap = true, silent = true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, diagnostic_opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, diagnostic_opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, diagnostic_opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, diagnostic_opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap = true, silent = true, buffer = bufnr }

  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>f', vim.lsp.buf.format, bufopts)
end

-- LSP set up.
local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

local opts = {
  on_attach = on_attach,
  flags = { debounce_text_changes = 150 },
  capabilities = capabilities
}

--- LSP
require("language-servers.lua").setup(lspconfig, opts)
require("language-servers.perl").setup(lspconfig, opts)
require("language-servers.typescript").setup(lspconfig, opts)
require("language-servers.rust").setup(lspconfig, opts)
require("language-servers.json").setup(lspconfig, opts)
require("language-servers.yaml").setup(lspconfig, opts)
require("language-servers.graphql").setup(lspconfig, opts)
require("language-servers.python").setup(lspconfig, opts)
require("language-servers.bash").setup(lspconfig, opts)
require("language-servers.groovy").setup(lspconfig, opts)
require("language-servers.kotlin").setup(lspconfig, opts)

--- Null LS
require("language-servers.nls").setup(opts)
require("language-servers.java").setup(opts)
