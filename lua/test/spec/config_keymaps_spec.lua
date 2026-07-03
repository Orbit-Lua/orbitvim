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
end)
