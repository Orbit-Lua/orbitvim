local M = {}

local order = require("service.order")

local function command_not_found(message)
  return type(message) == "string" and message:match("^Command '.+' not found$")
end

local function is_configured_for_ft(conform, ft, name)
  return vim.tbl_contains(conform.formatters_by_ft[ft] or {}, name)
end

local function executable_status(conform, name)
  if type(conform.get_formatter_info) ~= "function" then
    return nil, nil
  end

  local ok, info = pcall(conform.get_formatter_info, name)
  if not ok or type(info) ~= "table" then
    return nil, nil
  end

  if info.available == false and command_not_found(info.available_msg) then
    return "no binary", "DiagnosticError"
  end
  return nil, nil
end

---@param opts Service.ApplyRuntimeOpts
---@return nil
function M.apply_runtime(opts)
  local name, meta, is_enabled = opts.name, opts.meta, opts.is_enabled
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    return
  end
  for _, ft in ipairs(meta.ft or {}) do
    local list = conform.formatters_by_ft[ft] or {}
    if is_enabled then
      if not vim.tbl_contains(list, name) then
        table.insert(list, name)
      end
    else
      for i = #list, 1, -1 do
        if list[i] == name then
          table.remove(list, i)
        end
      end
    end
    conform.formatters_by_ft[ft] =
      order.enabled_names_for_ft("formatter", ft, list)
  end
end

---@param opts Service.ApplyOrderOpts
---@return nil
function M.apply_order(opts)
  local ft, enabled_names = opts.ft, opts.enabled_names
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    return
  end
  conform.formatters_by_ft[ft] = enabled_names
end

---@param opts Service.EntryStatusOpts
---@return string?, string?
function M.entry_status(opts)
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    return nil, nil
  end

  local total = #(opts.meta.ft or {})
  if total == 0 then
    return "no ft", "DiagnosticWarn"
  end

  local configured = 0
  for _, ft in ipairs(opts.meta.ft or {}) do
    if is_configured_for_ft(conform, ft, opts.name) then
      configured = configured + 1
    end
  end

  if configured == 0 then
    return "not configured", "DiagnosticWarn"
  end

  local executable_text, executable_hl = executable_status(conform, opts.name)
  if executable_text then
    return executable_text, executable_hl
  end

  if configured < total then
    return string.format("partly configured %d/%d", configured, total),
      "DiagnosticWarn"
  end
  return "configured", "DiagnosticOk"
end

return M
