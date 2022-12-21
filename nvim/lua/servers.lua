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
  "sumneko_lua",
}

for _, server in ipairs(servers) do
  local overrides

  if (server == "sumneko_lua") then
    require("neodev").setup {}
  end

  if (server == "jsonls") then
    overrides = require("json")
  end

  if (server == "jdtls") then
    overrides = require("java")
    require("jdtls").start_or_attach(config.setup_with_coq(java))
    goto continue
  end

  config.setup(server, overrides)

  ::continue::
end
