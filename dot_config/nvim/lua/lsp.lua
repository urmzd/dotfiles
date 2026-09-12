-- Language servers and formatters, installed when a project actually needs them.
--
-- The previous arrangement handed mason a list of eighteen servers and nine
-- formatters and let it install every one on first launch, on every machine,
-- whether or not that machine would ever open Kotlin or Terraform. It also
-- assumed each install would succeed, which is not true: mason installs npm
-- packages with npm and Go packages with go, so a machine without those
-- toolchains fails the same install on every startup.
--
-- This module keeps the roster but moves the decision to the moment a matching
-- filetype is opened, and skips anything whose install needs a backend this
-- machine does not have. Servers already installed are left to
-- mason-lspconfig's automatic_enable; this only handles the first time.

local M = {}

---The roster: one server per language, chosen rather than accumulated.
---Order is irrelevant; mason-lspconfig maps each name to its package and its
---filetypes, so neither is repeated here.
---@type string[]
M.servers = {
	"lua_ls",
	-- ty type-checks; basedpyright supplies the completion, hover and
	-- signature help ty still lacks.
	"ty",
	"basedpyright",
	"rust_analyzer",
	"gopls",
	"clangd",
	-- JetBrains' own Kotlin server, built on IntelliJ, rather than the
	-- community fwcd one it has effectively superseded.
	"kotlin_lsp",
	"terraformls",
	-- Docker's official server covers Dockerfiles, Compose and Bake; dockerls
	-- only ever covered Dockerfiles.
	"docker_language_server",
	"jsonls",
	"yamlls",
	"bashls",
	-- vtsls wraps the same TypeScript service VS Code drives, which the plain
	-- typescript-language-server does not.
	"vtsls",
	"marksman",
	"mdx_analyzer",
	"astro",
	-- ltex-ls is unmaintained; ltex-ls-plus is the fork that still ships.
	"ltex_plus",
}

-- Scala and Java are absent on purpose. Metals is not in the mason registry at
-- all and is driven by nvim-metals through coursier, and Java stays with jdtls
-- via nvim-jdtls.

local wanted = {}
for _, name in ipairs(M.servers) do
	wanted[name] = true
end

-- mason installs from several package registries and each needs its own
-- toolchain present to do the install. The package spec says which one.
local RUNTIME_FOR_SCHEME = {
	npm = "npm",
	golang = "go",
	cargo = "cargo",
	pypi = "python3",
	gem = "gem",
	composer = "composer",
	luarocks = "luarocks",
	nuget = "dotnet",
	opam = "opam",
}

-- Servers that ship as a plain binary but still need a runtime to start.
local RUNTIME_FOR_SERVER = {
	kotlin_lsp = "java",
	jdtls = "java",
}

-- Conform formatter names that do not match their mason package name. Anything
-- missing here is looked up under its own name, then with dashes.
local PACKAGE_FOR_FORMATTER = {
	ruff_fix = "ruff",
	ruff_format = "ruff",
	ruff_organize_imports = "ruff",
}

local runtime_cache = {}

---macOS ships /usr/bin/java as a stub that exists, is executable, and only
---prints "Unable to locate a Java Runtime", so executable() alone says nothing.
---@return boolean
local function java_runs()
	vim.fn.system({ "java", "-version" })
	return vim.v.shell_error == 0
end

---@param name string
---@return boolean
local function has_runtime(name)
	if runtime_cache[name] == nil then
		if vim.fn.executable(name) ~= 1 then
			runtime_cache[name] = false
		elseif name == "java" then
			runtime_cache[name] = java_runs()
		else
			runtime_cache[name] = true
		end
	end
	return runtime_cache[name]
end

---@param pkg table mason Package
---@return string|nil
local function runtime_for_package(pkg)
	local id = pkg.spec and pkg.spec.source and pkg.spec.source.id
	local scheme = id and id:match("^pkg:([^/]+)")
	return scheme and RUNTIME_FOR_SCHEME[scheme] or nil
end

local announced = {}

---Say once, per thing, why it is not being installed. Repeating it on every
---file opened would be noise rather than information.
---@param key string
---@param message string
local function announce_once(key, message)
	if announced[key] then
		return
	end
	announced[key] = true
	vim.notify(message, vim.log.levels.WARN)
end

---Install `package_name` if it is missing and this machine can build it.
---@param package_name string
---@param label string Human name used in messages.
---@param extra_runtime string|nil Runtime the tool needs to run, not to install.
---@param on_ready fun()|nil Called once the package is present.
local function ensure(package_name, label, extra_runtime, on_ready)
	local ok, registry = pcall(require, "mason-registry")
	if not ok then
		return
	end
	local found, pkg = pcall(registry.get_package, package_name)
	if not found then
		return
	end

	if extra_runtime and not has_runtime(extra_runtime) then
		-- Deliberately not "not on PATH": java in particular is usually on
		-- PATH and still unusable, which is the whole reason for java_runs().
		announce_once(
			label,
			("%s needs a working %s runtime, which this machine does not have"):format(label, extra_runtime)
		)
		return
	end

	if pkg:is_installed() then
		if on_ready then
			on_ready()
		end
		return
	end
	if pkg:is_installing() then
		return
	end

	local runtime = runtime_for_package(pkg)
	if runtime and not has_runtime(runtime) then
		announce_once(
			label,
			("%s cannot be installed here: mason needs %s for %s"):format(label, runtime, package_name)
		)
		return
	end

	vim.notify(("Installing %s"):format(label), vim.log.levels.INFO)
	pkg:install({}, function(success, result)
		vim.schedule(function()
			if not success then
				vim.notify(("Failed to install %s: %s"):format(label, tostring(result)), vim.log.levels.ERROR)
				return
			end
			vim.notify(("Installed %s"):format(label), vim.log.levels.INFO)
			if on_ready then
				on_ready()
			end
		end)
	end)
end

local handled_servers = {}

---@param filetype string
local function ensure_servers(filetype)
	if handled_servers[filetype] then
		return
	end
	handled_servers[filetype] = true

	local ok, mappings = pcall(require, "mason-lspconfig.mappings")
	if not ok then
		return
	end
	local for_filetype = mappings.get_filetype_map()[filetype]
	if not for_filetype then
		return
	end
	local to_package = mappings.get_mason_map().lspconfig_to_package

	for _, server in ipairs(for_filetype) do
		if wanted[server] then
			local package_name = to_package[server]
			if package_name then
				ensure(package_name, server, RUNTIME_FOR_SERVER[server], function()
					-- Already-installed servers are enabled by
					-- mason-lspconfig at startup; this covers the install
					-- that just finished, so the server starts without a
					-- restart.
					pcall(vim.lsp.enable, server)
				end)
			end
		end
	end
end

---Mason package names to try for a conform formatter, most specific first.
---Built by appending rather than with a table constructor: a nil first element
---would end an ipairs walk before it started.
---@param formatter string
---@return string[]
local function package_candidates(formatter)
	local candidates = {}
	local mapped = PACKAGE_FOR_FORMATTER[formatter]
	if mapped then
		candidates[#candidates + 1] = mapped
	end
	candidates[#candidates + 1] = formatter
	local dashed = formatter:gsub("_", "-")
	if dashed ~= formatter then
		candidates[#candidates + 1] = dashed
	end
	return candidates
end

local handled_formatters = {}

---@param filetype string
local function ensure_formatters(filetype)
	if handled_formatters[filetype] then
		return
	end
	handled_formatters[filetype] = true

	local ok, conform = pcall(require, "conform")
	if not ok then
		return
	end
	local formatters = conform.formatters_by_ft[filetype]
	if type(formatters) ~= "table" then
		return
	end

	local registry_ok, registry = pcall(require, "mason-registry")
	if not registry_ok then
		return
	end

	-- ipairs on purpose: entries like `lsp_format = "fallback"` sit on the same
	-- table and are settings, not formatters.
	for _, formatter in ipairs(formatters) do
		for _, candidate in ipairs(package_candidates(formatter)) do
			if registry.has_package(candidate) then
				ensure(candidate, candidate, nil, nil)
				break
			end
		end
	end
end

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("LspOnDemand", { clear = true }),
		callback = function(args)
			local filetype = args.match
			if filetype == "" then
				return
			end
			-- Never block the file opening on a registry lookup.
			vim.schedule(function()
				ensure_servers(filetype)
				ensure_formatters(filetype)
			end)
		end,
		desc = "Install the servers and formatters this filetype needs, once",
	})
end

return M
