local M = {}

local order = require("service.order")

local function is_configured_for_ft(conform, ft, name)
  return vim.tbl_contains(conform.formatters_by_ft[ft] or {}, name)
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

  if configured == total then
    return "wired", "DiagnosticOk"
  elseif configured > 0 then
    return string.format("partly wired %d/%d", configured, total),
      "DiagnosticWarn"
  end
  return "not wired", "DiagnosticWarn"
end

return M
