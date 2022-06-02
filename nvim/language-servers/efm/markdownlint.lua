local M = {
   lintCommand = "mdl -s",
   lintStdin = true,
   lintFormats = { "%f:%l %m", "%f:l:%c %m", "%f: %l: %m" }
}

return M
