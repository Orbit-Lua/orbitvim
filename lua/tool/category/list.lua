local M = {}

---@class Tool.ListAdapterSpec
---@field module string
---@field field string
---@field category "formatter"|"linter"

---@param spec Tool.ListAdapterSpec
---@return Tool.CategoryHandler
function M.new(spec)
  local order = require("tool.order")
  local adapter = {
    capabilities = { toggle = true, install = true, reorder = true },
  }

  local function backend()
    local ok, module = pcall(require, spec.module)
    if not ok then
      return nil
    end
    return module
  end

  function adapter.apply_runtime(opts)
    local module = backend()
    if not module then
      return
    end

    for _, ft in ipairs(opts.meta.ft or {}) do
      local list = module[spec.field][ft] or {}
      if opts.is_enabled then
        if not vim.tbl_contains(list, opts.name) then
          table.insert(list, opts.name)
        end
      else
        for i = #list, 1, -1 do
          if list[i] == opts.name then
            table.remove(list, i)
          end
        end
      end
      module[spec.field][ft] =
        order.enabled_names_for_ft(spec.category, ft, list)
    end
  end

  function adapter.apply_order(opts)
    local module = backend()
    if module then
      module[spec.field][opts.ft] = opts.enabled_names
    end
  end

  function adapter.wiring_status(opts)
    local module = backend()
    if not module then
      return nil, nil
    end

    local total = #(opts.meta.ft or {})
    if total == 0 then
      return "no ft", "DiagnosticWarn"
    end

    local configured = 0
    for _, ft in ipairs(opts.meta.ft or {}) do
      if vim.tbl_contains(module[spec.field][ft] or {}, opts.name) then
        configured = configured + 1
      end
    end

    if configured == 0 then
      return "not configured", "DiagnosticWarn"
    elseif configured < total then
      return string.format("partly configured %d/%d", configured, total),
        "DiagnosticWarn"
    end
    return nil, nil
  end

  return adapter
end

return M
