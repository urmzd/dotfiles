local nls = require("null-ls")

local sources = {
    nls.builtins.code_actions.gitsigns,
    nls.builtins.hover.dictionary,
    nls.builtins.formatting.stylua,
    nls.builtins.formatting.prettierd,
    nls.builtins.formatting.beautysh,
    nls.builtins.formatting.taplo,
    nls.builtins.formatting.npm_groovy_lint,
    nls.builtins.formatting.markdownlint,
    nls.builtins.formatting.mdformat,
    nls.builtins.formatting.black,
}

nls.setup({
    sources = sources,
    save_after_format = true,
    debounce = 150,
})
