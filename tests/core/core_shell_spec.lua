describe("core.shell", function()
  local original_executable, original_info, original_is_win, original_cc

  before_each(function()
    original_executable = vim.fn.executable
    original_info = vim.api.nvim_get_option_info2
    original_is_win = require("utils.os").is_win
    original_cc = vim.env.CC
    require("utils.os").is_win = function()
      return true
    end
  end)

  after_each(function()
    vim.fn.executable = original_executable
    vim.api.nvim_get_option_info2 = original_info
    require("utils.os").is_win = original_is_win
    vim.env.CC = original_cc
  end)

  it("preserves an explicitly selected shell, flags and compiler", function()
    vim.o.shell = "custom-shell"
    vim.o.shellcmdflag = "--custom-command"
    vim.env.CC = "custom-compiler"
    require("core.shell").setup()
    assert.equals("custom-shell", vim.o.shell)
    assert.equals("--custom-command", vim.o.shellcmdflag)
    assert.equals("custom-compiler", vim.env.CC)
  end)

  it("selects an available default shell and compiler", function()
    vim.env.CC = nil
    vim.api.nvim_get_option_info2 = function(name, opts)
      local info = original_info(name, opts)
      if name == "shell" then
        info.was_set = false
      end
      return info
    end
    vim.fn.executable = function(name)
      return (name == "powershell.exe" or name == "clang") and 1 or 0
    end
    require("core.shell").setup()
    assert.equals("powershell.exe", vim.o.shell)
    assert.equals("clang", vim.env.CC)
  end)
end)
