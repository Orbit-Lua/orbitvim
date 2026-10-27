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

  local function line_for(text)
    for index, line in ipairs(vim.api.nvim_buf_get_lines(body(), 0, -1, false)) do
      if line:find(text, 1, true) then
        return index
      end
    end
    error("missing row: " .. text)
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
      details = function(selection)
        return {
          logs = logger.get_entries("linter", selection.name),
          diagnostics = linter.get_linter_diagnostics(selection.name),
        }
      end,
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
            health_status = {
              label = "Configured",
              icon = "✓",
              severity = "DiagnosticOk",
              installation = "installed",
              source = "Mason",
              runtime = "Started",
              enabled = true,
              attention = false,
            },
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

  -- Registered after the spec's own hook, so setup follows any module reset.
  before_each(function()
    require("tests.helpers").configure_tool()
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
      assert.is_true(line_for("ruff_fix") < line_for("ruff_format"))
      select("ruff_fix")
      press("]")
      assert.is_true(vim.wait(100, function()
        return #snapshots >= 7
      end))
      assert.is_true(line_for("ruff_format") < line_for("ruff_fix"))
      local selected_line = vim.api.nvim_win_get_cursor(window)[1]
      assert.is_truthy(
        vim.api
          .nvim_buf_get_lines(buffer, selected_line - 1, selected_line, false)[1]
          :find("ruff_fix", 1, true)
      )
      press("o")
      assert.is_truthy(lines():find("ruff_fix", 1, true))
      assert.is_nil(lines():find("ft: python", 1, true))
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
      for _, size in ipairs({
        { 180, 45 },
        { 120, 40 },
        { 120, 21 },
        { 48, 40 },
      }) do
        vim.o.columns, vim.o.lines = size[1], size[2]
        local count = #snapshots
        vim.api.nvim_exec_autocmds("VimResized", {})
        assert.is_true(vim.wait(100, function()
          return #snapshots > count
        end))
        assert.equals(body(), vim.api.nvim_get_current_buf())
        local preview = buffer_for("ToolManagerDetails")
        if size[1] < 85 or size[2] < 23 then
          assert.is_nil(preview)
        else
          local frame = vim.fn.bufwinid(buffer_for("ToolManagerFrame"))
          assert.is_not_nil(preview)
          local preview_window = vim.fn.bufwinid(preview)
          local fp = vim.api.nvim_win_get_position(frame)
          local dp = vim.api.nvim_win_get_position(preview_window)
          assert.is_true(
            dp[2] >= fp[2] + vim.api.nvim_win_get_width(frame) + 2
              or dp[1] >= fp[1] + vim.api.nvim_win_get_height(frame) + 2
          )
        end
      end
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
      local detail_text = lines(buffer_for("ToolManagerDetails"))
      assert.is_truthy(detail_text:find("Installation: Installed", 1, true))
      assert.is_truthy(detail_text:find("Source: Mason", 1, true))
      assert.is_truthy(detail_text:find("Runtime: Started", 1, true))
      assert.is_truthy(detail_text:find("Enabled: On", 1, true))
      local detail_buffer = buffer_for("ToolManagerDetails")
      assert.equals(detail_buffer, vim.api.nvim_get_current_buf())
      press("<Esc>", detail_buffer)
      assert.equals(body(), vim.api.nvim_get_current_buf())
      press("6")
      select("pyright")
      press("K")
      assert.is_truthy(
        lines(buffer_for("ToolManagerDetails")):find("Enabled: N/A", 1, true)
      )
      press("<Esc>", buffer_for("ToolManagerDetails"))
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
      assert.is_true(detail_width > 0)
      assert.is_true(vim.wo[vim.fn.bufwinid(detail_buffer)].wrap)
      assert.is_truthy(
        lines(detail_buffer):find(string.rep("診斷", 50), 1, true)
      )
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
      vim.api.nvim_win_close(
        vim.fn.bufwinid(buffer_for("ToolManagerFrame")),
        true
      )
      assert.is_true(vim.wait(100, function()
        return buffer_for("ToolManager") == nil
      end))
      vim.api.nvim_exec_autocmds("User", { pattern = "ToolManagerChanged" })
      vim.wait(20)
      assert.equals(count + 1, #snapshots)
      for _, autocmd in ipairs(vim.api.nvim_get_autocmds({})) do
        assert.is_nil((autocmd.group_name or ""):match("^OrbitVimToolManager"))
      end
    end
  )

  it(
    "fits narrow layouts and disposes debounced refreshes and wiped buffers",
    function()
      -- Exercise the real timer without waiting for the user-facing debounce.
      local config = require("config.tool_manager")
      config.refresh.debounce_ms = 10
      tool.open()
      press("3")
      select("ruff")
      press("K")
      for _, size in ipairs({ { 120, 40 }, { 120, 24 }, { 48, 14 }, { 24, 9 } }) do
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
        local frame = vim.fn.bufwinid(buffer_for("ToolManagerFrame"))
        local origin = vim.api.nvim_win_get_position(frame)
        -- Neovim reports the outer border position; child windows start inside it.
        origin[1], origin[2] = origin[1] + 1, origin[2] + 1
        local frame_width = vim.api.nvim_win_get_width(frame)
        local frame_height = vim.api.nvim_win_get_height(frame)
        for _, filetype in ipairs({
          "ToolManagerNavigation",
          "ToolManager",
          "ToolManagerStatus",
        }) do
          local window = vim.fn.bufwinid(buffer_for(filetype))
          local position = vim.api.nvim_win_get_position(window)
          assert.equals(origin[2], position[2])
          assert.equals(frame_width, vim.api.nvim_win_get_width(window))
          assert.is_true(position[1] >= origin[1])
          assert.is_true(
            position[1] + vim.api.nvim_win_get_height(window)
              <= origin[1] + frame_height
          )
          assert.equals("none", vim.api.nvim_win_get_config(window).border)
        end
        if size[1] == 24 then
          assert.is_truthy(
            lines(buffer_for("ToolManagerNavigation")):find("Linter", 1, true)
          )
        end
        if size[1] == 120 then
          local frame_position = vim.api.nvim_win_get_position(frame)
          local frame_bottom = frame_position[1]
            + vim.api.nvim_win_get_height(frame)
          local details_window =
            vim.fn.bufwinid(buffer_for("ToolManagerDetails"))
          local details_position = vim.api.nvim_win_get_position(details_window)
          assert.is_true(details_position[1] >= frame_bottom)
        end
        for _, window in ipairs(vim.api.nvim_list_wins()) do
          local buffer = vim.api.nvim_win_get_buf(window)
          if
            vim.bo[buffer].filetype:match("^ToolManager")
            and vim.bo[buffer].filetype ~= "ToolManagerDetails"
          then
            assert.is_true(vim.api.nvim_win_get_width(window) <= vim.o.columns)
            for _, line in
              ipairs(vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
            do
              assert.is_true(vim.api.nvim_win_call(window, function()
                return vim.fn.strdisplaywidth(line)
              end) <= vim.api.nvim_win_get_width(window), line)
            end
          end
        end
      end
      press("<Esc>", buffer_for("ToolManagerDetails"))
      local count = #snapshots
      vim.api.nvim_exec_autocmds("DiagnosticChanged", { buffer = source })
      assert.is_true(vim.wait(100, function()
        return #snapshots == count + 1
      end))
      vim.api.nvim_exec_autocmds("DiagnosticChanged", { buffer = source })
      count = #snapshots
      vim.api.nvim_buf_delete(body(), { force = true })
      vim.wait(config.refresh.debounce_ms * 2)
      assert.equals(count, #snapshots)
      assert.is_nil(buffer_for("ToolManager"))
      tool.close()
    end
  )
  it(
    "fits schema-valid details preferences inside the available editor",
    function()
      local test = require("tests.helpers")
      vim.o.columns, vim.o.lines = 160, 40
      test.write_file(
        vim.g.orbitvim_settings_path,
        '{"tool_manager":{"details":{"width":300}}}'
      )
      require("core.settings").setup()
      tool.open()
      press("K")
      for _, window in ipairs(vim.api.nvim_list_wins()) do
        local buffer = vim.api.nvim_win_get_buf(window)
        if vim.bo[buffer].filetype:match("^ToolManager") then
          local position = vim.api.nvim_win_get_position(window)
          assert.is_true(position[2] >= 0)
          assert.is_true(
            position[2] + vim.api.nvim_win_get_width(window) <= vim.o.columns
          )
          assert.is_true(
            position[1] + vim.api.nvim_win_get_height(window) <= vim.o.lines
          )
        end
      end
      assert.is_not_nil(buffer_for("ToolManagerDetails"))
    end
  )

  it(
    "refreshes an open view from saved settings while preserving help and selection",
    function()
      local test = require("tests.helpers")
      vim.o.columns, vim.o.lines = 180, 50
      vim.g.orbitvim_settings_path = test.temp_dir("ui-settings")
        .. "/settings.json"
      local runtime = require("core.settings")
      runtime.setup()
      tool.open()
      select("ruff")
      press("?")
      local count = #snapshots
      test.write_file(
        vim.g.orbitvim_settings_path,
        '{"tool_manager":{"width":90}}'
      )
      vim.api.nvim_exec_autocmds(
        "BufWritePost",
        { pattern = vim.g.orbitvim_settings_path }
      )
      assert.is_true(vim.wait(200, function()
        return #snapshots > count
      end))
      assert.equals(90, vim.api.nvim_win_get_width(vim.fn.bufwinid(body())))
      press("<Space>")
      assert.same({}, operations)
      press("?")
      assert.is_truthy(vim.api.nvim_get_current_line():find("ruff", 1, true))
    end
  )

  it(
    "keeps one details pane current across rows, categories and help",
    function()
      local manager = package.loaded["tool.manager"]
      local snapshot = manager.snapshot
      manager.snapshot = function(opts)
        local result = snapshot(opts)
        if opts.category == "package" then
          result.tools, result.groups, result.summary = {}, {}, { total = 0 }
        end
        return result
      end
      local tool_only =
        { "Installation:", "Source:", "Runtime:", "Mason package:", "Backend:" }
      local function pane()
        local buffer = buffer_for("ToolManagerDetails")
        return buffer, buffer and vim.fn.bufwinid(buffer)
      end
      local function text()
        return table.concat(
          vim.api.nvim_buf_get_lines((pane()), 0, -1, false),
          "\n"
        )
      end
      local function move(row)
        select(row)
        vim.api.nvim_exec_autocmds("CursorMoved", { buffer = body() })
      end
      local function without_tool_facts()
        for _, field in ipairs(tool_only) do
          assert.is_nil(text():find(field, 1, true), field)
        end
      end
      for _, size in ipairs({ { 160, 45 }, { 100, 40 } }) do
        vim.o.columns, vim.o.lines = size[1], size[2]
        tool.open()
        press("4")
        press("s")
        local buffer, window = pane()
        assert.is_not_nil(buffer)
        assert.truthy(text():find("Priority order", 1, true))
        assert.truthy(text():find("1. ruff_fix", 1, true))
        without_tool_facts()

        -- Expansion persists across sessions, so expand only when collapsed.
        if not lines():find("ruff_format", 1, true) then
          press("o")
        end
        move("ruff_format")
        assert.truthy(text():find("ruff_format", 1, true))
        assert.truthy(text():find("Installation:", 1, true))
        move("python (")
        without_tool_facts()

        press("6")
        assert.truthy(text():find("No managed tools", 1, true))
        without_tool_facts()
        press("?")
        assert.truthy(text():find("Legend", 1, true))
        without_tool_facts()
        assert.same({ buffer, window }, { pane() })

        press("?")
        press("4")
        local header = table.concat(
          vim.api.nvim_buf_get_lines(
            buffer_for("ToolManagerNavigation"),
            0,
            -1,
            false
          ),
          "\n"
        )
        assert.truthy(header:find("Enabled", 1, true))
        assert.is_nil(lines():find("Enabled", 1, true))

        move("python (")
        press("K")
        assert.equals(window, vim.api.nvim_get_current_win())
        press("q", buffer)
        assert.equals(vim.fn.bufwinid(body()), vim.api.nvim_get_current_win())
        assert.is_true(vim.api.nvim_win_is_valid(window))

        vim.api.nvim_win_close(window, true)
        vim.wait(50)
        move("python (")
        local _, reopened = pane()
        assert.is_true(reopened ~= nil and vim.api.nvim_win_is_valid(reopened))
        tool.close()
      end

      vim.o.columns, vim.o.lines = 80, 10
      tool.open()
      local compact = table.concat(
        vim.api.nvim_buf_get_lines(
          buffer_for("ToolManagerNavigation"),
          0,
          -1,
          false
        ),
        "\n"
      )
      assert.is_nil(compact:find("Enabled", 1, true))
    end
  )
end)
