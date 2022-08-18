local api = vim.api

-- Window movement (LDUR).
api.nvim_set_keymap('n', '<leader>h', ':wincmd h<CR>',
  { silent = true, noremap = true })
api.nvim_set_keymap('n', '<leader>j', ':wincmd j<CR>',
  { silent = true, noremap = true })
api.nvim_set_keymap('n', '<leader>k', ':wincmd k<CR>',
  { silent = true, noremap = true })
api.nvim_set_keymap('n', '<leader>l', ':wincmd l<CR>',
  { silent = true, noremap = true })

-- Escape
api.nvim_set_keymap('i', 'jj', '<ESC>', { noremap = true, silent = true })

-- Telescope bindings.
api.nvim_set_keymap("n", "<leader>ff",
  "<cmd>lua require('telescope.builtin').find_files()<cr>",
  { noremap = true, silent = true })
api.nvim_set_keymap("n", "<leader>fg",
  "<cmd>lua require('telescope.builtin').live_grep()<cr>",
  { noremap = true, silent = true })
api.nvim_set_keymap("n", "<leader>fb",
  "<cmd>lua require('telescope.builtin').buffers()<cr>",
  { noremap = true, silent = true })
api.nvim_set_keymap("n", "<leader>fh",
  "<cmd>lua require('telescope.builtin').buffers()<cr>",
  { noremap = true, silent = true })
-- Tree mappings
api.nvim_set_keymap("n", "<C-e>", ":NvimTreeToggle<CR>",
  { noremap = true, silent = true })

-- Ultest mappings
api.nvim_set_keymap("n", "<leader>tj", ":call ultest#output#jumpto()<cr>",
  { noremap = true, silent = true })