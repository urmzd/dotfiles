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
vim.o.hlsearch = not vim.o.hlsearch -- Toggles search highlighting on each config load

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
		vim.api.nvim_exec2("e", { -- Reloads markdown files on entry
			output = false,
		})
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
					"pyright",
					"yamlls",
					"bashls",
					"taplo",
					"terraformls",
					"dockerls",
				},
			})
			require("servers") -- Assumes you have a servers.lua for LSP setup
		end,
	},
	{ "williamboman/mason-lspconfig.nvim" },
	{ "sheerun/vim-polyglot" },
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"rust",
					"python",
					"c",
					"lua",
					"javascript",
					"typescript",
					"tsx",
					"json",
					"yaml",
					"toml",
					"markdown",
					"markdown_inline",
					"bash",
					"go",
					"html",
					"css",
					"dockerfile",
					"gitignore",
					"vim",
					"vimdoc",
				},
				sync_install = false,
				auto_install = true,
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
				indent = {
					enable = true,
				},
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "gnn",
						node_incremental = "grn",
						scope_incremental = "grc",
						node_decremental = "grm",
					},
				},
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
						},
					},
				},
			})
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
	},
	{

		"jay-babu/mason-nvim-dap.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"mfussenegger/nvim-dap",
		},
		config = function()
			require("mason-nvim-dap").setup({
				ensure_installed = {
					"python",
				},
				automatic_installation = true,
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
	{
		"numToStr/Comment.nvim",
		opts = {
			-- add any options here
		},
		lazy = false,
	},
	{ "IndianBoy42/tree-sitter-just" },
	{ "nvim-neotest/nvim-nio" },
	{
		"scottmckendry/cyberdream.nvim",
		priority = 1000,
		config = function()
			local colorscheme = "cyberdream"
			local style = "dark" -- light | dark

			require(colorscheme).setup({
				transparent = false,
				italic_comments = true,
				hide_fillchars = true,
				borderless_telescope = true,
			})

			-- Lualine set for cyberdream theme
			require("lualine").setup({
					options = {
						theme = "cyberdream",
					},
					sections = {
						lualine_x = {
							"copilot",
							"encoding",
							"fileformat",
							"filetype",
						},
					},
				})

			vim.opt.termguicolors = true
			vim.opt.background = style
			vim.cmd.colorscheme(colorscheme)
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			{ "nvim-tree/nvim-web-devicons" },
			{ "AndreM222/copilot-lualine" },
		}
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
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { { "nvim-lua/plenary.nvim" } },
		opts = {},
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		config = function()
			vim.keymap.set("n", "<leader>v", ":Neotree toggle<CR>", { desc = "Toggle NeoTree" })
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"junegunn/fzf",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			"nvim-telescope/telescope-project.nvim",
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
			vim.keymap.set("n", "<leader>fp", telescope.extensions.project.project, { desc = "Find Project" })
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help Tags" })
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("telescope").load_extension("ui-select")
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
			{ "rouge8/neotest-rust", ft = "rust" },
		},
		config = function()
			require("neotest").setup({
				adapters = {
					require("neotest-plenary"),
					require("neotest-python")({
						runner = "pytest",
						dap_adapter = "python", -- Crucial for DAP integration
						dap_adapter_config = { -- Template for DAP configuration when debugging tests
							type = "python",
							request = "launch",
							name = "Debug Test (neotest)",
							module = "pytest",
							console = "integratedTerminal",
							justMyCode = false,
						},
						dap_test_only = true,
					}),
					require("neotest-rust"),
				},
				-- Optional: You can add a global DAP strategy preference
				-- dap_strategy = "toggle",
			})

			-- New Neotest Keymaps (more structured)
			local neotest = require("neotest")

			-- Run tests
			vim.keymap.set("n", "<leader>trc", function()
				neotest.run.run()
			end, { desc = "Test: Run Closest/Cursor" })
			vim.keymap.set("n", "<leader>trf", function()
				neotest.run.run(vim.fn.expand("%"))
			end, { desc = "Test: Run File" })
			vim.keymap.set("n", "<leader>trl", function()
				neotest.run.run_last()
			end, { desc = "Test: Run Last" })

			-- Debug tests
			vim.keymap.set("n", "<leader>tdc", function()
				neotest.run.run({ strategy = "dap" })
			end, { desc = "Test: Debug Closest/Cursor" })
			vim.keymap.set("n", "<leader>tdf", function()
				neotest.run.run_file({ strategy = "dap", file_path = vim.fn.expand("%") })
			end, { desc = "Test: Debug File" })
			vim.keymap.set("n", "<leader>tdl", function()
				neotest.run.run_last({ strategy = "dap" })
			end, { desc = "Test: Debug Last Run" })

			-- View/Manage Test UI
			vim.keymap.set("n", "<leader>ts", function()
				neotest.summary.toggle()
			end, { desc = "Test: Summary (Toggle)" })
			vim.keymap.set("n", "<leader>to", function()
				neotest.output.open({ enter = true })
			end, { desc = "Test: Output (Open Focused/Last)" })
			vim.keymap.set("n", "<leader>tp", function()
				neotest.output_panel.toggle()
			end, { desc = "Test: Output Panel (Toggle)" })
			vim.keymap.set("n", "<leader>tx", function()
				neotest.run.stop()
			end, { desc = "Test: Stop Execution" })
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
			local dap, dap_ui = require("dap"), require("dapui")
			dap_ui.setup() -- Setup nvim-dap-ui

			-- Python DAP setup using nvim-dap-python
			local dap_python_ok, dap_python = pcall(require, "dap-python")
			if dap_python_ok then
				dap_python.setup() -- Call setup without arguments for auto-detection
				dap_python.test_runner = "pytest" -- Specify pytest as the test runner
				vim.notify(
					"nvim-dap-python setup successful with auto-detection. Test runner: pytest.",
					vim.log.levels.INFO
				)
			else
				vim.notify("Error: nvim-dap-python plugin not found or failed to load.", vim.log.levels.ERROR)
			end

			-- Java DAP setup
			local jdtls_ok, jdtls = pcall(require, "jdtls")
			if jdtls_ok then
				jdtls.setup_dap({ hotcodereplace = "auto" })
			end

			-- DAP UI listeners
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dap_ui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dap_ui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dap_ui.close()
			end

			-- DAP Keymaps
			-- Preserve existing F-key mappings
			vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP: Continue" })
			vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP: Step Over" })
			vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP: Step Into" })
			vim.keymap.set("n", "<F12>", dap.step_out, { desc = "DAP: Step Out" })

			-- Preserve existing breakpoint mappings
			vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>dB", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "DAP: Set Conditional Breakpoint" })

			-- New & Enhanced DAP Keymaps
			-- Stepping alternatives (more mnemonic)
			vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP: Continue (Alt)" })
			vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "DAP: Step Over (Alt)" })
			vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP: Step Into (Alt)" })
			vim.keymap.set("n", "<leader>du", dap.step_out, { desc = "DAP: Step Out (Alt)" })

			-- Session Management
			vim.keymap.set("n", "<leader>ds", function()
				dap.continue()
			end, { desc = "DAP: Start/Select Session (Prompts)" })
			vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "DAP: Run Last Session" })
			vim.keymap.set("n", "<leader>dq", dap.terminate, { desc = "DAP: Quit/Terminate Session" })
			vim.keymap.set("n", "<leader>dr", dap.restart, { desc = "DAP: Restart Session" })

			-- REPL
			vim.keymap.set("n", "<leader>dR", dap.repl.open, { desc = "DAP: Open REPL" })

			-- Breakpoints extended
			vim.keymap.set("n", "<leader>dp", function()
				dap.set_breakpoint(nil, nil, vim.fn.input("Log message: "))
			end, { desc = "DAP: Set Log Point" })
			vim.keymap.set("n", "<leader>dC", function()
				dap.clear_breakpoints()
			end, { desc = "DAP: Clear Breakpoints (Buffer/Session)" })

			-- DAP UI & Inspection
			vim.keymap.set("n", "<leader>dui", function()
				require("dapui").toggle()
			end, { desc = "DAP: Toggle UI" })
			vim.keymap.set("n", "<leader>de", function()
				require("dapui").eval()
			end, { desc = "DAP: Evaluate Expression (Cursor/Prompt)" })
			vim.keymap.set("n", "<leader>dw", function()
				require("dapui").eval(nil, { enter = true })
			end, { desc = "DAP: Add Expression to Watch via Eval" })
		end,
	},
	-- LSP Tools
	{ "lervag/vimtex", ft = "tex" },
	{ "simrat39/rust-tools.nvim", ft = "rust" },
	{ "mfussenegger/nvim-jdtls", ft = "java" },
	{ "udalov/kotlin-vim", ft = "kotlin" },
	{ "b0O/schemastore.nvim", ft = { "yaml", "json" } },
	-- Utils
	{
		"iamcco/markdown-preview.nvim",
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		ft = "markdown",
	},
	{ "urmzd/lume.nvim" },
	{ "folke/neodev.nvim", opts = {} },
	{ "j-hui/fidget.nvim", opts = {} },
	-- copilot stuff
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
		dependencies = { "zbirenbaum/copilot.lua" },
		config = function()
			require("copilot_cmp").setup()
		end,
	},
	{ "mbbill/undotree" },
	{ "Bekaboo/deadcolumn.nvim", opts = {} },
	{ "sindrets/diffview.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
	{
		"preservim/vimux",
		config = function()
			vim.keymap.set("n", "<leader>vp", ":VimuxPromptCommand<CR>", { desc = "Vimux Prompt Command" })
			vim.keymap.set("n", "<leader>vl", ":VimuxRunLastCommand<CR>", { desc = "Vimux Run Last Command" })
			vim.keymap.set("n", "<leader>vr", function()
				local filetype = vim.bo.filetype
				local command = ""
				if filetype == "python" then
					command = "python " .. vim.fn.expand("%")
				elseif filetype == "javascript" then
					command = "node " .. vim.fn.expand("%")
				elseif filetype == "rust" then
					command = "cargo run"
				elseif filetype == "sh" then
					command = "./" .. vim.fn.expand("%")
				end
				if command ~= "" then
					vim.cmd('VimuxRunCommand "' .. command .. '"')
				else
					print("No Vimux run command defined for filetype: " .. filetype)
				end
			end, { desc = "Vimux Run Current File" })
		end,
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
			"zbirenbaum/copilot-cmp",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local lspkind = require("lspkind")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "copilot" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
				}),
				formatting = {
					format = lspkind.cmp_format({
						mode = "symbol_text",
						maxwidth = 50,
						ellipsis_char = "...",
					}),
				},
			})
		end,
	},
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			-- require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"sindrets/diffview.nvim",
		},
		config = true,
	},
	{ "junegunn/fzf", build = "./install --bin" },
	{
		"sontungexpt/url-open",
		event = "VeryLazy",
		cmd = "URLOpenUnderCursor",
		config = function()
			require("url-open").setup({})
		end,
	},
	{
		"ahmedkhalf/project.nvim",
		config = function()
			require("project_nvim").setup({})
		end,
	},
	{
		"f-person/git-blame.nvim",
		config = function()
			require("gitblame").setup({
				enabled = false,
			})
			vim.keymap.set("n", "<leader>gb", function()
				local gb = require("gitblame")
				if gb.is_blame_enabled_for_buffer() then
					gb.close()
				else
					gb.popup_blame()
				end
			end, { desc = "Toggle Git Blame" })
		end,
	},
	{
		"chentoast/marks.nvim",
		config = function()
			require("marks").setup({})
		end,
	},
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
		},
		keys = {
			{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
			{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
		},
	},
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("refactoring").setup()

			vim.keymap.set({ "n", "x" }, "<leader>re", function()
				return require("refactoring").refactor("Extract Function")
			end, { expr = true })
			vim.keymap.set({ "n", "x" }, "<leader>rf", function()
				return require("refactoring").refactor("Extract Function To File")
			end, { expr = true })
			vim.keymap.set({ "n", "x" }, "<leader>rv", function()
				return require("refactoring").refactor("Extract Variable")
			end, { expr = true })
			vim.keymap.set({ "n", "x" }, "<leader>rI", function()
				return require("refactoring").refactor("Inline Function")
			end, { expr = true })
			vim.keymap.set({ "n", "x" }, "<leader>ri", function()
				return require("refactoring").refactor("Inline Variable")
			end, { expr = true })

			vim.keymap.set({ "n", "x" }, "<leader>rbb", function()
				return require("refactoring").refactor("Extract Block")
			end, { expr = true })
			vim.keymap.set({ "n", "x" }, "<leader>rbf", function()
				return require("refactoring").refactor("Extract Block To File")
			end, { expr = true })

			require("telescope").load_extension("refactoring")

			vim.keymap.set({ "n", "x" }, "<leader>rr", function()
				require("telescope").extensions.refactoring.refactors()
			end)
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				python = { "ruff_fix", "ruff_format" },
				lua = { "stylua" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
		},
	},
})

-- Undotree Keymap
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Toggle Undotree" })

-- Keymap to toggle hlsearch
vim.keymap.set("n", "<leader>/", "<cmd>set hlsearch!<CR>", { desc = "Toggle Highlight Search" })
