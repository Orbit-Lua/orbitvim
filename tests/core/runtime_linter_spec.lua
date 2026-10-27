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
    pcall(vim.api.nvim_del_augroup_by_name, "OrbitVimLint")
    if vim.api.nvim_buf_is_valid(original_buffer) then
      vim.api.nvim_set_current_buf(original_buffer)
    end
    package.loaded.lint = previous_lint
    package.loaded["runtime.linter"] = previous_runtime
    test.cleanup_all()
  end)

  -- Registered after the spec's own hook, so setup follows any module reset.
  before_each(function()
    require("tests.helpers").configure_tool()
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

  it("lints compound filetypes with each part's linters", function()
    local buffer = vim.api.nvim_create_buf(true, false)
    test_buffers = { buffer }
    vim.bo[buffer].filetype = "markdown.mdx"
    runtime.setup({
      events = { "BufWritePost" },
      linters_by_ft = { markdown = { "probe" } },
      linters = {},
    })

    vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buffer })

    assert.is_true(vim.wait(1000, function()
      return #buffers == 1
    end))
  end)

  it("runs slow linters only when a burst includes more than edits", function()
    local buffer = vim.api.nvim_create_buf(true, false)
    test_buffers = { buffer }
    vim.bo[buffer].filetype = "sql"
    local runs = {}
    package.loaded.lint.linters.slow = { cmd = vim.v.progpath }
    package.loaded.lint.try_lint = function(names)
      runs[#runs + 1] = table.concat(names, ",")
    end
    runtime.setup({
      events = { "BufWritePost", "TextChanged" },
      linters_by_ft = { sql = { "probe", "slow" } },
      linters = {},
      skip_while_editing = { "slow" },
    })

    vim.api.nvim_exec_autocmds("TextChanged", { buffer = buffer })
    assert.is_true(vim.wait(1000, function()
      return #runs == 1
    end))
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = buffer })
    vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buffer })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = buffer })
    assert.is_true(vim.wait(1000, function()
      return #runs == 2
    end))

    assert.same({ "probe", "probe,slow" }, runs)
  end)

  it("strips CRLF on Windows for table and factory linters", function()
    local os_utils = require("utils.os")
    local is_win = os_utils.is_win
    os_utils.is_win = function()
      return true
    end
    local ok, err = pcall(function()
      local function echo(output)
        return output
      end
      package.loaded.lint.linters.factory = function()
        return { parser = echo }
      end
      local opts = {
        events = { "BufWritePost" },
        linters_by_ft = {},
        linters = { direct = { parser = echo } },
      }
      runtime.setup(opts)
      local linters = package.loaded.lint.linters
      local parser, factory = linters.direct.parser, linters.factory
      runtime.setup(opts)

      assert.equals(parser, linters.direct.parser)
      assert.equals(factory, linters.factory)
      assert.equals("a\nb", linters.direct.parser("a\r\nb"))
      assert.equals("a\nb", linters.factory().parser("a\r\nb"))
    end)
    os_utils.is_win = is_win
    assert(ok, err)
  end)
end)
