require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "rust_analyzer", "tsserver", "pyright", "jdtls", "yamlls", "bashls", "gopls" },
})
require("mason-null-ls").setup{
  automatic_installation=true
}
