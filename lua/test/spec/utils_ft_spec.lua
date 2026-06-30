describe("utils.ft", function()
  local ft = require("utils.ft")

  describe("sql_ft", function()
    it("is a table", function()
      assert.is_true(type(ft.sql_ft) == "table")
    end)

    it("contains sql", function()
      assert.is_true(vim.tbl_contains(ft.sql_ft, "sql"))
    end)

    it("contains mysql", function()
      assert.is_true(vim.tbl_contains(ft.sql_ft, "mysql"))
    end)

    it("contains plsql", function()
      assert.is_true(vim.tbl_contains(ft.sql_ft, "plsql"))
    end)

    it("has exactly three entries", function()
      assert.equals(3, #ft.sql_ft)
    end)
  end)

  describe("ts", function()
    it("is a table", function()
      assert.is_true(type(ft.ts) == "table")
    end)

    it("contains typescript", function()
      assert.is_true(vim.tbl_contains(ft.ts, "typescript"))
    end)

    it("contains typescriptreact", function()
      assert.is_true(vim.tbl_contains(ft.ts, "typescriptreact"))
    end)

    it("contains javascript", function()
      assert.is_true(vim.tbl_contains(ft.ts, "javascript"))
    end)

    it("contains javascriptreact", function()
      assert.is_true(vim.tbl_contains(ft.ts, "javascriptreact"))
    end)

    it("contains jsx", function()
      assert.is_true(vim.tbl_contains(ft.ts, "jsx"))
    end)
  end)

  describe("js", function()
    it("is a table", function()
      assert.is_true(type(ft.js) == "table")
    end)

    it("contains javascript", function()
      assert.is_true(vim.tbl_contains(ft.js, "javascript"))
    end)

    it("contains javascriptreact", function()
      assert.is_true(vim.tbl_contains(ft.js, "javascriptreact"))
    end)

    it("is a strict subset of ts", function()
      for _, v in ipairs(ft.js) do
        assert.is_true(vim.tbl_contains(ft.ts, v), v .. " in js but not in ts")
      end
    end)
  end)
end)
