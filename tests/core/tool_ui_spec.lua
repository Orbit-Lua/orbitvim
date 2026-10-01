describe("Tool Manager Nui sessions", function()
  local tool
  local source
  local original_window
  local original_runtimepath
  local original_notify
  local original_columns
  local original_lines
  local saved_modules
  local callbacks
  local operations
  local snapshots
  local order
  local logger
  local linter
  local original_entries
  local original_diagnostics

  local function buffer_for(filetype)
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
      if
        vim.api.nvim_buf_is_loaded(buffer)
        and vim.bo[buffer].filetype == filetype
      then
        return buffer
      end
    end
  end

  local function body()
    local buffer = assert(buffer_for("ToolManager"))
    return buffer
  end

  local function lines(buffer)
    return table.concat(
      vim.api.nvim_buf_get_lines(buffer or body(), 0, -1, false),
      "\n"
    )
  end

  local function press(key, buffer)
    local mapping = vim.api.nvim_buf_call(buffer or body(), function()
      return vim.fn.maparg(key, "n", false, true)
    end)
    assert(mapping.callback, "missing mapping: " .. key)()
  end

  local function select(text)
    local window = vim.fn.bufwinid(body())
    for index, line in ipairs(vim.api.nvim_buf_get_lines(body(), 0, -1, false)) do
      if line:find(text, 1, true) then
        vim.api.nvim_win_set_cursor(window, { index, 0 })
        return index
      end
    end
    error("missing entry: " .. text)
  end

  before_each(function()
    original_runtimepath = vim.o.runtimepath
    original_window = vim.api.nvim_get_current_win()
    original_columns, original_lines = vim.o.columns, vim.o.lines
    original_notify = vim.notify
    vim.notify = function() end
    local nui = require("tests.helpers").plugin_path("nui.nvim")
    assert.equals(
      1,
      vim.fn.isdirectory(nui),
      "nui.nvim is required for UI specs"
    )
    vim.opt.runtimepath:append(nui)
    saved_modules = {}
    for name, value in pairs(package.loaded) do
      if
        name == "tool"
        or name:match("^tool%.")
        or name == "tool.manager"
        or name == "config.tool_manager"
        or name == "utils.logger"
        or name:match("^nui[%.]?")
      then
        saved_modules[name] = value
      end
    end
    for name in pairs(saved_modules) do
      package.loaded[name] = nil
    end
    logger = require("utils.logger")
    linter = require("tool.category").linter
    original_entries = logger.get_entries
    original_diagnostics = linter.get_linter_diagnostics
    source = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(original_window, source)
    vim.bo[source].filetype = "python"
    vim.api.nvim_buf_set_name(
      source,
      require("tests.helpers").temp_dir("ui-source") .. "/sample.py"
    )
    callbacks, operations, snapshots = {}, {}, {}
    order = { "ruff_fix", "ruff_format" }
    package.loaded["tool.manager"] = {
      snapshot = function(opts)
        table.insert(snapshots, vim.deepcopy(opts))
        local names = opts.category == "formatter" and order
          or { "pyright", "ruff" }
        local tools = {}
        for _, name in ipairs(names) do
          table.insert(tools, {
            name = name,
            meta = { ft = { "python", "lua" }, source = "external" },
            enabled = true,
            status = "configured",
            status_hl = "DiagnosticOk",
          })
        end
        return {
          category = opts.category,
          tools = tools,
          groups = { { ft = "python", names = vim.deepcopy(names) } },
          summary = { total = #tools },
        }
      end,
      toggle = function(selection, callback)
        table.insert(operations, selection)
        table.insert(callbacks, callback)
      end,
      install = function(selection, callback)
        table.insert(operations, selection)
        table.insert(callbacks, callback)
      end,
      reorder = function(selection, callback)
        table.insert(operations, selection)
        order[1], order[2] = order[2], order[1]
        callback(true)
      end,
    }
    tool = require("tool")
  end)

  after_each(function()
    tool.close()
    vim.wait(20)
    if vim.api.nvim_win_is_valid(original_window) then
      vim.api.nvim_set_current_win(original_window)
    end
    if vim.api.nvim_buf_is_valid(source) then
      vim.api.nvim_buf_delete(source, { force = true })
    end
    vim.o.runtimepath = original_runtimepath
    vim.o.columns, vim.o.lines = original_columns, original_lines
    vim.notify = original_notify
    logger.get_entries = original_entries
    linter.get_linter_diagnostics = original_diagnostics
    for name in pairs(package.loaded) do
      if
        name == "tool"
        or name:match("^tool%.")
        or name == "tool.manager"
        or name == "config.tool_manager"
        or name == "utils.logger"
        or name:match("^nui[%.]?")
      then
        package.loaded[name] = saved_modules[name]
      end
    end
    require("tests.helpers").cleanup_all()
  end)

  it(
    "captures source scope, navigates categories, expands and retains reordered selection",
    function()
      tool.open()
      local buffer, window = body(), vim.api.nvim_get_current_win()
      tool.open()
      assert.equals(buffer, body())
      assert.equals(window, vim.api.nvim_get_current_win())
      assert.equals(source, snapshots[1].source.bufnr)
      assert.equals("python", snapshots[1].source.filetype)
      press("<S-Tab>")
      assert.equals("package", snapshots[#snapshots].category)
      press("<Tab>")
      assert.equals("lsp", snapshots[#snapshots].category)
      press("3")
      assert.equals("linter", snapshots[#snapshots].category)
      press("4")
      assert.equals("formatter", snapshots[#snapshots].category)
      select("ruff_fix")
      press("]")
      assert.is_true(vim.wait(100, function()
        return #snapshots >= 7
      end))
      local selected_line = vim.api.nvim_win_get_cursor(window)[1]
      assert.is_truthy(
        vim.api
          .nvim_buf_get_lines(buffer, selected_line - 1, selected_line, false)[1]
          :find("ruff_fix", 1, true)
      )
      press("o")
      assert.is_nil(lines():find("ruff_fix", 1, true))
      assert.is_truthy(vim.api.nvim_get_current_line():find("python", 1, true))
      press("s")
      assert.equals("states", snapshots[#snapshots].scope)
      assert.is_nil(lines():find("ruff_fix", 1, true))
      press("<CR>")
      assert.is_truthy(lines():find("ruff_fix", 1, true))
      tool.close()
      tool.open()
      assert.equals("formatter", snapshots[#snapshots].category)
      assert.equals("buffer", snapshots[#snapshots].scope)
      assert.is_truthy(lines():find("ruff_fix", 1, true))
    end
  )

  it(
    "keeps help inert and rejects stale callbacks after external close and reopen",
    function()
      tool.open()
      select("ruff")
      press("i")
      press("?")
      local help = lines()
      for _, key in ipairs({ "<Space>", "i", "[", "]", "o", "K" }) do
        press(key)
      end
      assert.equals(1, #operations)
      callbacks[1](true)
      vim.api.nvim_exec_autocmds("User", { pattern = "ToolManagerChanged" })
      vim.wait(20)
      assert.equals(help, lines())
      press("g?")
      assert.is_truthy(vim.api.nvim_get_current_line():find("ruff", 1, true))
      press("K")
      assert.is_truthy(
        lines(buffer_for("ToolManagerDetails")):find("ruff", 1, true)
      )
      local detail_buffer = buffer_for("ToolManagerDetails")
      assert.equals(detail_buffer, vim.api.nvim_get_current_buf())
      press("<Esc>", detail_buffer)
      assert.equals(body(), vim.api.nvim_get_current_buf())
      press("3")
      local maximum = require("config.tool_manager").details.max_messages
      logger.get_entries = function()
        return { { level = "ERROR", message = string.rep("字", 100) } }
      end
      linter.get_linter_diagnostics = function()
        local messages = {}
        for index = 1, maximum + 2 do
          messages[index] = {
            file = "sample.py",
            lnum = index,
            message = string.rep("診斷", 100),
            severity = vim.diagnostic.severity.ERROR,
          }
        end
        return { messages = messages }
      end
      select("ruff")
      press("K")
      detail_buffer = buffer_for("ToolManagerDetails")
      assert.is_truthy(lines(detail_buffer):find("+2 more", 1, true))
      local detail_width =
        vim.api.nvim_win_get_width(vim.fn.bufwinid(detail_buffer))
      for _, line in
        ipairs(vim.api.nvim_buf_get_lines(detail_buffer, 0, -1, false))
      do
        assert.is_true(vim.fn.strdisplaywidth(line) <= detail_width)
      end
      local old_buffers = {}
      for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buffer].filetype:match("^ToolManager") then
          table.insert(old_buffers, buffer)
        end
      end
      vim.api.nvim_win_close(vim.fn.bufwinid(body()), true)
      assert.is_true(vim.wait(100, function()
        return buffer_for("ToolManager") == nil
      end))
      for _, buffer in ipairs(old_buffers) do
        assert.is_false(vim.api.nvim_buf_is_valid(buffer))
      end
      tool.open()
      local count = #snapshots
      callbacks[1](true)
      vim.wait(20)
      assert.equals(count, #snapshots)
      vim.api.nvim_exec_autocmds("User", { pattern = "ToolManagerChanged" })
      assert.is_true(vim.wait(100, function()
        return #snapshots == count + 1
      end))
      tool.close()
      vim.api.nvim_exec_autocmds("User", { pattern = "ToolManagerChanged" })
      vim.wait(20)
      assert.equals(count + 1, #snapshots)
      for _, autocmd in ipairs(vim.api.nvim_get_autocmds({})) do
        assert.is_nil((autocmd.group_name or ""):match("^ToolManagerSession"))
      end
    end
  )

  it(
    "fits narrow layouts and disposes debounced refreshes and wiped buffers",
    function()
      tool.open()
      press("3")
      select("ruff")
      press("K")
      for _, size in ipairs({ { 120, 40 }, { 48, 14 }, { 24, 9 } }) do
        vim.o.columns, vim.o.lines = size[1], size[2]
        vim.api.nvim_exec_autocmds("VimResized", {})
        local count = #snapshots
        assert.is_true(vim.wait(100, function()
          return #snapshots > count
        end))
        assert.equals(
          buffer_for("ToolManagerDetails"),
          vim.api.nvim_get_current_buf()
        )
        for _, window in ipairs(vim.api.nvim_list_wins()) do
          local buffer = vim.api.nvim_win_get_buf(window)
          if vim.bo[buffer].filetype:match("^ToolManager") then
            assert.is_true(vim.api.nvim_win_get_width(window) <= vim.o.columns)
            for _, line in
              ipairs(vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
            do
              assert.is_true(
                vim.fn.strdisplaywidth(line)
                  <= vim.api.nvim_win_get_width(window),
                line
              )
            end
          end
        end
      end
      press("<Esc>", buffer_for("ToolManagerDetails"))
      vim.api.nvim_exec_autocmds("DiagnosticChanged", { buffer = source })
      local count = #snapshots
      vim.api.nvim_buf_delete(body(), { force = true })
      vim.wait(600)
      assert.equals(count, #snapshots)
      assert.is_nil(buffer_for("ToolManager"))
      tool.close()
    end
  )
end)
