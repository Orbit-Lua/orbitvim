describe("utils.os", function()
  local os_utils = require("utils.os")

  describe("is_win / is_linux", function()
    it("is_win returns a boolean", function()
      assert.is_true(type(os_utils.is_win()) == "boolean")
    end)

    it("is_linux returns a boolean", function()
      assert.is_true(type(os_utils.is_linux()) == "boolean")
    end)

    it("is_win and is_linux are not both true simultaneously", function()
      assert.is_false(os_utils.is_win() and os_utils.is_linux())
    end)
  end)

  describe("get_current_date", function()
    it("returns a string", function()
      assert.is_true(type(os_utils.get_current_date()) == "string")
    end)

    it("default format matches YYYY-MM-DD", function()
      local d = os_utils.get_current_date()
      assert.is_true(d:match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil)
    end)

    it("accepts a custom format string", function()
      local year = os_utils.get_current_date("%Y")
      assert.is_true(year:match("^%d%d%d%d$") ~= nil)
    end)

    it("custom day format returns two digits", function()
      local day = os_utils.get_current_date("%d")
      assert.is_true(#day == 2)
    end)
  end)

  describe("get_current_time", function()
    it("returns a string", function()
      assert.is_true(type(os_utils.get_current_time()) == "string")
    end)

    it("default format matches HH:MM:SS", function()
      local t = os_utils.get_current_time()
      assert.is_true(t:match("^%d%d:%d%d:%d%d$") ~= nil)
    end)

    it("accepts a custom format string", function()
      local hour = os_utils.get_current_time("%H")
      assert.is_true(hour:match("^%d%d$") ~= nil)
    end)
  end)

  describe("get_datetime", function()
    it("returns a string", function()
      assert.is_true(type(os_utils.get_datetime()) == "string")
    end)

    it("contains a date portion", function()
      local dt = os_utils.get_datetime()
      assert.is_true(dt:match("%d%d%d%d%-%d%d%-%d%d") ~= nil)
    end)

    it("contains a time portion", function()
      local dt = os_utils.get_datetime()
      assert.is_true(dt:match("%d%d:%d%d:%d%d") ~= nil)
    end)

    it("accepts a custom format", function()
      local result = os_utils.get_datetime("%Y/%m/%d")
      assert.is_true(result:match("^%d%d%d%d/%d%d/%d%d$") ~= nil)
    end)
  end)

  describe("get_env", function()
    it("returns a string for a known environment variable", function()
      local home = os_utils.get_env("HOME") or os_utils.get_env("USERPROFILE")
      assert.is_true(home == nil or type(home) == "string")
    end)

    it("returns nil for a variable that does not exist", function()
      assert.is_nil(os_utils.get_env("_NVIM_TEST_NONEXISTENT_XYZ_ABC_"))
    end)
  end)

  describe("get_hostname", function()
    it("returns a string or nil", function()
      local h = os_utils.get_hostname()
      assert.is_true(h == nil or type(h) == "string")
    end)

    it("is non-empty when present", function()
      local h = os_utils.get_hostname()
      if h ~= nil then
        assert.is_true(#h > 0)
      end
    end)
  end)

  describe("get_username", function()
    it("returns a string or nil", function()
      local u = os_utils.get_username()
      assert.is_true(u == nil or type(u) == "string")
    end)

    it("is non-empty when present", function()
      local u = os_utils.get_username()
      if u ~= nil then
        assert.is_true(#u > 0)
      end
    end)
  end)
end)
