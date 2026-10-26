local M = {}

---Build only private copies of plugin sources, never installed dependencies.
function M.run(name, callback)
  local source = (vim.env.ORBITVIM_TEST_PLUGIN_DATA or vim.fn.stdpath("data"))
    .. "/lazy/"
    .. name
  local root = vim.fn.tempname()
  local destination = root .. "/" .. name
  local function copy(from, to)
    assert(vim.uv.fs_mkdir(to, 448))
    for entry, kind in vim.fs.dir(from) do
      if entry ~= ".git" and entry ~= "node_modules" and entry ~= "tests" then
        local input, output = from .. "/" .. entry, to .. "/" .. entry
        if kind == "directory" then
          copy(input, output)
        elseif kind == "file" then
          local generated = name == "LuaSnip"
            and (
              entry:match("%.so$")
              or entry:match("%.o$")
              or entry:match("%.a$")
            )
          if not generated then
            assert(vim.uv.fs_copyfile(input, output))
          end
        else
          error("unsupported source entry: " .. input)
        end
      end
    end
  end
  vim.fn.mkdir(root, "p")
  local ok, err = xpcall(function()
    copy(source, destination)
    if name == "LuaSnip" then
      -- Upstream runs submodule init/update. Sources are already copied, and
      -- an empty local index prevents network or installed-source mutations.
      local initialized = vim
        .system({ "git", "init", "--quiet", destination }, { text = true })
        :wait(10000)
      assert(initialized.code == 0, initialized.stderr)
    end
    callback(destination)
  end, debug.traceback)
  vim.fn.delete(root, "rf")
  assert(ok, err)
end

return M
