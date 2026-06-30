local M = {}

local _state = {
  log_path = vim.fn.stdpath("log") .. "/nvim-config.log",
  entries = {},
  max_per_channel = 200,
}

---Writes a structured entry to the in-memory ring buffer and appends it to the
---log file. Silently drops file-write failures to avoid cascading errors.
---@param channel string   Logical namespace (e.g. "linter").
---@param level   string   Severity: "ERROR"|"WARN"|"INFO"|"DEBUG".
---@param source  string   Originating tool name (e.g. linter name).
---@param message string
---@param tags?   table    Arbitrary key/value metadata (e.g. `{ kind = "binary_not_found" }`).
function M.write(channel, level, source, message, tags)
  if not _state.entries[channel] then
    _state.entries[channel] = {}
  end
  local channel_entries = _state.entries[channel]
  local entry = {
    timestamp = os.date("%Y-%m-%dT%H:%M:%S"),
    level = level,
    source = source,
    message = message,
    tags = tags or {},
  }
  table.insert(channel_entries, entry)
  while #channel_entries > _state.max_per_channel do
    table.remove(channel_entries, 1)
  end
  local file = io.open(_state.log_path, "a")
  if file then
    file:write(
      string.format(
        "[%s] [%s] [%s] %s\n",
        entry.timestamp,
        level,
        source,
        message
      )
    )
    file:close()
  end
end

---Returns all entries for `channel`, optionally filtered to a single `source`.
---@param channel string
---@param source? string
---@return table[]
function M.get_entries(channel, source)
  local channel_entries = _state.entries[channel] or {}
  if not source then
    return vim.deepcopy(channel_entries)
  end
  return vim.tbl_filter(function(e)
    return e.source == source
  end, channel_entries)
end

---Removes all entries for `source` within `channel`.
---@param channel string
---@param source  string
function M.clear_source(channel, source)
  if not _state.entries[channel] then
    return
  end
  _state.entries[channel] = vim.tbl_filter(function(e)
    return e.source ~= source
  end, _state.entries[channel])
end

---Removes all entries for `channel`.
---@param channel string
function M.clear_channel(channel)
  _state.entries[channel] = {}
end

---@return string
function M.get_log_path()
  return _state.log_path
end

return M
