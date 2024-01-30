vim.loader.enable()

vim.g.mapleader = " "

vim.wo.wrap = false

vim.opt.clipboard = "unnamedplus"
vim.opt.relativenumber = true
vim.opt.nu = true
vim.opt.exrc = true
vim.opt.guicursor = ""
vim.opt.hidden = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.scrolloff = 16
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "80"
vim.opt.fileformat = "unix"
vim.opt.nrformats = "alpha"
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("config") .. "/undo"

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Window Movements
vim.keymap.set("n", "<leader>h", ":wincmd h<CR>")
vim.keymap.set("n", "<leader>l", ":wincmd l<CR>")
vim.keymap.set("n", "<leader>k", ":wincmd k<CR>")
vim.keymap.set("n", "<leader>j", ":wincmd j<CR>")

-- Escape
vim.keymap.set("i", "jj", "<ESC>")
vim.keymap.set("i", "jk", "<ESC>")
vim.keymap.set("i", "kk", "<ESC>")
vim.keymap.set("i", "kj", "<ESC>")

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
	pattern = { "*.md" },
	callback = function()
		vim.api.nvim_exec("e", false)
	end,
})

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
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({
				-- Configuration here, or leave empty to use defaults
			})
		end,
	},
	-- add this to your lua/plugins.lua, lua/plugins/init.lua,  or the file you keep your other plugins:
	{
		"numToStr/Comment.nvim",
		opts = {
			-- add any options here
		},
		lazy = false,
	},
	{
		"nyoom-engineering/oxocarbon.nvim",
		--"ellisonleao/gruvbox.nvim",
		priority = 1000,
		config = function()
			--local colorscheme = "gruvbox"
			local colorscheme = "oxocarbon"
			-- light | dark
			local style = "dark"

			vim.opt.termguicolors = true
			vim.opt.background = style

			vim.cmd.colorscheme(colorscheme)
			-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
			-- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
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
			"junegunn/fzf",
			"nvim-telescope/telescope-fzf-native.nvim",
			"nvim-telescope/telescope-project.nvim",
			build = "make",
		},
		config = function()
			local telescope = require("telescope")
			telescope.load_extension("fzf")
			telescope.load_extension("project")

			telescope.setup({
				defaults = {
					layout_strategy = "vertical",
				},
				pickers = {
					find_files = {
						hidden = true,
					},
				},
			})

			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<leader>fp", telescope.extensions.project.project)
			vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
			vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
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
			local function get_python_path()
				local file = io.popen("which python")
				if file == nil then
					return
				end
				local output = file:read("*all")
				file:close()
				return output
			end

			local python_path = get_python_path()

			local dap, dap_ui = require("dap"), require("dapui")

			dap_ui.setup()

			local dap_python = require("dap-python")
			local jdtls = require("jdtls")

			jdtls.setup_dap({ hotcodereplace = "auto" })

			dap_python.setup(python_path)
			dap_python.test_runner = "pytest"

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dap_ui.open()
			end

			dap.listeners.before.event_terminated["dapui_config"] = function()
				dap_ui.close()
			end

			dap.listeners.before.event_exited["dapui_config"] = function()
				dap_ui.close()
			end

			vim.keymap.set("n", "<F5>", dap.continue)
			vim.keymap.set("n", "<F10>", dap.step_over)
			vim.keymap.set("n", "<F11>", dap.step_into)
			vim.keymap.set("n", "<F12>", dap.step_out)
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
	},
	{
		"zbirenbaum/copilot.lua",
		event = { "InsertEnter" },
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
			})
		end,
	},
	{
		"zbirenbaum/copilot-cmp",
		config = function()
			require("copilot_cmp").setup()
		end,
		dependencies = {
			"zbirenbaum/copilot.lua",
		},
	},
	{ "mbbill/undotree" },
	{
		"anuvyklack/pretty-fold.nvim",
	},

	{
		"Bekaboo/deadcolumn.nvim",
	},
	--[[ {
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		opts = {},
	}, ]]
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
			"onsails/lspkind.nvim",
			"saadparwaiz1/cmp_luasnip",
		},
	},
	{
		"L3MON4D3/LuaSnip",
		version = "v2.0.0",
		build = "make install_jsregexp",
	},
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",      -- required
			"nvim-telescope/telescope.nvim", -- optional
			"sindrets/diffview.nvim",     -- optional
		},
		config = true,
	},
	{ "junegunn/fzf",   build = "./install --bin" },
	-- {
	-- 	"folke/flash.nvim",
	-- 	event = "VeryLazy",
	-- 	---@type Flash.Config
	-- 	opts = {},
	-- 	-- stylua: ignore
	-- 	keys = {
	-- 		{ "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
	-- 		{ "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
	-- 		{ "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
	-- 		{ "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
	-- 		{ "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
	-- 	},
	-- },
	{
		"sontungexpt/url-open",
		event = "VeryLazy",
		cmd = "URLOpenUnderCursor",
		config = function()
			local status_ok, url_open = pcall(require, "url-open")
			if not status_ok then
				return
			end
			url_open.setup({})
		end,
	},
	{
		"ahmedkhalf/project.nvim",
		dependencies = {
			"nvim-tree/nvim-tree.lua",
		},
		config = function()
			require("project_nvim").setup({})
			require("nvim-tree").setup({
				sync_root_with_cwd = true,
				respect_buf_cwd = true,
				update_focused_file = {
					enable = true,
					update_root = true,
				},
			})
		end,
	},
	{
		"f-person/git-blame.nvim",
		config = function()
			require("gitblame").setup({
				enabled = false,
			})
		end,
	},
	{
		"olimorris/persisted.nvim",
		config = function()
			require("persisted").setup({})
			require("telescope").load_extension("persisted")
		end,
	},
})