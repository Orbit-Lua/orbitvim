local M = {}

function M.setup(dap, definitions, state)
  for name, adapter in pairs(definitions.adapters) do
    if state.is_enabled("dap", name) then
      dap.adapters[name] = adapter
    end
  end

  for filetype, configurations in pairs(definitions.configurations) do
    dap.configurations[filetype] = {}
    for _, configuration in ipairs(configurations) do
      if
        configuration.type == nil
        or state.is_enabled("dap", configuration.type)
      then
        table.insert(dap.configurations[filetype], vim.deepcopy(configuration))
      end
    end
  end
end

return M
