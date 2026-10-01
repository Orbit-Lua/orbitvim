describe("tool.category.package", function()
  local package_handler
  local original_handler
  local original_mason

  before_each(function()
    original_handler = package.loaded["tool.category.package"]
    original_mason = package.loaded["tool.mason"]
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
    package.loaded["tool.category.package"] = original_handler
    package.loaded["tool.mason"] = original_mason
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
  end)
end)
