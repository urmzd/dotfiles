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
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
	},
	{
		"williamboman/mason.nvim",
		dependencies = { "neovim/nvim-lspconfig" },
		config = function()
			require("plugins.mason")
			require("servers")
		end,
	},
	{ "williamboman/mason-lspconfig.nvim" },
	{
		"jayp0521/mason-null-ls.nvim",
	},
	{ "sheerun/vim-polyglot" },
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TsUpdate",
		config = function()
			require("plugins.treesitter")
		end
	},
	{ "tpope/vim-surround" },
	{ "tpope/vim-repeat" },
	{ "tpope/vim-fugitive" },
	{ "tpope/vim-unimpaired" },
	{ "preservim/nerdcommenter" },
	{ "preservim/vimux" },
	{
		"nyoom-engineering/oxocarbon.nvim",
		--"ellisonleao/gruvbox.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("theme")
		end,
	},

	{ "nvim-tree/nvim-web-devicons", opt = true },

	{ "nvim-lualine/lualine.nvim" },
	-- Documentation
	{
		"kkoomen/vim-doge",
		build = function()
			vim.fn["doge#install"]()
		end,
		config = function()
			require("plugins.doge")
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
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-telescope/telescope-fzf-native.nvim", build = "make"
		},
		config = function()
			require("plugins.telescope")
		end,
	},
	-- Completion
	{
		"windwp/nvim-autopairs",
		config = function()
			require("plugins.autopairs")
		end,
	},
	-- Tests
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/neotest-plenary",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-neotest/neotest-python",
			"rouge8/neotest-rust",
		},
		config = function()
			require("plugins.neotest")
		end
	},
	-- Debuggers
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{ "theHamsta/nvim-dap-virtual-text" },
			{ "rcarriga/nvim-dap-ui" },
			{ "mfussenegger/nvim-dap-python" },
		},
		config = function()
			require("plugins.dap")
		end,
	},
	-- LSP Tools
	{ "lervag/vimtex",           ft = "tex" },
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
	{
		"folke/neodev.nvim",
		config = function()
			require("plugins.neodev")
		end
	},
	{ "j-hui/fidget.nvim" },
	{
		"ms-jpq/chadtree",
		branch = "chad",
		build = "python3 -m chadtree deps",
		dependencies = {
			{ "ms-jpq/coq_nvim",       branch = "coq" },
			{ "ms-jpq/coq.artifacts",  branch = "artifacts" },
			{ "ms-jpq/coq.thirdparty", branch = "3p" },
		},
		config = function()
			require("plugins.chad-tree")
		end,
	},
	"mbbill/undotree",
	{
		"anuvyklack/pretty-fold.nvim",
		config = function()
			require("pretty-fold").setup()
		end,
	},
	"https://github.com/github/copilot.vim",
})
