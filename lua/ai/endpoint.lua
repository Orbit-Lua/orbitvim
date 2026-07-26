local M = {}

local default_url = "http://127.0.0.1:11434/v1/completions"
local completion_path = "/v1/completions"
local state

local function state_path()
  return vim.g.minuet_endpoint_state_path
    or (vim.fn.stdpath("data") .. "/minuet-endpoints.json")
end

local function validate_authority(authority)
  if authority == "" or authority:find("@", 1, true) then
    return nil, "endpoint host is invalid"
  end

  local host
  local port

  if vim.startswith(authority, "[") then
    local suffix
    host, suffix = authority:match("^(%[[^%]]+%])(.*)$")
    if not host or not host:match("^%[[%x:%.]+%]$") then
      return nil, "endpoint IPv6 address is invalid"
    end
    if suffix ~= "" then
      port = suffix:match("^:(%d+)$")
      if not port then
        return nil, "endpoint port is invalid"
      end
    end
  else
    local _, colon_count = authority:gsub(":", "")
    if colon_count > 1 then
      return nil, "IPv6 addresses must be enclosed in brackets"
    end

    host, port = authority:match("^([^:]+):(%d+)$")
    if not host then
      host = authority
      if colon_count == 1 then
        return nil, "endpoint port is invalid"
      end
    end

    if not host:match("^[%w][%w%.%-]*$") then
      return nil, "endpoint host is invalid"
    end
  end

  if port and (tonumber(port) < 1 or tonumber(port) > 65535) then
    return nil, "endpoint port must be between 1 and 65535"
  end

  return port ~= nil
end

function M.default_url()
  return default_url
end

function M.normalize(value)
  if type(value) ~= "string" then
    return nil, "endpoint must be a string"
  end

  value = vim.trim(value)
  if value == "" then
    return nil, "endpoint cannot be empty"
  end
  if value:find("%s") or value:find("[?#]") then
    return nil, "endpoint cannot contain whitespace, a query, or a fragment"
  end

  local scheme, remainder = value:match("^(https?)://(.+)$")
  if not scheme then
    if value:find("://", 1, true) then
      return nil, "endpoint must use http or https"
    end
    scheme = "http"
    remainder = value
  end

  local authority, path = remainder:match("^([^/]+)(/.*)$")
  if not authority then
    authority = remainder
    path = ""
  end

  local has_port, error_message = validate_authority(authority)
  if has_port == nil then
    return nil, error_message
  end

  if path == "" or path == "/" then
    path = completion_path
  elseif path ~= completion_path then
    return nil, "endpoint path must be /v1/completions"
  end

  if scheme == "http" and not has_port then
    authority = authority .. ":11434"
  end

  return scheme .. "://" .. authority .. path
end

local function add_endpoint(result, seen, value)
  local normalized = M.normalize(value)
  if normalized and not seen[normalized] then
    result[#result + 1] = normalized
    seen[normalized] = true
  end
  return normalized
end

function M.load()
  local endpoints = {}
  local seen = {}
  add_endpoint(endpoints, seen, default_url)

  local file = io.open(state_path(), "r")
  if not file then
    return { current = default_url, endpoints = endpoints }
  end

  local content = file:read("*a")
  file:close()

  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    return { current = default_url, endpoints = endpoints }
  end

  if type(decoded.endpoints) == "table" then
    for _, value in ipairs(decoded.endpoints) do
      if type(value) == "string" then
        add_endpoint(endpoints, seen, value)
      end
    end
  end

  local current
  if type(decoded.current) == "string" then
    current = add_endpoint(endpoints, seen, decoded.current)
  end

  return {
    current = current or default_url,
    endpoints = endpoints,
  }
end

function M.get()
  if not state then
    state = M.load()
  end
  return state
end

function M.current()
  return M.get().current
end

function M.list()
  return vim.deepcopy(M.get().endpoints)
end

function M.save()
  local path = state_path()
  local parent = vim.fn.fnamemodify(path, ":h")
  if vim.fn.isdirectory(parent) == 0 then
    local ok = vim.fn.mkdir(parent, "p")
    if ok == 0 then
      return false, "failed to create state directory: " .. parent
    end
  end

  local file, open_error = io.open(path, "w")
  if not file then
    return false, open_error
  end

  local ok, encoded = pcall(vim.json.encode, M.get())
  if not ok then
    file:close()
    return false, encoded
  end

  local write_ok, write_error = file:write(encoded)
  file:close()
  if not write_ok then
    return false, write_error
  end

  return true
end

function M.set(value)
  local normalized, error_message = M.normalize(value)
  if not normalized then
    return nil, error_message
  end

  local previous = vim.deepcopy(M.get())
  local exists = false
  for _, endpoint in ipairs(state.endpoints) do
    if endpoint == normalized then
      exists = true
      break
    end
  end
  if not exists then
    state.endpoints[#state.endpoints + 1] = normalized
  end
  state.current = normalized

  local ok, save_error = M.save()
  if not ok then
    state = previous
    return nil, save_error
  end

  return normalized
end

function M.remove(value)
  local normalized, error_message = M.normalize(value)
  if not normalized then
    return nil, error_message
  end
  if normalized == default_url then
    return nil, "the local default endpoint cannot be removed"
  end

  local previous = vim.deepcopy(M.get())
  local found = false
  local endpoints = {}
  for _, endpoint in ipairs(state.endpoints) do
    if endpoint == normalized then
      found = true
    else
      endpoints[#endpoints + 1] = endpoint
    end
  end
  if not found then
    return nil, "endpoint is not saved"
  end

  state.endpoints = endpoints
  if state.current == normalized then
    state.current = default_url
  end

  local ok, save_error = M.save()
  if not ok then
    state = previous
    return nil, save_error
  end

  return state.current
end

function M.apply(value)
  local minuet = package.loaded.minuet
  local options = minuet and minuet.config and minuet.config.provider_options
  local provider = options and options.openai_fim_compatible
  if not provider then
    return false
  end

  provider.end_point = value
  return true
end

function M.transform_request(data)
  if
    type(data) ~= "table"
    or type(data.end_point) ~= "string"
    or type(data.headers) ~= "table"
  then
    return data
  end

  local authority = data.end_point:match("^https://([^/]+)")
  local hostname = authority and authority:match("^([^:]+)")
  if hostname and vim.endswith(hostname, ".ts.net") then
    data.headers.Host = "localhost:11434"
  end

  return data
end

function M._reset()
  state = nil
end

return M
