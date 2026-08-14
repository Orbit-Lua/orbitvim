describe("utils.table", function()
  it("deduplicates by key while preserving the first-seen order", function()
    local unique_by_key = require("utils.table").unique_by_key
    local cases = {
      { input = {}, expected = {} },
      {
        input = { { id = 1 }, { id = 2 }, { id = 1 }, { missing = true } },
        expected = { { id = 1 }, { id = 2 } },
      },
      {
        input = { { name = "b" }, { name = "a" }, { name = "b" } },
        expected = { { name = "b" }, { name = "a" } },
        key = "name",
      },
    }

    for _, case in ipairs(cases) do
      assert.same(case.expected, unique_by_key(case.input, case.key or "id"))
    end
  end)
end)
