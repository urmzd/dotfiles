local overrides = {
    filetypes = { "json", "jsonc" },
    capabilities = vim.lsp.protocol.make_client_capabilities();
    settings = {
        json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true }
        }
    }
}

overrides.capabilities.textDocument.completion.completionItem.snippetSupport = true

local config = require("lsp_config")
config.setup("jsonls", overrides)
