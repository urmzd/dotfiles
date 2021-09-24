-- Bootstrap `packer.nvim`.
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
  vim.cmd 'packadd packer.nvim'
end

-- Install plugins.
require('packer').startup(function()
	use {'wbthomason/packer.nvim', opt=true}
  use {'norcalli/nvim_utils'}
	use {'lewis6991/gitsigns.nvim', requires = {
			'nvim-lua/plenary.nvim'
	}}
	use {'neovim/nvim-lspconfig'}
	use {'tpope/vim-surround'}
	use {'tpope/vim-repeat'}
	use {'tpope/vim-fugitive'}
	use {'nvim-treesitter/nvim-treesitter'}
	use {'sheerun/vim-polyglot'}
	use {'itchyny/lightline.vim'}
	use {'preservim/nerdcommenter'}
	use {'preservim/vimux'}
	use {'alvan/vim-closetag'}
	use {'junegunn/fzf', run = function() fn["fzf#install"]() end}
	use {'junegunn/fzf.vim'}
	use {'airblade/vim-rooter'}
	use {'vim-test/vim-test'}
	use {'bkad/CamelCaseMotion'}
	use {'morhetz/gruvbox'}
	use {'kkoomen/vim-doge', run = function() fn["doge#install"]() end }
	use {'rust-lang/rust.vim'}
end)

-- Require utils.
require 'nvim_utils'

local cmd = vim.cmd;
-- Global options.
local opt = vim.opt
-- Global 'let' options.
local g = vim.g;
-- Buffer options.
local bo = vim.bo
-- Window options.
local wo  = vim.wo
-- Api
local api = vim.api

-- Global let.
g.mapleader = ' ' 
g.fzf_action = {
       ['ctrl-s'] =  'split',
       ['ctrl-d'] = 'vsplit' 
		 }


-- Global Settings
opt.relativenumber = true
opt.nu = true
opt.exrc = true
opt.guicursor = ""
opt.hidden = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.termguicolors = true
opt.scrolloff = 16
opt.signcolumn = "yes"
opt.colorcolumn = "80"
opt.clipboard = "unnamedplus"
opt.fileformat = "unix"
opt.background = "dark"

-- Window movement (LDUR).
vim.api.nvim_set_keymap('n', '<leader>h', '<C-w>h', {silent=true})
vim.api.nvim_set_keymap('n', '<leader>j', '<C-j>h', {silent=true})
vim.api.nvim_set_keymap('n', '<leader>k', '<C-w>k', {silent=true})
vim.api.nvim_set_keymap('n', '<leader>l', '<C-w>l', {silent=true})

-- Escape
api.nvim_set_keymap('i', 'jk', '<ESC>', {noremap=true, silent=true})
api.nvim_set_keymap('i', 'kj', '<ESC>', {noremap=true, silent=true})
api.nvim_set_keymap('i', 'jj', '<ESC>', {noremap=true, silent=true})

-- Automatically close braces.
api.nvim_set_keymap('i', '"', '""<left>', {noremap=true, silent=true})
api.nvim_set_keymap('i', '\'', '\'\'<left>', {noremap=true, silent=true})
api.nvim_set_keymap('i', '(', '()<left>', {noremap=true, silent=true}) 
api.nvim_set_keymap('i', '[', '[]<left>', {noremap=true, silent=true}) 
api.nvim_set_keymap('i', '{', '{}<left>', {noremap=true, silent=true}) 
api.nvim_set_keymap('i', '{', '{}<left>', {noremap=true, silent=true}) 

-- Set colour scheme.
cmd([[colorscheme gruvbox]])


--autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescriptreact
--autocmd BufEnter * highlight Normal guibg=0

--let g:python3_host_prog = '/usr/bin/python3.9'

