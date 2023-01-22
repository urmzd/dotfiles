local nt = require("neotest")

nt.setup({
  adapters = {
    require("neotest-plenary"),
    require("neotest-python")({
      runner = "pytest",
    }),
    require("neotest-rust")
  }
})

vim.keymap.set("n", '<leader>ts', function() nt.summary.toggle() end, {remap=true})
vim.keymap.set("n", '<leader>tr', function() nt.summary.run_marked() end,{remap=true})
