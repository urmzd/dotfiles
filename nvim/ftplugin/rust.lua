local setup = require("lsp_setup")
local rust_tools = require("rust-tools")
local opts = setup.opts

rust_tools.setup {
   server = opts
}
