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
  "lua_ls",
  "rust_analyzer",
  "jsonls",
  "terraformls",
}

for _, server in ipairs(servers) do
  local overrides = nil

  if server == "yamlls" then
    overrides = {
      settings = {
        schemas = {
          yaml = {
            format = {
              singleQuote = true,
            },
            schemas = {
              ["https://raw.githubusercontent.com/open-telemetry/opentelemetry-specification/main/schemas/1.9.0"] = "/otel-collector-config.yaml",
            },
          },
        },
      },
    }
  end

  if server == "pyright" then
    local util = require("lspconfig.util")
    overrides = {
      settings = {
        python = {
          analysis = {
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
            diagnosticMode = "openFilesOnly",
          },
        },
      },
      root_dir = util.root_pattern(".git"),
    }
  end

  if server == "jsonls" then
    overrides = {
      filetypes = { "json", "jsonc" },
      settings = {
        json = {
          schemas = require("schemastore").json.schemas(),
          validate = { enable = true },
        },
      },
    }
  end

  if server == "rust_analyzer" then
    local rt = require("rust-tools")

    rt.setup({
      server = config.setup_with_coq(),
    })
  else
    config.setup(server, overrides)
  end
end
