describe("utils.fs", function()
  local test = require("test.helpers")
  local fs = require("utils.fs")

  after_each(function()
    test.cleanup_all()
  end)

  it("makes paths relative only to an exact root directory", function()
    local cases = {
      { "/project/src/main.lua", "/project", "src/main.lua" },
      { "/project/main.lua", "/project/", "main.lua" },
      { "/project", "/project", "" },
      { "/project-other/main.lua", "/project", "" },
      { "/a/b/c/d/e.lua", "/a/b", "c/d/e.lua" },
    }

    for _, case in ipairs(cases) do
      assert.equals(case[3], fs.make_relative_path(case[1], case[2]))
    end
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

  it(
    "keeps the project-root marker policy complete and duplicate-free",
    function()
      local seen = {}
      for _, marker in ipairs(fs.root_pattern) do
        assert.is_nil(seen[marker], "duplicate root marker: " .. marker)
        seen[marker] = true
      end

      for _, required in ipairs({
        ".git",
        "package.json",
        "pyproject.toml",
        "Cargo.toml",
        "go.mod",
        "Makefile",
      }) do
        assert.is_true(seen[required], "missing root marker: " .. required)
      end
    end
  )

  it("prefers an attached LSP root for the current buffer", function()
    local original_get_clients = vim.lsp.get_clients
    local root = test.temp_dir("lsp-root")
    vim.lsp.get_clients = function(opts)
      assert.equals(0, opts.bufnr)
      return { { config = { root_dir = root } } }
    end

    local resolved = fs.get_root()
    vim.lsp.get_clients = original_get_clients

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
      local original_markers = fs.root_pattern
      fs.root_pattern = { "_orbitvim_missing_root_marker_" }
      local fallback = fs.get_root(standalone)
      fs.root_pattern = original_markers

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
