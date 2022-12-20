local config = require("lsp_setup")


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
  if (server == "sumneko_lua") then
    -- For dev purposes only.
    require("neodev").setup {}
  end

  config.setup(server)
end
