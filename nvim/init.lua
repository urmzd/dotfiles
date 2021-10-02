-- Bootstrap `packer.nvim`.
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/wbthomason/packer.nvim',
    install_path
  })
  vim.cmd 'packadd packer.nvim'
end


-- Install plugins.
require('packer').startup(function()
	use {'wbthomason/packer.nvim', opt=true}
	use {'nvim-treesitter/nvim-treesitter'}
	use {
      'lewis6991/gitsigns.nvim',
      requires = {'nvim-lua/plenary.nvim'}
  }
	use {'neovim/nvim-lspconfig'}
	use {'tpope/vim-surround'}
	use {'tpope/vim-repeat'}
	use {'tpope/vim-fugitive'}
	use {'sheerun/vim-polyglot'}
	use {'itchyny/lightline.vim'}
	use {'preservim/nerdcommenter'}
	use {'preservim/vimux'}
	use {'alvan/vim-closetag'}
	use {'airblade/vim-rooter'}
	use {'vim-test/vim-test'}
	use {'morhetz/gruvbox'}
	use {
    'kkoomen/vim-doge', 
  run = function() fn["doge#install"]() end 
  }
	use {'rust-lang/rust.vim'}
	use {
		'nvim-telescope/telescope.nvim',
		requires = { { 'nvim-lua/plenary.nvim' } }
	}
	use {
    'williamboman/nvim-lsp-installer'
	}
  use 'hrsh7th/nvim-cmp' -- Autocompletion plugin
  use 'hrsh7th/cmp-nvim-lsp' -- LSP source for nvim-cmp
  use 'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
  use 'L3MON4D3/LuaSnip' -- Snippets plugin
end)

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = function(fallback)
      if vim.fn.pumvisible() == 1 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-n>', true, true, true), 'n')
      elseif luasnip.expand_or_jumpable() then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-expand-or-jump', true, true, true), '')
      else
        fallback()
      end
    end,
    ['<S-Tab>'] = function(fallback)
      if vim.fn.pumvisible() == 1 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-p>', true, true, true), 'n')
      elseif luasnip.jumpable(-1) then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-jump-prev', true, true, true), '')
      else
        fallback()
      end
    end,
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
}

local nvim_lsp = require('lspconfig')

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
end

--let s:clip = '/mnt/c/Windows/System32/clip.exe'
--if executable(s:clip)
      --augroup WSLYank
            --autocmd!
            --autocmd TextYankPost * if v:event.operator ==# 'y' | call system(s:clip, @0) | endif
      --augroup END
--endif 

local lsp_installer = require("nvim-lsp-installer")

lsp_installer.on_server_ready(function(server)
  local opts = {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150
    }
  }

  server:setup(opts)
  vim.cmd [[ do User LspAttachBuffers ]]
end)

-- Commands.
local cmd = vim.cmd
-- Global options.
local opt = vim.opt
-- Global 'let' options.
local g = vim.g
-- Buffer options.
local bo = vim.bo
-- Window options.
local wo  = vim.wo
-- Api
local api = vim.api

-- Global let.
g.mapleader = ' ' 

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
opt.fileformat = "unix"
opt.background = "dark"

-- WSL copy/paste support.
opt.clipboard="unnamedplus"
g.clipboard = {
  name = "win32yank-wsl",
  copy = {
    ["+"] = "win32yank.exe -i --crlf",
    ["*"] = "win32yank.exe -i --crlf"
  },
  paste = {
    ["+"] = "win32yank.exe -o --crlf",
    ["*"] = "win32yank.exe -o --crlf"
  },
  cache_enable = 0,
}

-- Set colour scheme.
cmd([[colorscheme gruvbox]])

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

-- Telescope bindings.
api.nvim_set_keymap("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<cr>", {noremap=true, silent=true})
api.nvim_set_keymap("n", "<leader>fg", "<cmd>lua require('telescope.builtin').live_grep()<cr>", {noremap=true, silent=true})
api.nvim_set_keymap("n", "<leader>fb", "<cmd>lua require('telescope.builtin').buffers()<cr>", {noremap=true, silent=true})
api.nvim_set_keymap("n", "<leader>fh", "<cmd>lua require('telescope.builtin').buffers()<cr>", {noremap=true, silent=true})

-- Icons for LSP package manager.
require("nvim-lsp-installer").settings {
    ui = {
        icons = {
            server_installed = "✓",
            server_pending = "➜",
            server_uninstalled = "✗"
        }
    }
}

