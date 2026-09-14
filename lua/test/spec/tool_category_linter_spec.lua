describe("tool.category.linter", function()
  local linter
  local logger
  local state
  local tools = require("config.tools")

  before_each(function()
    package.loaded["tool.category.linter"] = nil
    package.loaded["utils.logger"] = nil
    package.loaded["tool.state"] = nil

    package.loaded.lint = {
      linters_by_ft = { lua = { "luacheck" } },
      linters = { luacheck = { cmd = vim.v.progpath } },
    }
    logger = require("utils.logger")
    logger.clear_channel("linter")
    state = require("tool.state")
    state.set_enabled("linter", "luacheck", true)
    state.set_enabled("linter", "eslint_d", true)
    linter = require("tool.category.linter")
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
        meta = tools.linter.luacheck,
        installed = true,
      })

      assert.equals("ok", status)
      assert.equals("DiagnosticOk", hl)
    end
  )

  it("reports configured linters with a missing executable", function()
    package.loaded.lint.linters.luacheck.cmd = "__orbitvim_missing_linter_bin__"

    local status, hl = linter.entry_status({
      name = "luacheck",
      meta = tools.linter.luacheck,
      installed = true,
    })

    assert.equals("no binary", status)
    assert.equals("DiagnosticError", hl)
  end)

  it("reports linters missing from runtime filetype config", function()
    local status, hl = linter.entry_status({
      name = "eslint_d",
      meta = tools.linter.eslint_d,
      installed = true,
    })

    assert.equals("not configured", status)
    assert.equals("DiagnosticWarn", hl)
  end)

  it("reports partial runtime wiring across declared filetypes", function()
    package.loaded.lint.linters_by_ft.typescript = { "eslint_d" }

    local status, hl = linter.entry_status({
      name = "eslint_d",
      meta = tools.linter.eslint_d,
      installed = true,
    })

    assert.equals("partly configured 1/4", status)
    assert.equals("DiagnosticWarn", hl)
  end)
end)
