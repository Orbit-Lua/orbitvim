local M = {}

function M.setup()
  if not require("utils.os").is_win() then
    return
  end

  if not vim.api.nvim_get_option_info2("shell", {}).was_set then
    for _, shell in ipairs({ "pwsh.exe", "powershell.exe" }) do
      if vim.fn.executable(shell) == 1 then
        vim.o.shell = shell
        vim.o.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned "
          .. "-Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
        vim.o.shellredir =
          "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
        vim.o.shellpipe = vim.o.shellredir
        vim.o.shellquote = ""
        vim.o.shellxquote = ""
        break
      end
    end
  end

  if not vim.env.CC or vim.env.CC == "" then
    for _, compiler in ipairs({ "gcc", "clang" }) do
      if vim.fn.executable(compiler) == 1 then
        vim.env.CC = compiler
        break
      end
    end
  end
end

return M
