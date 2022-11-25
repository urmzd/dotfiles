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

vim.keymap.set("n", "<F5>", dap.continue, buffer_opts)
vim.keymap.set("n", "<F10>", dap.step_over, buffer_opts)
vim.keymap.set("n", "<F11>", dap.step_into, buffer_opts)
vim.keymap.set("n", "<F12>", dap.step_out, buffer_opts)
vim.keymap.set("n", "<leader>B", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, buffer_opts)
