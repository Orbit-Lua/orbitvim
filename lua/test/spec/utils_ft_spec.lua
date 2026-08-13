describe("utils.ft", function()
  it("exports the shared filetype collections", function()
    local filetypes = require("utils.ft")

    assert.same({ "sql", "mysql", "plsql" }, filetypes.sql_ft)
    assert.same({
      "jsx",
      "typescript",
      "typescriptreact",
      "javascript",
      "javascriptreact",
    }, filetypes.ts)
    assert.same({ "javascript", "javascriptreact" }, filetypes.js)
  end)
end)
