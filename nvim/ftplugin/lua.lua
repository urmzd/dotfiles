local setup = require("lsp_setup")
local config = require("lspconfig")
local opts = setup.opts

local neodev = require("neodev")
neodev.setup {}

local overrides =  {
  settings = {
    Lua = {
      completion = {
        callSnippet = "Replace"
      }
    }
  }
}

config.sumneko_lua.setup(opts)

