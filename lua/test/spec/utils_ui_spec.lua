describe("utils.ui", function()
  local ui = require("utils.ui")

  describe("trunc", function()
    it("returns the string unchanged when it fits within max_w", function()
      assert.equals("hello", ui.trunc("hello", 10))
    end)

    it("truncates a long string", function()
      local result = ui.trunc("hello world long string", 8)
      assert.is_true(vim.fn.strdisplaywidth(result) <= 8)
    end)

    it("appends an ellipsis on truncation", function()
      local result = ui.trunc("hello world", 5)
      assert.is_true(result:find("…") ~= nil)
    end)

    it("does not truncate at exact display width", function()
      local s = "hello"
      assert.equals(s, ui.trunc(s, vim.fn.strdisplaywidth(s)))
    end)

    it("handles an empty string", function()
      assert.equals("", ui.trunc("", 5))
    end)
  end)

  describe("rpad", function()
    it("pads a short string to the target display width", function()
      local result = ui.rpad("ab", 5)
      assert.equals(5, vim.fn.strdisplaywidth(result))
    end)

    it(
      "does not alter a string that already equals the target width",
      function()
        assert.equals("hello", ui.rpad("hello", 5))
      end
    )

    it("does not truncate a string that exceeds the target width", function()
      assert.equals("hello world", ui.rpad("hello world", 5))
    end)

    it("pads with space characters", function()
      local result = ui.rpad("hi", 6)
      assert.equals("hi    ", result)
    end)
  end)

  describe("fill_line", function()
    it("pads to the requested inner width", function()
      local result = ui.fill_line("hi", 10)
      assert.equals(10, vim.fn.strdisplaywidth(result))
    end)

    it("does not modify a string already at the exact width", function()
      assert.equals("hello", ui.fill_line("hello", 5))
    end)

    it("does not truncate a wider string", function()
      assert.equals("hello world", ui.fill_line("hello world", 5))
    end)
  end)

  describe("buf_hl", function()
    it("applies a highlight without raising an error", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello world" })
      local ns = vim.api.nvim_create_namespace("test_buf_hl_basic")
      local ok = pcall(ui.buf_hl, buf, ns, "Normal", 0, 0, 5)
      assert.is_true(ok)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles end_col = -1 (highlight to end of line)", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "test line" })
      local ns = vim.api.nvim_create_namespace("test_buf_hl_eol")
      local ok = pcall(ui.buf_hl, buf, ns, "Normal", 0, 0, -1)
      assert.is_true(ok)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("is a no-op when end_col <= start_col", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello" })
      local ns = vim.api.nvim_create_namespace("test_buf_hl_noop")
      local ok = pcall(ui.buf_hl, buf, ns, "Normal", 0, 5, 2)
      assert.is_true(ok)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("win_is_floating", function()
    it("returns true for a window opened as floating", function()
      local buf = vim.api.nvim_create_buf(false, true)
      local ok, win = pcall(vim.api.nvim_open_win, buf, false, {
        relative = "editor",
        row = 1,
        col = 1,
        width = 10,
        height = 5,
        style = "minimal",
      })
      if ok and win then
        assert.is_true(ui.win_is_floating(win))
        pcall(vim.api.nvim_win_close, win, true)
      end
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end)
  end)

  describe("get_completion_window_size", function()
    it("returns two positive numbers", function()
      local w, h = ui.get_completion_window_size()
      assert.is_true(type(w) == "number" and w > 0)
      assert.is_true(type(h) == "number" and h > 0)
    end)

    it("width does not exceed the hard cap of 60", function()
      local w, _ = ui.get_completion_window_size()
      assert.is_true(w <= 60)
    end)

    it("height does not exceed the hard cap of 15", function()
      local _, h = ui.get_completion_window_size()
      assert.is_true(h <= 15)
    end)
  end)

  describe("get_doc_window_size", function()
    it("returns two positive numbers", function()
      local w, h = ui.get_doc_window_size()
      assert.is_true(w > 0)
      assert.is_true(h > 0)
    end)

    it("width does not exceed the hard cap of 80", function()
      local w, _ = ui.get_doc_window_size()
      assert.is_true(w <= 80)
    end)

    it("height does not exceed the hard cap of 20", function()
      local _, h = ui.get_doc_window_size()
      assert.is_true(h <= 20)
    end)
  end)

  describe("check_toggle_term", function()
    it("is a callable function", function()
      assert.is_true(type(ui.check_toggle_term) == "function")
    end)

    it("returns a boolean", function()
      local result = ui.check_toggle_term()
      assert.is_true(type(result) == "boolean")
    end)
  end)

  describe("harpoon", function()
    it("exposes a short_path_length constant", function()
      assert.is_true(type(ui.harpoon.short_path_length) == "number")
    end)

    it("format_display prefixes with spaces and includes path", function()
      local result = ui.harpoon.format_display("some/path.lua")
      assert.is_true(result:find("some/path.lua") ~= nil)
      assert.is_true(result:sub(1, 2) == "  ")
    end)

    it("highlight_current_file returns a table with UI_CREATE key", function()
      local ext = ui.harpoon.highlight_current_file()
      assert.is_true(type(ext) == "table")
      assert.is_true(type(ext.UI_CREATE) == "function")
    end)
  end)
end)
