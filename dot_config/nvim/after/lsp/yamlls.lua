--@type vim.lsp.Config
return {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml", "yaml.docker-compose" },
	root_markers = { ".git" },
	settings = {
		yaml = {
			format = {
				singleQuote = true,
			},
			-- schemastore.nvim supplies the catalog, so the server's own
			-- fetch of it is turned off rather than run alongside.
			schemaStore = { enable = false, url = "" },
			schemas = require("schemastore").yaml.schemas(),
		},
	},
}
