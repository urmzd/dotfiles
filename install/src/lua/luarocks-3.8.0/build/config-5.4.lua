-- LuaRocks configuration

rocks_trees = {
   { name = "user", root = home .. "/.luarocks" };
   { name = "system", root = "/usr/local" };
}
lua_interpreter = "lua";
variables = {
   LUA_DIR = "/usr/local";
   LUA_INCDIR = "/usr/local/include";
   LUA_BINDIR = "/usr/local/bin";
}
