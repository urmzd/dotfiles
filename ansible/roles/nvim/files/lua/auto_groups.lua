vim.api.nvim_create_autocmd(
  { "InsertEnter" },
  {
  pattern = {"*"},
  callback = function()
    vim.api.nvim_set_option("hlsearch", false)
  end
})

vim.api.nvim_create_autocmd(
  { "BufWinEnter" },
  {
    pattern = { "*.md" },
    callback = function()
      vim.api.nvim_exec("e", false)
    end
  }
)
