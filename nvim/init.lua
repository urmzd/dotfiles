-- TODO: Split configurations by plugins.
require("plugins")
require("neodev").setup()
require("mason").setup()
require("mason-lspconfig").setup {
  ensure_installed = {"sumneko_lua", "rust_analyzer", "tsserver", "pyright", "jdtls"}
}
require("nvim-treesitter.configs").setup {
  ensure_installed = {"rust", "python", "c", "lua"}
}
require("test_setup")
require("debuggers")
require("lsp_setup")
require("cmp_setup")
require("settings")
require("key_mappings")
require("auto_groups")
require("neovide")
require("fidget").setup()

require("plugins.telescope")
require("plugins.nvim-tree")
require("nls")
