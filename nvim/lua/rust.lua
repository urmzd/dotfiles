local config = require("lsp_setup")
local rt = require("rust-tools")

rt.setup {
   server = config.opts
}
