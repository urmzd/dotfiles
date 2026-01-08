return {
	name = "go: go test",
	builder = function()
		return {
			cmd = "go",
			args = { "test", "./...", "-v", "-race" },
			components = {
				{ "on_output_quickfix", open = true },
				"on_exit_set_status",
				"default",
			},
			cwd = vim.fn.getcwd(),
		}
	end,
	condition = {
		filetype = { "go" },
		dir = { "go.mod" },
	},
}
