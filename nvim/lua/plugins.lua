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
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"rust_analyzer",
					"tsserver",
					"pyright",
					"jdtls",
					"yamlls",
					"bashls",
					"gopls",
				},
			})
			require("mason-null-ls").setup({
				automatic_installation = true,
			})
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
					local nls = require("null-ls")

					local sources = {
						nls.builtins.code_actions.gitsigns,
						nls.builtins.hover.dictionary,
						nls.builtins.formatting.stylua,
						nls.builtins.formatting.prettierd,
						nls.builtins.formatting.beautysh,
						nls.builtins.formatting.taplo,
						nls.builtins.formatting.npm_groovy_lint,
						nls.builtins.formatting.markdownlint,
						nls.builtins.formatting.mdformat,
						nls.builtins.formatting.black,
					}

					nls.setup({
						sources = sources,
						save_after_format = true,
						debounce = 150,
					})
				end,
			},
		},
	},
	{ "sheerun/vim-polyglot" },
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "rust", "python", "c", "lua" },
			})
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
		config = function()
			vim.keymap.set("n", "<leader>v", ":NvimTreeToggle<CR>")
		end,
	},
	-- Documentation
	{
		"kkoomen/vim-doge",
		build = ":call doge#install()",
		config = function()
			vim.g.doge_doc_standard_python = "google"
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
		event = "InsertEnter",
		opts = {},
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
			require("neotest").setup({
				adapters = {
					require("neotest-plenary"),
					require("neotest-python")({
						runner = "pytest",
					}),
					require("neotest-rust"),
				},
			})
		end,
	},
	-- Debuggers
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{ "rcarriga/nvim-dap-ui" },
			{ "mfussenegger/nvim-dap-python", ft = "python" },
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
	},
	{ "j-hui/fidget.nvim" },
	{
		"nvim-tree/nvim-tree.lua",
		version = "*",
		lazy = false,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("nvim-tree").setup({})
		end,
	},

	{
		"zbirenbaum/copilot.lua",
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
			})
		end,
	},
	{ "mbbill/undotree" },
	{
		"anuvyklack/pretty-fold.nvim",
	},

	{
		"Bekaboo/deadcolumn.nvim",
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		opts = {},
	},
	{
		"junegunn/fzf.vim",
		requires = {
			"junegunn/fzf",
			build = ":call fzf#install()",
		},
	},
	{
		"sindrets/diffview.nvim",
	},
	{
		"preservim/vimux",
	},
	{
		"hrsh7th/nvim-cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"onsails/lspkind.nvim",
			"saadparwaiz1/cmp_luasnip",
		},
	},
	{
		"zbirenbaum/copilot-cmp",
		config = function()
			require("copilot_cmp").setup()
		end,
	},
	{
		"ahmedkhalf/project.nvim",
		config = function()
			require("project_nvim").setup({})
		end,
	},
	{
		"hinell/lsp-timeout.nvim",
		dependencies = { "neovim/nvim-lspconfig" },
	},
	{
		"L3MON4D3/LuaSnip",
		version = "v2.0.0",
		build = "make install_jsregexp",
	},
})
