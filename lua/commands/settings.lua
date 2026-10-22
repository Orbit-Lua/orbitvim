local M = {}

local function open()
  local settings = require("config.settings")
  local path = settings.path()
  if not vim.uv.fs_stat(path) then
    local reference = vim.fs.dirname(path)
          == vim.fs.dirname(settings.schema_path)
        and "./settings.schema.json"
      or vim.uri_from_fname(settings.schema_path)
    local contents = '{\n  "$schema": ' .. vim.json.encode(reference) .. "\n}\n"
    local ok, err = require("utils.fs").atomic_write(path, contents)
    if not ok then
      vim.notify(
        tostring(err),
        vim.log.levels.WARN,
        { title = "OrbitSettings" }
      )
      return
    end
  end
  vim.cmd.edit({ args = { path } })
end

local function info()
  local data = require("core.settings").info()
  local lines = { "Settings: " .. data.path, "" }
  if data.error then
    table.insert(lines, "Last error: " .. data.error)
  end
  if #data.restart_required > 0 then
    table.insert(
      lines,
      "Restart required: " .. table.concat(data.restart_required, ", ")
    )
  end
  local function visit(values, path)
    for _, name in ipairs(vim.fn.sort(vim.tbl_keys(values))) do
      local key = path == "" and name or path .. "." .. name
      local value = values[name]
      if type(value) == "table" and not vim.islist(value) and next(value) then
        visit(value, key)
      else
        table.insert(
          lines,
          key
            .. " = "
            .. vim.json.encode(value)
            .. " ["
            .. data.sources[key]
            .. "]"
        )
      end
    end
  end
  visit(data.values, "")
  vim.cmd.new()
  local buffer = vim.api.nvim_get_current_buf()
  vim.bo[buffer].buftype, vim.bo[buffer].bufhidden, vim.bo[buffer].swapfile =
    "nofile", "wipe", false
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].modifiable = false
end

function M.setup()
  vim.api.nvim_create_user_command("OrbitSettings", function(opts)
    local action = opts.args == "" and "open" or opts.args
    if action == "open" then
      open()
    elseif action == "reload" then
      require("core.settings").reload()
    elseif action == "info" then
      info()
    else
      vim.notify("Expected open, reload or info", vim.log.levels.WARN)
    end
  end, {
    nargs = "?",
    desc = "Open, reload or inspect OrbitVim settings",
    complete = function(lead)
      return vim.tbl_filter(function(action)
        return action:find(lead, 1, true) == 1
      end, { "open", "reload", "info" })
    end,
  })
end

return M
