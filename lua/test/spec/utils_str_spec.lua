describe("utils.str", function()
  local str = require("utils.str")

  it("removes only trailing slash runs", function()
    for input, expected in pairs({
      [""] = "",
      ["/"] = "",
      ["/foo/bar"] = "/foo/bar",
      ["/foo/bar/"] = "/foo/bar",
      ["/foo/bar///"] = "/foo/bar",
      ["a/b/c"] = "a/b/c",
    }) do
      assert.equals(expected, str.rstrip_slash(input), input)
    end

    local _, changed = str.rstrip_slash("/foo/bar/")
    local _, unchanged = str.rstrip_slash("/foo/bar")
    assert.is_true(changed > 0)
    assert.equals(0, unchanged)
  end)

  it("truncates by display width without splitting multibyte text", function()
    assert.equals("hello", str.trunc("hello", 10))
    assert.equals("", str.trunc("hello", 0))

    local result = str.trunc("󰈚 hello world", 5)
    assert.is_true(vim.fn.strdisplaywidth(result) <= 5)
    assert.is_truthy(result:find("…", 1, true))
    assert.is_true(vim.fn.strchars(result) > 0)
  end)

  it("right-pads short text and preserves wider text", function()
    assert.equals("ab   ", str.rpad("ab", 5))
    assert.equals("hello", str.rpad("hello", 5))
    assert.equals("hello world", str.rpad("hello world", 5))
    assert.equals("hi      ", str.fill_line("hi", 8))
  end)
end)
