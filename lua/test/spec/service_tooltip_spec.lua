describe("service.tooltip", function()
  local tooltip
  local cfg = require("service.config")

  before_each(function()
    package.loaded["service.tooltip"] = nil
    tooltip = require("service.tooltip")
  end)

  it("builds reusable service tooltip lines from an entry", function()
    local lines, status_hl, name_hl = tooltip.build_lines({
      category = "linter",
      entry = {
        name = "luacheck",
        meta = {
          ft = { "lua" },
          mason = "luacheck",
          note = "Lua linter",
        },
      },
      is_enabled = true,
      installed = true,
      status_text = "ok",
      status_hl = "DiagnosticOk",
      run_errors = {},
      diagnostic_summary = { error_count = 0, warn_count = 0, messages = {} },
    })

    assert.equals("DiagnosticOk", status_hl)
    assert.equals("DiagnosticOk", name_hl)
    assert.equals(" " .. cfg.tooltip.enabled_icon .. "  luacheck ", lines[1])
    assert.is_true(vim.tbl_contains(lines, "   ft:     lua "))
    assert.is_true(
      vim.tbl_contains(
        lines,
        "   mason:  luacheck " .. cfg.tooltip.installed_icon .. " "
      )
    )
    assert.is_true(vim.tbl_contains(lines, "   status: ok "))
    assert.is_true(vim.tbl_contains(lines, "   note:   Lua linter "))
  end)

  it("limits linter diagnostics and truncates long lines", function()
    local messages = {}
    for i = 1, cfg.tooltip.max_messages + 2 do
      table.insert(messages, {
        file = "very-long-file-name.lua",
        lnum = i,
        col = 1,
        severity = vim.diagnostic.severity.ERROR,
        message = string.rep("x", cfg.tooltip.max_w),
      })
    end

    local lines = tooltip.build_lines({
      category = "linter",
      entry = {
        name = "luacheck",
        meta = { ft = { "lua" } },
      },
      is_enabled = true,
      status_text = "10E 0W",
      status_hl = "DiagnosticError",
      run_errors = {
        { level = "ERROR", message = string.rep("y", cfg.tooltip.max_w) },
      },
      diagnostic_summary = {
        error_count = #messages,
        warn_count = 0,
        messages = messages,
      },
    })

    local overflow_seen = false
    for _, line in ipairs(lines) do
      assert.is_true(vim.fn.strdisplaywidth(line) <= cfg.tooltip.max_w)
      if line == "   +2 more " then
        overflow_seen = true
      end
    end
    assert.is_true(overflow_seen)
  end)
end)
