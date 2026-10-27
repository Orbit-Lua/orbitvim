-- OrbitVim's composition of hangar.nvim: settings, activation and logs reach
-- the installed plugin through core.tools.
describe("hangar wiring through core.tools", function()
  local test = require("tests.helpers")

  before_each(function()
    vim.g.tool_state_path = test.temp_dir("hangar-wiring") .. "/tools.json"
    vim.notify = function() end
  end)

  it("applies a saved missing-package policy to the configured view", function()
    test.configure_tool()
    vim.g.orbitvim_settings_path = test.temp_dir("hangar-policy")
      .. "/settings.json"
    test.write_file(
      vim.g.orbitvim_settings_path,
      '{"tool_manager":{"missing_package_policy":"manual"}}'
    )
    -- Settings update config.tool_manager in place, the table hangar holds.
    require("core.settings").setup()
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
    "re-enables a formatter only where config.formatter activates it",
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
      local meta = require("config.tools").formatter.deno_fmt
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
