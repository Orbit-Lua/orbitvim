describe("utils.str", function()
  local str = require("utils.str")

  describe("rstrip_slash", function()
    it("removes a single trailing slash", function()
      assert.equals("/foo/bar", str.rstrip_slash("/foo/bar/"))
    end)

    it("removes multiple consecutive trailing slashes", function()
      assert.equals("/foo/bar", str.rstrip_slash("/foo/bar///"))
    end)

    it("leaves strings without trailing slash unchanged", function()
      assert.equals("/foo/bar", str.rstrip_slash("/foo/bar"))
    end)

    it("handles a lone slash (root)", function()
      assert.equals("", str.rstrip_slash("/"))
    end)

    it("handles an empty string", function()
      assert.equals("", str.rstrip_slash(""))
    end)

    it("handles strings with internal slashes", function()
      assert.equals("a/b/c", str.rstrip_slash("a/b/c"))
    end)

    it(
      "returns a positive replacement count when trailing slash present",
      function()
        local _, count = str.rstrip_slash("/foo/")
        assert.is_true(count > 0)
      end
    )

    it("returns zero replacement count when no trailing slash", function()
      local _, count = str.rstrip_slash("/foo/bar")
      assert.equals(0, count)
    end)
  end)

  describe("trunc", function()
    it("returns the string unchanged when it fits", function()
      assert.equals("hello", str.trunc("hello", 10))
    end)

    it("truncates to the requested display width", function()
      local result = str.trunc("hello world", 5)
      assert.is_true(vim.fn.strdisplaywidth(result) <= 5)
      assert.is_true(result:find("…") ~= nil)
    end)

    it("handles multibyte characters without producing invalid text", function()
      local result = str.trunc("󰈚 hello", 5)
      assert.is_true(vim.fn.strdisplaywidth(result) <= 5)
      assert.is_true(pcall(vim.fn.strdisplaywidth, result))
    end)
  end)

  describe("rpad", function()
    it("pads to the requested display width", function()
      local result = str.rpad("ab", 5)
      assert.equals(5, vim.fn.strdisplaywidth(result))
    end)
  end)

  describe("fill_line", function()
    it("pads to the requested display width", function()
      local result = str.fill_line("hi", 8)
      assert.equals(8, vim.fn.strdisplaywidth(result))
    end)
  end)
end)
