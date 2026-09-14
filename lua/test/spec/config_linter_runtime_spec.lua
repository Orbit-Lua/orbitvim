describe("config.linter.runtime", function()
  local original_lint
  local buffers

  before_each(function()
    original_lint = package.loaded.lint
    buffers = {
      vim.api.nvim_create_buf(false, true),
      vim.api.nvim_create_buf(false, true),
    }
    for _, bufnr in ipairs(buffers) do
      vim.bo[bufnr].filetype = "lua"
    end
    package.loaded["config.linter.runtime"] = nil
  end)

  after_each(function()
    package.loaded.lint = original_lint
    package.loaded["config.linter.runtime"] = nil
    for _, bufnr in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end
    pcall(vim.api.nvim_del_augroup_by_name, "nvim-lint")
  end)

  it(
    "debounces independently per buffer and lints in the originating buffer",
    function()
      local runs = {}
      package.loaded.lint = {
        linters = {},
        linters_by_ft = {},
        try_lint = function()
          table.insert(runs, vim.api.nvim_get_current_buf())
        end,
      }

      require("config.linter.runtime").setup({
        events = { "TextChanged" },
        linters = {},
        linters_by_ft = { lua = { "luacheck" } },
      })

      vim.api.nvim_exec_autocmds("TextChanged", { buffer = buffers[1] })
      vim.api.nvim_exec_autocmds("TextChanged", { buffer = buffers[2] })
      assert.is_true(vim.wait(1000, function()
        return #runs == 2
      end))
      table.sort(runs)
      local expected = { buffers[1], buffers[2] }
      table.sort(expected)
      assert.same(expected, runs)
    end
  )
end)
