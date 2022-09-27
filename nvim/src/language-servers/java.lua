local root_dir = require("utils.path").root_dir;

local M = {}

-- local function get_java_cmd()
--    local executable = "java"
--    local jar = table.concat({
--       root_dir, "plugins", "org.eclipse.equinox.launcher_*.jar"
--    }, "/")
--    return {
--       executable, "-Declipse.application=org.eclipse.jdt.ls.core.id1",
--       "-Dosgi.bundles.defaultStartLevel=4",
--       "-Declipse.product=org.eclipse.jdt.ls.core.product",
--       "-Dlog.protocol=true", "-Dlog.level=ALL", "-Xms1g", "-Xmx2G",
--       "-javaagent:" .. table.concat({ root_dir, "lombok.jar" }, "/"), "-jar", jar,
--       "-configuration", table.concat({ root_dir, "config_linux" }, "/"), "-data",
--       vim.env.WORKSPACE and vim.env.WORKSPACE or
--           table.concat({ vim.env.HOME, "workspace" }, "/"), "--add-modules=ALL-SYSTEM",
--       "--add-opens", "java.base/java.util=ALL-UNNAMED", "--add-opens",
--       "java.base/java.lang=ALL-UNNAMED"
--    }
-- end

local lume = require("lume")

function M.setup(config, opts)
   config.jdtls.setup(
      lume.merge(opts, {
         -- cmd = get_java_cmd(),
         settings = {
            java = {
               format = {
                  settings = {
                     url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
                     profile = "GoogleStyle"
                  },
                  enabled = true
               },
               trace = {
                  server = "verbose"
               },
               maven = {
                  downloadSources = true
               },
               import = {
                  maven = {
                     enabled = true
                  }
               }
            }
         },
         use_lombok_agent = true
      }))

end

return M
