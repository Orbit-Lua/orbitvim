describe("service.help", function()
  local help = require("service.help")

  it("builds help lines and marks section headings", function()
    local lines, section_lnums = help.build(100)

    assert.is_true(#lines > 0)
    assert.is_true(lines[2]:find("? Help", 1, true) ~= nil)
    assert.is_true(vim.tbl_count(section_lnums) > 0)

    for lnum in pairs(section_lnums) do
      assert.is_true(lines[lnum]:match("%S") ~= nil)
    end
  end)
end)
