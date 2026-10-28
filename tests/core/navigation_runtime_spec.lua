describe("Harpoon current-file selection", function()
  it(
    "selects a filename containing Lua pattern characters literally",
    function()
      local test = require("tests.helpers")
      local cwd = vim.fn.getcwd()
      local root = test.temp_dir("harpoon-selection")
      package.loaded["utils.icons"] = {
        get_file_icon = function()
          return ""
        end,
      }
      local harpoon = require("features.navigation.runtime")
      local buffer = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buffer)
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
        harpoon.format_display("other.lua"),
        harpoon.format_display("selected("),
      })
      vim.api.nvim_set_current_dir(root)
      local ok, err = pcall(harpoon.highlight_current_file().UI_CREATE, {
        contents = vim.api.nvim_buf_get_lines(buffer, 0, -1, false),
        current_file = root .. "/selected(",
        bufnr = buffer,
        win_id = vim.api.nvim_get_current_win(),
      })
      vim.api.nvim_set_current_dir(cwd)
      assert.is_true(ok, err)
      assert.equals(2, vim.api.nvim_win_get_cursor(0)[1])
      local marks = vim.api.nvim_buf_get_extmarks(
        buffer,
        vim.api.nvim_get_namespaces().harpoon,
        0,
        -1,
        {}
      )
      assert.equals(1, marks[1][2])
    end
  )
end)
