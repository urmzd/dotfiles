-- Bootstrap `packer.nvim`.
local bootstrap_packer = function()
  local paths = require("utils.path")
  local install_path = paths.install_dir

  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.system({
      "git",
      "clone",
      "--depth",
      "1",
      "https://github.com/wbthomason/packer.nvim",
      install_path,
    })
    vim.cmd("packadd packer.nvim")
    return true
  else
    return false
  end
end

local packer_bootstrapped = bootstrap_packer()

-- Install plugins.
local packer = require("packer")

packer.startup(function(use)
  use("wbthomason/packer.nvim")
  use({
    "nathom/filetype.nvim",
    config = function()
      require("filetype").setup({})
    end,
  })

  use({
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",
  })

  use("sheerun/vim-polyglot")
  use({ "nvim-treesitter/nvim-treesitter", run = ":TsUpdate" })

  use("tpope/vim-surround")
  use("tpope/vim-repeat")
  use("tpope/vim-fugitive")
  use("tpope/vim-unimpaired")

  use("preservim/nerdcommenter")
  use("preservim/vimux")

  -- Themes
  use("ayu-theme/ayu-vim")
  use("nyoom-engineering/oxocarbon.nvim")

  --
  use({
    "nvim-lualine/lualine.nvim",
    requires = { "kyazdani42/nvim-web-devicons", opt = true },
  })

  -- Documentation
  use({
    "kkoomen/vim-doge",
    run = function()
      vim.fn["doge#install"]()
    end,
  })

  -- Misc
  use({
    "lewis6991/gitsigns.nvim",
    requires = { "nvim-lua/plenary.nvim" },
    config = function()
      require("gitsigns").setup()
    end,
  })
  use("folke/lsp-colors.nvim")
  use({
    "folke/trouble.nvim",
    requires = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("trouble").setup({})
    end,
  })
  use({
    "folke/todo-comments.nvim",
    requires = "nvim-lua/plenary.nvim",
    config = function()
      require("todo-comments").setup()
    end,
  })

  -- Fuzzy Finder
  use({
    "nvim-telescope/telescope.nvim",
    requires = { { "nvim-lua/plenary.nvim" } },
  })
  use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" })

  -- Completion
  use("hrsh7th/nvim-cmp") -- Autocompletion plugin
  use("hrsh7th/cmp-nvim-lsp") -- LSP source for nvim-cmp
  use("saadparwaiz1/cmp_luasnip") -- Snippets source for nvim-cmp
  use("L3MON4D3/LuaSnip") -- Snippets plugin
  use({
    "tzachar/cmp-tabnine",
    run = "./install.sh",
    requires = "hrsh7th/nvim-cmp",
  })

  -- Path
  use({ "ahmedkhalf/project.nvim" })

  -- Completion
  use("windwp/nvim-autopairs")

  -- Tests
  use({
    "nvim-neotest/neotest",
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      -- OPTIONAL
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-plenary",
      "rouge8/neotest-rust",
    },
  })

  -- Debuggers
  use("mfussenegger/nvim-dap")
  use("theHamsta/nvim-dap-virtual-text")
  use({ "rcarriga/nvim-dap-ui", requires = { "mfussenegger/nvim-dap" } })
  use("mfussenegger/nvim-dap-python")

  -- Latex
  use({ "lervag/vimtex", ft = "tex" })
  use("simrat39/rust-tools.nvim")
  use("mfussenegger/nvim-jdtls")
  use("udalov/kotlin-vim")
  use("b0O/schemastore.nvim")

  -- Utils
  use({
    "iamcco/markdown-preview.nvim",
    run = function()
      vim.fn["mkdp#util#install"]()
    end,
  })
  use("urmzd/lume.nvim")
  use("jose-elias-alvarez/null-ls.nvim")
  use("folke/neodev.nvim")
  use("j-hui/fidget.nvim")
  use({
    "nvim-tree/nvim-tree.lua",
    requires = {
      "nvim-tree/nvim-web-devicons", -- optional, for file icons
    },
    tag = "nightly", -- optional, updated every week. (see issue #1193)
  })

  if packer_bootstrapped then
    packer.sync()
  end
end)