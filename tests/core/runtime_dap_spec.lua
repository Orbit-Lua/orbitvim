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
end)
