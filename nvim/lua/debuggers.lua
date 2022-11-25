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
