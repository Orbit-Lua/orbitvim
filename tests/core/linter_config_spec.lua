describe("features.linter.config", function()
  local test = require("tests.helpers")
  local original_buf
  local test_buf
  local loaded

  before_each(function()
    loaded = {
      config = package.loaded["features.linter.config"],
      lint = package.loaded["lint"],
      parser = package.loaded["lint.parser"],
      sqlfluff = package.loaded["lint.linters.sqlfluff"],
    }
    package.loaded["lint"] = {}
    package.loaded["lint.parser"] = {
      from_errorformat = function()
        return function() end
      end,
    }
    package.loaded["lint.linters.sqlfluff"] = {
      cmd = "sqlfluff",
      stdin = true,
      args = { "lint", "--format=json", "-" },
    }
    original_buf = vim.api.nvim_get_current_buf()
    test_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(test_buf)
    package.loaded["features.linter.config"] = nil
  end)

  after_each(function()
    vim.api.nvim_set_current_buf(original_buf)
    if vim.api.nvim_buf_is_valid(test_buf) then
      vim.api.nvim_buf_delete(test_buf, { force = true })
    end
    package.loaded["features.linter.config"] = loaded.config
    package.loaded["lint"] = loaded.lint
    package.loaded["lint.parser"] = loaded.parser
    package.loaded["lint.linters.sqlfluff"] = loaded.sqlfluff
    test.cleanup_all()
  end)

  it(
    "resolves SQLFluff args, cwd, and UTF-8 from the current buffer",
    function()
      local root = test.temp_dir("sqlfluff-project")
      local filename = root .. "/query.sql"
      vim.fn.mkdir(root .. "/.git", "p")
      vim.api.nvim_buf_set_name(test_buf, filename)

      local linter = require("features.linter.config").linters.sqlfluff()

      assert.same({
        "lint",
        "--format=json",
        "--stdin-filename",
        filename,
        "--config",
        require("utils.fs").config_path
          .. "/lua/features/sql/config/template/sqlfluff.cfg",
        "-",
      }, linter.args)
      test.assert_path(root, linter.cwd)
      assert.is_true(linter.stdin)
      assert.same("1", linter.env.PYTHONUTF8)
    end
  )
end)
