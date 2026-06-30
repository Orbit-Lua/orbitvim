describe("utils.fs", function()
  local fs = require("utils.fs")

  describe("make_relative_path", function()
    it("returns relative path when buf is under root", function()
      local result = fs.make_relative_path(
        "/home/user/project/src/main.lua",
        "/home/user/project"
      )
      assert.equals("src/main.lua", result)
    end)

    it("returns empty string when buf is not under root", function()
      local result =
        fs.make_relative_path("/other/path/file.lua", "/home/user/project")
      assert.equals("", result)
    end)

    it("handles root with existing trailing slash", function()
      local result = fs.make_relative_path(
        "/home/user/project/main.lua",
        "/home/user/project/"
      )
      assert.equals("main.lua", result)
    end)

    it("returns empty string when buf equals root (not a child)", function()
      local result =
        fs.make_relative_path("/home/user/project", "/home/user/project")
      assert.equals("", result)
    end)

    it("handles nested paths", function()
      local result = fs.make_relative_path("/a/b/c/d/e.lua", "/a/b")
      assert.equals("c/d/e.lua", result)
    end)
  end)

  describe("pretty_path", function()
    it("returns empty string for an empty path argument", function()
      assert.equals("", fs.pretty_path(""))
    end)

    it(
      "returns path unchanged when parts count <= default length (3)",
      function()
        -- "/a/b" splits into {"", "a", "b"} = 3 parts, so length=3 does not truncate.
        local result = fs.pretty_path("/a/b", { length = 3 })
        assert.is_true(result ~= "")
        assert.is_true(result:find("…") == nil)
      end
    )

    it("truncates long paths and inserts an ellipsis", function()
      local result = fs.pretty_path("/a/b/c/d/e/f/g", { length = 3 })
      assert.is_true(result:find("…") ~= nil)
    end)

    it("preserves the first component in a truncated path", function()
      local result = fs.pretty_path("/home/user/a/b/c/d/e", { length = 2 })
      assert.is_true(result ~= "")
      assert.is_true(result:find("…") ~= nil)
    end)

    it("returns a non-empty string for a short absolute path", function()
      local result = fs.pretty_path("/usr/local/bin")
      assert.is_true(type(result) == "string")
      assert.is_true(#result > 0)
    end)

    it("only_cwd strips the cwd prefix from the path", function()
      local cwd = vim.fn.getcwd()
      local abs = cwd .. "/some/nested/file.lua"
      local result = fs.pretty_path(abs, { only_cwd = true })
      assert.is_true(result:sub(1, #cwd) ~= cwd)
    end)

    it("respects a custom length option", function()
      local result4 = fs.pretty_path("/a/b/c/d/e/f/g/h", { length = 4 })
      local result2 = fs.pretty_path("/a/b/c/d/e/f/g/h", { length = 2 })
      assert.is_true(#result4 >= #result2)
    end)
  end)

  describe("root_pattern", function()
    it("is a non-empty table", function()
      assert.is_true(type(fs.root_pattern) == "table")
      assert.is_true(#fs.root_pattern > 0)
    end)

    it("contains .git", function()
      assert.is_true(vim.tbl_contains(fs.root_pattern, ".git"))
    end)

    it("contains package.json", function()
      assert.is_true(vim.tbl_contains(fs.root_pattern, "package.json"))
    end)

    it("contains pyproject.toml", function()
      assert.is_true(vim.tbl_contains(fs.root_pattern, "pyproject.toml"))
    end)

    it("contains Cargo.toml", function()
      assert.is_true(vim.tbl_contains(fs.root_pattern, "Cargo.toml"))
    end)

    it("contains go.mod", function()
      assert.is_true(vim.tbl_contains(fs.root_pattern, "go.mod"))
    end)

    it("contains Makefile", function()
      assert.is_true(vim.tbl_contains(fs.root_pattern, "Makefile"))
    end)
  end)

  describe("sqlfluff_pattern", function()
    it("is a table", function()
      assert.is_true(type(fs.sqlfluff_pattern) == "table")
    end)

    it("contains .sqlfluff", function()
      assert.is_true(vim.tbl_contains(fs.sqlfluff_pattern, ".sqlfluff"))
    end)
  end)

  describe("path constants", function()
    it("config_path is a non-empty string", function()
      assert.is_true(type(fs.config_path) == "string")
      assert.is_true(#fs.config_path > 0)
    end)

    it("data_path is a non-empty string", function()
      assert.is_true(type(fs.data_path) == "string")
      assert.is_true(#fs.data_path > 0)
    end)

    it("mason_pkg_path contains mason/packages", function()
      assert.is_true(fs.mason_pkg_path:match("mason/packages") ~= nil)
    end)
  end)

  describe("scandir", function()
    it("returns an empty table for a nonexistent path", function()
      local names = fs.scandir("/nonexistent_path_xyz_abc_123", "all")
      assert.same({}, names)
    end)

    it("returns a table for an existing directory", function()
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir, "p")
      local names = fs.scandir(tmpdir, "all")
      assert.is_true(type(names) == "table")
      vim.fn.delete(tmpdir, "rf")
    end)

    it("lists files with mode 'file'", function()
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir, "p")
      local f = io.open(tmpdir .. "/test.txt", "w")
      if f then
        f:write("hello")
        f:close()
      end
      local names = fs.scandir(tmpdir, "file")
      assert.is_true(vim.tbl_contains(names, "test.txt"))
      vim.fn.delete(tmpdir, "rf")
    end)

    it("lists directories with mode 'directory'", function()
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir .. "/sub", "p")
      local names = fs.scandir(tmpdir, "directory")
      assert.is_true(vim.tbl_contains(names, "sub"))
      vim.fn.delete(tmpdir, "rf")
    end)

    it("mode 'all' lists both files and directories", function()
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir .. "/subdir", "p")
      local f = io.open(tmpdir .. "/file.txt", "w")
      if f then
        f:write("x")
        f:close()
      end
      local names = fs.scandir(tmpdir, "all")
      assert.is_true(#names >= 2)
      vim.fn.delete(tmpdir, "rf")
    end)

    it("returns names sorted alphabetically", function()
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir, "p")
      for _, name in ipairs({ "z.lua", "a.lua", "m.lua" }) do
        local f = io.open(tmpdir .. "/" .. name, "w")
        if f then
          f:write("x")
          f:close()
        end
      end

      local names = fs.scandir(tmpdir, "file")

      assert.same({ "a.lua", "m.lua", "z.lua" }, names)
      vim.fn.delete(tmpdir, "rf")
    end)
  end)
end)
