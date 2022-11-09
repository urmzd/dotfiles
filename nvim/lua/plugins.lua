local cmd = vim.cmd
-- Global Options
local opt = vim.opt
-- Global 'let' Options
local g = vim.g
-- Window Options
local wo = vim.wo
-- API Shortcut
local api = vim.api
-- Functions
local fn = vim.fn

-- Bootstrap `packer.nvim`.
local paths = require("utils.path")

local install_path = paths.install_dir

if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system({
    'git', 'clone', '--depth', '1',
    'https://github.com/wbthomason/packer.nvim', install_path
  })
  cmd 'packadd packer.nvim'
end

-- Install plugins.
local packer = require('packer')
packer.startup(function(use)
  -- Plugin Manager
  use 'wbthomason/packer.nvim'

  -- LSP
  use {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",
  }
  -- Extra LSP Support
  use 'simrat39/rust-tools.nvim'

  -- File Detection
  use 'sheerun/vim-polyglot'
  use { 'nvim-treesitter/nvim-treesitter', run = ":TsUpdate" }
  use 'tpope/vim-surround'
  use 'tpope/vim-repeat'
  use 'tpope/vim-fugitive'
  use 'tpope/vim-unimpaired'
  use 'preservim/nerdcommenter'
  use 'preservim/vimux'

  -- Themes
  use 'ayu-theme/ayu-vim'
  use 'itchyny/lightline.vim'

  -- Documentation
  use { 'kkoomen/vim-doge', run = function() fn["doge#install"]() end }

  -- Misc
  use {
    'lewis6991/gitsigns.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function() require("gitsigns").setup() end
  }
  use 'folke/lsp-colors.nvim'
  use {
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function() require("trouble").setup({}) end
  }
  use {
    "folke/todo-comments.nvim",
    requires = "nvim-lua/plenary.nvim",
    config = function() require("todo-comments").setup() end
  }

  -- Fuzzy Finder
  use {
    'nvim-telescope/telescope.nvim',
    requires = { { 'nvim-lua/plenary.nvim' } }
  }
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }

  -- Completion
  use 'hrsh7th/nvim-cmp' -- Autocompletion plugin
  use 'hrsh7th/cmp-nvim-lsp' -- LSP source for nvim-cmp
  use 'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
  use 'L3MON4D3/LuaSnip' -- Snippets plugin
  use {
    'tzachar/cmp-tabnine',
    run = './install.sh',
    requires = 'hrsh7th/nvim-cmp'
  }

  -- Path
  use {
    'notjedi/nvim-rooter.lua',
    config = function() require 'nvim-rooter'.setup() end
  }

  -- Completion
  use 'windwp/nvim-autopairs'

  -- Tests
  use 'nvim-neotest/neotest-python'
  use 'nvim-neotest/neotest-plenary'
  use 'rouge8/neotest-rust'
  use { 'nvim-neotest/neotest-vim-test', requires = "vim-test/vim-test" }

  use {
    "nvim-neotest/neotest",
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim"
    },
  }

  -- Debuggers
  use 'mfussenegger/nvim-dap'
  use 'theHamsta/nvim-dap-virtual-text'
  use { "rcarriga/nvim-dap-ui", requires = { "mfussenegger/nvim-dap" } }
  use 'mfussenegger/nvim-dap-python'

  -- Latex
  use { 'lervag/vimtex', ft = 'tex' }

  -- Utils
  use 'norcalli/nvim_utils'
  use {
    'iamcco/markdown-preview.nvim',
    run = function() vim.fn["mkdp#util#install"]() end
  }
  use 'urmzd/lume.nvim'
  use 'udalov/kotlin-vim'
  use 'b0O/schemastore.nvim'
  use 'nvim-telescope/telescope-file-browser.nvim'

  use 'jose-elias-alvarez/null-ls.nvim'

  use 'folke/neodev.nvim'

  if PACKER_BOOTSTRAP then require('packer').sync() end
end)
