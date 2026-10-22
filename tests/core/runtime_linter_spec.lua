describe("runtime.linter", function()
  local test = require("tests.helpers")
  local runtime
  local previous_lint
  local previous_runtime
  local buffers
  local test_buffers
  local original_buffer
  local original_ppid

  before_each(function()
    original_ppid = vim.env.ESLINT_D_PPID
    previous_lint = package.loaded.lint
    previous_runtime = package.loaded["runtime.linter"]
    package.loaded["runtime.linter"] = nil
    buffers = {}
    test_buffers = {}
    original_buffer = vim.api.nvim_get_current_buf()
    package.loaded.lint = {
      linters = { probe = { cmd = vim.v.progpath } },
      linters_by_ft = {},
      _resolve_linter_by_ft = function()
        return { "probe" }
      end,
      try_lint = function()
        buffers[#buffers + 1] = vim.api.nvim_get_current_buf()
      end,
    }
    runtime = require("runtime.linter")
  end)

  after_each(function()
    vim.env.ESLINT_D_PPID = original_ppid
    for _, bufnr in ipairs(test_buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
      end
    end
    pcall(vim.api.nvim_del_augroup_by_name, "nvim-lint")
    if vim.api.nvim_buf_is_valid(original_buffer) then
      vim.api.nvim_set_current_buf(original_buffer)
    end
    package.loaded.lint = previous_lint
    package.loaded["runtime.linter"] = previous_runtime
    test.cleanup_all()
  end)

  it(
    "runs per captured buffer and cancels timers from an older setup",
    function()
      local a = vim.api.nvim_create_buf(true, false)
      local b = vim.api.nvim_create_buf(true, false)
      local unrelated = vim.api.nvim_create_buf(true, false)
      test_buffers = { a, b, unrelated }
      vim.bo[a].filetype = "lua"
      vim.bo[b].filetype = "lua"
      vim.bo[unrelated].filetype = "lua"
      local opts = {
        events = { "BufWritePost" },
        linters_by_ft = { lua = { "probe" } },
        linters = {},
      }

      runtime.setup(opts)
      vim.api.nvim_exec_autocmds("BufWritePost", { buffer = a })
      vim.api.nvim_exec_autocmds("BufWritePost", { buffer = b })
      vim.api.nvim_set_current_buf(unrelated)
      assert.is_true(vim.wait(1000, function()
        return #buffers == 2
      end))
      table.sort(buffers)
      assert.same({ a, b }, buffers)

      buffers = {}
      vim.api.nvim_exec_autocmds("BufWritePost", { buffer = a })
      runtime.setup(opts)
      vim.api.nvim_exec_autocmds("BufWritePost", { buffer = b })
      vim.api.nvim_exec_autocmds("BufWritePost", { buffer = a })
      vim.api.nvim_buf_delete(a, { force = true })
      assert.is_true(vim.wait(1000, function()
        return #buffers == 1
      end))
      assert.same({ b }, buffers)
    end
  )
end)
