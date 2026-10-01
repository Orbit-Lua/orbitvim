describe("utils.fs", function()
  local test = require("tests.helpers")
  local fs = require("utils.fs")
  local original_get_clients
  local original_root_pattern

  before_each(function()
    original_get_clients = vim.lsp.get_clients
    original_root_pattern = fs.root_pattern
  end)

  after_each(function()
    vim.lsp.get_clients = original_get_clients
    fs.root_pattern = original_root_pattern
    test.cleanup_all()
  end)

  it(
    "shortens paths by display structure and supports cwd-relative output",
    function()
      assert.equals("", fs.pretty_path(""))
      assert.is_nil(fs.pretty_path("/a/b", { length = 3 }):find("…", 1, true))

      local shortened = fs.pretty_path("/a/b/c/d/e/f", { length = 2 })
      assert.is_truthy(shortened:find("…", 1, true))

      local cwd_path = fs.pretty_path(vim.fn.getcwd() .. "/src/main.lua", {
        only_cwd = true,
        length = -1,
      })
      assert.equals("src/main.lua", cwd_path)
    end
  )

  it("discovers project roots from directory and file markers", function()
    local cases = {
      { marker = ".git", directory = true },
      { marker = "pyproject.toml", content = "[project]\n" },
      { marker = "go.mod", content = "module example.test/app\n" },
    }

    for index, case in ipairs(cases) do
      local root = test.temp_dir("root-marker-" .. index)
      local nested = root .. "/src/deep"
      vim.fn.mkdir(nested, "p")
      if case.directory then
        vim.fn.mkdir(root .. "/" .. case.marker, "p")
      else
        test.write_file(root .. "/" .. case.marker, case.content)
      end
      assert.equals(root, fs.get_root(nested .. "/main.lua"), case.marker)
    end
  end)

  it("prefers an attached LSP root for the current buffer", function()
    local root = test.temp_dir("lsp-root")
    vim.lsp.get_clients = function(opts)
      assert.equals(0, opts.bufnr)
      return { { config = { root_dir = root } } }
    end

    local resolved = fs.get_root()
    assert.equals(root, resolved)
  end)

  it(
    "discovers markers for explicit paths and otherwise uses their directory",
    function()
      local root = test.temp_dir("marker-root")
      local nested = root .. "/src/deep"
      vim.fn.mkdir(root .. "/.git", "p")
      vim.fn.mkdir(nested, "p")

      assert.equals(root, fs.get_root(nested .. "/main.lua"))

      local standalone = test.temp_dir("standalone") .. "/query.sql"
      fs.root_pattern = { "_orbitvim_missing_root_marker_" }
      local fallback = fs.get_root(standalone)

      assert.equals(vim.fs.dirname(standalone), fallback)
    end
  )

  it("scans files and directories with deterministic filtering", function()
    local root = test.temp_dir("scandir")
    vim.fn.mkdir(root .. "/subdir", "p")
    for _, name in ipairs({ "z.lua", "a.lua", "m.lua" }) do
      test.write_file(root .. "/" .. name, name)
    end

    assert.same({ "a.lua", "m.lua", "z.lua" }, fs.scandir(root, "file"))
    assert.same({ "subdir" }, fs.scandir(root, "directory"))
    assert.same(
      { "a.lua", "m.lua", "subdir", "z.lua" },
      fs.scandir(root, "all")
    )
    assert.same({}, fs.scandir(root .. "/missing", "all"))
  end)

  it(
    "deletes selected files while preserving skip-condition matches",
    function()
      local root = test.temp_dir("delete-files")
      test.write_file(root .. "/main.shada", "keep")
      test.write_file(root .. "/old.shada.tmp", "remove")

      fs.delete_files(root, {
        skip_condition = function(name)
          return name == "main.shada"
        end,
      })

      assert.equals(1, vim.fn.filereadable(root .. "/main.shada"))
      assert.equals(0, vim.fn.filereadable(root .. "/old.shada.tmp"))
    end
  )
end)
