-- TODO: Split configurations by plugins.
require("plugins")
require 'nvim-rooter'.setup {
  rooter_patterns = { '.git', '.root' },
  trigger_pattern = { '*' },
  manual = false
}
require("mason").setup()
require("mason-lspconfig").setup()
require("test_setup")
require("debuggers")
require("lsp_setup")
require("cmp_setup")
require("settings")
require("key_mappings")
require("auto_groups")
require("plugins.telescope")
require("neovide")
require("fidget").setup()
