-- Window movement (LDUR).
vim.api.nvim_set_keymap('n', '<leader>h', ':wincmd h<CR>',
  { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>j', ':wincmd j<CR>',
  { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>k', ':wincmd k<CR>',
  { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>l', ':wincmd l<CR>',
  { silent = true, noremap = true })

-- Escape
vim.api.nvim_set_keymap('i', 'jj', '<ESC>', { noremap = true, silent = true })

-- Telescope bindings.
vim.api.nvim_set_keymap("n", "<leader>ff",
  "<cmd>lua require('telescope.builtin').find_files()<cr>",
  { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>fg",
  "<cmd>lua require('telescope.builtin').live_grep()<cr>",
  { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>fb",
  "<cmd>lua require('telescope.builtin').buffers()<cr>",
  { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>fh",
  ":Telescope file_browser<cr>",
  { noremap = true, silent = true })

