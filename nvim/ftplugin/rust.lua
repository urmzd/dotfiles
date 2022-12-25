local rt = require("rust-tools")
local config = require("lsp_config")
rt.setup {
    server = config.setup_with_coq()
}
