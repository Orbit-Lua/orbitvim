local M = {
  capabilities = { toggle = true, install = true, reorder = false },
}

local config = require("tool.config")

function M.apply_runtime(opts)
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    return false, "nvim-dap is unavailable: " .. tostring(dap)
  end
  local owner = config.get().adapters.dap
  return owner
    .runtime()
    .apply_adapter(dap, opts.name, opts.is_enabled, owner.options())
end

function M.entry_status(opts)
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    return nil, nil
  end
  return config.get().adapters.dap.runtime().adapter_status(dap, opts.name)
end

return M
