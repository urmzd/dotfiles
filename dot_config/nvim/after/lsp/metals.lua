---@type vim.lsp.Config
return {
	cmd = { "metals" },
	filetypes = { "scala", "sbt" },
	root_markers = { "build.sbt", "build.sc", "build.gradle", "pom.xml", ".git" },
}
