describe("utils.shell", function()
  local shell = require("utils.shell")

  local original_shell
  local original_shellcmdflag
  local original_shellredir
  local original_shellpipe
  local original_shellquote
  local original_shellxquote
  local original_cc

  before_each(function()
    original_shell = vim.o.shell
    original_shellcmdflag = vim.o.shellcmdflag
    original_shellredir = vim.o.shellredir
    original_shellpipe = vim.o.shellpipe
    original_shellquote = vim.o.shellquote
    original_shellxquote = vim.o.shellxquote
    original_cc = vim.env.CC
  end)

  after_each(function()
    vim.o.shell = original_shell
    vim.o.shellcmdflag = original_shellcmdflag
    vim.o.shellredir = original_shellredir
    vim.o.shellpipe = original_shellpipe
    vim.o.shellquote = original_shellquote
    vim.o.shellxquote = original_shellxquote
    vim.env.CC = original_cc
  end)

  it("exposes a setup function", function()
    assert.is_true(type(shell.setup) == "function")
  end)

  it("setup runs without error", function()
    local ok = pcall(shell.setup)
    assert.is_true(ok)
  end)

  it("setup is idempotent (can be called multiple times)", function()
    local ok1 = pcall(shell.setup)
    local ok2 = pcall(shell.setup)
    assert.is_true(ok1)
    assert.is_true(ok2)
  end)

  it("uses the win64 check result when selecting a Windows shell", function()
    local os_utils = require("utils.os")
    local original_is_win = os_utils.is_win
    local original_has = vim.fn.has

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

    vim.fn.has = original_has
    os_utils.is_win = original_is_win
  end)
end)
