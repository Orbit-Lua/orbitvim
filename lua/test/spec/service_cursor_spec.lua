describe("service.cursor", function()
  local cursor = require("service.cursor")
  local buf
  local win

  before_each(function()
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "one", "two", "three" })
    win = vim.api.nvim_open_win(buf, false, {
      relative = "editor",
      width = 20,
      height = 3,
      row = 0,
      col = 0,
      style = "minimal",
    })
  end)

  after_each(function()
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end)

  local function ui()
    return {
      win = win,
      help_open = false,
      line_map = {
        [2] = {
          name = "two",
          icon_byte = 0,
          status_byte = 0,
          status_hl = "Comment",
        },
        [3] = {
          name = "three",
          icon_byte = 0,
          status_byte = 0,
          status_hl = "Comment",
        },
      },
    }
  end

  it("reads the current mapped entry", function()
    local state = ui()
    vim.api.nvim_win_set_cursor(win, { 2, 0 })

    assert.equals("two", cursor.current_entry(state).name)
    state.help_open = true
    assert.is_nil(cursor.current_entry(state))
  end)

  it("focuses first, matching, and clamps to mapped entries", function()
    local state = ui()

    cursor.focus_first(state)
    assert.equals(2, vim.api.nvim_win_get_cursor(win)[1])

    assert.is_true(cursor.focus_match(state, function(entry)
      return entry.name == "three"
    end))
    assert.equals(3, vim.api.nvim_win_get_cursor(win)[1])

    vim.api.nvim_win_set_cursor(win, { 1, 0 })
    cursor.clamp_to_entries(state)
    assert.equals(2, vim.api.nvim_win_get_cursor(win)[1])
  end)
end)
