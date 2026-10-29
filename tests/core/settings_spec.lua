describe("JSON settings", function()
  local test = require("tests.helpers")
  local settings

  before_each(function()
    vim.g.orbitvim_settings_path = test.temp_dir("settings") .. "/settings.json"
    vim.g.hangar_state_path = test.temp_dir("settings-state") .. "/hangar.json"
    package.loaded["features.settings.config"] = nil
    settings = require("features.settings.config")
  end)

  -- Registered after the spec's own hook, so setup follows any module reset.
  before_each(function()
    require("tests.helpers").configure_tool()
  end)

  it(
    "resolves partial overrides without changing unrelated defaults",
    function()
      local missing = assert(settings.read())
      assert.equals(2, missing.editor.shiftwidth)
      test.write_file(
        settings.path(),
        [[{
      "editor": { "relativenumber": false, "shiftwidth": 4 },
      "lsp": { "inlay_hints": { "exclude": ["help"] } }
    }]]
      )
      local values = assert(settings.read())
      assert.is_false(values.editor.relativenumber)
      assert.equals(4, values.editor.shiftwidth)
      assert.equals(2, values.editor.tabstop)
      assert.same({ "help" }, values.lsp.inlay_hints.exclude)
      assert.is_true(values.lsp.inlay_hints.enabled)
    end
  )
  it(
    "rejects unknown fields, wrong types and unsupported logical tool defaults",
    function()
      for _, content in ipairs({
        '{"editor":{"relativenumber":"false"}}',
        '{"editor":{"unknown":true}}',
        '{"tools":{"formatter_defaults":{"lua":["yamlfmt"]}}}',
        '{"hangar":{"layout":{"margin":-1}}}',
        '{"hangar":{"layout":{"padding":{"vertical":9}}}}',
        '{"hangar":{"layout":{"padding":{"horizontal":9}}}}',
        '{"hangar":{"layout":{"column_gap":9}}}',
        '{"hangar":{"layout":{"gap":11}}}',
        '{"hangar":{"layout":{"margin":11}}}',
        '{"hangar":{"layout":{"spacing":1}}}',
        '{"tool_manager":{"width":90}}',
      }) do
        test.write_file(settings.path(), content)
        local values, err = settings.read()
        assert.is_nil(values)
        assert.is_truthy(err:find("settings.", 1, true))
      end
    end
  )

  it(
    "reloads saved settings and reverts removed fields without touching saved tool state",
    function()
      local buffer = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_set_current_buf(buffer)
      test.write_file(settings.path(), '{"editor":{"shiftwidth":4}}')
      local runtime = require("features.settings.runtime")
      runtime.setup()
      assert.equals(4, vim.bo[buffer].shiftwidth)
      local state = require("hangar.state")
      assert.is_true(state.set_enabled("formatter", "yaml", false))
      local persisted =
        table.concat(vim.fn.readfile(vim.g.hangar_state_path), "\n")
      test.write_file(settings.path(), '{"editor":{"relativenumber":false}}')
      vim.api.nvim_exec_autocmds("BufWritePost", { pattern = settings.path() })
      assert.equals(2, vim.bo[buffer].shiftwidth)
      assert.is_false(vim.wo.relativenumber)
      assert.equals(
        persisted,
        table.concat(vim.fn.readfile(vim.g.hangar_state_path), "\n")
      )
    end
  )
  it("rejects typed null without changing accepted settings", function()
    test.write_file(settings.path(), '{"editor":{"shiftwidth":4}}')
    local runtime = require("features.settings.runtime")
    runtime.setup()
    local before, source = settings.get(), settings.info().overrides
    local notified, notify = {}, vim.notify
    vim.notify = function(message, level)
      notified = { message, level }
    end
    local ok, err = pcall(function()
      for _, case in ipairs({
        { '{"editor":null}', "settings.editor" },
        { '{"editor":{"number":null}}', "settings.editor.number" },
        { '{"editor":{"shiftwidth":null}}', "settings.editor.shiftwidth" },
        { '{"notes":{"vault":null}}', "settings.notes.vault" },
        {
          '{"lsp":{"inlay_hints":{"exclude":null}}}',
          "settings.lsp.inlay_hints.exclude",
        },
        {
          '{"lsp":{"inlay_hints":{"exclude":[null]}}}',
          "settings.lsp.inlay_hints.exclude[1]",
        },
        {
          '{"lsp":{"servers":{"lua_ls":{"settings":null}}}}',
          "settings.lsp.servers.lua_ls.settings",
        },
      }) do
        test.write_file(settings.path(), case[1])
        local values, read_error = settings.read()
        assert.is_nil(values)
        assert.is_truthy(read_error:find(case[2] .. ": expected ", 1, true))
        local reloaded, reload_error = runtime.reload()
        assert.is_false(reloaded)
        assert.equals(read_error, reload_error)
        assert.same({ read_error, vim.log.levels.WARN }, notified)
        assert.same(before, settings.get())
        assert.same(source, settings.info().overrides)
        assert.equals(4, vim.o.shiftwidth)
      end

      -- Server-specific values are arbitrary JSON below the typed object.
      test.write_file(
        settings.path(),
        '{"lsp":{"servers":{"lua_ls":{"settings":{"nullable":null}}}}}'
      )
      local values = assert(settings.read())
      assert.equals(vim.NIL, values.lsp.servers.lua_ls.settings.nullable)
    end)
    vim.notify = notify
    assert(ok, err)
  end)

  it(
    "keeps last valid values after invalid input or a runtime apply failure",
    function()
      local runtime = require("features.settings.runtime")
      runtime.setup()
      local before = settings.get()
      local before_ui = runtime.info().values.hangar
      test.write_file(
        settings.path(),
        '{"editor":{"number":false},"hangar":{"width":0}}'
      )
      assert.is_false(runtime.reload())
      assert.same(before, settings.get())
      package.loaded["features.lsp.runtime"] = {
        apply_inlay_hints = function()
          error("inlay backend refused")
        end,
      }
      test.write_file(
        settings.path(),
        [[{
      "editor":{"shiftwidth":6},"hangar":{"width":90},
      "lsp":{"inlay_hints":{"enabled":false}}
    }]]
      )
      assert.is_false(runtime.reload())
      assert.equals(2, vim.o.shiftwidth)
      assert.same(before, settings.get())
      assert.same(before_ui, runtime.info().values.hangar)
    end
  )

  it(
    "changes only edited options while preserving unrelated buffer and window overrides",
    function()
      local runtime = require("features.settings.runtime")
      runtime.setup()
      vim.bo.shiftwidth, vim.bo.tabstop = 4, 8
      vim.wo.cursorline = false
      test.write_file(settings.path(), '{"editor":{"number":false}}')
      assert.is_true(runtime.reload())
      assert.is_false(vim.wo.number)
      assert.equals(4, vim.bo.shiftwidth)
      assert.equals(8, vim.bo.tabstop)
      assert.is_false(vim.wo.cursorline)
    end
  )

  it(
    "reports rollback failures together with the original apply error",
    function()
      local runtime = require("features.settings.runtime")
      runtime.setup()
      local setter = vim.api.nvim_set_option_value
      local restoring = false
      package.loaded["features.lsp.runtime"] = {
        apply_inlay_hints = function()
          restoring = true
          error("backend refused")
        end,
      }
      vim.api.nvim_set_option_value = function(name, value, scope)
        if restoring and name == "shiftwidth" and value == 2 then
          error("restore refused")
        end
        return setter(name, value, scope)
      end
      test.write_file(
        settings.path(),
        '{"editor":{"shiftwidth":6},"lsp":{"inlay_hints":{"enabled":false}}}'
      )
      local called, result, err = pcall(runtime.reload)
      vim.api.nvim_set_option_value = setter
      assert.is_true(called)
      assert.is_false(result)
      assert.is_truthy(err:find("backend refused", 1, true))
      assert.is_truthy(err:find("restore refused", 1, true))
      assert.is_truthy(runtime.info().error:find("rollback failed", 1, true))
      assert.equals(2, settings.get().editor.shiftwidth)
    end
  )

  it(
    "reports restart-only edits and actual override sources while observing only its own file",
    function()
      local runtime = require("features.settings.runtime")
      runtime.setup()
      runtime.setup()
      test.write_file(
        settings.path(),
        [[{
      "editor":{"relativenumber":false},"lsp":{"codelens":{"enabled":true}}
    }]]
      )
      local calls, reload = 0, runtime.reload
      runtime.reload = function()
        calls = calls + 1
        return reload()
      end
      vim.api.nvim_exec_autocmds(
        "BufWritePost",
        { pattern = settings.path() .. ".other.json" }
      )
      assert.is_true(vim.wo.relativenumber)
      vim.api.nvim_exec_autocmds("BufWritePost", { pattern = settings.path() })
      assert.equals(1, calls)
      local info = runtime.info()
      assert.is_false(info.values.editor.relativenumber)
      assert.is_false(info.values.lsp.codelens.enabled)
      assert.same({ "lsp.codelens" }, info.restart_required)
      assert.equals("settings.json", info.sources["editor.relativenumber"])
      assert.equals("default", info.sources["editor.tabstop"])
    end
  )
  it(
    "uses configured default priorities only until an order has been saved",
    function()
      test.write_file(
        settings.path(),
        [[{"tools":{"formatter_defaults":{
      "python":["ruff_format","ruff_fix","ruff_organize_imports"]
    }},"lsp":{"servers":{"pyright":{"settings":{"python":{"analysis":{"typeCheckingMode":"strict"}}}}}}}]]
      )
      require("features.settings.runtime").setup()
      local state = require("hangar.state")
      assert.same(
        { "ruff_format", "ruff_fix", "ruff_organize_imports" },
        state.get_order("formatter", "python")
      )
      assert.is_true(
        state.set_order("formatter", "python", { "ruff_fix", "ruff_format" })
      )
      package.loaded["hangar.state"] = nil
      assert.same(
        { "ruff_fix", "ruff_format" },
        require("hangar.state").get_order("formatter", "python")
      )
      assert.equals(
        "strict",
        require("features.lsp.config").servers.pyright.settings.python.analysis.typeCheckingMode
      )
    end
  )
end)
