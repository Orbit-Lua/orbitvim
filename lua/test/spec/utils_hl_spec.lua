describe("utils.hl", function()
  local highlights = require("utils.hl")

  it("creates extmarks only for non-empty ranges", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local ns = vim.api.nvim_create_namespace("test_utils_hl")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello world" })

    highlights.buf_hl(buf, ns, "Normal", 0, 0, 5)
    highlights.buf_hl(buf, ns, "Normal", 0, 5, 2)
    highlights.buf_hl(buf, ns, "Normal", 0, 6, -1)

    local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {
      details = true,
    })
    assert.equals(2, #marks)
    assert.equals(5, marks[1][4].end_col)
    assert.equals(11, marks[2][4].end_col)

    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end)
