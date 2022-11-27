local setup = require("lsp_setup")
local config = require("lspconfig")
local opts = setup.opts

config.kotlin_language_server.setup(opts)
