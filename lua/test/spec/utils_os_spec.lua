describe("utils.os", function()
  local os_utils = require("utils.os")

  it("reports mutually exclusive platform flags", function()
    local is_win = os_utils.is_win()
    local is_linux = os_utils.is_linux()

    assert.is_boolean(is_win)
    assert.is_boolean(is_linux)
    assert.is_false(is_win and is_linux)
  end)

  it("applies default and custom date-time formats", function()
    assert.matches("^%d%d%d%d%-%d%d%-%d%d$", os_utils.get_current_date())
    assert.matches("^%d%d:%d%d:%d%d$", os_utils.get_current_time())
    assert.matches(
      "^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$",
      os_utils.get_datetime()
    )
    assert.matches("^%d%d%d%d/%d%d$", os_utils.get_current_date("%Y/%m"))
  end)

  it("substitutes the POSIX seconds directive on every platform", function()
    assert.matches("^epoch=%d+$", os_utils.get_datetime("epoch=%s"))
  end)

  it("returns absent environment values and usable machine identity", function()
    assert.is_nil(os_utils.get_env("_NVIM_TEST_NONEXISTENT_XYZ_ABC_"))

    for name, value in pairs({
      hostname = os_utils.get_hostname(),
      username = os_utils.get_username(),
    }) do
      if value ~= nil then
        assert.is_true(
          type(value) == "string" and value ~= "",
          name .. " must be a non-empty string when available"
        )
      end
    end
  end)
end)
