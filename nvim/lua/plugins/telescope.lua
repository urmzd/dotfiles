local telescope = require("telescope");

telescope.setup {
  pickers = {
    find_files = {
      hidden = true
    }
  }
}

telescope.load_extension('fzf')
telescope.load_extension("projects")

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
