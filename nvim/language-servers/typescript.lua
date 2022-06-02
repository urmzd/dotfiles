local M = {}

local lume = require("lume")

function M.setup(config, opts)
   config.tsserver.setup({
      opts = lume.merge(opts, {
         on_attach = function(client, bufnr)
            client.resolved_capabilities.document_formatting = false
            client.resolved_capabilities.document_range_formatting = false
         end
      })
   })

end

return M
