local M = {}

M.root_dir = vim.fn.stdpath('data')
M.lsp_servers_dir = M.root_dir .. '/lsp_servers'

return M
