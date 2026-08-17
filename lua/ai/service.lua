local M = {}

local endpoint = require("ai.endpoint")

local active_url
local activation_id = 0
local last_error

---@class AiServiceActivateOpts
---@field before_enable? fun(url: string): any
---@field on_complete? fun(ok: boolean, reason?: string)
---@field notify? boolean

local function invoke(callback, ...)
  if not callback then
    return
  end

  local ok, callback_error = pcall(callback, ...)
  if not ok then
    vim.notify_once(
      "Completion state callback failed: " .. tostring(callback_error),
      vim.log.levels.WARN,
      { title = "Minuet", timeout = 4000 }
    )
  end
end

local function notify_failure(url, reason)
  local prefix = active_url and "Completion endpoint unavailable"
    or "Completion disabled"
  vim.notify_once(
    string.format("%s for %s: %s", prefix, url, reason),
    vim.log.levels.WARN,
    { title = "Minuet", timeout = 4000 }
  )
end

local function error_reason(result)
  local stderr = vim.trim(result.stderr or "")
  local first_line = stderr:match("[^\r\n]+")
  if first_line and first_line ~= "" then
    return first_line
  end
  if result.code == 124 then
    return "connection check timed out"
  end
  return "curl exited with code " .. tostring(result.code)
end

local function load_minuet(url)
  local minuet = package.loaded.minuet
  if not (minuet and minuet.config) then
    local ok, load_error = pcall(function()
      require("lazy").load({ plugins = { "minuet-ai.nvim" } })
    end)
    if not ok then
      return false, "failed to load Minuet: " .. tostring(load_error)
    end
  end

  if not endpoint.apply(url) then
    return false, "Minuet did not initialize after the connection check"
  end

  return true
end

local function complete_failure(id, url, reason, opts)
  if id ~= activation_id then
    return
  end

  last_error = reason
  if opts.notify ~= false then
    notify_failure(url, reason)
  end
  invoke(opts.on_complete, false, reason)
end

local function complete_success(id, url, opts)
  if id ~= activation_id then
    return
  end

  if opts.before_enable then
    local ok, result, update_error = pcall(opts.before_enable, url)
    if not ok then
      complete_failure(id, url, tostring(result), opts)
      return
    end
    if not result then
      complete_failure(
        id,
        url,
        "failed to update completion endpoint: " .. tostring(update_error),
        opts
      )
      return
    end
  end

  local previous_url = active_url
  active_url = url
  last_error = nil

  local ok, load_error = load_minuet(url)
  if not ok then
    active_url = previous_url
    complete_failure(id, url, load_error, opts)
    return
  end

  invoke(opts.on_complete, true)
end

---@param value string
---@param opts? AiServiceActivateOpts
function M.activate(value, opts)
  opts = opts or {}

  local url, normalize_error = endpoint.normalize(value)
  if not url then
    activation_id = activation_id + 1
    local id = activation_id
    vim.schedule(function()
      complete_failure(id, tostring(value), normalize_error, opts)
    end)
    return
  end

  local models_url = assert(endpoint.models_url(url))
  local command = {
    "curl",
    "--silent",
    "--show-error",
    "--fail",
    "--connect-timeout",
    "1",
    "--max-time",
    "3",
  }
  local host_header = endpoint.host_header(url)
  if host_header then
    vim.list_extend(command, { "--header", "Host: " .. host_header })
  end
  command[#command + 1] = models_url

  activation_id = activation_id + 1
  local id = activation_id

  if vim.fn.executable("curl") ~= 1 then
    vim.schedule(function()
      complete_failure(id, url, "curl executable was not found", opts)
    end)
    return
  end

  local started, start_error = pcall(vim.system, command, {
    text = true,
    timeout = 3500,
    stdout = false,
  }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        complete_success(id, url, opts)
      else
        complete_failure(id, url, error_reason(result), opts)
      end
    end)
  end)

  if not started then
    vim.schedule(function()
      complete_failure(
        id,
        url,
        "failed to start curl: " .. tostring(start_error),
        opts
      )
    end)
  end
end

function M.disable(reason)
  activation_id = activation_id + 1
  active_url = nil
  last_error = reason
end

function M.is_ready()
  return active_url ~= nil
end

function M.current()
  return active_url
end

function M.failure_reason()
  return last_error
end

return M
