local lume = require("lume")
local lsp_setup = require("lsp_setup")
local config = require("lspconfig")
local opts = lsp_setup.opts

local overide_opts = {
   settings = {
      yaml = {
         --schemas = {
              --["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*"
         --},
         schemaStore = {
            enable = true
         }
      }
   }
}

config.yamlls.setup(lume.merge(opts, overide_opts))
