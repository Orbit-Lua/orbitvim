describe("tool.ui.live_update", function()
  local live_update = require("tool.ui.live_update")
  local context
  local buf
  local win

  after_each(function()
    if context then
      live_update.stop(context)
      context = nil
    end
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)

  it("renders subscribed events only while the UI is active", function()
    buf = vim.api.nvim_create_buf(false, true)
    win = vim.api.nvim_open_win(buf, false, {
      relative = "editor",
      width = 20,
      height = 4,
      row = 0,
      col = 0,
      style = "minimal",
    })

    local renders = 0
    context = {
      ui = { win = win, category_idx = 1, help_open = false },
      render = function()
        renders = renders + 1
      end,
    }
    live_update.start(context)

    vim.api.nvim_exec_autocmds("User", { pattern = "TSUpdate" })
    assert.is_true(vim.wait(100, function()
      return renders == 1
    end))

    vim.api.nvim_exec_autocmds("User", { pattern = "TSUpdate" })
    live_update.stop(context)
    vim.wait(20)
    assert.equals(1, renders)

    vim.api.nvim_exec_autocmds("User", { pattern = "TSUpdate" })
    vim.wait(20)
    assert.equals(1, renders)
  end)

  it(
    "stops window updates on close and restores one subscription on reopen",
    function()
      local renderer = require("tool.ui.renderer")
      local original_render = renderer.render
      local tool = require("tool")
      local renders = 0
      renderer.render = function(...)
        renders = renders + 1
        return original_render(...)
      end

      local ok, err = pcall(function()
        tool.open()
        assert.equals(1, renders)

        tool.close()
        vim.api.nvim_exec_autocmds("User", { pattern = "TSUpdate" })
        vim.wait(20)
        assert.equals(1, renders)

        tool.open()
        assert.equals(2, renders)
        vim.api.nvim_exec_autocmds("User", { pattern = "TSUpdate" })
        assert.is_true(vim.wait(100, function()
          return renders == 3
        end))
        vim.wait(20)
        assert.equals(3, renders)
      end)

      tool.close()
      renderer.render = original_render
      assert.is_true(ok, err)
    end
  )
end)
