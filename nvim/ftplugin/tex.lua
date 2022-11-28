local lsp_setup = require "lsp_setup"
local opts = lsp_setup.opts
local lspconfig = require "lspconfig"

lspconfig.texlab.setup(opts)
