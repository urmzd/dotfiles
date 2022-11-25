local dap, dap_ui = require("dap"), require("dapui")

require("nvim-dap-virtual-text").setup {
  commented = true
}

dap_ui.setup()

local dap_python = require("dap-python")

dap_python.setup("/home/urmzd/.pyenv/shims/python")
dap_python.test_runner = "pytest"

dap.listeners.after.event_initialized["dapui_config"] = function()
  dap_ui.open()
end

dap.listeners.before.event_terminated["dapui_config"] = function()
  dap_ui.close()
end

dap.listeners.before.event_exited["dapui_config"] = function()
  dap_ui.close()
end


local buffer_opts = { noremap=true, silent=true }

vim.keymap.set("n", "<leader>dsb", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, buffer_opts)
vim.keymap.set("n", "<leader>dc", dap.continue, buffer_opts)
vim.keymap.set("n", "<leader>di", dap.step_into, buffer_opts)
vim.keymap.set("n", "<leader>dt", dap.step_out, buffer_opts)
vim.keymap.set("n", "<leader>dv", dap.step_over, buffer_opts)
vim.keymap.set("n", "<leader>dv", dap.step_over, buffer_opts)
