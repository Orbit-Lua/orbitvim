local M = {
  capabilities = { toggle = true, install = true, reorder = false },
}

function M.apply_runtime(opts)
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    return
  end
  require("runtime.dap").apply_adapter(
    dap,
    opts.name,
    opts.is_enabled,
    require("config.dap.config")
  )
end

function M.entry_status(opts)
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    return nil, nil
  end
  return require("runtime.dap").adapter_status(dap, opts.name)
end

return M
