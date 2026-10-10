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
-- A panel with nothing to show still owns its tab. Its slot is filled by a
-- placeholder buffer of this filetype that says why, so the strip never
-- changes shape between projects and `3` always means Tests.
local EMPTY_FT = "sidebar-empty"
local WIDTH = 40

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
---@field empty (fun(): string[])|nil Paragraphs for the placeholder shown when not available.

-- `available` is asked on every winbar redraw, so anything that shells out or
-- walks the filesystem is answered from this cache and recomputed only when the
-- working directory, or the directory of the file being edited, changes.
local probe = { cwd = nil, file_dir = nil, probed_dir = nil, git = false, tests = false, claimed = {} }

local function has_git()
	local found = vim.fs.find(".git", { upward = true, path = vim.fn.getcwd(), limit = 1 })
	return #found > 0
end

---True when at least one configured neotest adapter claims `dir`. Adapters
---expose `root(dir)`, which is how neotest itself decides whether it has
---anything to say about a directory. Some shell out to answer (cargo
---metadata), hence the memo.
---@param dir string
local function claimed(dir)
	if probe.claimed[dir] ~= nil then
		return probe.claimed[dir]
	end
	local found = false
	local ok, config = pcall(require, "neotest.config")
	if ok and type(config.adapters) == "table" then
		for _, adapter in ipairs(config.adapters) do
			if type(adapter) == "table" and type(adapter.root) == "function" then
				local called, root = pcall(adapter.root, dir)
				if called and root then
					found = true
					break
				end
			end
		end
	end
	probe.claimed[dir] = found
	return found
end

---The working directory is usually the repository root, and in a repository
---that keeps its code a level down (a crate in `cli/`, a package in `web/`)
---no adapter claims that. The file being edited is asked as well, so the
---Tests tab follows the code rather than the checkout.
local function probe_cwd()
	local cwd = vim.fn.getcwd()
	if probe.cwd == cwd and probe.probed_dir == probe.file_dir then
		return
	end
	if probe.cwd ~= cwd then
		probe.git = has_git()
		probe.tests = false
	end
	probe.cwd = cwd
	probe.probed_dir = probe.file_dir
	-- Sticky until the working directory changes: stepping from a test file
	-- to the README should not take the tab away again.
	probe.tests = probe.tests or claimed(cwd) or (probe.file_dir ~= nil and claimed(probe.file_dir))
end

---Names of the configured neotest adapters, without the `neotest-` prefix.
---@return string[]
local function adapter_names()
	local names = {}
	local ok, config = pcall(require, "neotest.config")
	if ok and type(config.adapters) == "table" then
		for _, adapter in ipairs(config.adapters) do
			if type(adapter) == "table" and type(adapter.name) == "string" then
				names[#names + 1] = (adapter.name:gsub("^neotest%-", ""))
			end
		end
	end
	return names
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
		empty = function()
			return {
				"Not inside a git repository.",
				"Changed files list here once this directory, or one above it, has a .git.",
			}
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
		empty = function()
			local names = adapter_names()
			local configured = #names > 0 and ("Configured adapters: " .. table.concat(names, ", ") .. ".")
				or "No neotest adapters are configured."
			return {
				"No test adapter claims this project.",
				configured,
				"Tests list here when the working directory is a project one of them recognises.",
			}
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
	if filetype == EMPTY_FT then
		return by_key[vim.b[buf].sidebar_panel]
	end
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

---@return integer|nil
local function empty_win()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == EMPTY_FT then
			return win
		end
	end
	return nil
end

local function close_empty()
	local win = empty_win()
	if win then
		pcall(vim.api.nvim_win_close, win, true)
	end
end

local empty_ns = vim.api.nvim_create_namespace("sidebar-empty")

---Fill the sidebar slot with a note saying why `panel` has nothing to show.
---@param panel SidebarPanel
local function show_empty(panel)
	local lines = { "", "  " .. panel.icon .. "  " .. panel.label, "" }
	for _, paragraph in ipairs(panel.empty and panel.empty() or {}) do
		lines[#lines + 1] = "  " .. paragraph
		lines[#lines + 1] = ""
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_extmark(buf, empty_ns, 1, 0, { end_row = 2, hl_group = "SidebarTabActive" })
	vim.api.nvim_buf_set_extmark(buf, empty_ns, 3, 0, { end_row = #lines, hl_group = "Comment" })
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.b[buf].sidebar_panel = panel.key

	local win = empty_win()
	if win then
		vim.api.nvim_win_set_buf(win, buf)
		vim.api.nvim_set_current_win(win)
	else
		win = vim.api.nvim_open_win(buf, true, { split = "left", win = -1, width = WIDTH })
	end
	local wo = vim.wo[win]
	wo.number = false
	wo.relativenumber = false
	wo.signcolumn = "no"
	wo.foldcolumn = "0"
	wo.cursorline = false
	wo.list = false
	wo.spell = false
	wo.winfixwidth = true
	-- Paragraphs are single lines; wrapping them here keeps the text right
	-- at any sidebar width, and breakindent carries the left margin down.
	wo.wrap = true
	wo.linebreak = true
	wo.breakindent = true

	vim.keymap.set("n", "q", M.close, { buffer = buf, nowait = true, desc = "Sidebar: Close" })
	-- Last, so the FileType autocmd decorates a window that is already set up.
	vim.bo[buf].filetype = EMPTY_FT
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
	M.last = key
	if not target.available() then
		for _, panel in ipairs(panels) do
			close_panel(panel)
		end
		show_empty(target)
		return
	end
	close_empty()
	for _, panel in ipairs(panels) do
		-- Panels sharing a filetype share the window, and neo-tree swaps the
		-- source in place; closing first would only make it flicker.
		if panel.filetype ~= target.filetype then
			close_panel(panel)
		end
	end
	open_panel(target)
end

function M.close()
	close_empty()
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

---Step to the next (or, with a negative `step`, previous) panel, wrapping at
---either end.
---@param step integer
function M.cycle(step)
	local active = M.active()
	local current = 0
	for index, panel in ipairs(panels) do
		if active and panel.key == active.key then
			current = index
		end
	end
	if current == 0 then
		M.open(panels[1].key)
		return
	end
	M.open(panels[(current - 1 + step) % #panels + 1].key)
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

	local all_labelled, active_labelled = fit(panels, active, width)

	local out = {}
	for index, panel in ipairs(panels) do
		local is_active = active ~= nil and panel.key == active.key
		local labelled = all_labelled or (is_active and active_labelled)
		-- Every tab is always drawn; one with nothing to show is dimmed
		-- rather than dropped, so the strip keeps its shape.
		local group = is_active and "SidebarTabActive"
			or panel.available() and "SidebarTabInactive"
			or "SidebarTabUnavailable"
		out[#out + 1] = ("%%%d@v:lua.___sidebar_click@%%#%s#%s%%X"):format(index, group, tab_text(panel, labelled))
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
	vim.api.nvim_set_hl(0, "SidebarTabUnavailable", { fg = fg("NonText") or fg("Comment") })
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
	if filetype ~= NEOTREE_FT and filetype ~= NEOTEST_FT and filetype ~= EMPTY_FT then
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
	-- Globally <Tab> cycles buffers, which means nothing in a panel; here it
	-- walks the tab strip instead.
	vim.keymap.set("n", "<Tab>", function()
		M.cycle(1)
	end, { buffer = buf, nowait = true, desc = "Sidebar: Next panel" })
	vim.keymap.set("n", "<S-Tab>", function()
		M.cycle(-1)
	end, { buffer = buf, nowait = true, desc = "Sidebar: Previous panel" })
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

	-- A placeholder describes the place just left; redraw it, or swap in the
	-- real panel if the new place has one.
	local function refresh_empty()
		local win = empty_win()
		local panel = win and panel_for_buf(vim.api.nvim_win_get_buf(win))
		if not panel then
			return
		end
		local focused = vim.api.nvim_get_current_win()
		M.open(panel.key)
		if focused ~= win and vim.api.nvim_win_is_valid(focused) then
			vim.api.nvim_set_current_win(focused)
		end
	end

	vim.api.nvim_create_autocmd("DirChanged", {
		group = group,
		callback = function()
			probe.cwd = nil
			probe.claimed = {}
			vim.schedule(refresh_empty)
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function(args)
			local name = vim.api.nvim_buf_get_name(args.buf)
			if vim.bo[args.buf].buftype ~= "" or name == "" then
				return
			end
			local dir = vim.fs.dirname(name)
			if dir ~= probe.file_dir then
				probe.file_dir = dir
				vim.schedule(refresh_empty)
			end
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
