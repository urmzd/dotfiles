local M = {}

local lume = require("lume")

function M.setup(config, opts)
   config.yamlls.setup(lume.merge(opts, {
      filetypes = { "yaml" },
      settings = {
         yaml = {
            schemaStore = {
               enable = true
            },
            schemas = {
               ["https://unpkg.com/graphql-config@4.1.0/config-schema.json"] = "graphql.config.yml",
               'https://bitbucket.org/atlassianlabs/atlascode/raw/main/resources/schemas/pipelines-schema.json'
            }
         }
      }
   }))
end

return M
