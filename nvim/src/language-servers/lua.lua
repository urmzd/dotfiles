local M = {}

function M.setup(lspconfig, opts)
    local luadev = require("lua-dev").setup({ lspconfig = opts, library = {
        plugins = {
            "neotest"
        },
        types = true
    } })
    lspconfig.sumneko_lua.setup(luadev)
end

return M
