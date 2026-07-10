local ft = require("utils.ft")
local icons = require("config").icons

local function noice_spinner_frame()
  local ok, spinners = pcall(require, "noice.util.spinners")
  return ok and spinners.spin("dots") or icons.misc.dots
end

---@param notification unknown
---@param level number
---@param state string
---@param icon string
---@param message? string
---@return boolean
local function update_noice_notification(
  notification,
  level,
  state,
  icon,
  message
)
  if type(notification) ~= "table" or not notification.id then
    return false
  end

  local ok, manager = pcall(require, "noice.message.manager")
  if not ok then
    return false
  end

  local current = manager.get_by_id(notification.id)
  if not current then
    return false
  end

  if message then
    current:set(message)
  end

  current.level = level == vim.log.levels.ERROR and "error" or "info"
  current.opts.keep = nil
  current.opts.orbit_formatter = state
  current.opts.orbit_formatter_icon = icon
  manager.add(current)
  return true
end

local function start_noice_spinner(notification, is_formatting)
  if type(notification) ~= "table" or not notification.id then
    return function() end
  end

  local ok, manager = pcall(require, "noice.message.manager")
  if not ok then
    return function() end
  end

  local timer = vim.uv.new_timer()
  if not timer then
    return function() end
  end

  timer:start(
    80,
    80,
    vim.schedule_wrap(function()
      if not is_formatting() then
        return
      end
      local message = manager.get_by_id(notification.id)
      if message then
        message.opts.orbit_formatter_icon = noice_spinner_frame()
        manager.add(message)
      end
    end)
  )

  return function()
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end
end

local function format_file()
  local conform = require("conform")
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.b[bufnr].orbit_formatting then
    vim.notify("This buffer is already being formatted", vim.log.levels.WARN, {
      orbit_formatter = "error",
      orbit_formatter_icon = icons.formatter.error,
    })
    return
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  local display_name = filename == "" and "[No Name]"
    or vim.fs.basename(filename)
  local formatters = conform.list_formatters_to_run(bufnr)
  local was_modifiable = vim.bo[bufnr].modifiable
  local locked = was_modifiable and #formatters > 0
  local post_autocmd
  local pending = {}

  local function unlock_for_apply()
    if locked and vim.api.nvim_buf_is_valid(bufnr) then
      vim.bo[bufnr].modifiable = true
    end
    locked = false
    if post_autocmd then
      pcall(vim.api.nvim_del_autocmd, post_autocmd)
      post_autocmd = nil
    end
  end

  if locked then
    for _, formatter in ipairs(formatters) do
      pending[formatter.name] = (pending[formatter.name] or 0) + 1
    end
    vim.b[bufnr].orbit_formatting = true
    vim.bo[bufnr].modifiable = false
    post_autocmd = vim.api.nvim_create_autocmd("User", {
      pattern = "ConformFormatPost",
      callback = function(args)
        local name = args.data
          and args.data.formatter
          and args.data.formatter.name
        if not name or not pending[name] then
          return
        end
        pending[name] = pending[name] - 1
        if pending[name] == 0 then
          pending[name] = nil
        end
        if vim.tbl_isempty(pending) then
          unlock_for_apply()
        end
      end,
    })
  else
    vim.b[bufnr].orbit_formatting = true
  end

  local started = vim.uv.hrtime()
  local formatting = true
  local notification =
    vim.notify("Formatting " .. display_name .. "…", vim.log.levels.INFO, {
      orbit_formatter = "progress",
      orbit_formatter_icon = noice_spinner_frame(),
      keep = function()
        return formatting
      end,
    })
  local stop_spinner = start_noice_spinner(notification, function()
    return formatting
  end)

  conform.format({
    async = true,
    lsp_format = "fallback",
    quiet = true,
  }, function(err, did_edit)
    formatting = false
    stop_spinner()
    unlock_for_apply()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].orbit_formatting = nil
      if was_modifiable then
        vim.bo[bufnr].modifiable = true
      end
    end
    local elapsed = (vim.uv.hrtime() - started) / 1e9
    local message
    local level = vim.log.levels.INFO
    if err then
      message = string.format(
        "Formatting %s failed after %.1fs. See :ConformInfo",
        display_name,
        elapsed
      )
      level = vim.log.levels.ERROR
    elseif did_edit then
      message = string.format("Formatted %s in %.1fs", display_name, elapsed)
    else
      message =
        string.format("%s is already formatted (%.1fs)", display_name, elapsed)
    end

    local state = err and "error" or "done"
    local icon = err and icons.formatter.error or icons.formatter.success

    update_noice_notification(notification, level, state, icon)

    vim.notify(message, level, {
      orbit_formatter = state,
      orbit_formatter_icon = icon,
    })
  end)
end

---@type LazySpec[]
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    keys = {
      {
        "<leader>fm",
        format_file,
        desc = "format file",
        mode = { "n", "x" },
      },
    },
    opts = function()
      local opts = require("config.formatter")
      local state_mod = require("service.state")
      local order = require("service.order")

      -- Inject sqlfluff for SQL filetypes before filtering
      if state_mod.is_enabled("formatter", "sqlfluff") then
        for _, filetype in ipairs(ft.sql_ft) do
          opts.formatters_by_ft[filetype] = opts.formatters_by_ft[filetype]
            or {}
          table.insert(opts.formatters_by_ft[filetype], "sqlfluff")
        end
      end

      -- Apply saved priority order then filter disabled formatters.
      for filetype, fmts in pairs(opts.formatters_by_ft) do
        opts.formatters_by_ft[filetype] =
          order.enabled_names_for_ft("formatter", filetype, fmts)
      end

      return opts
    end,
  },
}
