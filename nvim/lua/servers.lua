local config = require("lsp_config")
local util = require("lspconfig.util")

local servers = {
  "bashls",
  "gopls",
  "dockerls",
  "yamlls",
  "tsserver",
  "graphql",
  "groovyls",
  "pyright",
  "pyre",
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

  if server == "lua_ls" then
    require("neodev").setup({
      library = {
        plugins = { "neotest" },
        types = true,
      },
    })
  end

  if server == "yamlls" then
    overrides = {
      settings = {
        schemas = {
          yaml = {
            format = {
              singleQuote = true,
            },
          },
        },
      },
    }
  end

  if server == "terraformls" then
    overrides = {
      single_file_support = false,
      root_dir = util.root_pattern(".terraform", ".git"),
    }
  end

  if server == "pyright" then
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
      --root_dir = util.root_pattern(".git")
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
    require("rust-tools").setup({
      server = {
        on_attach = config.opts.on_attach,
        capabilities = config.opts.capabilities,
      },
    })
  else
    config.setup(server, overrides)
  end
end
