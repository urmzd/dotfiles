-- Git worktree management from inside Neovim.
--
-- Agents get their own worktree so the primary checkout never leaves its
-- branch, which means reviewing their work is mostly a matter of hopping
-- between checkouts of the same repository. Doing that by hand is three
-- commands and a stale buffer list, so this module makes the hop one keystroke
-- and cleans up after itself:
--
--   * worktrees always live at <repo-root>/.worktrees/<name>
--   * .worktrees/ is kept out of git via .git/info/exclude, never the tracked
--     .gitignore, so the layout costs the repository nothing
--   * switching retargets the tab's working directory, drops the buffers that
--     belonged to the checkout you left, and re-roots the sidebar
--
-- Nothing here removes a worktree that has uncommitted work without saying so.

local M = {}

local DIR = ".worktrees"

---@param args string[]
---@param cwd string|nil
---@return string[] lines, boolean ok
local function git(args, cwd)
	local cmd = { "git" }
	if cwd then
		table.insert(cmd, "-C")
		table.insert(cmd, cwd)
	end
	vim.list_extend(cmd, args)
	local lines = vim.fn.systemlist(cmd)
	return lines, vim.v.shell_error == 0
end

---@class Worktree
---@field path string
---@field name string Directory name, which is what the user picks by.
---@field branch string
---@field head string
---@field main boolean Primary checkout, the one that must never be switched.
---@field current boolean
---@field locked boolean

---Every worktree of the repository containing `cwd`, primary checkout first.
---@param cwd string|nil
---@return Worktree[]
function M.list(cwd)
	cwd = cwd or vim.fn.getcwd()
	local lines, ok = git({ "worktree", "list", "--porcelain" }, cwd)
	if not ok then
		return {}
	end

	local here = vim.fn.getcwd()
	local trees, entry = {}, nil
	local function flush()
		if entry and entry.path then
			entry.name = vim.fn.fnamemodify(entry.path, ":t")
			entry.main = #trees == 0
			entry.current = here == entry.path or vim.startswith(here, entry.path .. "/")
			trees[#trees + 1] = entry
		end
		entry = nil
	end

	for _, line in ipairs(lines) do
		if line == "" then
			flush()
		else
			local key, value = line:match("^(%S+)%s*(.*)$")
			entry = entry or { branch = "(detached)", head = "", locked = false }
			if key == "worktree" then
				entry.path = value
			elseif key == "HEAD" then
				entry.head = value:sub(1, 7)
			elseif key == "branch" then
				entry.branch = value:gsub("^refs/heads/", "")
			elseif key == "locked" then
				entry.locked = true
			end
		end
	end
	flush()

	-- The primary checkout is the one buffers get compared against, and nested
	-- worktrees live underneath it, so a longest-path-first current check keeps
	-- .worktrees/x from being reported as "in the main worktree".
	local current = nil
	for _, tree in ipairs(trees) do
		if tree.current and (not current or #tree.path > #current.path) then
			current = tree
		end
	end
	for _, tree in ipairs(trees) do
		tree.current = current ~= nil and tree.path == current.path
	end
	return trees
end

---The worktree the editor is sitting in, if any.
---@return Worktree|nil
function M.current()
	for _, tree in ipairs(M.list()) do
		if tree.current then
			return tree
		end
	end
	return nil
end

---The primary checkout, which owns .worktrees/.
---@return Worktree|nil
function M.main()
	local trees = M.list()
	return trees[1]
end

---Keep .worktrees/ untracked without touching the repository's own .gitignore,
---which belongs to the project rather than to this workflow.
---@param root string
local function exclude_worktree_dir(root)
	local git_dir = git({ "rev-parse", "--git-common-dir" }, root)[1]
	if not git_dir or git_dir == "" then
		return
	end
	if not vim.startswith(git_dir, "/") then
		git_dir = root .. "/" .. git_dir
	end
	local exclude = git_dir .. "/info/exclude"
	local existing = vim.fn.filereadable(exclude) == 1 and vim.fn.readfile(exclude) or {}
	for _, line in ipairs(existing) do
		if vim.trim(line) == DIR .. "/" then
			return
		end
	end
	vim.fn.mkdir(vim.fn.fnamemodify(exclude, ":h"), "p")
	table.insert(existing, DIR .. "/")
	vim.fn.writefile(existing, exclude)
end

---Linked worktrees live *underneath* the primary checkout, so "is this path
---inside `to`" is not a prefix test: every file in .worktrees/x is also inside
---the main root. The owner is whichever of the two roots matches longest.
---@param name string
---@param from string
---@param to string
---@return boolean
local function belongs_to_old(name, from, to)
	local in_from = vim.startswith(name, from .. "/")
	if not in_from then
		return false
	end
	if vim.startswith(name, to .. "/") then
		return #from > #to
	end
	return true
end

---Buffers that belonged to the checkout being left are stale the moment the
---directory changes; unmodified ones are dropped, modified ones are kept and
---reported so nothing is lost silently.
---@param from string
---@param to string
local function release_buffers(from, to)
	local dropped, kept = 0, 0
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
			local name = vim.api.nvim_buf_get_name(buf)
			if name ~= "" and belongs_to_old(name, from, to) then
				if vim.bo[buf].modified then
					kept = kept + 1
				elseif pcall(vim.api.nvim_buf_delete, buf, {}) then
					dropped = dropped + 1
				end
			end
		end
	end
	return dropped, kept
end

---Point this tab at `path` and bring the sidebar along.
---@param path string
function M.switch(path)
	if vim.fn.isdirectory(path) ~= 1 then
		vim.notify("Worktree: no such directory " .. path, vim.log.levels.ERROR)
		return
	end
	local from = vim.fn.getcwd()
	if from == path then
		vim.notify("Worktree: already in " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
		return
	end

	local sidebar_ok, sidebar = pcall(require, "sidebar")
	local reopen = sidebar_ok and sidebar.active() or nil

	vim.cmd.tcd(vim.fn.fnameescape(path))
	local dropped, kept = release_buffers(from, path)

	if reopen then
		-- The panel that was open may not apply to the checkout being entered
		-- (a worktree of a different branch need not have the same tests), so
		-- fall back to the one panel that always applies.
		sidebar.close()
		sidebar.open(sidebar.available(reopen.key) and reopen.key or "files")
	end
	pcall(function()
		require("gitsigns").refresh()
	end)

	local summary = ("Worktree: %s"):format(vim.fn.fnamemodify(path, ":t"))
	if dropped > 0 then
		summary = summary .. (" · closed %d buffer%s"):format(dropped, dropped == 1 and "" or "s")
	end
	if kept > 0 then
		summary = summary .. (" · kept %d unsaved"):format(kept)
	end
	vim.notify(summary, vim.log.levels.INFO)
end

---Create <repo-root>/.worktrees/<name> on a new branch and switch into it.
---@param name string
---@param base string|nil Ref to branch from; defaults to the current HEAD.
function M.create(name, base)
	name = vim.trim(name or "")
	if name == "" then
		return
	end
	local main = M.main()
	if not main then
		vim.notify("Worktree: not inside a git repository", vim.log.levels.ERROR)
		return
	end

	exclude_worktree_dir(main.path)
	local path = ("%s/%s/%s"):format(main.path, DIR, name)
	local args = { "worktree", "add" }
	-- Reuse the branch if it already exists; only ask git to create it if not.
	local _, exists = git({ "rev-parse", "--verify", "--quiet", "refs/heads/" .. name }, main.path)
	if not exists then
		table.insert(args, "-b")
		table.insert(args, name)
	end
	table.insert(args, path)
	if base and base ~= "" then
		table.insert(args, base)
	end

	local out, ok = git(args, main.path)
	if not ok then
		vim.notify("Worktree: " .. table.concat(out, " "), vim.log.levels.ERROR)
		return
	end
	M.switch(path)
end

---@param tree Worktree
function M.remove(tree)
	if tree.main then
		vim.notify("Worktree: refusing to remove the primary checkout", vim.log.levels.ERROR)
		return
	end
	local main = M.main()
	if tree.current and main then
		M.switch(main.path)
	end
	local out, ok = git({ "worktree", "remove", tree.path }, main and main.path or nil)
	if not ok then
		-- git refuses while the worktree is dirty; say what it said rather than
		-- forcing, since the dirt is usually unreviewed agent work.
		vim.notify("Worktree: " .. table.concat(out, " "), vim.log.levels.WARN)
		return
	end
	vim.notify("Worktree: removed " .. tree.name, vim.log.levels.INFO)
end

---Telescope picker over the repository's worktrees.
---<CR> switches, <C-d> removes.
function M.pick()
	local ok, pickers = pcall(require, "telescope.pickers")
	if not ok then
		vim.notify("Worktree: telescope is not available", vim.log.levels.ERROR)
		return
	end
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local previewers = require("telescope.previewers")

	local trees = M.list()
	if #trees == 0 then
		vim.notify("Worktree: not inside a git repository", vim.log.levels.WARN)
		return
	end

	local width = 0
	for _, tree in ipairs(trees) do
		width = math.max(width, #tree.name)
	end

	pickers
		.new({}, {
			prompt_title = "Worktrees",
			finder = finders.new_table({
				results = trees,
				entry_maker = function(tree)
					local marker = tree.current and "●" or (tree.main and "◉" or " ")
					return {
						value = tree,
						ordinal = tree.name .. " " .. tree.branch,
						display = ("%s %-" .. width .. "s  %s  %s"):format(marker, tree.name, tree.branch, tree.head),
						path = tree.path,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = previewers.new_termopen_previewer({
				get_command = function(entry)
					return { "git", "-C", entry.value.path, "log", "--oneline", "--decorate", "-20" }
				end,
			}),
			attach_mappings = function(bufnr, map)
				actions.select_default:replace(function()
					local entry = action_state.get_selected_entry()
					actions.close(bufnr)
					if entry then
						M.switch(entry.value.path)
					end
				end)
				map({ "i", "n" }, "<C-d>", function()
					local entry = action_state.get_selected_entry()
					actions.close(bufnr)
					if entry then
						M.remove(entry.value)
					end
				end)
				return true
			end,
		})
		:find()
end

-- The statusline asks for this on every redraw and answering it means shelling
-- out to git, so it is computed once per working directory.
local label_cache = { cwd = nil, value = "" }

---Short label for the statusline: only interesting off the primary checkout.
---@return string
function M.label()
	local cwd = vim.fn.getcwd()
	if label_cache.cwd ~= cwd then
		local tree = M.current()
		label_cache.cwd = cwd
		label_cache.value = (not tree or tree.main) and "" or ("󰘬 " .. tree.name)
	end
	return label_cache.value
end

function M.setup()
	vim.api.nvim_create_user_command("Worktree", function(opts)
		local action = opts.fargs[1] or "list"
		if action == "list" then
			M.pick()
		elseif action == "new" then
			local name = opts.fargs[2]
			if name then
				M.create(name, opts.fargs[3])
			else
				vim.ui.input({ prompt = "New worktree name: " }, function(input)
					if input then
						M.create(input)
					end
				end)
			end
		elseif action == "main" then
			local main = M.main()
			if main then
				M.switch(main.path)
			end
		else
			vim.notify("Worktree: unknown action " .. action, vim.log.levels.ERROR)
		end
	end, {
		nargs = "*",
		complete = function()
			return { "list", "new", "main" }
		end,
		desc = "Switch, create, or list git worktrees",
	})

	vim.keymap.set("n", "<leader>ww", M.pick, { desc = "Worktree: Switch" })
	vim.keymap.set("n", "<leader>wn", function()
		vim.ui.input({ prompt = "New worktree name: " }, function(input)
			if input then
				M.create(input)
			end
		end)
	end, { desc = "Worktree: New" })
	vim.keymap.set("n", "<leader>wm", function()
		local main = M.main()
		if main then
			M.switch(main.path)
		end
	end, { desc = "Worktree: Back to primary checkout" })
end

return M
