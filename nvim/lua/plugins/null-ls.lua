local nls = require("null-ls")

local sources = {
    -- diagnostics
    --nls.builtins.diagnostics.eslint_d,
    --nls.builtins.diagnostics.cspell.with({
            --extra_args = {
                --"--locale",
                --"en-GB"
            --}
    --}),
    --nls.builtins.diagnostics.misspell,
    --nls.builtins.diagnostics.proselint,
    -- completion
    --nls.builtins.completion.spell,
    -- code actions
    --nls.builtins.code_actions.cspell.with({
        --"--locale", "en-GB"
    --}),
    nls.builtins.code_actions.gitsigns,
    --nls.builtins.code_actions.spellcheck,
    -- hover
    nls.builtins.hover.dictionary,
    -- formatting
    nls.builtins.formatting.stylua,
    nls.builtins.formatting.prettierd,
    nls.builtins.formatting.beautysh,
    nls.builtins.formatting.taplo,
    nls.builtins.formatting.npm_groovy_lint,
    nls.builtins.formatting.markdownlint,
    nls.builtins.formatting.mdformat,
    nls.builtins.formatting.codespell,
    nls.builtins.formatting.black

}

nls.setup {
    sources = sources,
    save_after_format = true,
    debounce = 150
}
