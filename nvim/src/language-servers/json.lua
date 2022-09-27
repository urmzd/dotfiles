local M = {}

local lume = require("lume")

function M.setup(config, opts)
   local overrides = {}

   overrides.on_attach = function(client, bufnr)
      client.resolved_capabilities.document_formatting = false
      client.resolved_capabilities.document_range_formatting = false
   end
   overrides.filetypes = { "json", "jsonc" }

   local _capabilities = vim.lsp.protocol.make_client_capabilities()
   _capabilities.textDocument.completion.completionItem.snippetSupport = true

   overrides.capabilities = _capabilities
   overrides.settings = {
      json = {
         schemas = require("schemastore").json.schemas(),
         validate = { enable = true }

      }
   }

   config.jsonls.setup(lume.merge(opts, overrides))

end

return M
