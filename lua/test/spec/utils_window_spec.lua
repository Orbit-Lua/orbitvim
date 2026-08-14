describe("utils.window", function()
  local window = require("utils.window")

  it("identifies floating and editor windows", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local floating = vim.api.nvim_open_win(buf, false, {
      relative = "editor",
      row = 1,
      col = 1,
      width = 10,
      height = 5,
      style = "minimal",
    })

    assert.is_true(window.is_floating(floating))
    assert.is_false(window.is_floating(vim.api.nvim_get_current_win()))
    assert.is_not_nil(window.get_editor_win())

    vim.api.nvim_win_close(floating, true)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it(
    "bounds completion and documentation sizes to the current editor",
    function()
      local previous_columns = vim.o.columns
      local previous_lines = vim.o.lines
      vim.o.columns = 100
      vim.o.lines = 50

      local completion_w, completion_h = window.get_completion_size()
      local doc_w, doc_h = window.get_doc_size()

      vim.o.columns = previous_columns
      vim.o.lines = previous_lines

      assert.same({ 40, 15 }, { completion_w, completion_h })
      assert.same({ 50, 20 }, { doc_w, doc_h })
    end
  )
end)
