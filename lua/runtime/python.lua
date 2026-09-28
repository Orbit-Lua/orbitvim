local M = {}

local os_utils = require("utils.os")

function M.get_venv_path()
  local venv_path = os.getenv("VIRTUAL_ENV")
  if not venv_path or venv_path == "" then
    return ""
  end
  return vim.fs.normalize(venv_path)
end

function M.get_virtual_python_path()
  local venv_path = M.get_venv_path()
  if venv_path == "" then
    return ""
  end
  local executable = os_utils.is_win() and "/Scripts/pythonw.exe"
    or "/bin/python"
  return venv_path .. executable
end

function M.check_venv()
  if M.get_virtual_python_path() == "" then
    vim.notify("venv has not been activated", vim.log.levels.WARN)
    return 1
  end
  return 0
end

return M
