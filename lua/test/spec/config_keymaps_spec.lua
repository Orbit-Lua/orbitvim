describe("config.keymaps", function()
  it("<leader>fd changes cwd to roots containing spaces", function()
    local fs = require("utils.fs")
    local original_get_root = fs.get_root
    local original_cwd = vim.fn.getcwd()
    local root = vim.fn.tempname() .. " with space"

    vim.fn.mkdir(root, "p")
    vim.g.mapleader = " "
    package.loaded["config.keymaps"] = nil
    require("config.keymaps")

    fs.get_root = function()
      return root
    end

    local mapping = vim.fn.maparg("<leader>fd", "n", false, true)
    assert.equals("function", type(mapping.callback))

    mapping.callback()
    assert.equals(vim.fs.normalize(root), vim.fs.normalize(vim.fn.getcwd()))

    fs.get_root = original_get_root
    vim.api.nvim_set_current_dir(original_cwd)
    vim.fn.delete(root, "rf")
  end)

  it("prevents K from falling back to unrelated help", function()
    local original_win = vim.api.nvim_get_current_win()
    local original_buf = vim.api.nvim_get_current_buf()
    local buf = vim.api.nvim_create_buf(false, true)
    local existing_windows = {}

    for _, win in ipairs(vim.api.nvim_list_wins()) do
      existing_windows[win] = true
    end

    vim.g.mapleader = " "
    package.loaded["config.keymaps"] = nil
    require("config.keymaps")
    vim.api.nvim_win_set_buf(original_win, buf)
    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      { "OPEN SYMMETRIC KEY DemoKey;" }
    )
    vim.api.nvim_set_option_value("filetype", "sql", { buf = buf })
    vim.api.nvim_win_set_cursor(original_win, { 1, 0 })

    vim.api.nvim_feedkeys("K", "x", false)

    local unexpected = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if not existing_windows[win] then
        local win_buf = vim.api.nvim_win_get_buf(win)
        table.insert(unexpected, vim.bo[win_buf].filetype)
        vim.api.nvim_win_close(win, true)
      end
    end

    vim.api.nvim_win_set_buf(original_win, original_buf)
    vim.api.nvim_buf_delete(buf, { force = true })
    assert.same({}, unexpected)
  end)

  it("only replaces K when an LSP supports hover", function()
    package.loaded["plugins.lsp.keymaps"] = nil
    local specs = require("plugins.lsp.keymaps").get()

    for _, spec in ipairs(specs) do
      if spec[1] == "K" then
        assert.equals("hover", spec.has)
        return
      end
    end

    error("missing LSP hover keymap")
  end)
end)
