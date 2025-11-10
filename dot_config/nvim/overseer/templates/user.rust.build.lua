return {
  name = "rust: cargo test",
  builder = function()
    return {
      cmd = "cargo",
      args = { "test", "--", "--nocapture" },
      components = {
        { "on_output_quickfix", open = true },
        "on_exit_set_status",
        "default",
      },
      cwd = vim.fn.getcwd(),
    }
  end,
  condition = {
    filetype = { "rust" },
    dir = { "Cargo.toml" },
  },
}
