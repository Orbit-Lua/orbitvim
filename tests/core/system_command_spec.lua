describe("system commands", function()
  local test = require("tests.helpers")
  local is_win, commands

  before_each(function()
    is_win = require("utils.os").is_win
    commands = vim.api.nvim_get_commands({ builtin = false })
  end)

  after_each(function()
    require("utils.os").is_win = is_win
    for name in pairs(vim.api.nvim_get_commands({ builtin = false })) do
      if not commands[name] then
        vim.api.nvim_del_user_command(name)
      end
    end
  end)

  it(
    "clears temporary ShaDa files through ClearShada and keeps main.shada",
    function()
      require("utils.os").is_win = function()
        return true
      end
      local root = vim.fn.stdpath("data") .. "/shada"
      local unrelated = test.temp_dir("unrelated-shada") .. "/other.tmp"
      test.write_file(root .. "/main.shada", "saved editor state")
      test.write_file(root .. "/main.shada.tmp.a", "temporary state")
      test.write_file(root .. "/main.shada.tmp.b", "temporary state")
      test.write_file(unrelated, "unrelated state")

      require("commands").setup()
      vim.cmd.ClearShada()

      assert.same({ "main.shada" }, require("utils.fs").scandir(root, "file"))
      assert.same(
        { "saved editor state" },
        vim.fn.readfile(root .. "/main.shada")
      )
      assert.same({ "unrelated state" }, vim.fn.readfile(unrelated))
    end
  )
end)
