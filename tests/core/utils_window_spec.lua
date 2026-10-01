describe("utils.window", function()
  local window = require("utils.window")
  local original_columns
  local original_lines
  local floating_windows = {}
  local buffers = {}

  before_each(function()
    original_columns = vim.o.columns
    original_lines = vim.o.lines
    floating_windows = {}
    buffers = {}
  end)

  after_each(function()
    for _, win in ipairs(floating_windows) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
    for _, buf in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    vim.o.columns = original_columns
    vim.o.lines = original_lines
  end)

  it("identifies floating and editor windows", function()
    local buf = vim.api.nvim_create_buf(false, true)
    table.insert(buffers, buf)
    local floating = vim.api.nvim_open_win(buf, false, {
      relative = "editor",
      row = 1,
      col = 1,
      width = 10,
      height = 5,
      style = "minimal",
    })
    table.insert(floating_windows, floating)

    assert.is_true(window.is_floating(floating))
    assert.is_false(window.is_floating(vim.api.nvim_get_current_win()))
  end)

  it(
    "bounds completion and documentation sizes to the current editor",
    function()
      vim.o.columns = 100
      vim.o.lines = 50

      local completion_w, completion_h = window.get_completion_size()
      local doc_w, doc_h = window.get_doc_size()

      assert.same({ 40, 15 }, { completion_w, completion_h })
      assert.same({ 50, 20 }, { doc_w, doc_h })
    end
  )
end)
