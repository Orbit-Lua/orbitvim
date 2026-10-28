describe("hangar settings integration", function()
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
    local buffer = assert(buffer_for("Hangar"))
    return buffer
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
        name == "hangar"
        or name:match("^hangar%.")
        or name == "features.hangar.config.view"
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
    linter = require("hangar.category").linter
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
    package.loaded["hangar.manager"] = {
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
    tool = require("hangar")
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
        name == "hangar"
        or name:match("^hangar%.")
        or name == "features.hangar.config.view"
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
    "fits schema-valid details preferences inside the available editor",
    function()
      local test = require("tests.helpers")
      vim.o.columns, vim.o.lines = 160, 40
      test.write_file(
        vim.g.orbitvim_settings_path,
        '{"tool_manager":{"details":{"width":300}}}'
      )
      require("features.settings.runtime").setup()
      tool.open()
      press("K")
      for _, window in ipairs(vim.api.nvim_list_wins()) do
        local buffer = vim.api.nvim_win_get_buf(window)
        if vim.bo[buffer].filetype:match("^Hangar") then
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
      assert.is_not_nil(buffer_for("HangarDetails"))
    end
  )

  it(
    "refreshes an open view from saved settings while preserving help and selection",
    function()
      local test = require("tests.helpers")
      vim.o.columns, vim.o.lines = 180, 50
      vim.g.orbitvim_settings_path = test.temp_dir("ui-settings")
        .. "/settings.json"
      local runtime = require("features.settings.runtime")
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

  it("applies, resets and bounds layout spacing from saved settings", function()
    local test = require("tests.helpers")
    vim.o.columns, vim.o.lines = 160, 45
    vim.g.orbitvim_settings_path = test.temp_dir("ui-layout")
      .. "/settings.json"
    require("features.settings.runtime").setup()
    tool.open()
    local function refreshed(apply)
      local count = #snapshots
      apply()
      assert.is_true(vim.wait(200, function()
        return #snapshots > count
      end))
    end
    local function save(layout)
      refreshed(function()
        test.write_file(
          vim.g.orbitvim_settings_path,
          vim.json.encode({ tool_manager = { layout = layout } })
        )
        vim.api.nvim_exec_autocmds(
          "BufWritePost",
          { pattern = vim.g.orbitvim_settings_path }
        )
      end)
    end
    local function resize(columns, rows)
      refreshed(function()
        vim.o.columns, vim.o.lines = columns, rows
        vim.api.nvim_exec_autocmds("VimResized", {})
      end)
    end
    ---Outer border box of a bordered window.
    local function box(filetype)
      local buffer = buffer_for(filetype)
      local window = buffer and vim.fn.bufwinid(buffer)
      if not window or window == -1 then
        return nil
      end
      local position = vim.api.nvim_win_get_position(window)
      return {
        row = position[1],
        col = position[2],
        width = vim.api.nvim_win_get_width(window) + 2,
        height = vim.api.nvim_win_get_height(window) + 2,
      }
    end
    local function measure()
      local row = line_for("pyright")
      local text = vim.api.nvim_buf_get_lines(body(), row - 1, row, false)[1]
      local frame, details = box("HangarFrame"), box("HangarDetails")
      local on = text:find("On", 1, true)
      return {
        row = row,
        indent = #text:match("^ *"),
        -- "On" is padded to the Enabled width; the gap follows it.
        -- Narrow columns can truncate the status, so it may be absent.
        status = on
          and text:find("Configured", 1, true)
          and (text:find("Configured", 1, true) - on),
        gap = details and details.col - frame.col - frame.width,
        margin = math.min(
          frame.row,
          frame.col,
          vim.o.columns - (details or frame).col - (details or frame).width
        ),
      }
    end

    local default = measure()
    assert.equals(1, default.row)
    assert.equals(2 + 2, default.indent)
    assert.equals(2, default.gap)
    assert.is_true(default.margin >= 2)

    save({ padding = { horizontal = 5 } })
    assert.equals(5 + 2, measure().indent)
    save({ padding = { vertical = 3 } })
    assert.equals(3 + 1, measure().row)
    save({ column_gap = 7 })
    assert.equals(default.status + 4, measure().status)
    save({ gap = 6 })
    assert.equals(6, measure().gap)
    save({ margin = 9 })
    assert.is_true(measure().margin >= 9)
    save(vim.empty_dict())
    assert.same(default, measure())

    -- Margin gives way first; gap shrinks only after margin reaches 0.
    save({
      padding = { vertical = 8, horizontal = 8 },
      column_gap = 8,
      gap = 10,
      margin = 10,
    })
    resize(160, 40)
    assert.equals(10, measure().gap)
    resize(160, 24)
    assert.equals(0, measure().gap)
    for _, size in ipairs({ { 48, 14 }, { 24, 9 } }) do
      resize(size[1], size[2])
      for _, filetype in ipairs({ "HangarFrame", "HangarDetails" }) do
        local window = box(filetype)
        if window then
          assert.is_true(window.row >= 0 and window.col >= 0, filetype)
          assert.is_true(window.col + window.width <= vim.o.columns, filetype)
          assert.is_true(window.row + window.height <= vim.o.lines, filetype)
        end
      end
      assert.is_true(vim.api.nvim_win_get_height(vim.fn.bufwinid(body())) >= 1)
    end
  end)
end)
