describe("config", function()
  local config = require("config")

  describe("packages", function()
    it("is accessible", function()
      assert.is_not_nil(config.packages)
    end)
  end)

  describe("chadrc", function()
    local chadrc = require("chadrc")

    it("keeps base46 settings in the Nv UI user config", function()
      assert.equals("tokyonight", chadrc.base46.theme)
      assert.is_not_nil(chadrc.base46.hl_add)
      assert.is_not_nil(chadrc.base46.hl_override)
    end)

    it("exposes the remaining local Nv UI settings", function()
      assert.is_not_nil(chadrc.base46.integrations)
      assert.is_not_nil(chadrc.colorify)
    end)
  end)

  describe("icons.mason", function()
    it("has package_installed icon", function()
      assert.is_not_nil(config.icons.mason.package_installed)
    end)

    it("has package_pending icon", function()
      assert.is_not_nil(config.icons.mason.package_pending)
    end)

    it("has package_uninstalled icon", function()
      assert.is_not_nil(config.icons.mason.package_uninstalled)
    end)

    it("all values are non-empty strings", function()
      for k, v in pairs(config.icons.mason) do
        assert.is_true(
          type(v) == "string" and #v > 0,
          k .. " must be a non-empty string"
        )
      end
    end)
  end)

  describe("icons.dap", function()
    it("has Stopped entry", function()
      assert.is_not_nil(config.icons.dap.Stopped)
    end)

    it("has Breakpoint entry", function()
      assert.is_not_nil(config.icons.dap.Breakpoint)
    end)

    it("has BreakpointCondition entry", function()
      assert.is_not_nil(config.icons.dap.BreakpointCondition)
    end)

    it("has BreakpointRejected entry", function()
      assert.is_not_nil(config.icons.dap.BreakpointRejected)
    end)

    it("has LogPoint entry", function()
      assert.is_not_nil(config.icons.dap.LogPoint)
    end)
  end)

  describe("icons.diagnostics", function()
    it("has error icon", function()
      assert.is_not_nil(config.icons.diagnostics.error)
    end)

    it("has warning icon", function()
      assert.is_not_nil(config.icons.diagnostics.warning)
    end)

    it("has hint icon", function()
      assert.is_not_nil(config.icons.diagnostics.hint)
    end)

    it("has info icon", function()
      assert.is_not_nil(config.icons.diagnostics.info)
    end)

    it("all values are non-empty strings", function()
      for k, v in pairs(config.icons.diagnostics) do
        assert.is_true(
          type(v) == "string" and #v > 0,
          k .. " must be a non-empty string"
        )
      end
    end)
  end)

  describe("icons.git", function()
    it("has added icon", function()
      assert.is_not_nil(config.icons.git.added)
    end)

    it("has modified icon", function()
      assert.is_not_nil(config.icons.git.modified)
    end)

    it("has removed icon", function()
      assert.is_not_nil(config.icons.git.removed)
    end)
  end)

  describe("icons.separators", function()
    it("exposes default separators", function()
      assert.is_not_nil(config.icons.separators.default)
      assert.is_not_nil(config.icons.separators.default.left)
      assert.is_not_nil(config.icons.separators.default.right)
    end)

    it("exposes round separators", function()
      assert.is_not_nil(config.icons.separators.round)
      assert.is_not_nil(config.icons.separators.round.left)
      assert.is_not_nil(config.icons.separators.round.right)
    end)

    it("exposes block separators", function()
      assert.is_not_nil(config.icons.separators.block)
    end)

    it("exposes arrow separators", function()
      assert.is_not_nil(config.icons.separators.arrow)
    end)
  end)

  describe("icons.kinds", function()
    local required_kinds = {
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
    }

    for _, kind in ipairs(required_kinds) do
      it("has " .. kind .. " icon", function()
        assert.is_not_nil(config.icons.kinds[kind])
        assert.is_true(type(config.icons.kinds[kind]) == "string")
      end)
    end
  end)

  describe("message_ignored", function()
    it("has an lsp sub-table", function()
      assert.is_not_nil(config.message_ignored.lsp)
      assert.is_true(type(config.message_ignored.lsp) == "table")
    end)

    it("has a notify sub-table", function()
      assert.is_not_nil(config.message_ignored.notify)
      assert.is_true(type(config.message_ignored.notify) == "table")
    end)
  end)
end)
