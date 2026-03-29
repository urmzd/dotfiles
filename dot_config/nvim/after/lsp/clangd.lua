---@type vim.lsp.Config
return {
	cmd = { "clangd" },
	filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
	root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git" },
}
