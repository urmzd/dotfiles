local config = require("lsp_setup")

-- For dev purposes only.
local neodev = require("neodev")
neodev.setup {}

local servers = {
  "bashls",
  "gopls",
  "dockerls",
  "yamlls",
  "tsserver",
  "graphql",
  "groovyls",
  "pyright",
  "kotlin_language_server",
  "perlls",
  "texlab",
  "sumneko_lua"
}

for _, server in ipairs(servers) do
  --print(server)
  config.setup(server)
end
