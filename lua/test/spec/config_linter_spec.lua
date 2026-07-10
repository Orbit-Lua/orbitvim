describe("config.linter", function()
  local original_buf
  local test_buf

  before_each(function()
    vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/nvim-lint")
    original_buf = vim.api.nvim_get_current_buf()
    test_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(test_buf)
    package.loaded["config.linter"] = nil
  end)

  after_each(function()
    vim.api.nvim_set_current_buf(original_buf)
    vim.api.nvim_buf_delete(test_buf, { force = true })
    package.loaded["config.linter"] = nil
  end)

  it(
    "resolves SQLFluff arguments for the current buffer on every run",
    function()
      local root = vim.fn.tempname()
      local filename = root .. "/query.sql"
      vim.fn.mkdir(root .. "/.git", "p")
      vim.api.nvim_buf_set_name(test_buf, filename)

      local sqlfluff = require("utils.sqlfluff")
      local linter = require("config.linter").linters.sqlfluff()

      assert.same(sqlfluff.lint_args(filename), linter.args)
      assert.same(sqlfluff.cwd(filename), linter.cwd)
      assert.is_true(linter.stdin)

      vim.fn.delete(root, "rf")
    end
  )
end)
