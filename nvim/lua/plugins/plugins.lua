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
		config = function()
			require("plugins.mason")
			require("servers")
		end,
	},
	{ "williamboman/mason-lspconfig.nvim" },
	{
		"jayp0521/mason-null-ls.nvim",
		dependencies = {
			{
				"jose-elias-alvarez/null-ls.nvim",
				config = function()
					require("plugins.null-ls")
				end,
			},
		},
	},

	{ "sheerun/vim-polyglot" },
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("plugins.treesitter")
		end,
	},
	{ "tpope/vim-surround" },
	{ "tpope/vim-repeat" },
	{ "tpope/vim-fugitive" },
	{ "tpope/vim-unimpaired" },
	{ "preservim/nerdcommenter" },
	{
		--"nyoom-engineering/oxocarbon.nvim",
		"ellisonleao/gruvbox.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("theme")
		end,
	},

	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			{ "nvim-tree/nvim-web-devicons" },
		},
	},
	-- Documentation
	{
		"kkoomen/vim-doge",
		build = ":call doge#install()",
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
	{
		"folke/trouble.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {},
	},
	{
		"folke/todo-comments.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
		},
		opts = {},
	},
	-- Fuzzy Finder
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
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
			{ "nvim-neotest/neotest-plenary" },
			{ "nvim-neotest/neotest-python", ft = "python" },
			{ "rouge8/neotest-rust",         ft = "rust" },
		},
		config = function()
			require("plugins.neotest")
		end,
	},
	-- Debuggers
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{ "theHamsta/nvim-dap-virtual-text" },
			{ "rcarriga/nvim-dap-ui" },
			{ "mfussenegger/nvim-dap-python",   ft = "python" },
		},
		config = function()
			require("plugins.dap")
		end,
	},
	-- LSP Tools
	{ "lervag/vimtex",            ft = "tex" },
	{ "simrat39/rust-tools.nvim", ft = "rust" },
	{ "mfussenegger/nvim-jdtls",  ft = "java" },
	{ "udalov/kotlin-vim",        ft = "kotlin" },
	{ "b0O/schemastore.nvim",     ft = { "yaml", "json" } },
	-- Utils
	{
		"iamcco/markdown-preview.nvim",
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		ft = "markdown",
	},
	{ "urmzd/lume.nvim" },
	{
		"folke/neodev.nvim",
		config = function()
			require("plugins.neodev")
		end,
		ft = "lua",
	},
	{ "j-hui/fidget.nvim" },
	{
		"ms-jpq/chadtree",
		branch = "chad",
		build = "python3 -m chadtree deps",
		dependencies = {
			{ "ms-jpq/coq_nvim",      branch = "coq" },
			{ "ms-jpq/coq.artifacts", branch = "artifacts" },
			{
				"ms-jpq/coq.thirdparty",
				branch = "3p",
				config = function()
					require("coq_3p")({
						{ src = "copilot", short_name = "COP", accept_key = "<c-f>" },
						{ src = "dap" },
					})
				end,
			},
		},
		config = function()
			require("plugins.chad-tree")
		end,
	},
	{
		"https://github.com/github/copilot.vim",
	},
	"mbbill/undotree",
	{
		"anuvyklack/pretty-fold.nvim",
	},

	{
		"ahmedkhalf/project.nvim",
		config = function()
			require("project_nvim").setup()
		end,
	},
})
