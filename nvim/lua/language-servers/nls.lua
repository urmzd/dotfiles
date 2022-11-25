local nls = require("null-ls")


local sources = {
    nls.builtins.formatting.stylua,
    nls.builtins.formatting.prettierd,
    nls.builtins.diagnostics.eslint_d,
    nls.builtins.completion.spell,
    nls.builtins.code_actions.gitsigns,
    nls.builtins.hover.dictionary
        --.with({
            --filetypes={"markdown", "text", "tex"}
        --}),
}

local M = {}

function M.setup(opts)
    nls.setup {
        sources = sources,
        on_attach = opts.on_attach,
        save_after_format = false,
        debounce = 150
    }
end

return M
