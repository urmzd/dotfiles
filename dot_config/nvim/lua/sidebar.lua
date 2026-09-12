-- VS Code style left sidebar: one window slot, several panels, one clickable
-- tab strip.
--
-- The panels themselves are borrowed from plugins that already do the work
-- (neo-tree for the file tree and the git status list, neotest for the test
-- tree). What this module adds is the thing they do not have between them: a
-- visible, clickable row of tabs so every panel is discoverable from whichever
-- panel happens to be open, instead of being hidden behind a command you have
-- to remember.
--
-- The strip lives in the panel window's 'winbar'. 'winbar' takes the statusline
-- format, so `%N@v:lua.Fn@ ... %X` gives each tab a mouse click handler, and
-- `vim.g.statusline_winid` tells us which window is being drawn, which is also
-- how we know which panel is currently showing.

local M = {}

local NEOTREE_FT = "neo-tree"
local NEOTEST_FT = "neotest-summary"

-- The `%!` form (rather than `%{%…%}`) is what sets `g:statusline_winid`, which
-- is how render() knows which window it is drawing into. Both forms re-parse
-- the result, so click items survive either way.
M.winbar = "%!v:lua.require'sidebar'.render()"

---@class SidebarPanel
---@field key string Stable identifier used by :Sidebar and the keymaps.
---@field icon string Nerd Font glyph shown in the tab strip.
---@field label string Shown next to the glyph when the window is wide enough.
---@field filetype string Filetype of the buffer this panel renders into.
---@field source string|nil neo-tree source name; nil means the panel is neotest.
---@field available fun(): boolean

-- `available` is asked on every winbar redraw, so anything that shells out or
-- walks the filesystem is answered from this cache and recomputed only when the
-- working directory changes.
local probe = { cwd = nil, git = false, tests = false }

local function has_git()
	local found = vim.fs.find(".git", { upward = true, path = vim.fn.getcwd(), limit = 1 })
	return #found > 0
end

---True when at least one configured neotest adapter claims this project.
---Adapters expose `root(dir)`, which is how neotest itself decides whether it
---has anything to say about a directory.
local function has_tests()
	local ok, config = pcall(require, "neotest.config")
	if not ok or type(config.adapters) ~= "table" then
		return false
	end
	local cwd = vim.fn.getcwd()
	for _, adapter in ipairs(config.adapters) do
		if type(adapter) == "table" and type(adapter.root) == "function" then
			local called, root = pcall(adapter.root, cwd)
			if called and root then
				return true
			end
		end
	end
	return false
end

local function probe_cwd()
	local cwd = vim.fn.getcwd()
	if probe.cwd == cwd then
		return
	end
	probe.cwd = cwd
	probe.git = has_git()
	probe.tests = has_tests()
end

---Panel order is tab order; the index doubles as the mouse click id.
---@type SidebarPanel[]
local panels = {
	{
		key = "files",
		icon = "󰉋",
		label = "Files",
		filetype = NEOTREE_FT,
		source = "filesystem",
		available = function()
			return true
		end,
	},
	{
		key = "changes",
		icon = "󰊢",
		label = "Changes",
		filetype = NEOTREE_FT,
		source = "git_status",
		available = function()
			return probe.git
		end,
	},
	{
		key = "tests",
		icon = "󰙨",
		label = "Tests",
		filetype = NEOTEST_FT,
		source = nil,
		available = function()
			return probe.tests
		end,
	},
}

local by_key = {}
for _, panel in ipairs(panels) do
	by_key[panel.key] = panel
end

---@param buf integer
---@return SidebarPanel|nil
local function panel_for_buf(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return nil
	end
	local filetype = vim.bo[buf].filetype
	for _, panel in ipairs(panels) do
		if filetype == panel.filetype then
			-- Every neo-tree panel shares a filetype, so the source decides.
			if not panel.source or vim.b[buf].neo_tree_source == panel.source then
				return panel
			end
		end
	end
	return nil
end

---@param panel SidebarPanel
---@return integer|nil
local function panel_win(panel)
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local found = panel_for_buf(vim.api.nvim_win_get_buf(win))
		if found and found.key == panel.key then
			return win
		end
	end
	return nil
end

---The panel currently on screen, if any.
---@return SidebarPanel|nil
function M.active()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local panel = panel_for_buf(vim.api.nvim_win_get_buf(win))
		if panel then
			return panel
		end
	end
	return nil
end

---Whether `key` has anything to show in the current project.
---@param key string
---@return boolean
function M.available(key)
	local panel = by_key[key]
	if not panel then
		return false
	end
	probe_cwd()
	return panel.available()
end

local function open_panel(panel)
	if panel.source then
		vim.cmd("Neotree focus " .. panel.source .. " left")
	else
		require("neotest").summary.open()
		local win = panel_win(panel)
		if win then
			vim.api.nvim_set_current_win(win)
		end
	end
end

local function close_panel(panel)
	if panel.source then
		pcall(vim.cmd, "Neotree close")
	else
		pcall(function()
			require("neotest").summary.close()
		end)
	end
end

---Show `key`, closing whichever panel currently owns the slot.
---@param key string
function M.open(key)
	local target = by_key[key]
	if not target then
		vim.notify("Sidebar: unknown panel " .. tostring(key), vim.log.levels.ERROR)
		return
	end
	probe_cwd()
	if not target.available() then
		vim.notify(("Sidebar: no %s panel in this project"):format(target.label), vim.log.levels.WARN)
		return
	end
	for _, panel in ipairs(panels) do
		-- Panels sharing a filetype share the window, and neo-tree swaps the
		-- source in place; closing first would only make it flicker.
		if panel.filetype ~= target.filetype then
			close_panel(panel)
		end
	end
	open_panel(target)
	M.last = key
end

function M.close()
	for _, panel in ipairs(panels) do
		close_panel(panel)
	end
end

---@param key string
function M.toggle(key)
	local active = M.active()
	if active and active.key == key then
		M.close()
	else
		M.open(key)
	end
end

-- Statusline click handlers have to be reachable from Vimscript, so this is
-- global by necessity. The id is the panel's index in `panels`.
_G.___sidebar_click = function(id)
	local panel = panels[id]
	if panel then
		-- Clicking the tab you are already on closes the sidebar, like clicking
		-- the active icon in VS Code's activity bar.
		M.toggle(panel.key)
	end
end

---@param panel SidebarPanel
---@param labelled boolean
local function tab_text(panel, labelled)
	if labelled then
		return (" %s %s "):format(panel.icon, panel.label)
	end
	return (" %s "):format(panel.icon)
end

---Widest rendering that still fits: every tab labelled, only the active tab
---labelled, or icons alone.
---@return boolean all_labelled, boolean active_labelled
local function fit(visible, active, width)
	local function total(labelled)
		local sum = 0
		for _, panel in ipairs(visible) do
			sum = sum + vim.fn.strdisplaywidth(tab_text(panel, labelled(panel)))
		end
		return sum
	end
	local function always()
		return true
	end
	local function only_active(panel)
		return active ~= nil and panel.key == active.key
	end
	if total(always) <= width then
		return true, true
	end
	if total(only_active) <= width then
		return false, true
	end
	return false, false
end

---Renders the tab strip. Called by 'winbar' on every redraw of a panel window.
---@return string
function M.render()
	probe_cwd()

	local winid = vim.g.statusline_winid
	local valid = type(winid) == "number" and vim.api.nvim_win_is_valid(winid)
	local buf = valid and vim.api.nvim_win_get_buf(winid) or vim.api.nvim_get_current_buf()
	local width = valid and vim.api.nvim_win_get_width(winid) or 40
	local active = panel_for_buf(buf)

	local visible = {}
	for index, panel in ipairs(panels) do
		if panel.available() then
			visible[#visible + 1] = { panel = panel, index = index }
		end
	end

	local flat = {}
	for _, entry in ipairs(visible) do
		flat[#flat + 1] = entry.panel
	end
	local all_labelled, active_labelled = fit(flat, active, width)

	local out = {}
	for _, entry in ipairs(visible) do
		local panel = entry.panel
		local is_active = active ~= nil and panel.key == active.key
		local labelled = all_labelled or (is_active and active_labelled)
		local group = is_active and "SidebarTabActive" or "SidebarTabInactive"
		out[#out + 1] = ("%%%d@v:lua.___sidebar_click@%%#%s#%s%%X"):format(
			entry.index,
			group,
			tab_text(panel, labelled)
		)
	end
	return table.concat(out) .. "%*"
end

---Label for the active panel, for bufferline's offset header.
---@return string
function M.title()
	local active = M.active()
	if not active then
		return ""
	end
	return ("%s %s"):format(active.icon, active.label)
end

local function set_highlights()
	local function fg(name)
		local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
		return hl and hl.fg or nil
	end
	vim.api.nvim_set_hl(0, "SidebarTabActive", { fg = fg("Function") or fg("Title"), bold = true, underline = true })
	vim.api.nvim_set_hl(0, "SidebarTabInactive", { fg = fg("Comment") })
end

---Attach the tab strip (and its keyboard equivalents) to a panel window.
---
---Deliberately keyed on filetype rather than on `panel_for_buf`: neo-tree sets
---its `neo_tree_source` buffer variable when it renders, which is after
---FileType fires, so asking which panel this is would skip the first open of
---every window.
---@param win integer
local function decorate_win(win)
	if not vim.api.nvim_win_is_valid(win) then
		return
	end
	local buf = vim.api.nvim_win_get_buf(win)
	local filetype = vim.bo[buf].filetype
	if filetype ~= NEOTREE_FT and filetype ~= NEOTEST_FT then
		return
	end
	if vim.wo[win].winbar ~= M.winbar then
		vim.wo[win].winbar = M.winbar
	end
	-- Leader is <Space>, which neo-tree binds to toggle_node, so the global
	-- <leader>N maps are unreachable from inside a panel. Bare digits are not.
	for index, panel in ipairs(panels) do
		vim.keymap.set("n", tostring(index), function()
			M.open(panel.key)
		end, { buffer = buf, nowait = true, desc = "Sidebar: " .. panel.label })
	end
end

local function decorate()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		decorate_win(win)
	end
end

function M.setup()
	local group = vim.api.nvim_create_augroup("Sidebar", { clear = true })

	set_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlights })

	vim.api.nvim_create_autocmd("DirChanged", {
		group = group,
		callback = function()
			probe.cwd = nil
		end,
	})

	vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "WinEnter", "WinNew" }, {
		group = group,
		callback = decorate,
	})

	vim.api.nvim_create_user_command("Sidebar", function(opts)
		local key = opts.args ~= "" and opts.args or "files"
		if key == "close" then
			M.close()
		else
			M.toggle(key)
		end
	end, {
		nargs = "?",
		complete = function()
			local keys = { "close" }
			for _, panel in ipairs(panels) do
				keys[#keys + 1] = panel.key
			end
			return keys
		end,
		desc = "Toggle a sidebar panel",
	})

	for index, panel in ipairs(panels) do
		vim.keymap.set("n", "<leader>" .. index, function()
			M.toggle(panel.key)
		end, { desc = "Sidebar: " .. panel.label })
		vim.keymap.set("n", "<leader>s" .. panel.key:sub(1, 1), function()
			M.toggle(panel.key)
		end, { desc = "Sidebar: " .. panel.label })
	end
	vim.keymap.set("n", "<leader>ss", function()
		M.toggle(M.last or "files")
	end, { desc = "Sidebar: Toggle last panel" })
	vim.keymap.set("n", "<leader>sq", M.close, { desc = "Sidebar: Close" })
end

return M
