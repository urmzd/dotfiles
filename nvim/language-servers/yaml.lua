local M = {}

local lume = require("lume")

function M.setup(config, opts)
   config.yamlls.setup(lume.merge(opts, {
      filetypes = { "yaml" },
      settings = {
         yaml = {
            schemaStore = {
               enable = true
            }
         }
      }
   }))
end

return M
