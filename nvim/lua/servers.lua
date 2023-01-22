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
  "rust_analyzer",
  "jsonls"
}


for _, server in ipairs(servers) do
  local overrides = nil

  if server == "jsonls" then
    overrides = {
        filetypes = { "json", "jsonc" },
        settings = {
            json = {
                schemas = require("schemastore").json.schemas(),
                validate = { enable = true }
            }
        }
      }
  end

  if server == "rust_analyzer" then
    local rt = require("rust-tools")

    rt.setup {
        server = config.setup_with_coq()
    }
  else
    config.setup(server, overrides)
  end


end
