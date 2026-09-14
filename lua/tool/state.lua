local M = {}

local core = require("tool.core")

local _state = nil

local function state_path()
  return vim.g.tool_state_path or (vim.fn.stdpath("data") .. "/tools.json")
end

local function legacy_state_path()
  if vim.g.tool_state_path then
    return nil
  end
  return vim.fn.stdpath("data") .. "/service.json"
end

local function build_defaults()
  local tools = require("config.tools")
  local defaults = { formatter_order = {}, linter_order = {} }
  for _, cat in ipairs({ "lsp", "dap", "linter", "formatter" }) do
    defaults[cat] = {}
    for name in pairs(tools[cat] or {}) do
      defaults[cat][name] = true
    end
  end
  for ft, order in pairs(tools.formatter_defaults or {}) do
    defaults.formatter_order[ft] = vim.deepcopy(order)
  end
  for ft, order in pairs(tools.linter_defaults or {}) do
    defaults.linter_order[ft] = vim.deepcopy(order)
  end
  return defaults
end

local function is_string_list(value)
  if type(value) ~= "table" then
    return false
  end
  for _, item in ipairs(value) do
    if type(item) ~= "string" then
      return false
    end
  end
  return #value == vim.tbl_count(value)
end

---@param opts? { path: string?, legacy_path: string? }
function M.load(opts)
  opts = opts or {}
  local file = io.open(opts.path or state_path(), "r")
  if not file then
    local legacy_path = opts.legacy_path or legacy_state_path()
    file = legacy_path and io.open(legacy_path, "r") or nil
    if not file then
      return build_defaults()
    end
  end
  local raw = file:read("*a")
  file:close()
  local parse_ok, decoded = pcall(vim.json.decode, raw)
  if not parse_ok or type(decoded) ~= "table" then
    return build_defaults()
  end

  local state = build_defaults()
  for cat, val in pairs(decoded) do
    if type(val) == "table" then
      if cat == "formatter_order" or cat == "linter_order" then
        for ft, order in pairs(val) do
          if type(ft) == "string" and is_string_list(order) then
            state[cat][ft] = order
          end
        end
      elseif state[cat] then
        for name, enabled in pairs(val) do
          if state[cat][name] ~= nil and type(enabled) == "boolean" then
            state[cat][name] = enabled
          end
        end
      end
    end
  end
  return state
end

function M.get()
  if not _state then
    _state = M.load()
  end
  return _state
end

function M.save()
  local path = state_path()
  local file = io.open(path, "w")
  if not file then
    vim.notify("ToolManager: cannot write " .. path, vim.log.levels.WARN)
    return
  end
  file:write(vim.json.encode(M.get()))
  file:close()
end

function M.is_enabled(cat, name)
  local state = M.get()
  if not state[cat] then
    return true
  end
  local v = state[cat][name]
  return v == nil or v == true
end

function M.set_enabled(cat, name, enabled)
  local state = M.get()
  if state[cat] then
    state[cat][name] = enabled
    M.save()
  end
end

---@param kind "formatter"|"linter"
function M.get_order(kind, ft)
  return M.get()[core.order_key(kind)][ft]
end

---@param kind "formatter"|"linter"
function M.set_order(kind, ft, order)
  M.get()[core.order_key(kind)][ft] = order
  M.save()
end

return M
