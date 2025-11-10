return {
  name = "python: pytest (with coverage)",
  builder = function()
    return {
      cmd = "python",
      args = { "-m", "pytest", "--cov", "--cov-report=term-missing", "-v" },
      components = {
        { "on_output_quickfix", open = true },
        "on_exit_set_status",
        "default",
      },
    }
  end,
  condition = {
    filetype = { "python" },
    dir = { "pytest.ini", "setup.py", "pyproject.toml" },
  },
}
