local mod = {}

function mod.setup(lspconfig, opts)
    local luadev = require("lua-dev").setup({ lspconfig = opts })
    lspconfig.sumneko_lua.setup(luadev)
end

return mod
