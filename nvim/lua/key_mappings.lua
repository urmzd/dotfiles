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
