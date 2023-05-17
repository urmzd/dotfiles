local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	"nvim-lua/plenary.nvim",
	{
		"nathom/filetype.nvim",
		config = function()
			require("filetype").setup({})
		end,
	},
	{ "neovim/nvim-lspconfig" },
	{
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		requires = { "neovim/nvim-lspconfig" },
	},
	{
		"jayp0521/mason-null-ls.nvim",
	},
	{ "sheerun/vim-polyglot" },
	{ "nvim-treesitter/nvim-treesitter", build = ":TsUpdate" },
	{ "tpope/vim-surround" },
	{ "tpope/vim-repeat" },
	{ "tpope/vim-fugitive" },
	{ "tpope/vim-unimpaired" },
	{ "preservim/nerdcommenter" },
	{ "preservim/vimux" },
	"nyoom-engineering/oxocarbon.nvim",
	"ellisonleao/gruvbox.nvim",
	"nvim-tree/nvim-web-devicons",
	{ "nvim-tree/nvim-web-devicons", opt = true },

	"nvim-lualine/lualine.nvim",
	-- Documentation
	{
		"kkoomen/vim-doge",
		build = function()
			vim.fn["doge#install"]()
		end,
	},
	-- Misc
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	},
	{ "folke/lsp-colors.nvim" },
	{
		"folke/trouble.nvim",
		config = function()
			require("trouble").setup({})
		end,
	},
	{
		"folke/todo-comments.nvim",
		config = function()
			require("todo-comments").setup()
		end,
	},
	-- Fuzzy Finder
	"nvim-telescope/telescope.nvim",
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	-- Path
	{
		"ahmedkhalf/project.nvim",
	},
	-- Completion
	{ "windwp/nvim-autopairs" },
	-- Tests
	"nvim-neotest/neotest-plenary",
	"nvim-treesitter/nvim-treesitter",
	"antoinemadec/FixCursorHold.nvim",
	"nvim-neotest/neotest-python",
	"rouge8/neotest-rust",
	"nvim-neotest/neotest",
	-- Debuggers
	{ "mfussenegger/nvim-dap" },
	{ "theHamsta/nvim-dap-virtual-text" },
	{ "rcarriga/nvim-dap-ui" },
	{ "mfussenegger/nvim-dap-python" },
	-- LSP Tools
	{ "lervag/vimtex",                  ft = "tex" },
	{ "simrat39/rust-tools.nvim" },
	{ "mfussenegger/nvim-jdtls" },
	{ "udalov/kotlin-vim" },
	{ "b0O/schemastore.nvim" },
	-- Utils
	{
		"iamcco/markdown-preview.nvim",
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
	},
	{ "urmzd/lume.nvim" },
	{ "jose-elias-alvarez/null-ls.nvim" },
	{ "folke/neodev.nvim" },
	{ "j-hui/fidget.nvim" },
	{ "ms-jpq/chadtree",                branch = "chad",     build = "python3 -m chadtree deps" },
	{ "ms-jpq/coq_nvim",                branch = "coq" },
	{ "ms-jpq/coq.artifacts",           branch = "artifacts" },
	{ "ms-jpq/coq.thirdparty",          branch = "3p" },
	"mbbill/undotree",
	{
		"anuvyklack/pretty-fold.nvim",
		config = function()
			require("pretty-fold").setup()
		end,
	},
	"https://github.com/github/copilot.vim",
	-- Lua
	{
		"folke/which-key.nvim",
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
			require("which-key").setup({
				-- your configuration comes here
				-- or leave it empty to , the default settings
				-- refer to the configuration section below
			})
		end,
	},
})
