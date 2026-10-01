describe("tool.category.formatter", function()
  local test = require("tests.helpers")
  local formatter
  local state
  local conform
  local tools = require("config.tools")
  local original_state_path
  local original_state_module
  local original_order_module
  local original_formatter_module
  local original_handler_module
  local original_conform

  before_each(function()
    original_state_path = vim.g.tool_state_path
    original_state_module = package.loaded["tool.state"]
    original_order_module = package.loaded["tool.order"]
    original_formatter_module = package.loaded["tool.category.formatter"]
    original_handler_module = package.loaded["tool.category.list"]
    original_conform = package.loaded.conform
    vim.g.tool_state_path = test.temp_dir("tool-category-formatter")
      .. "/tools.json"
    package.loaded["tool.category.formatter"] = nil
    package.loaded["tool.order"] = nil
    package.loaded["tool.state"] = nil

    conform = { formatters_by_ft = { python = { "ruff_format" } } }
    package.loaded.conform = conform

    state = require("tool.state")
    state.set_order("formatter", "python", { "ruff_fix", "ruff_format" })
    state.set_enabled("formatter", "ruff_fix", true)
    state.set_enabled("formatter", "ruff_format", true)
    vim.g.tool_state_path = original_state_path
    package.loaded["tool.state"] = original_state_module
    package.loaded["tool.order"] = original_order_module
    package.loaded["tool.category.formatter"] = original_formatter_module
    package.loaded["tool.category.list"] = original_handler_module
    test.cleanup_all()

    formatter = require("tool.category.formatter")
  end)

  after_each(function()
    package.loaded.conform = original_conform
    if tools.formatter_defaults.python then
      state.set_order(
        "formatter",
        "python",
        vim.deepcopy(tools.formatter_defaults.python)
      )
    end
    state.set_enabled("formatter", "ruff_fix", true)
    state.set_enabled("formatter", "ruff_format", true)
  end)

  it("re-enables a formatter at its saved runtime priority", function()
    formatter.apply_runtime({
      name = "ruff_fix",
      meta = tools.formatter.ruff_fix,
      is_enabled = true,
    })

    assert.same({ "ruff_fix", "ruff_format" }, conform.formatters_by_ft.python)
  end)

  it("reports partial runtime wiring across declared filetypes", function()
    local status, hl = formatter.entry_status({
      name = "deno_fmt",
      meta = tools.formatter.deno_fmt,
      installed = true,
    })

    assert.equals("not configured", status)
    assert.equals("DiagnosticWarn", hl)

    conform.formatters_by_ft.html = { "deno_fmt" }

    status, hl = formatter.entry_status({
      name = "deno_fmt",
      meta = tools.formatter.deno_fmt,
      installed = true,
    })

    assert.equals("partly configured 1/11", status)
    assert.equals("DiagnosticWarn", hl)
  end)

  it("reports fully configured formatters", function()
    conform.formatters_by_ft.lua = { "stylua" }

    local status, hl = formatter.entry_status({
      name = "stylua",
      meta = tools.formatter.stylua,
      installed = true,
    })

    assert.equals("configured", status)
    assert.equals("DiagnosticOk", hl)
  end)

  it(
    "maps the persisted yaml tool identity to Conform's yamlfmt runtime",
    function()
      conform.formatters_by_ft.yaml = { "yamlfmt" }
      formatter.apply_runtime({
        name = "yaml",
        meta = tools.formatter.yaml,
        is_enabled = false,
      })
      assert.same({}, conform.formatters_by_ft.yaml)

      formatter.apply_runtime({
        name = "yaml",
        meta = tools.formatter.yaml,
        is_enabled = true,
      })
      assert.same({ "yamlfmt" }, conform.formatters_by_ft.yaml)
    end
  )

  it("reports configured formatters with a missing executable", function()
    conform.formatters_by_ft.lua = { "stylua" }
    conform.get_formatter_info = function(name)
      return {
        name = name,
        available = false,
        available_msg = "Command '__orbitvim_missing_formatter_bin__' not found",
      }
    end

    local status, hl = formatter.entry_status({
      name = "stylua",
      meta = tools.formatter.stylua,
      installed = true,
    })

    assert.equals("no binary", status)
    assert.equals("DiagnosticError", hl)
  end)

  it("does not treat formatter conditions as missing executables", function()
    conform.formatters_by_ft.lua = { "stylua" }
    conform.get_formatter_info = function(name)
      return {
        name = name,
        available = false,
        available_msg = "Condition failed",
      }
    end

    local status, hl = formatter.entry_status({
      name = "stylua",
      meta = tools.formatter.stylua,
      installed = true,
    })

    assert.equals("configured", status)
    assert.equals("DiagnosticOk", hl)
  end)
end)
