local yamllint = require("yamllint")
local luafmt = require("luafmt")
local prettier = require("prettier")
local eslint = require("eslint")
local markdownlint = require("markdownlint")
local lume = require("lume")
local lsp_servers = require("nvim.utils.path").lsp_servers_dir

local M = {}
     local M.default_settings = {
         yaml = {yamllint},
         json = {prettier},
         jsonc = {prettier},
         lua = {luafmt},
         javascript = {eslint, prettier},
         javascriptreact = {eslint, prettier},
         typescript = {eslint, prettier},
         typescriptreact = {eslint, prettier},
         markdown = {markdownlint, prettier}
     }

local efmls = lsp_servers .. "efmls"
           local overrides = {
cmd = {efmls, "-logfile", "/tmp/efm.log"},
init_options = {documentFormatting = true, codeAction = true},
filetypes = vim.tbl_keys(efm_settings),
settings = {languages = efm_settings}
}

function M.setup(config, opts)
   config.efm.setup(lume.merge(opts, overrides))
end

return M

