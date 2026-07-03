describe("service.category.linter", function()
  local linter
  local logger
  local state
  local services = require("config.services")

  before_each(function()
    package.loaded["service.category.linter"] = nil
    package.loaded["utils.logger"] = nil
    package.loaded["service.state"] = nil

    package.loaded.lint = { linters_by_ft = { lua = { "luacheck" } } }
    logger = require("utils.logger")
    logger.clear_channel("linter")
    state = require("service.state")
    state.set_enabled("linter", "luacheck", true)
    state.set_enabled("linter", "eslint_d", true)
    linter = require("service.category.linter")
  end)

  after_each(function()
    package.loaded.lint = nil
    logger.clear_channel("linter")
    state.set_enabled("linter", "luacheck", true)
    state.set_enabled("linter", "eslint_d", true)
  end)

  it(
    "reports fully configured linters as ok when there are no diagnostics",
    function()
      local status, hl = linter.entry_status({
        name = "luacheck",
        meta = services.linter.luacheck,
        installed = true,
      })

      assert.equals("ok", status)
      assert.equals("DiagnosticOk", hl)
    end
  )

  it("reports linters missing from runtime filetype config", function()
    local status, hl = linter.entry_status({
      name = "eslint_d",
      meta = services.linter.eslint_d,
      installed = true,
    })

    assert.equals("not configured", status)
    assert.equals("DiagnosticWarn", hl)
  end)

  it("reports partial runtime wiring across declared filetypes", function()
    package.loaded.lint.linters_by_ft.typescript = { "eslint_d" }

    local status, hl = linter.entry_status({
      name = "eslint_d",
      meta = services.linter.eslint_d,
      installed = true,
    })

    assert.equals("partly configured 1/4", status)
    assert.equals("DiagnosticWarn", hl)
  end)
end)
