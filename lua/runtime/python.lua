local M = {}

local os_utils = require("utils.os")
local stub_jobs = {}

---Retain the old stub until generation succeeds, restoring it after failure.
---@param root string
---@param name string
---@param on_done fun(success: boolean, err?: string)
---@return boolean
function M.recreate_stub(root, name, on_done)
  if
    type(name) ~= "string"
    or name == "."
    or name == ".."
    or name:find("[/\\:]")
  then
    on_done(false, "Invalid stub selection")
    return false
  end
  root = vim.fs.normalize(vim.fn.resolve(vim.fn.fnamemodify(root, ":p")))
  local directory = vim.fs.joinpath(root, "typings")
  local target = vim.fs.joinpath(directory, name)
  local stat = vim.uv.fs_lstat(target)
  local parent = vim.uv.fs_lstat(directory)
  if
    not parent
    or parent.type ~= "directory"
    or not stat
    or stat.type ~= "directory"
  then
    on_done(false, "Selected stub is no longer a directory")
    return false
  end
  if stub_jobs[target] then
    on_done(false, "This stub is already being regenerated")
    return false
  end
  -- Both exact targets are direct children of the resolved project's typings.
  local backup =
    vim.fs.joinpath(directory, ".orbitvim-stub-" .. tostring(vim.uv.hrtime()))
  local moved, move_error = vim.uv.fs_rename(target, backup)
  if not moved then
    on_done(false, tostring(move_error))
    return false
  end
  stub_jobs[target] = true
  local finished = false
  local function finish(success, err)
    if finished then
      return
    end
    finished = true
    if success and vim.fn.isdirectory(target) ~= 1 then
      success, err = false, "Pyright produced no stub directory"
    end
    if success then
      if vim.fn.delete(backup, "rf") ~= 0 then
        err = "Generated stub saved; old copy retained at " .. backup
      end
    else
      if vim.uv.fs_lstat(target) and vim.fn.delete(target, "rf") ~= 0 then
        err = tostring(err)
          .. "; could not remove incomplete stub; old copy at "
          .. backup
      else
        local restored, restore_error = vim.uv.fs_rename(backup, target)
        if not restored then
          err = tostring(err)
            .. "; restore failed: "
            .. tostring(restore_error)
            .. "; old copy at "
            .. backup
        end
      end
    end
    stub_jobs[target] = nil
    on_done(success, err)
  end
  local ok, job = pcall(vim.fn.jobstart, { "pyright", "--createstub", name }, {
    cwd = root,
    on_exit = vim.schedule_wrap(function(_, code)
      finish(
        code == 0,
        code ~= 0 and "Pyright exited with code " .. code or nil
      )
    end),
  })
  if not ok or job <= 0 then
    finish(false, ok and "Could not start Pyright" or tostring(job))
    return false
  end
  return true
end

---Path of an executable inside the active virtual environment, or nil when
---no environment is active.
---@param name string executable name without extension
---@return string?
function M.venv_executable(name)
  local venv = os.getenv("VIRTUAL_ENV")
  if not venv or venv == "" then
    return nil
  end
  local windows = os_utils.is_win()
  return vim.fs.joinpath(
    vim.fs.normalize(venv),
    windows and "Scripts" or "bin",
    name .. (windows and ".exe" or "")
  )
end

---Interpreter for the debug adapter; pythonw avoids a console window on
---Windows.
---@return string?
function M.venv_python()
  return M.venv_executable(os_utils.is_win() and "pythonw" or "python")
end

return M
