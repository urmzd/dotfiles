local lume = require("lume")
local lsp_setup = require("lsp_setup")
local config = lsp_setup.config

config.yamlls.setup(lume.merge(opts, {
   --filetypes = { "yaml"},
   settings = {
      yaml = {
         schemaStore = {
            enable = true
         }
      }
   }
}))
