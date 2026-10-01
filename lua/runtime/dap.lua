local M = {}

local function same_configuration(a, b)
  return a.type == b.type and a.request == b.request and a.name == b.name
end

local function remove_configurations(dap, name)
  for ft, configurations in pairs(dap.configurations or {}) do
    for i = #configurations, 1, -1 do
      if configurations[i].type == name then
        table.remove(configurations, i)
      end
    end
    if vim.tbl_isempty(configurations) then
      dap.configurations[ft] = nil
    end
  end
end

local function add_configurations(dap, name, available)
  dap.configurations = dap.configurations or {}
  for ft, configurations in pairs(available or {}) do
    for _, configuration in ipairs(configurations) do
      if configuration.type == name then
        dap.configurations[ft] = dap.configurations[ft] or {}
        local exists = false
        for _, item in ipairs(dap.configurations[ft]) do
          if same_configuration(item, configuration) then
            exists = true
            break
          end
        end
        if not exists then
          table.insert(dap.configurations[ft], vim.deepcopy(configuration))
        end
      end
    end
  end
end

function M.apply_adapter(dap, name, enabled, definitions)
  if enabled then
    if name == "coreclr" then
      local ok, dotnet = pcall(require, "dotnet-cli")
      if ok then
        local ready, err = dotnet.setup_dap()
        if not ready then
          vim.notify(err, vim.log.levels.ERROR)
        end
      end
    else
      dap.adapters[name] = definitions.adapters[name]
      add_configurations(dap, name, definitions.configurations)
    end
  else
    dap.adapters[name] = nil
    remove_configurations(dap, name)
  end
end

function M.adapter_status(dap, name)
  local registered = dap.adapters and dap.adapters[name] ~= nil
  local count = 0
  for _, configurations in pairs(dap.configurations or {}) do
    for _, configuration in ipairs(configurations) do
      if configuration.type == name then
        count = count + 1
      end
    end
  end
  local status = string.format(
    "%s %d cfg",
    registered and "registered" or "not registered",
    count
  )
  if not registered then
    return status, "DiagnosticError"
  elseif count == 0 then
    return status, "DiagnosticWarn"
  end
  return status, "DiagnosticOk"
end

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
