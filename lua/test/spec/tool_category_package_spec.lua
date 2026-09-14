describe("tool.category.package", function()
  local package_handler

  before_each(function()
    package.loaded["tool.category.package"] = nil
    package.loaded["tool.mason"] = {
      package_status = function(name)
        return name == "installed-package", nil
      end,
      install = function()
        return true
      end,
    }
    package_handler = require("tool.category.package")
  end)

  after_each(function()
    package.loaded["tool.category.package"] = nil
    package.loaded["tool.mason"] = nil
  end)

  it("reports Mason dependency installation", function()
    assert.same({ "installed", "DiagnosticOk" }, {
      package_handler.entry_status({ name = "installed-package", meta = {} }),
    })
    assert.same(
      { "not installed", "DiagnosticError" },
      { package_handler.entry_status({ name = "missing-package", meta = {} }) }
    )
  end)

  it("summarizes dependencies without exposing toggle behavior", function()
    assert.same(
      { total = 2, installed = 1, missing = 1 },
      package_handler.summary({
        ["installed-package"] = {},
        ["missing-package"] = {},
      })
    )
    assert.is_false(package_handler.capabilities.toggle)
    assert.is_true(package_handler.capabilities.install)
  end)
end)
