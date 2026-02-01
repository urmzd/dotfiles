--@type vim.lsp.Config
return {
	cmd = { "jdtls" },
	filetypes = { "java" },
	root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts" },
	settings = {
		java = {
			format = {
				enabled = true,
			},
			maven = {
				downloadSources = true,
			},
			signatureHelp = {
				enabled = true,
			},
			contentProvider = {
				preferred = "fernflower",
			},
		},
	},
}
