local lume = require("lume")
local setup = require("lsp_setup")
local config = require("lspconfig")
local opts = setup.opts

local overrides = {}

overrides.filetypes = { "json", "jsonc" }

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

overrides.capabilities = capabilities

overrides.settings = {
   json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true }
   }
}

config.jsonls.setup(lume.merge(opts, overrides))

