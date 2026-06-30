describe("utils.table", function()
  local tbl = require("utils.table")

  describe("unique_by_key", function()
    it("deduplicates by the given key", function()
      local list = {
        { name = "a", val = 1 },
        { name = "b", val = 2 },
        { name = "a", val = 3 },
      }
      local result = tbl.unique_by_key(list, "name")
      assert.equals(2, #result)
    end)

    it("keeps the first occurrence when duplicated", function()
      local list = {
        { name = "x", val = 10 },
        { name = "x", val = 20 },
      }
      local result = tbl.unique_by_key(list, "name")
      assert.equals(1, #result)
      assert.equals(10, result[1].val)
    end)

    it("preserves insertion order for unique items", function()
      local list = {
        { id = 3 },
        { id = 1 },
        { id = 2 },
      }
      local result = tbl.unique_by_key(list, "id")
      assert.equals(3, #result)
      assert.equals(3, result[1].id)
      assert.equals(1, result[2].id)
      assert.equals(2, result[3].id)
    end)

    it("returns an empty table for an empty input", function()
      assert.same({}, tbl.unique_by_key({}, "name"))
    end)

    it("skips items with a nil key value", function()
      local list = {
        { val = 1 },
        { name = "a", val = 2 },
        { val = 3 },
      }
      local result = tbl.unique_by_key(list, "name")
      assert.equals(1, #result)
      assert.equals("a", result[1].name)
    end)

    it("handles all unique items", function()
      local list = { { id = 1 }, { id = 2 }, { id = 3 } }
      local result = tbl.unique_by_key(list, "id")
      assert.equals(3, #result)
    end)

    it("handles a mix of duplicate and unique items", function()
      local list = {
        { k = "a" },
        { k = "b" },
        { k = "a" },
        { k = "c" },
        { k = "b" },
      }
      local result = tbl.unique_by_key(list, "k")
      assert.equals(3, #result)
      assert.equals("a", result[1].k)
      assert.equals("b", result[2].k)
      assert.equals("c", result[3].k)
    end)
  end)
end)
