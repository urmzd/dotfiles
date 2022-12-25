local config = require("lsp_config")

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
  "sumneko_lua",
}

for _, server in ipairs(servers) do
  config.setup(server, overrides)
end
