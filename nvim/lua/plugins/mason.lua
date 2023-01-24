require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "sumneko_lua", "rust_analyzer", "tsserver", "pyright", "jdtls", "yamlls", "bashls", "gopls" },
})
