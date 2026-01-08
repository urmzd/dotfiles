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
		},
	},
}
