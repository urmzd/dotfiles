require('neotest').setup({
  adapters = {
    require("neotest-plenary"),
    require("neotest-python")({
      runner = "pytest",
    }),
    require("neotest-rust")
  }
})

vim.api.nvim_create_user_command(
  "NtNear",
  "lua require('neotest').run.run()",
  {}
)

vim.api.nvim_create_user_command(
  "NtFile",
  "lua require('neotest').run.run(vim.fn.expand('%'))",
  {}
)
