vim.opt.runtimepath:prepend(vim.fn.getcwd())
package.path = vim.fn.getcwd() .. "/?.lua;" .. package.path
require("scripts.tests.build_fixture").run("LuaSnip", function(directory)
  local build
  for _, dependency in ipairs(require("plugins.completion")[1].dependencies) do
    if type(dependency) == "table" and dependency[1] == "L3MON4D3/LuaSnip" then
      build = dependency.build
    end
  end
  assert(build, "LuaSnip build is not configured")({ dir = directory })
  vim.opt.runtimepath:append(directory)
  local compile = assert(
    require("luasnip.util.jsregexp"),
    "LuaSnip native extension is unavailable"
  )
  local regex = assert(compile("^hello$", ""))
  assert(regex:exec("hello"), "native regex did not match")
  assert(not regex:exec("other"), "native regex ignored its pattern")
  print("LuaSnip native build and regex execution passed")
end)
