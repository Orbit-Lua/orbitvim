describe("tool.state", function()
  local test = require("test.helpers")
  local tools = require("config.tools")
  local state
  local state_path

  local function reload()
    package.loaded["tool.state"] = nil
    state = require("tool.state")
  end

  before_each(function()
    state_path = test.temp_dir("tool-state") .. "/tools.json"
    vim.g.tool_state_path = state_path
    reload()
  end)

  after_each(function()
    vim.g.tool_state_path = nil
    package.loaded["tool.state"] = nil
    test.cleanup_all()
  end)

  it("builds deterministic defaults from the tool registry", function()
    local loaded = state.load()

    for _, category in ipairs({ "lsp", "dap", "linter", "formatter" }) do
      local expected = {}
      for name in pairs(tools[category]) do
        expected[name] = true
      end
      assert.same(expected, loaded[category], category)
    end

    assert.same(tools.formatter_defaults, loaded.formatter_order)
    assert.same(tools.linter_defaults, loaded.linter_order)
  end)

  it(
    "falls back to legacy service state when the current file is absent",
    function()
      local legacy_path = test.temp_dir("legacy-state") .. "/service.json"
      test.write_file(
        legacy_path,
        vim.json.encode({ lsp = { lua_ls = false } })
      )

      local loaded = state.load({
        path = state_path .. ".missing",
        legacy_path = legacy_path,
      })

      assert.is_false(loaded.lsp.lua_ls)
      assert.is_true(loaded.lsp.pyright)
    end
  )

  it("falls back safely for malformed persisted state", function()
    for index, content in ipairs({ "{broken", "null", "[]" }) do
      local path = test.temp_dir("invalid-state-" .. index) .. "/tools.json"
      test.write_file(path, content)
      assert.same(
        state.load({ path = state_path .. ".missing" }),
        state.load({
          path = path,
          legacy_path = path .. ".missing",
        })
      )
    end
  end)

  it("accepts only known tools, booleans, and valid order lists", function()
    test.write_file(
      state_path,
      vim.json.encode({
        lsp = {
          lua_ls = false,
          pyright = "disabled",
          removed_server = false,
        },
        formatter_order = {
          python = { "ruff_format", "removed_formatter" },
          lua = { [1] = "stylua", named = "invalid" },
          invalid = "stylua",
        },
        removed_category = { anything = false },
      })
    )

    local loaded = state.load()
    assert.is_false(loaded.lsp.lua_ls)
    assert.is_true(loaded.lsp.pyright)
    assert.is_nil(loaded.lsp.removed_server)
    assert.same(
      { "ruff_format", "removed_formatter" },
      loaded.formatter_order.python
    )
    assert.is_nil(loaded.formatter_order.lua)
    assert.is_nil(loaded.formatter_order.invalid)
    assert.is_nil(loaded.removed_category)
  end)

  it("memoizes state and enables unknown tools by default", function()
    assert.equals(state.get(), state.get())
    assert.is_true(state.is_enabled("lsp", "removed_server"))
    assert.is_true(state.is_enabled("removed_category", "anything"))
  end)

  it(
    "persists enablement and ordering changes through the public interface",
    function()
      state.set_enabled("lsp", "lua_ls", false)
      state.set_order("formatter", "lua", { "stylua" })

      reload()
      assert.is_false(state.is_enabled("lsp", "lua_ls"))
      assert.same({ "stylua" }, state.get_order("formatter", "lua"))

      local persisted =
        vim.json.decode(table.concat(vim.fn.readfile(state_path)))
      assert.is_false(persisted.lsp.lua_ls)
      assert.same({ "stylua" }, persisted.formatter_order.lua)
    end
  )
end)
