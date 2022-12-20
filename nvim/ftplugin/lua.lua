local config = require("lsp_setup")

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

config.setup("sumneko_lua", overrides)

