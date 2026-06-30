describe("service.mason", function()
  local previous_registry
  local mason

  before_each(function()
    previous_registry = package.loaded["mason-registry"]
    package.loaded["service.mason"] = nil
    mason = require("service.mason")
  end)

  after_each(function()
    package.loaded["mason-registry"] = previous_registry
  end)

  it("returns package installation status through mason-registry", function()
    package.loaded["mason-registry"] = {
      get_package = function(name)
        assert.equals("stylua", name)
        return {
          is_installed = function()
            return true
          end,
        }
      end,
    }

    local installed, err = mason.package_status("stylua")

    assert.is_nil(err)
    assert.is_true(installed)
  end)

  it("normalizes missing package lookup errors", function()
    package.loaded["mason-registry"] = {
      get_package = function()
        error("unknown package")
      end,
    }

    local pkg, err = mason.get_package("_missing_")

    assert.is_nil(pkg)
    assert.equals("mason package not found: _missing_", err)
  end)
end)
