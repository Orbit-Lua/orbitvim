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

  local function registry_name(runtime_name)
    for name, meta in pairs(require("config.tools")[spec.category] or {}) do
      if (meta.runtime_name or name) == runtime_name then
        return name
      end
    end
    return runtime_name
  end

  function adapter.apply_runtime(opts)
    local module = backend()
    if not module then
      return
    end

    for _, ft in ipairs(opts.meta.ft or {}) do
      local list = module[spec.field][ft] or {}
      local runtime_name = opts.meta.runtime_name or opts.name
      if opts.is_enabled then
        if not vim.tbl_contains(list, runtime_name) then
          table.insert(list, runtime_name)
        end
      else
        for i = #list, 1, -1 do
          if list[i] == runtime_name then
            table.remove(list, i)
          end
        end
      end
      local names = vim.tbl_map(registry_name, list)
      local ordered = order.enabled_names_for_ft(spec.category, ft, names)
      module[spec.field][ft] = vim.tbl_map(function(name)
        local meta = require("config.tools")[spec.category][name]
        return meta and (meta.runtime_name or name) or name
      end, ordered)
    end
  end

  function adapter.apply_order(opts)
    local module = backend()
    if module then
      local old = module[spec.field][opts.ft] or {}
      local known = {}
      for name, meta in pairs(require("config.tools")[spec.category] or {}) do
        if vim.tbl_contains(meta.ft or {}, opts.ft) then
          known[meta.runtime_name or name] = true
        end
      end
      local result = vim.deepcopy(opts.enabled_names)
      result = vim.tbl_map(function(name)
        local meta = require("config.tools")[spec.category][name]
        return meta and (meta.runtime_name or name) or name
      end, result)
      for _, name in ipairs(old) do
        if not known[name] and not vim.tbl_contains(result, name) then
          table.insert(result, name)
        end
      end
      module[spec.field][opts.ft] = result
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
      if
        vim.tbl_contains(
          module[spec.field][ft] or {},
          opts.meta.runtime_name or opts.name
        )
      then
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
