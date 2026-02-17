--@type vim.lsp.Config
return {
	cmd = { "ltex-ls" },
	filetypes = { "markdown", "mdx", "text", "gitcommit" },
	root_markers = { ".git" },
	settings = {
		ltex = {
			language = "en-US",
			checkFrequency = "save",
			disabledRules = {
				["en-US"] = { "MORFOLOGIK_RULE_EN_US" },
			},
		},
	},
}
