local setup = require("lsp_setup")
local config = require("lspconfig")
local opts = setup.opts

config.pyright.setup(opts)
