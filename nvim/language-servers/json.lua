local M = {}

local lume = require("lume")

function M.setup(config, opts)
   local overrides = {}

   overrides.on_attach = function(client, bufnr)
      client.resolved_capabilities.document_formatting = false
      client.resolved_capabilities.document_range_formatting = false
   end
   overrides.filetypes = { "json", "jsonc" }

   local _capabilities = vim.lsp.protocol.make_client_capabilities()
   _capabilities.textDocument.completion.completionItem.snippetSupport = true

   overrides.capabilities = _capabilities
   overrides.settings = {
      json = {
         schemas = {
            {
               description = "Cypress",
               fileMatch = { "cypress.*.json" },
               url = "https://raw.githubusercontent.com/cypress-io/cypress/develop/cli/schema/cypress.schema.json"
            }, {

               description = "NPM",
               fileMatch = { "package.json" },
               url = "https://raw.githubusercontent.com/SchemaStore/schemastore/master/src/schemas/json/package.json"
            }, {
               description = "Mozilla manifest",
               fileMatch = { "manifest.json" },
               url = "https://json.schemastore.org/web-manifest-combined.json"
            }, {
               description = 'TypeScript compiler configuration file',
               fileMatch = { 'tsconfig.json', 'tsconfig.*.json' },
               url = 'http://json.schemastore.org/tsconfig'
            }, {
               description = 'Babel configuration',
               fileMatch = {
                  '.babelrc.json', '.babelrc', 'babel.config.json'
               },
               url = 'http://json.schemastore.org/lerna'
            }, {
               description = 'ESLint config',
               fileMatch = { '.eslintrc.json', '.eslintrc' },
               url = 'http://json.schemastore.org/eslintrc'
            }, {
               description = 'Prettier config',
               fileMatch = {
                  '.prettierrc', '.prettierrc.json',
                  'prettier.config.json'
               },
               url = 'http://json.schemastore.org/prettierrc'
            }
         }
      }
   }

   config.jsonls.setup(lume.merge(opts, overrides))

end

return M
