local path = require("nvim-lsp-installer.core.path")
local root_dir = require("utils.path").root_dir;

local mod = {}

local function get_java_opts()
    local executable = "java"
    local jar = vim.fn.expand(path.concat {
        root_dir, "plugins", "org.eclipse.equinox.launcher_*.jar"
    })
    return {
        executable, "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true", "-Dlog.level=ALL", "-Xms1g", "-Xmx2G",
        "-javaagent:" .. path.concat { root_dir, "lombok.jar" }, "-jar", jar,
        "-configuration", path.concat { root_dir, "config_linux" }, "-data",
        vim.env.WORKSPACE and vim.env.WORKSPACE or
            path.concat { vim.env.HOME, "workspace" }, "--add-modules=ALL-SYSTEM",
        "--add-opens", "java.base/java.util=ALL-UNNAMED", "--add-opens",
        "java.base/java.lang=ALL-UNNAMED"
    }
end

local lume = require("lume")

--[[
   [function setup_java_server(config, opts) 
   [    
   [
   [
   [                settings = {
   [                    ["java.format.settings.url"] = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
   [                    ["java.format.settings.profile"] = "GoogleStyle",
   [                    ["java.format.enabled"] = false,
   [                    ["java.trace.server"] = "verbose",
   [                    ["java.maven.downloadSources"] = true,
   [                    ["java.import.maven.enabled"] = true
   [                }
   [
   [end
   [
   ]]
-- mod["setup"] =

return mod
