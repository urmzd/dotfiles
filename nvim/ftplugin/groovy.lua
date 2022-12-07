local setup = require("lsp_setup")
local config = require("lspconfig")
local lume = require("lume")
local opts = setup.opts

local path = require("mason-core.path")

local groovyls_path = path.concat({
  vim.fn.stdpath("data"),
  "mason",
  "packages",
  "groovy-language-server",
  "build",
  "libs",
  "groovy-language-server-all.jar",
})

print(groovyls_path)

local cmd = { "java", "-jar", groovyls_path }

config.groovyls.setup(lume.merge(opts, { cmd = cmd }))
