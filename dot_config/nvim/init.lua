vim.loader.enable()

vim.g.mapleader = " "

vim.wo.wrap = false

-- OPTIMIZED: Detect subprocess/non-interactive environment
-- This is crucial for Claude Code performance - incorrect detection causes hangs
-- Uses TTY detection as primary method with env var fallback

local is_subprocess = false

-- Step 1: PRIMARY CHECK - TTY detection (most reliable)
-- If stdin is not a TTY (terminal), it's likely a pipe/subprocess
local stdin_handle = vim.loop.guess_handle(0)
if stdin_handle ~= "tty" then
	is_subprocess = true
end

-- Step 2: FALLBACK - Check specific subprocess indicators
-- Only check explicit subprocess flags, not broad env vars like CLAUDECODE
if not is_subprocess then
	is_subprocess = vim.env.NVIM_SUBPROCESS == "1" or vim.env.CLAUDE_CODE_ENTRYPOINT ~= nil -- More specific than CLAUDECODE
end

-- Conditionally enable clipboard sync only in interactive environments
-- In subprocesses, clipboard sync can cause hanging/freezing
if not is_subprocess then
	vim.opt.clipboard = "unnamedplus"

	-- Cross-platform clipboard provider
	if vim.fn.has("mac") == 1 then
		vim.g.clipboard = {
			name = "macOS-clipboard",
			copy = {
				["+"] = "pbcopy",
				["*"] = "pbcopy",
			},
			paste = {
				["+"] = "pbpaste",
				["*"] = "pbpaste",
			},
			cache_enabled = 0,
		}
	elseif vim.fn.has("unix") == 1 then
		-- Check for Wayland first, then fall back to X11
		if vim.env.WAYLAND_DISPLAY then
			vim.g.clipboard = {
				name = "wayland-clipboard",
				copy = {
					["+"] = "wl-copy",
					["*"] = "wl-copy",
				},
				paste = {
					["+"] = "wl-paste",
					["*"] = "wl-paste",
				},
				cache_enabled = 0,
			}
		else
			vim.g.clipboard = {
				name = "xclip-clipboard",
				copy = {
					["+"] = "xclip -selection clipboard",
					["*"] = "xclip -selection primary",
				},
				paste = {
					["+"] = "xclip -selection clipboard -o",
					["*"] = "xclip -selection primary -o",
				},
				cache_enabled = 0,
			}
		end
	end
else
	-- Explicitly disable clipboard in subprocess to prevent hangs
	vim.opt.clipboard = ""
end

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

-- Buffer and Window Navigation

-- Window navigation - Leader key for all directions
vim.keymap.set("n", "<leader>h", ":wincmd h<CR>", { desc = "Move to left window" })
vim.keymap.set("n", "<leader>j", ":wincmd j<CR>", { desc = "Move to window below" })
vim.keymap.set("n", "<leader>k", ":wincmd k<CR>", { desc = "Move to window above" })
vim.keymap.set("n", "<leader>l", ":wincmd l<CR>", { desc = "Move to right window" })
-- Note: Ctrl-h/j/k/l also work via vim-tmux-navigator for seamless tmux integration

-- Window splitting - Mirror tmux keybindings
vim.keymap.set("n", "<leader>|", ":vsplit<CR>", { desc = "Split window vertically (open current buffer)" })
vim.keymap.set("n", "<leader>-", ":split<CR>", { desc = "Split window horizontally (open current buffer)" })

-- Window resizing - Mirror tmux's H/J/K/L pattern (resize in each direction)
vim.keymap.set("n", "<leader>H", ":vertical resize -5<CR>", { desc = "Resize window left" })
vim.keymap.set("n", "<leader>J", ":resize +5<CR>", { desc = "Resize window down" })
vim.keymap.set("n", "<leader>K", ":resize -5<CR>", { desc = "Resize window up" })
vim.keymap.set("n", "<leader>L", ":vertical resize +5<CR>", { desc = "Resize window right" })

-- Window management
vim.keymap.set("n", "<leader>o", ":only<CR>", { desc = "Close all other windows" })
vim.keymap.set("n", "<leader>=", "<C-w>=", { desc = "Equalize all window sizes" })

-- Buffer cycling - Tab key (normal mode only, doesn't affect insert/command mode)
vim.keymap.set("n", "<Tab>", function()
	local state = vim.b[vim.api.nvim_get_current_buf()].nes_state
	if state then
		if not require("copilot-lsp.nes").walk_cursor_start_edit() then
			require("copilot-lsp.nes").apply_pending_nes()
			require("copilot-lsp.nes").walk_cursor_end_edit()
		end
	else
		vim.cmd("BufferLineCycleNext")
	end
end, { desc = "Copilot NES or next buffer" })
vim.keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })

-- Buffer cycling - gt prefix (like tab navigation)
vim.keymap.set("n", "gtn", "<cmd>BufferLineCycleNext<CR>", { desc = "Go to next buffer" })
vim.keymap.set("n", "gtp", "<cmd>BufferLineCyclePrev<CR>", { desc = "Go to previous buffer" })

-- Additional buffer commands
vim.keymap.set("n", "<leader>bp", "<cmd>BufferLinePick<CR>", { desc = "Pick buffer" })
vim.keymap.set("n", "<leader>bc", "<cmd>bdelete<CR>", { desc = "Close buffer" })
vim.keymap.set("n", "<leader>bse", "<cmd>BufferLineSortByExtension<CR>", { desc = "Sort buffers by extension" })
vim.keymap.set("n", "<leader>bsd", "<cmd>BufferLineSortByDirectory<CR>", { desc = "Sort buffers by directory" })

-- Escape
vim.keymap.set("n", "<Esc>", function()
	if not require("copilot-lsp.nes").clear() then
		vim.cmd("nohlsearch")
	end
end, { desc = "Clear Copilot NES or search highlight" })

vim.keymap.set("i", "jj", "<ESC>")
vim.keymap.set("i", "jk", "<ESC>")
vim.keymap.set("i", "kk", "<ESC>")
vim.keymap.set("i", "kj", "<ESC>")

-- Diagnostics
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

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

vim.lsp.config("mdx_analyzer", {
	capabilities = {
		workspace = {
			didChangeWatchedFiles = {
				dynamicRegistration = false,
			},
		},
	},
})

require("lazy").setup({
	{ "neovim/nvim-lspconfig" },
	{
		"copilotlsp-nvim/copilot-lsp",
		init = function()
			vim.g.copilot_nes_debounce = 500
			vim.lsp.enable("copilot_ls")
		end,
		config = function()
			require("copilot-lsp").setup()
		end,
	},
	{
		"mason-org/mason.nvim",
		opts = {},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			ensure_installed = {
				"lua_ls",
				"basedpyright",
				"rust_analyzer",
				"gopls",
				"terraformls",
				"dockerls",
				"jsonls",
				"yamlls",
				"bashls",
				"ts_ls",
				"marksman",
				"mdx_analyzer",
				"astro",
			},
			automatic_enable = true,
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				"ruff",
				"stylua",
				"biome",
				"goimports",
				"gofumpt",
				"shfmt",
				"google-java-format",
				"yamlfmt",
			},
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
		},
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		init = function()
			vim.g.no_plugin_maps = true
		end,
		config = function() end,
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
					"java",
					"golang",
					"rust",
					"typescript",
				},
				automatic_installation = true,
			})
		end,
	},
	{
		"kylechui/nvim-surround",
		version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
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
	{
		"IndianBoy42/tree-sitter-just",
		config = function()
			require("tree-sitter-just").setup({})
		end,
	},
	{
		"scottmckendry/cyberdream.nvim",
		priority = 1000,
		lazy = false,
		config = function()
			local colorscheme = "cyberdream"
			local style = "dark" -- light | dark

			require(colorscheme).setup({
				transparent = true,
				italic_comments = true,
				hide_fillchars = true,
				borderless_telescope = true,
			})

			-- Build lualine_x components conditionally
			local lualine_x_components = vim.tbl_filter(function(component)
				return component ~= nil
			end, {
				{
					-- Trouble status indicator
					function()
						local ok, trouble = pcall(require, "trouble")
						if ok and trouble.is_open() then
							return "Trouble"
						end
						return ""
					end,
					icon = "",
					color = { fg = "#f7768e" },
				},
				"encoding",
				"fileformat",
				"filetype",
			})

			-- Lualine set for cyberdream theme
			require("lualine").setup({
				options = {
					theme = "cyberdream",
				},
				sections = {
					lualine_c = {
						"filename",
						{
							"diagnostics",
							sources = { "nvim_diagnostic" },
							sections = { "error", "warn", "info", "hint" },
							symbols = { error = " ", warn = " ", info = " ", hint = " " },
							update_in_insert = false,
							always_visible = false,
						},
						{
							-- Current line diagnostic
							function()
								local line_diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
								if #line_diagnostics > 0 then
									local diag = line_diagnostics[1]
									local message = diag.message:gsub("\n", " "):sub(1, 50)
									if #diag.message > 50 then
										message = message .. "..."
									end
									return message
								end
								return ""
							end,
							icon = "",
							color = { fg = "#7aa2f7" },
						},
					},
					lualine_x = lualine_x_components,
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
		},
	},
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = "nvim-tree/nvim-web-devicons",
		opts = {
			options = {
				mode = "buffers",
				themable = true,
				numbers = "none",
				close_command = "bdelete! %d",
				right_mouse_command = "bdelete! %d",
				left_mouse_command = "buffer %d",
				middle_mouse_command = nil,
				indicator = {
					icon = "▎",
					style = "icon",
				},
				buffer_close_icon = "󰅖",
				modified_icon = "●",
				close_icon = "",
				left_trunc_marker = "",
				right_trunc_marker = "",
				max_name_length = 18,
				max_prefix_length = 15,
				truncate_names = true,
				tab_size = 18,
				diagnostics = "nvim_lsp",
				diagnostics_update_in_insert = false,
				diagnostics_indicator = function(count, level, diagnostics_dict, context)
					local icon = level:match("error") and " " or " "
					return " " .. icon .. count
				end,
				offsets = {
					{
						filetype = "neo-tree",
						text = "File Explorer",
						text_align = "center",
						separator = true,
					},
				},
				color_icons = true,
				show_buffer_icons = true,
				show_buffer_close_icons = true,
				show_close_icon = false,
				show_tab_indicators = true,
				show_duplicate_prefix = true,
				persist_buffer_sort = true,
				separator_style = "thin",
				enforce_regular_tabs = false,
				always_show_bufferline = true,
				hover = {
					enabled = true,
					delay = 200,
					reveal = { "close" },
				},
				sort_by = "insert_after_current",
			},
		},
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
		opts = {
			modes = {
				diagnostics = {
					auto_open = false,
					auto_close = false,
					auto_preview = true,
					auto_refresh = true,
				},
			},
		},
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xd",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>xl",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xq",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("neo-tree").setup({
				filesystem = {
					follow_current_file = {
						enabled = true, -- Automatically reveal and focus current file
						leave_dirs_open = false, -- Close folders when moving to another file
					},
					hijack_netrw_behavior = "open_current",
				},
				window = {
					mappings = {
						["Z"] = "expand_all_nodes",
						["z"] = "close_all_nodes",
					},
				},
			})
			vim.keymap.set("n", "<leader>v", ":Neotree toggle<CR>", { desc = "Toggle NeoTree" })
		end,
		lazy = false,
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
			{ "nvim-neotest/nvim-nio" },
			{ "nvim-lua/plenary.nvim" },
			{ "antoinemadec/FixCursorHold.nvim" },
			{ "nvim-neotest/neotest-python", ft = "python" },
			{ "rouge8/neotest-rust", ft = "rust" },
		},
		config = function()
			require("neotest").setup({
				adapters = {
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
		"theHamsta/nvim-dap-virtual-text",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			enabled = true,
			all_frames = true,
			virt_text_pos = "eol",
			highlight_changed_variables = true,
			highlight_new_as_changed = true,
		},
	},
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
	{ "mfussenegger/nvim-jdtls", ft = "java" },
	{ "b0O/schemastore.nvim", ft = { "yaml", "json" } },
	-- Utils
	{
		"iamcco/markdown-preview.nvim",
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		ft = "markdown",
	},
	{ "j-hui/fidget.nvim", opts = {} },
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "helix",
			delay = 300,
			icons = {
				mappings = true,
				keys = {},
			},
			spec = {
				{ "<leader>b", group = "buffer" },
				{ "<leader>d", group = "debug" },
				{ "<leader>f", group = "find" },
				{ "<leader>t", group = "test" },
				{ "<leader>v", group = "vimux" },
				{ "<leader>x", group = "trouble" },
			},
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps",
			},
		},
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
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {},
		},
	},
	{
		"saghen/blink.cmp",
		dependencies = {
			"rafamadriz/friendly-snippets",
			"fang2hou/blink-copilot",
		},
		version = "1.*",
		opts = {
			cmdline = { keymap = { preset = "default" } },
			keymap = {
				preset = "default",
				["<CR>"] = { "select_and_accept", "fallback" },
				["<Tab>"] = {
					function(cmp)
						if vim.b[vim.api.nvim_get_current_buf()].nes_state then
							cmp.hide()
							require("copilot-lsp.nes").apply_pending_nes()
							require("copilot-lsp.nes").walk_cursor_end_edit()
							return true
						end
					end,
					"snippet_forward",
					"fallback",
				},
			},
			appearance = { nerd_font_variant = "mono" },
			completion = {
				documentation = { auto_show = false },
				ghost_text = { enabled = true },
			},
			snippets = { preset = "luasnip" },
			sources = {
				default = { "copilot", "lsp", "snippets", "buffer", "path", "lazydev" },
				providers = {
					copilot = {
						name = "copilot",
						module = "blink-copilot",
						score_offset = 75,
						async = true,
						opts = {
							max_completions = 3,
							max_attempts = 4,
						},
					},
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
						score_offset = 100,
					},
					lsp = {
						name = "LSP",
						module = "blink.cmp.sources.lsp",
						transform_items = function(_, items)
							return vim.tbl_filter(function(item)
								return not (
									item.client_name
									and string.find(string.lower(item.client_name), "copilot")
								)
							end, items)
						end,
					},
				},
			},
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
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
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				python = { "ruff_fix", "ruff_format" },
				lua = { "stylua" },
				rust = { "rustfmt", lsp_format = "fallback" },
				go = { "goimports", "gofumpt" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				java = { "google-java-format", lsp_format = "fallback" },
				javascript = { "biome" },
				typescript = { "biome" },
				javascriptreact = { "biome" },
				typescriptreact = { "biome" },
				json = { "biome" },
				jsonc = { "biome" },
				yaml = { "yamlfmt" },
				html = { "biome" },
				css = { "biome" },
				astro = { "biome" },
				terraform = { lsp_format = "prefer" },
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
