describe("service.config", function()
  local cfg = require("service.config")

  it("defaults missing mason packages to auto-install on enable", function()
    assert.equals("auto", cfg.missing_package_policy)
  end)

  it("uses explicit enabled and disabled service icons", function()
    assert.equals("", cfg.icons.enabled)
    assert.equals("", cfg.icons.disabled)
  end)
end)
