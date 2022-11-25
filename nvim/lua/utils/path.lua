local M = {}

M.root_dir = vim.fn.stdpath('data')
M.install_dir = M.root_dir .. '/site/pack/packer/start/packer.nvim'
M.lsp_servers_dir = M.root_dir .. '/lsp_servers'

return M
