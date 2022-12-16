local nls = require("null-ls")
local setup = require("lsp_setup")
local opts = setup.opts

local sources = {
    nls.builtins.formatting.stylua,
    nls.builtins.formatting.prettierd,
    nls.builtins.diagnostics.eslint_d,
    nls.builtins.completion.spell,
    nls.builtins.code_actions.gitsigns,
    nls.builtins.hover.dictionary,
    nls.builtins.formatting.beautysh,
    nls.builtins.formatting.taplo,
    nls.builtins.formatting.npm_groovy_lint
}

nls.setup {
    sources = sources,
    on_attach = opts.on_attach,
    save_after_format = true,
    debounce = 150
}
