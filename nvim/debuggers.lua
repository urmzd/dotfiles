require("nvim-dap-virtual-text").setup()
require("dapui").setup()

local dap_python = require("dap-python")
dap_python.setup("/home/urmzd/.pyenv/shims/python")
dap_python.test_runner = "pytest"
