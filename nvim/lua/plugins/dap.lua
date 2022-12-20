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


vim.keymap.set("n", "<F5>", dap.continue)
vim.keymap.set("n", "<F10>", dap.step_over)
vim.keymap.set("n", "<F11>", dap.step_into)
vim.keymap.set("n", "<F12>", dap.step_out)
vim.keymap.set("n", "<leader>B", function()
  local condition = vim.fn.input("Breakpoint condition: ")
  dap.set_breakpoint(condition)
end)
