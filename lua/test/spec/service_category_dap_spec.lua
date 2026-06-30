describe("service.category.dap", function()
  local dap_category
  local previous_loaded_dap
  local previous_preload_dap

  before_each(function()
    package.loaded["service.category.dap"] = nil
    previous_loaded_dap = package.loaded.dap
    previous_preload_dap = package.preload.dap
    dap_category = require("service.category.dap")
  end)

  after_each(function()
    package.loaded.dap = previous_loaded_dap
    package.preload.dap = previous_preload_dap
  end)

  it("returns nil status when nvim-dap is unavailable", function()
    package.loaded.dap = nil
    package.preload.dap = function()
      error("dap unavailable")
    end

    local status, hl = dap_category.entry_status({ name = "python" })

    assert.is_nil(status)
    assert.is_nil(hl)
  end)

  it("reports registered adapter and matching configuration count", function()
    package.loaded.dap = {
      adapters = { python = function() end },
      configurations = {
        python = {
          { type = "python", request = "launch", name = "launch" },
          { type = "python", request = "attach", name = "attach" },
        },
        cs = {
          { type = "coreclr", request = "launch", name = "launch" },
        },
      },
    }

    local status, hl = dap_category.entry_status({ name = "python" })

    assert.equals("registered 2 cfg", status)
    assert.equals("DiagnosticOk", hl)
  end)

  it("reports missing adapter while still counting configurations", function()
    package.loaded.dap = {
      adapters = {},
      configurations = {
        python = {
          { type = "python", request = "launch", name = "launch" },
        },
      },
    }

    local status, hl = dap_category.entry_status({ name = "python" })

    assert.equals("not registered 1 cfg", status)
    assert.equals("DiagnosticError", hl)
  end)

  it("warns when adapter is registered without configurations", function()
    package.loaded.dap = {
      adapters = { python = function() end },
      configurations = {},
    }

    local status, hl = dap_category.entry_status({ name = "python" })

    assert.equals("registered 0 cfg", status)
    assert.equals("DiagnosticWarn", hl)
  end)
end)
