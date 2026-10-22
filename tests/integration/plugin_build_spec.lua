describe("plugin build adapters", function()
  local function compiler()
    for _, name in ipairs({ "cc", "gcc", "clang" }) do
      if vim.fn.executable(name) == 1 then
        return name
      end
    end
    error("GCC or Clang is required for build integration")
  end

  it(
    "builds a loadable Lua extension from a directory containing spaces",
    function()
      local test = require("tests.helpers")
      local root = test.temp_dir("snippet build with spaces")
      local headers = test.plugin_path("LuaSnip") .. "/deps/lua51_include"
      test.write_file(
        root .. "/extension.c",
        [[
#include <lua.h>
#ifdef _WIN32
__declspec(dllexport)
#endif
int luaopen_orbitvim_build(lua_State *state) {
  lua_pushinteger(state, 42);
  return 1;
}
]]
      )
      test.write_file(
        root .. "/Makefile",
        table.concat({
          "CC = " .. compiler(),
          "ifeq ($(OS),Windows_NT)",
          "LUA_LDLIBS = -L'$(NEOVIM_BIN_PATH)' -llua51",
          "endif",
          vim.fn.has("mac") == 1 and "LUA_LDLIBS = -undefined dynamic_lookup"
            or "",
          "install_jsregexp:",
          '\t$(CC) -shared -fPIC -I"'
            .. headers
            .. '" extension.c $(LUA_LDLIBS) -o extension.so',
        }, "\n")
      )
      local build
      for _, dependency in ipairs(require("plugins.completion")[1].dependencies) do
        if
          type(dependency) == "table" and dependency[1] == "L3MON4D3/LuaSnip"
        then
          build = dependency.build
        end
      end
      if type(build) == "function" then
        build({ dir = root })
      else
        local args = vim.fn.has("win32") == 1
            and { "powershell.exe", "-NoLogo", "-NoProfile", "-Command", build }
          or { "sh", "-c", build }
        local result = vim.system(args, { cwd = root, text = true }):wait(15000)
        assert.equals(0, result.code, result.stderr)
      end
      test.write_file(
        root .. "/load.lua",
        [[
local loader, err = package.loadlib(arg[1], "luaopen_orbitvim_build")
assert(loader, err)
assert(loader() == 42, "extension did not execute the Lua API")
]]
      )
      local loaded = vim
        .system({
          vim.v.progpath,
          "--headless",
          "-u",
          "NONE",
          "-l",
          root .. "/load.lua",
          root .. "/extension.so",
        }, { text = true })
        :wait(10000)
      assert.equals(0, loaded.code, loaded.stderr)
    end
  )

  it(
    "finishes preview installation before returning under the selected shell",
    function()
      local test = require("tests.helpers")
      local root = test.temp_dir("preview install with spaces")
      local windows = vim.fn.has("win32") == 1
      local platform = windows and "win" or "linux"
      if vim.fn.has("mac") == 1 then
        platform = vim.uv.os_uname().machine == "arm64" and "macos-arm64"
          or "macos"
      end
      test.write_file(root .. "/package.json", '{"version":"1.2.3"}')
      test.write_file(
        root .. "/version.c",
        '#include <stdio.h>\nint main(void) { puts("1.2.3"); return 0; }'
      )
      test.write_file(
        root .. "/app/install.cmd",
        "@echo off\nmkdir bin\ncopy /y payload.exe bin\\markdown-preview-win.exe >nul\n"
      )
      local compiled = vim
        .system({
          compiler(),
          root .. "/version.c",
          "-o",
          root .. "/app/payload.exe",
        }, { text = true })
        :wait(10000)
      assert.equals(0, compiled.code, compiled.stderr)
      test.write_file(
        root .. "/app/install.sh",
        "mkdir -p bin\ncp payload.exe bin/markdown-preview-" .. platform .. "\n"
      )
      local upstream = test.plugin_path("markdown-preview.nvim")
        .. "/autoload/mkdp/util.vim"
      test.write_file(
        root .. "/autoload/mkdp/util.vim",
        vim.fn.readfile(upstream)
      )
      test.write_file(
        root .. "/build.lua",
        [[
local root, repository, platform = arg[1], arg[2], arg[3]
vim.opt.runtimepath:prepend(repository)
vim.opt.runtimepath:prepend(root)
if vim.fn.has('win32') == 1 then
  vim.o.shell = 'powershell.exe'
  vim.o.shellcmdflag = '-NoLogo -NoProfile -Command'
  vim.o.shellquote, vim.o.shellxquote = '', ''
end
local build
for _, plugin in ipairs(require('plugins.editor')) do
  if plugin[1] == 'iamcco/markdown-preview.nvim' then build = plugin.build end
end
if type(build) == 'function' then build({dir=root}) else vim.cmd(build:sub(2)) end
local executable = root .. '/app/bin/markdown-preview-' .. platform .. (platform == 'win' and '.exe' or '')
local result = vim.system({executable, '--version'}, {text=true}):wait(5000)
assert(result.code == 0, result.stderr)
assert(vim.trim(result.stdout) == '1.2.3', 'installer returned before its executable was ready')
]]
      )
      local installed = vim
        .system({
          vim.v.progpath,
          "--headless",
          "-u",
          "NONE",
          "-l",
          root .. "/build.lua",
          root,
          vim.fn.getcwd(),
          platform,
        }, { text = true })
        :wait(15000)
      assert.equals(0, installed.code, installed.stderr)
    end
  )
end)
