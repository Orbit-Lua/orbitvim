local M = {}

M.schema_path = assert(
  vim.api.nvim_get_runtime_file("settings.schema.json", false)[1],
  "settings schema is missing"
)
M.schema_path = vim.fs.normalize(vim.fn.fnamemodify(M.schema_path, ":p"))
local schema =
  vim.json.decode(table.concat(vim.fn.readfile(M.schema_path), "\n"))
-- Read-only for callers that describe settings, such as the effective view.
M.schema = schema
local active, overrides

function M.path()
  local destination = M.edit_path()
  local _, _, code = vim.uv.fs_stat(destination)
  if not vim.g.orbitvim_settings_path and code == "ENOENT" then
    local legacy = M.legacy_path()
    local _, _, legacy_code = vim.uv.fs_stat(legacy)
    if legacy_code ~= "ENOENT" then
      return legacy
    end
  end
  return destination
end

function M.legacy_path()
  return vim.fs.normalize(vim.fn.stdpath("config") .. "/settings.json")
end

function M.edit_path()
  return vim.fs.normalize(
    vim.fn.fnamemodify(
      vim.g.orbitvim_settings_path
        or (vim.fn.stdpath("data") .. "/settings.json"),
      ":p"
    )
  )
end

function M.schema_paths()
  local paths = { M.edit_path() }
  if not vim.g.orbitvim_settings_path then
    table.insert(paths, M.legacy_path())
  end
  return paths
end

local function defaults(node)
  if node.default ~= nil then
    return vim.deepcopy(node.default)
  end
  if node.type == "object" then
    local result = vim.empty_dict()
    for name, child in pairs(node.properties or {}) do
      result[name] = defaults(child)
    end
    return result
  end
end

local function resolve(value, node, path)
  if value == nil then
    return defaults(node)
  end
  local kind = node.type
  local matches = type(value) == kind
  if kind == "object" then
    matches = type(value) == "table" and not vim.islist(value)
  elseif kind == "array" then
    matches = type(value) == "table" and vim.islist(value)
  elseif kind == "integer" then
    matches = type(value) == "number" and value == math.floor(value)
  end
  if not matches then
    return nil, path .. ": expected " .. kind
  end
  if node.enum and not vim.tbl_contains(node.enum, value) then
    return nil, path .. ": expected one of " .. table.concat(node.enum, ", ")
  end
  if kind == "integer" and (value < node.minimum or value > node.maximum) then
    return nil, path .. ": expected " .. node.minimum .. ".." .. node.maximum
  end
  if kind == "string" and node.minLength and #value < node.minLength then
    return nil, path .. ": must not be empty"
  end
  if kind == "object" then
    local result = defaults(node)
    for _, name in ipairs(vim.fn.sort(vim.tbl_keys(value))) do
      local child = (node.properties or {})[name] or node.additionalProperties
      if child == false or child == nil then
        return nil, path .. "." .. name .. ": unknown setting"
      elseif child == true then
        result[name] = vim.deepcopy(value[name])
      else
        local item, err = resolve(value[name], child, path .. "." .. name)
        if err then
          return nil, err
        end
        result[name] = item
      end
    end
    return result
  elseif kind == "array" then
    if node.minItems and #value < node.minItems then
      return nil, path .. ": must not be empty"
    end
    local seen, result = {}, {}
    for index, item in ipairs(value) do
      local resolved, err =
        resolve(item, node.items, path .. "[" .. index .. "]")
      if err then
        return nil, err
      end
      if node.uniqueItems and seen[resolved] then
        return nil, path .. ": duplicate item " .. resolved
      end
      seen[resolved] = true
      result[index] = resolved
    end
    return result
  end
  return value
end

function M.read()
  local path = M.path()
  local stat, stat_error, code = vim.uv.fs_stat(path)
  if not stat and code == "ENOENT" then
    return defaults(schema), nil, vim.empty_dict()
  elseif not stat then
    return nil, tostring(stat_error)
  elseif stat.type ~= "file" then
    return nil, "settings path must be a file: " .. path
  end
  local file, open_error = io.open(path, "r")
  if not file then
    return nil, open_error
  end
  local content = file:read("*a")
  file:close()
  local parsed, decoded = pcall(vim.json.decode, content)
  if not parsed then
    return nil, "settings.json: " .. tostring(decoded)
  end
  local values, err = resolve(decoded, schema, "settings")
  if err then
    return nil, err
  end
  local tools = require("features.hangar.config")
  for _, category in ipairs({ "formatter", "linter" }) do
    for filetype, names in pairs(values.tools[category .. "_defaults"]) do
      for _, name in ipairs(names) do
        local definition = tools[category][name]
        if not definition or not vim.tbl_contains(definition.ft, filetype) then
          return nil,
            "settings.tools."
              .. category
              .. "_defaults."
              .. filetype
              .. ": unsupported tool "
              .. name
        end
      end
    end
  end
  for name in pairs(values.lsp.servers) do
    if not tools.lsp[name] then
      return nil, "settings.lsp.servers: unknown server " .. name
    end
  end
  values["$schema"] = nil
  return values, nil, decoded
end

function M.get()
  return vim.deepcopy(active or defaults(schema))
end

function M.accept(values, source)
  active, overrides =
    vim.deepcopy(values), vim.deepcopy(source or vim.empty_dict())
end

function M.info()
  return {
    values = M.get(),
    overrides = vim.deepcopy(overrides or vim.empty_dict()),
    path = M.path(),
    destination = M.edit_path(),
  }
end

function M.restart_paths()
  local result = {}
  local function visit(node, path)
    if node["x-reload"] == "restart" then
      table.insert(result, path)
    else
      for _, name in ipairs(vim.fn.sort(vim.tbl_keys(node.properties or {}))) do
        local child = vim.deepcopy(path)
        table.insert(child, name)
        visit(node.properties[name], child)
      end
    end
  end
  visit(schema, {})
  return result
end

return M
