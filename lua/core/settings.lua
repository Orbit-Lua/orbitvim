local M = {}
local settings = require("config.settings")
local initialized = false
local pending, last_error = {}, nil

local function get_path(value, path)
  for _, name in ipairs(path) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[name]
  end
  return value
end

local function set_path(value, path, replacement)
  for index = 1, #path - 1 do
    local name = path[index]
    if value[name] == nil then
      if replacement == nil then
        return
      end
      value[name] = {}
    end
    value = value[name]
  end
  value[path[#path]] = vim.deepcopy(replacement)
end

local function apply_editor(values, undo)
  local function set(name, value, scope)
    local previous = vim.api.nvim_get_option_value(name, scope)
    if previous == value then
      return
    end
    table.insert(undo, function()
      vim.api.nvim_set_option_value(name, previous, scope)
    end)
    vim.api.nvim_set_option_value(name, value, scope)
  end
  for name, value in pairs(values) do
    set(name, value, { scope = "global" })
    local scope = vim.api.nvim_get_option_info2(name, {}).scope
    if scope == "buf" then
      for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if
          vim.api.nvim_buf_is_loaded(buffer) and vim.bo[buffer].buftype == ""
        then
          set(name, value, { buf = buffer })
        end
      end
    elseif scope == "win" then
      for _, window in ipairs(vim.api.nvim_list_wins()) do
        local buffer = vim.api.nvim_win_get_buf(window)
        if
          vim.bo[buffer].buftype == ""
          and vim.api.nvim_win_get_config(window).relative == ""
        then
          set(name, value, { win = window })
        end
      end
    end
  end
end

local function apply(values, before, initial)
  local undo, applied = {}, {}
  local ok, err = pcall(function()
    if initial or not vim.deep_equal(values.editor, before.editor) then
      local changes = {}
      for name, value in pairs(values.editor) do
        if initial or before.editor[name] ~= value then
          changes[name] = value
        end
      end
      apply_editor(changes, undo)
      table.insert(applied, "editor")
    end
    if
      initial or not vim.deep_equal(values.tool_manager, before.tool_manager)
    then
      local config = package.loaded["config.tool_manager"]
      if config then
        local previous = vim.deepcopy(config)
        table.insert(undo, function()
          for name, value in pairs(previous) do
            config[name] = value
          end
        end)
        for name, value in pairs(values.tool_manager) do
          config[name] = vim.deepcopy(value)
        end
      end
      table.insert(applied, "tool_manager")
    end
    if
      initial
      or not vim.deep_equal(values.lsp.inlay_hints, before.lsp.inlay_hints)
    then
      local lsp = package.loaded["runtime.lsp"]
      if lsp and lsp.apply_inlay_hints then
        lsp.apply_inlay_hints(values.lsp.inlay_hints)
      end
      table.insert(applied, "lsp.inlay_hints")
    end
  end)
  if not ok then
    local failures = {}
    for index = #undo, 1, -1 do
      local restored, restore_error = pcall(undo[index])
      if not restored then
        table.insert(failures, tostring(restore_error))
      end
    end
    if #failures > 0 then
      err = tostring(err)
        .. "; rollback failed: "
        .. table.concat(failures, "; ")
        .. "; restart required"
    end
    return nil, tostring(err)
  end
  return applied
end

local function reload(initial)
  local values, err, source = settings.read()
  if not values then
    last_error = err
    return false, err
  end
  local before = settings.get()
  local previous_source = settings.info().overrides
  local restart = {}
  if not initial then
    for _, path in ipairs(settings.restart_paths()) do
      if not vim.deep_equal(get_path(values, path), get_path(before, path)) then
        table.insert(restart, table.concat(path, "."))
        set_path(values, path, get_path(before, path))
        set_path(source, path, get_path(previous_source, path))
      end
    end
  end
  local applied, apply_error = apply(values, before, initial)
  if not applied then
    last_error = apply_error
    return false, apply_error
  end
  settings.accept(values, source)
  pending, last_error = restart, nil
  pcall(
    vim.api.nvim_exec_autocmds,
    "User",
    { pattern = "ToolManagerChanged", modeline = false }
  )
  return true, { applied = applied, restart_required = restart }
end

function M.reload()
  local ok, result = reload(false)
  local message
  if not ok then
    message = tostring(result)
  else
    message = #result.applied > 0
        and "Applied: " .. table.concat(result.applied, ", ")
      or "Settings unchanged"
    if #result.restart_required > 0 then
      local prefix = #result.applied > 0 and message .. "; " or ""
      message = prefix
        .. "Restart required: "
        .. table.concat(result.restart_required, ", ")
    end
  end
  vim.notify(
    message,
    ok and vim.log.levels.INFO or vim.log.levels.WARN,
    { title = "OrbitSettings" }
  )
  return ok, result
end

function M.info()
  local result = settings.info()
  result.restart_required, result.error, result.sources =
    vim.deepcopy(pending), last_error, {}
  local function visit(values, source, path)
    for name, value in pairs(values) do
      local key = path == "" and name or path .. "." .. name
      local override
      if type(source) == "table" then
        override = source[name]
      end
      if type(value) == "table" and not vim.islist(value) and next(value) then
        visit(value, override, key)
      else
        result.sources[key] = override ~= nil and "settings.json" or "default"
      end
    end
  end
  visit(result.values, result.overrides, "")
  return result
end

function M.setup()
  local ok, err = reload(not initialized)
  if not ok then
    if not initialized then
      apply(settings.get(), settings.get(), true)
    end
    vim.notify(tostring(err), vim.log.levels.WARN, { title = "OrbitSettings" })
  end
  initialized = true
  local group =
    vim.api.nvim_create_augroup("OrbitVimSettings", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(event)
      local path = vim.fs.normalize(vim.fn.fnamemodify(event.file, ":p"))
      local expected = settings.path()
      if require("utils.os").is_win() then
        path, expected = path:lower(), expected:lower()
      end
      if path == expected then
        M.reload()
      end
    end,
  })
end

return M
