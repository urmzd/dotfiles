local root_dir = vim.fn.stdpath('data')
local install_dir = root_dir .. '/site/pack/packer/start/packer.nvim'
local lsp_servers_dir = root_dir .. '/lsp_servers'

mod = {
    root_dir = root_dir,
    install_dir = install_dir,
    lsp_servers_dir = lsp_servers_dir
}

return mod
