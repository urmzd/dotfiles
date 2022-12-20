local M = {}
local opts = {}

vim.g.coq_settings = {auto_start = "shut-up"}

-- -- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local diagnostic_opts = { noremap = true, silent = true }
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, diagnostic_opts)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, diagnostic_opts)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, diagnostic_opts)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, diagnostic_opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
opts.on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap = true, silent = true, buffer = bufnr }

  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set("n", "<space>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, bufopts)
  vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, bufopts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
  vim.keymap.set("n", "<space>f", function ()
    vim.lsp.buf.format({timeout_ms=5000}) 
  end, bufopts)

  if client.name ~= "null-ls" then
    client.server_capabilities.document_formatting = false
    client.server_capabilities.document_range_formatting = false
  end
end

-- LSP set up.
opts.flags = { debounce_text_changes = 150 }

function M.setup(lsp, overrides)
  local coq = require("coq")()
  local lspconfig = require("lspconfig")
  local lume = require("lume")
  local merged_opts = lume.merge(opts, overrides or {})

  vim.schedule(function ()
    lspconfig[lsp].setup(coq.lsp_ensure_capabilities(merged_opts))
  end)

end

return M
