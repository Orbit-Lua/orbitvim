describe("hangar settings integration", function()
  local test = require("tests.helpers")
  local tool, source, original_window, original_runtimepath
  local original_columns, original_lines, original_update_ui, updates

  local function body()
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
      if
        vim.api.nvim_buf_is_loaded(buffer)
        and vim.bo[buffer].filetype == "Hangar"
      then
        return buffer
      end
    end
    error("missing Hangar buffer")
  end

  local function press(key)
    local mapping = vim.api.nvim_buf_call(body(), function()
      return vim.fn.maparg(key, "n", false, true)
    end)
    assert(mapping.callback, "missing mapping: " .. key)()
  end

  local function select(text)
    local buffer = body()
    for index, line in ipairs(vim.api.nvim_buf_get_lines(buffer, 0, -1, false)) do
      if line:find(text, 1, true) then
        vim.api.nvim_win_set_cursor(vim.fn.bufwinid(buffer), { index, 0 })
        return
      end
    end
    error("missing entry: " .. text)
  end

  local function save(values)
    test.write_file(vim.g.orbitvim_settings_path, vim.json.encode(values))
    vim.api.nvim_exec_autocmds(
      "BufWritePost",
      { pattern = vim.g.orbitvim_settings_path }
    )
  end

  before_each(function()
    original_runtimepath = vim.o.runtimepath
    original_window = vim.api.nvim_get_current_win()
    original_columns, original_lines = vim.o.columns, vim.o.lines
    local nui = test.plugin_path("nui.nvim")
    assert.equals(
      1,
      vim.fn.isdirectory(nui),
      "nui.nvim is required for UI specs"
    )
    vim.opt.runtimepath:append(nui)
    source = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(original_window, source)
    vim.bo[source].filetype = "python"
    vim.api.nvim_buf_set_name(
      source,
      test.temp_dir("ui-source") .. "/sample.py"
    )
    vim.g.orbitvim_settings_path = test.temp_dir("ui-settings")
      .. "/settings.json"
    test.configure_tool()
    tool = require("hangar")
    original_update_ui = tool.update_ui
    updates = {}
    tool.update_ui = function(values)
      updates[#updates + 1] = vim.deepcopy(values)
      return original_update_ui(values)
    end
  end)

  after_each(function()
    if tool then
      tool.close()
      tool.update_ui = original_update_ui
    end
    if vim.api.nvim_win_is_valid(original_window) then
      vim.api.nvim_set_current_win(original_window)
    end
    if vim.api.nvim_buf_is_valid(source) then
      vim.api.nvim_buf_delete(source, { force = true })
    end
    vim.o.runtimepath = original_runtimepath
    vim.o.columns, vim.o.lines = original_columns, original_lines
  end)

  it(
    "refreshes an open view from saved settings while preserving help and selection",
    function()
      vim.o.columns, vim.o.lines = 180, 50
      require("features.settings.runtime").setup()
      tool.open()
      select("ruff")
      press("?")
      local count = #updates
      save({ hangar = { width = 90 } })
      -- The public update schedules the real view refresh.
      assert.is_true(vim.wait(1000, function()
        return #updates > count
          and vim.api.nvim_win_get_width(vim.fn.bufwinid(body())) == 90
      end))
      assert.equals(90, vim.api.nvim_win_get_width(vim.fn.bufwinid(body())))
      press("?")
      assert.is_truthy(vim.api.nvim_get_current_line():find("ruff", 1, true))
    end
  )

  it("forwards saved view overrides and removes them on reload", function()
    local runtime = require("features.settings.runtime")
    runtime.setup()
    local defaults = runtime.info().values.hangar
    local empty_overrides = updates[#updates]
    local supplied = {
      details = { width = 300 },
      layout = {
        padding = { horizontal = 5, vertical = 3 },
        column_gap = 7,
        gap = 6,
        margin = 9,
      },
    }
    save({ hangar = supplied })
    assert.same(supplied.layout, updates[#updates].layout)
    assert.same(supplied.details, updates[#updates].details)
    assert.same(supplied.layout, runtime.info().values.hangar.layout)
    assert.equals(
      supplied.details.width,
      runtime.info().values.hangar.details.width
    )
    save({ hangar = vim.empty_dict() })
    assert.same(empty_overrides, updates[#updates])
    assert.same(defaults, runtime.info().values.hangar)
  end)

  it("shows hangar's defaults beside saved settings", function()
    local runtime = require("features.settings.runtime")
    runtime.setup()
    local defaults = runtime.info().values.hangar
    save({ hangar = { width = 90 } })
    local info = runtime.info()
    assert.equals(90, info.values.hangar.width)
    assert.equals("settings.json", info.sources["hangar.width"])
    assert.equals(defaults.height, info.values.hangar.height)
    assert.equals("hangar default", info.sources["hangar.height"])
    assert.equals(defaults.layout.margin, info.values.hangar.layout.margin)
    assert.equals("hangar default", info.sources["hangar.layout.margin"])
  end)
end)
