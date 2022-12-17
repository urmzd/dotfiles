require("plugins.packer")

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "sumneko_lua", "rust_analyzer", "tsserver", "pyright", "jdtls", "yamlls" },
})

require("nvim-treesitter.configs").setup({
  ensure_installed = { "rust", "python", "c", "lua" },
})

require("test_setup")
require("debuggers")
require("lsp_setup")
require("cmp_setup")
require("settings")
require("key_mappings")
require("auto_groups")
require("neovide")

-- Plugins
require("plugins.telescope")
require("plugins.nvim-tree")
require("plugins.vimtex")
require("plugins.null-ls")
require("plugins.project_nvim")
require("plugins.fidget")
require("plugins.lualine")

require("theme")
