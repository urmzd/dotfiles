local M = {}

function M.setup(_config, opts)
   local rust_tools = require("rust-tools")
   rust_tools.setup {
      server = opts
   }
end

return M
