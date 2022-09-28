local M = {}

local lume = require("lume")

function M.setup(config, opts)
   local new_config = lume.merge(opts, {
         -- cmd = get_java_cmd(),
         settings = {
            java = {
               configuration = {
                  runtimes = {
                     {
                        name = "JavaSE-11",
                        path = "~/.sdkman/candidate/java/11.0.10-open",
                        default = true
                     }
                  }
               },
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
      })

   

   config.jdtls.setup(new_config)
end

return M
