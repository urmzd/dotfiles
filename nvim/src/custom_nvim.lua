-- TODO: Split configurations by plugins.
require("plugins")
require 'nvim-rooter'.setup {
  rooter_patterns = { '.git', '.root' },
  trigger_pattern = { '*' },
  manual = false
}
require("test_setup")
require("nvim-lsp-installer").setup({})
require('telescope').load_extension('fzf')
require("debuggers")
require("lsp_setup")
require("cmp_setup")
require("settings")
require("key_mappings")
require("auto_groups")
