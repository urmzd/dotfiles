local yamllint = require("language-servers.efm.yamllint")
local luafmt = require("language-servers.efm.luafmt")
local prettier = require("language-servers.efm.prettier")
local eslint = require("language-servers.efm.eslint")
local markdownlint = require("language-servers.efm.markdownlint")
local lsp_servers = require("utils.path").lsp_servers_dir
local lume = require("lume")

local M = {}
local default_settings = {
    yaml = {yamllint},
    json = {prettier},
    jsonc = {prettier},
    toml = {prettier},
    lua = {luafmt},
    javascript = {eslint, prettier},
    javascriptreact = {eslint, prettier},
    typescript = {eslint, prettier},
    typescriptreact = {eslint, prettier},
    markdown = {markdownlint, prettier}
}

M.default_settings = default_settings

local efmls = lsp_servers .. "/efm/efm-langserver"

local overrides = {
    cmd = {efmls, "-logfile", "/tmp/efm.log"},
    init_options = {documentFormatting = true, codeAction = true},
    filetypes = vim.tbl_keys(default_settings),
    settings = {languages = default_settings}
}

function M.setup(config, opts) config.efm.setup(lume.merge(opts, overrides)) end

return M
