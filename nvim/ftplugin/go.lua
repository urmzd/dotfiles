local lspconfig = require("lspconfig")
local lsp_setup = require("lsp_setup")
local opts = lsp_setup.opts

lspconfig.gopls.setup(opts)
