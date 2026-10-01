describe("utils.shell", function()
  local shell = require("utils.shell")

  local original_shell
  local original_shellcmdflag
  local original_shellredir
  local original_shellpipe
  local original_shellquote
  local original_shellxquote
  local original_cc
  local original_is_win
  local original_has

  before_each(function()
    original_shell = vim.o.shell
    original_shellcmdflag = vim.o.shellcmdflag
    original_shellredir = vim.o.shellredir
    original_shellpipe = vim.o.shellpipe
    original_shellquote = vim.o.shellquote
    original_shellxquote = vim.o.shellxquote
    original_cc = vim.env.CC
    original_is_win = require("utils.os").is_win
    original_has = vim.fn.has
  end)

  after_each(function()
    vim.o.shell = original_shell
    vim.o.shellcmdflag = original_shellcmdflag
    vim.o.shellredir = original_shellredir
    vim.o.shellpipe = original_shellpipe
    vim.o.shellquote = original_shellquote
    vim.o.shellxquote = original_shellxquote
    vim.env.CC = original_cc
    require("utils.os").is_win = original_is_win
    vim.fn.has = original_has
  end)

  it("leaves shell options unchanged on repeated setup", function()
    local function options()
      return {
        shell = vim.o.shell,
        shellcmdflag = vim.o.shellcmdflag,
        shellredir = vim.o.shellredir,
        shellpipe = vim.o.shellpipe,
        shellquote = vim.o.shellquote,
        shellxquote = vim.o.shellxquote,
        cc = vim.env.CC,
      }
    end
    shell.setup()
    local first = options()
    shell.setup()
    assert.same(first, options())
  end)

  it("uses the win64 check result when selecting a Windows shell", function()
    local os_utils = require("utils.os")

    os_utils.is_win = function()
      return true
    end
    vim.fn.has = function(name)
      if name == "win64" then
        return 0
      end
      return original_has(name)
    end

    shell.setup()
    assert.equals("pwsh.exe", vim.o.shell)

    vim.fn.has = function(name)
      if name == "win64" then
        return 1
      end
      return original_has(name)
    end

    shell.setup()
    assert.equals("powershell.exe", vim.o.shell)
  end)
end)
