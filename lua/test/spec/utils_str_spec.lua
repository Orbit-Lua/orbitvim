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
end)
