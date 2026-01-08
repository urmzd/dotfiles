local M = {}
local dap = require("dap")
local dapui = require("dapui")

-- ============================================================================
-- PERSISTENT BREAKPOINTS
-- ============================================================================

local breakpoints_file = vim.fn.stdpath("config") .. "/breakpoints.json"

-- Load breakpoints from disk
local function load_breakpoints()
	if vim.fn.filereadable(breakpoints_file) == 1 then
		local content = vim.fn.readfile(breakpoints_file)
		local json_str = table.concat(content, "\n")
		local ok, data = pcall(vim.fn.json_decode, json_str)
		if ok then
			return data
		end
	end
	return {}
end

-- Save breakpoints to disk
local function save_breakpoints()
	local breakpoints = {}
	for buf, buf_breakpoints in pairs(dap.breakpoints) do
		for _, bp in ipairs(buf_breakpoints) do
			if not breakpoints[buf] then
				breakpoints[buf] = {}
			end
			table.insert(breakpoints[buf], {
				line = bp.line,
				condition = bp.condition,
				log_message = bp.log_message,
			})
		end
	end
	vim.fn.writefile({ vim.fn.json_encode(breakpoints) }, breakpoints_file)
end

-- Restore breakpoints on startup
local function restore_breakpoints()
	local saved_breakpoints = load_breakpoints()
	for buf_path, bp_list in pairs(saved_breakpoints) do
		for _, bp in ipairs(bp_list) do
			dap.set_breakpoint(bp.condition, bp.log_message, tonumber(bp.line))
		end
	end
end

-- ============================================================================
-- DEBUG CONFIGURATIONS
-- ============================================================================

-- Python Debug Config with Quick Launch
local function setup_python_debug()
	if not dap.configurations.python then
		dap.configurations.python = {}
	end

	-- Standard Python debugger
	table.insert(dap.configurations.python, {
		type = "python",
		request = "launch",
		name = "Launch Python (Current File)",
		program = "${file}",
		pythonPath = function()
			-- Try to detect venv
			local venv = os.getenv("VIRTUAL_ENV")
			if venv then
				return venv .. "/bin/python"
			end
			return "/usr/bin/python3"
		end,
		console = "integratedTerminal",
		justMyCode = false,
	})

	-- Python with module
	table.insert(dap.configurations.python, {
		type = "python",
		request = "launch",
		name = "Launch Python Module",
		module = function()
			return vim.fn.input("Module name: ")
		end,
		pythonPath = function()
			local venv = os.getenv("VIRTUAL_ENV")
			if venv then
				return venv .. "/bin/python"
			end
			return "/usr/bin/python3"
		end,
		console = "integratedTerminal",
		justMyCode = false,
	})

	-- Pytest
	table.insert(dap.configurations.python, {
		type = "python",
		request = "launch",
		name = "Debug Pytest (Current File)",
		module = "pytest",
		args = { "${file}", "-v", "-s" },
		pythonPath = function()
			local venv = os.getenv("VIRTUAL_ENV")
			if venv then
				return venv .. "/bin/python"
			end
			return "/usr/bin/python3"
		end,
		console = "integratedTerminal",
		justMyCode = false,
	})
end

-- Rust Debug Config
local function setup_rust_debug()
	if not dap.configurations.rust then
		dap.configurations.rust = {}
	end

	table.insert(dap.configurations.rust, {
		type = "lldb",
		request = "launch",
		name = "Debug Rust Binary",
		cargo = "build",
		args = {},
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		console = "integratedTerminal",
	})

	table.insert(dap.configurations.rust, {
		type = "lldb",
		request = "launch",
		name = "Debug Rust Tests",
		cargo = "test",
		args = { "--lib" },
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		console = "integratedTerminal",
	})
end

-- Go Debug Config
local function setup_go_debug()
	if not dap.configurations.go then
		dap.configurations.go = {}
	end

	table.insert(dap.configurations.go, {
		type = "delve",
		request = "launch",
		name = "Debug Go (Current File)",
		program = "${file}",
		mode = "debug",
		dlvToolPath = vim.fn.exepath("dlv"),
	})

	table.insert(dap.configurations.go, {
		type = "delve",
		request = "launch",
		name = "Debug Go Tests",
		mode = "test",
		program = "${fileDirname}",
		dlvToolPath = vim.fn.exepath("dlv"),
	})
end

-- JavaScript/TypeScript Debug Config
local function setup_js_debug()
	if not dap.configurations.javascript then
		dap.configurations.javascript = {}
	end
	if not dap.configurations.typescript then
		dap.configurations.typescript = {}
	end

	for _, config_table in ipairs({ dap.configurations.javascript, dap.configurations.typescript }) do
		table.insert(config_table, {
			type = "node2",
			request = "launch",
			name = "Launch Node (Current File)",
			program = "${file}",
			cwd = "${workspaceFolder}",
			console = "integratedTerminal",
			sourceMaps = true,
		})
	end
end

-- ============================================================================
-- QUICK DEBUG LAUNCHER
-- ============================================================================

-- Detect filetype and launch appropriate debugger
function M.quick_debug()
	local filetype = vim.bo.filetype
	local dap_config = dap.configurations[filetype]

	if not dap_config or #dap_config == 0 then
		vim.notify("No debug configuration for " .. filetype, vim.log.levels.WARN)
		return
	end

	if #dap_config == 1 then
		dap.continue()
	else
		-- Multiple configs, let user choose
		vim.ui.select(dap_config, {
			prompt = "Select debug configuration: ",
			format_item = function(item)
				return item.name
			end,
		}, function(selected)
			if selected then
				dap.continue()
			end
		end)
	end
end

-- ============================================================================
-- BREAKPOINT MANAGEMENT
-- ============================================================================

-- Toggle breakpoint with persistence
function M.toggle_breakpoint_persistent()
	dap.toggle_breakpoint()
	save_breakpoints()
	vim.notify("Breakpoint set at line " .. vim.fn.line("."), vim.log.levels.INFO)
end

-- Set conditional breakpoint with persistence
function M.set_conditional_breakpoint()
	local condition = vim.fn.input("Breakpoint condition: ")
	if condition ~= "" then
		dap.set_breakpoint(condition)
		save_breakpoints()
		vim.notify("Conditional breakpoint set", vim.log.levels.INFO)
	end
end

-- Set log point with persistence
function M.set_log_point()
	local log_msg = vim.fn.input("Log message: ")
	if log_msg ~= "" then
		dap.set_breakpoint(nil, nil, log_msg)
		save_breakpoints()
		vim.notify("Log point set", vim.log.levels.INFO)
	end
end

-- Clear all breakpoints
function M.clear_breakpoints()
	dap.clear_breakpoints()
	save_breakpoints()
	vim.notify("All breakpoints cleared", vim.log.levels.INFO)
end

-- List all breakpoints
function M.list_breakpoints()
	local breakpoints = dap.breakpoints
	if vim.tbl_count(breakpoints) == 0 then
		vim.notify("No breakpoints set", vim.log.levels.INFO)
		return
	end

	local lines = { "=== Breakpoints ===" }
	for buf, bp_list in pairs(breakpoints) do
		for _, bp in ipairs(bp_list) do
			table.insert(lines, string.format("Buffer %d, Line %d: %s", buf, bp.line, bp.condition or ""))
		end
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- ============================================================================
-- DEBUG SESSION MANAGEMENT
-- ============================================================================

-- Start debug session
function M.start_debug()
	M.quick_debug()
end

-- Restart debug session
function M.restart_debug()
	dap.restart()
	vim.notify("Debug session restarted", vim.log.levels.INFO)
end

-- Stop debug session
function M.stop_debug()
	dap.terminate()
	dapui.close()
	vim.notify("Debug session stopped", vim.log.levels.INFO)
end

-- Continue execution
function M.continue()
	dap.continue()
end

-- Step over
function M.step_over()
	dap.step_over()
end

-- Step into
function M.step_into()
	dap.step_into()
end

-- Step out
function M.step_out()
	dap.step_out()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function M.setup()
	-- Setup debug configurations for all languages
	setup_python_debug()
	setup_rust_debug()
	setup_go_debug()
	setup_js_debug()

	-- Restore breakpoints on startup
	restore_breakpoints()

	-- Auto-save breakpoints on change
	vim.api.nvim_create_autocmd("BufWritePost", {
		callback = function()
			if dap.session() then
				save_breakpoints()
			end
		end,
	})
end

return M
