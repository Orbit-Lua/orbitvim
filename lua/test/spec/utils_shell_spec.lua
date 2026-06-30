describe("utils.shell", function()
  local shell = require("utils.shell")

  it("exposes a setup function", function()
    assert.is_true(type(shell.setup) == "function")
  end)

  it("setup runs without error", function()
    local ok = pcall(shell.setup)
    assert.is_true(ok)
  end)

  it("setup is idempotent (can be called multiple times)", function()
    local ok1 = pcall(shell.setup)
    local ok2 = pcall(shell.setup)
    assert.is_true(ok1)
    assert.is_true(ok2)
  end)
end)
