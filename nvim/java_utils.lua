-- @reference: https://github.com/williamboman/nvim-lsp-installer/blob/main/lua/nvim-lsp-installer/servers/jdtls/init.lua
local path = require("nvim-lsp-installer.core.path")

return function(root_dir)
    local executable = "java"
    local jar = vim.fn.expand(path.concat {
        root_dir, "plugins", "org.eclipse.equinox.launcher_*.jar"
    })
    return {
        executable, "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true", "-Dlog.level=ALL", "-Xms1g", "-Xmx2G",
        "-javaagent:" .. path.concat {root_dir, "lombok.jar"}, "-jar", jar,
        "-configuration", path.concat {root_dir, "config_linux"}, "-data",
        vim.env.WORKSPACE and vim.env.WORKSPACE or
            path.concat {vim.env.HOME, "workspace"}, "--add-modules=ALL-SYSTEM",
        "--add-opens", "java.base/java.util=ALL-UNNAMED", "--add-opens",
        "java.base/java.lang=ALL-UNNAMED"
    }
end
