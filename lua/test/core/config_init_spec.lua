describe("config", function()
  local config = require("config")

  it("provides the icon values consumed by the UI", function()
    local required = {
      mason = {
        "package_pending",
        "package_installed",
        "package_uninstalled",
      },
      dap = {
        "Stopped",
        "Breakpoint",
        "BreakpointCondition",
        "BreakpointRejected",
        "LogPoint",
      },
      diagnostics = { "error", "warning", "hint", "info" },
      git = { "added", "modified", "removed" },
      kinds = {
        "Function",
        "Method",
        "Class",
        "Variable",
        "Keyword",
        "Module",
        "Field",
        "Property",
        "Snippet",
        "Text",
      },
    }

    for group, names in pairs(required) do
      for _, name in ipairs(names) do
        local value = config.icons[group][name]
        local icon = type(value) == "table" and value[1] or value
        assert.is_true(
          type(icon) == "string" and icon ~= "",
          group .. "." .. name .. " must provide an icon"
        )
      end
    end

    for name, separator in pairs(config.icons.separators) do
      assert.is_true(separator.left ~= "", name .. ".left must not be empty")
      assert.is_true(separator.right ~= "", name .. ".right must not be empty")
    end
  end)
end)
