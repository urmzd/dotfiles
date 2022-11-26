local setup = require("lsp_setup")
local opts = setup.opts
local rust_tools = require("rust-tools")

rust_tools.setup {
   server = opts
}
