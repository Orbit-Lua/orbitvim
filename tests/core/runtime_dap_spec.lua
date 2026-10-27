describe("runtime.dap", function()
  it("registers only enabled adapters and their configurations", function()
    local dap = { adapters = {}, configurations = {} }
    local definitions = {
      adapters = { python = "python-adapter", dotnet = "dotnet-adapter" },
      configurations = {
        python = {
          { type = "python", name = "launch" },
          { type = "dotnet", name = "other" },
          { name = "untyped" },
        },
      },
    }
    local state = {
      is_enabled = function(_, name)
        return name == "python"
      end,
    }

    require("runtime.dap").setup(dap, definitions, state)

    assert.same({ python = "python-adapter" }, dap.adapters)
    assert.same({
      python = {
        { type = "python", name = "launch" },
        { name = "untyped" },
      },
    }, dap.configurations)
    dap.configurations.python[1].name = "runtime mutation"
    assert.equals("launch", definitions.configurations.python[1].name)
  end)

  -- hangar's DAP category delegates status and enablement to this owner.
  it("reports registration and the matching configuration count", function()
    local runtime = require("runtime.dap")
    local cases = {
      {
        dap = {
          adapters = { python = function() end },
          configurations = {
            python = {
              { type = "python", request = "launch", name = "launch" },
              { type = "python", request = "attach", name = "attach" },
            },
            cs = { { type = "coreclr", request = "launch", name = "launch" } },
          },
        },
        expected = { "registered 2 cfg", "DiagnosticOk" },
      },
      {
        dap = {
          adapters = {},
          configurations = {
            python = {
              { type = "python", request = "launch", name = "launch" },
            },
          },
        },
        expected = { "not registered 1 cfg", "DiagnosticError" },
      },
      {
        dap = { adapters = { python = function() end }, configurations = {} },
        expected = { "registered 0 cfg", "DiagnosticWarn" },
      },
    }
    for _, case in ipairs(cases) do
      assert.same(case.expected, { runtime.adapter_status(case.dap, "python") })
    end
  end)

  it(
    "delegates coreclr enablement to dotnet-cli and removes it on disable",
    function()
      local dap = { adapters = {}, configurations = {} }
      local setup_calls = 0
      local previous = package.loaded["dotnet-cli"]
      package.loaded["dotnet-cli"] = {
        setup_dap = function()
          setup_calls = setup_calls + 1
          dap.adapters.coreclr = { type = "executable" }
          dap.configurations.cs = { { type = "coreclr", name = "Launch" } }
          return true
        end,
      }
      local runtime = require("runtime.dap")
      local definitions = { adapters = {}, configurations = {} }

      runtime.apply_adapter(dap, "coreclr", true, definitions)
      assert.equals(1, setup_calls)
      assert.is_not_nil(dap.adapters.coreclr)
      runtime.apply_adapter(dap, "coreclr", false, definitions)
      package.loaded["dotnet-cli"] = previous
      assert.is_nil(dap.adapters.coreclr)
      assert.is_nil(dap.configurations.cs)
    end
  )
end)
