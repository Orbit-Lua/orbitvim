local M = {}

local os_utils = require("utils.os")
local fs = require("utils.fs")

M.title = "Python"

M.get_venv_path = function()
  local venv_path = os.getenv("VIRTUAL_ENV")

  if venv_path == "" or venv_path == nil then
    return ""
  end

  return vim.fs.normalize(venv_path)
end

M.get_virtual_python_path = function()
  local venv_path = M.get_venv_path()

  if venv_path == "" then
    return ""
  end

  local executable_python_path

  if os_utils.is_win() then
    executable_python_path = venv_path .. "/Scripts/pythonw.exe"
  else
    executable_python_path = venv_path .. "/bin/python"
  end

  return executable_python_path
end

M.check_venv = function()
  if M.get_virtual_python_path() == "" then
    vim.notify("venv has not been activated", vim.log.levels.WARN)
    return 1
  end

  return 0
end

M.get_pyright_create_stub_cmd = function()
  return { "pyright", "--createstub" }
end

local pyright_create_stub = function(cmd)
  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify(
          "Create stub successfully",
          vim.log.levels.INFO,
          { title = M.title }
        )
      else
        vim.notify(
          "Error occor when create stub",
          vim.log.levels.ERROR,
          { title = M.title }
        )
      end
    end,
  })
end

vim.api.nvim_create_user_command("PyrightReCreateStub", function()
  local typing_path = vim.fn.getcwd() .. "/typings"
  local exist_stubs = fs.scandir(typing_path, "directory")
  local cmd = M.get_pyright_create_stub_cmd()

  vim.ui.select(
    exist_stubs,
    { prompt = "Choose exist stub" },
    function(item, _index)
      if item == nil then
        return
      end

      local success = vim.fn.delete(typing_path .. "/" .. item, "rf")
      if success == 0 then
        table.insert(cmd, item)
        pyright_create_stub(cmd)
      else
        vim.notify(
          "Error occor when delete existing stub",
          vim.log.levels.ERROR,
          { title = M.title }
        )
      end
    end
  )
end, { desc = "pyright re-generate stub (delete old)" })

return M
