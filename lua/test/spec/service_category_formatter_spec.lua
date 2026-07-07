describe("service.category.formatter", function()
  local formatter
  local state
  local conform
  local services = require("config.services")

  before_each(function()
    package.loaded["service.category.formatter"] = nil
    package.loaded["service.order"] = nil
    package.loaded["service.state"] = nil

    conform = { formatters_by_ft = { python = { "ruff_format" } } }
    package.loaded.conform = conform

    state = require("service.state")
    state.set_order("formatter", "python", { "ruff_fix", "ruff_format" })
    state.set_enabled("formatter", "ruff_fix", true)
    state.set_enabled("formatter", "ruff_format", true)

    formatter = require("service.category.formatter")
  end)

  after_each(function()
    package.loaded.conform = nil
    if services.formatter_defaults.python then
      state.set_order(
        "formatter",
        "python",
        vim.deepcopy(services.formatter_defaults.python)
      )
    end
    state.set_enabled("formatter", "ruff_fix", true)
    state.set_enabled("formatter", "ruff_format", true)
  end)

  it("re-enables a formatter at its saved runtime priority", function()
    formatter.apply_runtime({
      name = "ruff_fix",
      meta = services.formatter.ruff_fix,
      is_enabled = true,
    })

    assert.same({ "ruff_fix", "ruff_format" }, conform.formatters_by_ft.python)
  end)

  it("reports partial runtime wiring across declared filetypes", function()
    local status, hl = formatter.entry_status({
      name = "deno_fmt",
      meta = services.formatter.deno_fmt,
      installed = true,
    })

    assert.equals("not configured", status)
    assert.equals("DiagnosticWarn", hl)

    conform.formatters_by_ft.html = { "deno_fmt" }

    status, hl = formatter.entry_status({
      name = "deno_fmt",
      meta = services.formatter.deno_fmt,
      installed = true,
    })

    assert.equals("partly configured 1/5", status)
    assert.equals("DiagnosticWarn", hl)
  end)

  it("reports fully configured formatters", function()
    conform.formatters_by_ft.lua = { "stylua" }

    local status, hl = formatter.entry_status({
      name = "stylua",
      meta = services.formatter.stylua,
      installed = true,
    })

    assert.equals("configured", status)
    assert.equals("DiagnosticOk", hl)
  end)

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
      meta = services.formatter.stylua,
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
      meta = services.formatter.stylua,
      installed = true,
    })

    assert.equals("configured", status)
    assert.equals("DiagnosticOk", hl)
  end)
end)
