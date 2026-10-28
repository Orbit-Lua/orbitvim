-- OrbitVim's composition of hangar.nvim: settings, activation and logs reach
-- the installed plugin through features.hangar.runtime.
describe("hangar wiring through features.hangar.runtime", function()
  local test = require("tests.helpers")

  before_each(function()
    vim.g.hangar_state_path = test.temp_dir("hangar-wiring") .. "/hangar.json"
    vim.notify = function() end
  end)

  it("reads only hangar.json and honors an explicit state path", function()
    vim.g.hangar_state_path = nil
    local current = vim.fn.stdpath("data") .. "/hangar.json"
    -- The pre-rename file is not read and stays untouched.
    local legacy = vim.fn.stdpath("data") .. "/tools.json"
    local old_state = '{"lsp":{"lua_ls":false}}'
    test.write_file(legacy, old_state)
    test.configure_tool()
    local state = require("hangar.state")
    assert.is_true(state.is_enabled("lsp", "lua_ls"))
    assert.is_nil(vim.uv.fs_stat(current))

    assert.is_true(state.set_enabled("lsp", "lua_ls", false))
    local saved = vim.fn.readfile(current, "b")
    local persisted = vim.json.decode(table.concat(saved, "\n"))
    assert.is_false(persisted.lsp.lua_ls)

    local override = test.temp_dir("explicit-state") .. "/hangar.json"
    test.write_file(override, '{"lsp":{"lua_ls":true}}')
    vim.g.hangar_state_path = override
    test.configure_tool()
    assert.is_true(state.is_enabled("lsp", "lua_ls"))
    assert.is_true(state.set_enabled("lsp", "pyright", false))
    local overridden =
      vim.json.decode(table.concat(vim.fn.readfile(override), "\n"))
    assert.is_false(overridden.lsp.pyright)
    assert.same(saved, vim.fn.readfile(current, "b"))
    assert.same({ old_state }, vim.fn.readfile(legacy))
  end)

  it("applies a saved missing-package policy to the configured view", function()
    test.configure_tool()
    vim.g.orbitvim_settings_path = test.temp_dir("hangar-policy")
      .. "/settings.json"
    test.write_file(
      vim.g.orbitvim_settings_path,
      '{"hangar":{"missing_package_policy":"manual"}}'
    )
    -- Settings reach the configured view through hangar.update_ui.
    require("features.settings.runtime").setup()
    local mason = require("hangar.mason")
    mason.package_status = function()
      return false
    end
    local installs = 0
    mason.install = function()
      installs = installs + 1
      return true
    end
    local state = require("hangar.state")
    assert.is_true(state.set_enabled("lsp", "lua_ls", false))

    local result
    assert.is_false(
      require("hangar.manager").toggle(
        { category = "lsp", name = "lua_ls" },
        function(success, err)
          result = { success, err }
        end
      )
    )
    assert.is_false(result[1])
    assert.is_false(state.is_enabled("lsp", "lua_ls"))
    assert.equals(0, installs)
  end)

  it(
    "re-enables a formatter only where features.formatter.config activates it",
    function()
      test.configure_tool()
      local conform = {
        formatters_by_ft = {
          markdown = { "markdownlint-cli2" },
          html = { "deno_fmt" },
        },
      }
      package.loaded.conform = conform
      local formatter = require("hangar.category").formatter
      local meta = require("features.hangar.config").formatter.deno_fmt
      for _, enabled in ipairs({ false, true }) do
        formatter.apply_runtime({
          name = "deno_fmt",
          meta = meta,
          is_enabled = enabled,
        })
      end

      assert.same({ "markdownlint-cli2" }, conform.formatters_by_ft.markdown)
      assert.same({ "deno_fmt" }, conform.formatters_by_ft.html)
      assert.is_nil(conform.formatters_by_ft["markdown.mdx"])
    end
  )

  it("reports linter run errors recorded by utils.logger", function()
    test.configure_tool()
    local logger = require("utils.logger")
    logger.clear_source("linter", "luacheck")
    logger.write(
      "linter",
      "ERROR",
      "luacheck",
      "wiring probe",
      { kind = "binary_not_found" }
    )
    local logs = require("hangar.manager").details({
      category = "linter",
      name = "luacheck",
    }).logs
    logger.clear_source("linter", "luacheck")
    assert.equals("wiring probe", logs[#logs].message)
  end)
end)
