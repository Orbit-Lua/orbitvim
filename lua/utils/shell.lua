local os_utils = require("utils.os")
local M = {}

M.setup = function()
  if os_utils.is_win() then
    vim.o.shell = vim.fn.has("win64") == 1 and "powershell.exe" or "pwsh.exe"

    -- refer to https://www.reddit.com/r/neovim/comments/1crdv93/neovim_on_windows_using_windows_terminal_and
    vim.o.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned "
      .. "-Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
    vim.o.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.o.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.o.shellquote = ""
    vim.o.shellxquote = ""

    -- this option only modifiable in MS-Windows, so set value here
    -- vim.o.shellslash = true

    -- TODO: remove this when vim.ui.open is fixed upstream.
    -- https://github.com/neovim/neovim/issues/39524
    --
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.ui.open = function(uri)
      return vim.system(
        { "rundll32", "url.dll,FileProtocolHandler", uri },
        { detach = true }
      )
    end
    vim.g.netrw_browsex_viewer = "rundll32 url.dll,FileProtocolHandler"

    -- https://github.com/nvim-treesitter/nvim-treesitter/issues/8292#issuecomment-3734228891
    -- FIX: Compiler detection bug on Windows (treesitter)
    vim.env.CC = "gcc"
  else
    vim.o.shellcmdflag = "-c"
    vim.o.shellquote = ""
    vim.o.shellxquote = ""
  end
end

return M
