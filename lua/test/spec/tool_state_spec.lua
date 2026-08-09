describe("tool.state", function()
  local state
  local state_path
  local tools = require("config.tools")

  before_each(function()
    state_path = vim.fn.tempname()
    vim.g.tool_state_path = state_path
    package.loaded["tool.state"] = nil
    state = require("tool.state")
  end)

  after_each(function()
    if state_path then
      pcall(vim.fn.delete, state_path)
    end
    vim.g.tool_state_path = nil
    package.loaded["tool.state"] = nil
  end)

  describe("load", function()
    it("returns a table", function()
      local loaded = state.load()
      assert.is_true(type(loaded) == "table")
    end)

    it("falls back to legacy service.json state", function()
      local legacy_path = vim.fn.tempname()
      local file = assert(io.open(legacy_path, "w"))
      file:write(vim.json.encode({ lsp = { lua_ls = false } }))
      file:close()

      local loaded = state.load({
        path = state_path .. ".missing",
        legacy_path = legacy_path,
      })
      assert.is_false(loaded.lsp.lua_ls)
      vim.fn.delete(legacy_path)
    end)

    it("includes all four tool categories", function()
      local loaded = state.load()
      assert.is_not_nil(loaded.lsp)
      assert.is_not_nil(loaded.dap)
      assert.is_not_nil(loaded.linter)
      assert.is_not_nil(loaded.formatter)
    end)

    it("includes formatter_order", function()
      local loaded = state.load()
      assert.is_not_nil(loaded.formatter_order)
      assert.is_true(type(loaded.formatter_order) == "table")
    end)

    it("includes linter_order", function()
      local loaded = state.load()
      assert.is_not_nil(loaded.linter_order)
      assert.is_true(type(loaded.linter_order) == "table")
    end)

    it("defaults formatter_order for python from formatter_defaults", function()
      -- Only validate when no overriding file exists by comparing to tools defaults.
      local loaded = state.load()
      local defaults = tools.formatter_defaults.python
      if defaults and loaded.formatter_order.python then
        for i, name in ipairs(defaults) do
          assert.equals(name, loaded.formatter_order.python[i])
        end
      end
    end)

    it("all tool category tables have boolean values", function()
      local loaded = state.load()
      for _, cat in ipairs({ "lsp", "dap", "linter", "formatter" }) do
        for name, val in pairs(loaded[cat]) do
          assert.is_true(
            type(val) == "boolean",
            cat .. "." .. name .. " must be boolean"
          )
        end
      end
    end)
  end)

  describe("get", function()
    it("returns a table", function()
      assert.is_true(type(state.get()) == "table")
    end)

    it("returns the same table instance on repeated calls", function()
      local a = state.get()
      local b = state.get()
      assert.equals(a, b)
    end)
  end)

  describe("is_enabled", function()
    it("returns true for a tool not tracked in any category", function()
      assert.is_true(state.is_enabled("lsp", "_nonexistent_server_xyz_"))
    end)

    it("returns true for an unknown category", function()
      assert.is_true(state.is_enabled("_unknown_cat_", "anything"))
    end)

    it("returns true for every lsp server in the default state", function()
      -- After a clean load, all tools start enabled.
      -- Re-load to get defaults (may come from file, but all should be true).
      local loaded = state.load()
      for name, val in pairs(loaded.lsp) do
        assert.is_true(val, name .. " should default to enabled")
      end
    end)
  end)

  describe("set_enabled / is_enabled round-trip", function()
    it("disabling a tool makes is_enabled return false", function()
      local name = next(tools.lsp)
      if not name then
        return
      end
      state.set_enabled("lsp", name, false)
      assert.is_false(state.is_enabled("lsp", name))
      -- restore
      state.set_enabled("lsp", name, true)
    end)

    it("re-enabling a disabled tool makes is_enabled return true", function()
      local name = next(tools.lsp)
      if not name then
        return
      end
      state.set_enabled("lsp", name, false)
      state.set_enabled("lsp", name, true)
      assert.is_true(state.is_enabled("lsp", name))
    end)

    it("works for linter category", function()
      local name = next(tools.linter)
      if not name then
        return
      end
      state.set_enabled("linter", name, false)
      assert.is_false(state.is_enabled("linter", name))
      state.set_enabled("linter", name, true)
    end)

    it("works for formatter category", function()
      local name = next(tools.formatter)
      if not name then
        return
      end
      state.set_enabled("formatter", name, false)
      assert.is_false(state.is_enabled("formatter", name))
      state.set_enabled("formatter", name, true)
    end)
  end)

  describe("get_order / set_order round-trip", function()
    it("get_order returns nil for an unknown filetype", function()
      assert.is_nil(state.get_order("formatter", "_nonexistent_ft_xyz_"))
    end)

    it("stores and retrieves a custom formatter order", function()
      local order = { "tool_a", "tool_b", "tool_c" }
      state.set_order("formatter", "_test_ft_", order)
      assert.same(order, state.get_order("formatter", "_test_ft_"))
    end)

    it("stores and retrieves a custom linter order", function()
      local order = { "linter_x", "linter_y" }
      state.set_order("linter", "_test_ft2_", order)
      assert.same(order, state.get_order("linter", "_test_ft2_"))
    end)

    it("overwrites a previously set order", function()
      state.set_order("formatter", "_overwrite_ft_", { "first" })
      state.set_order("formatter", "_overwrite_ft_", { "second" })
      assert.same({ "second" }, state.get_order("formatter", "_overwrite_ft_"))
    end)
  end)
end)
