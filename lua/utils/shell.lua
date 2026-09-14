local os_utils = require("utils.os")
local M = {}

function M.setup()
  if os_utils.is_win() then
    if vim.fn.executable("pwsh") == 1 then
      vim.o.shell = "pwsh"
    elseif vim.fn.executable("powershell.exe") == 1 then
      vim.o.shell = "powershell.exe"
    end

    vim.o.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned "
      .. "-Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
    vim.o.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.o.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.o.shellquote = ""
    vim.o.shellxquote = ""

    if vim.fn.executable("gcc") == 1 then
      vim.env.CC = "gcc"
    end
  else
    vim.o.shellcmdflag = "-c"
    vim.o.shellquote = ""
    vim.o.shellxquote = ""
  end
end

return M
