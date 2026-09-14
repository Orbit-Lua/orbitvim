local M = {}

---@class ProgressNotification
---@field private active boolean
---@field private notification unknown
---@field private timer uv.uv_timer_t?
local ProgressNotification = {}
ProgressNotification.__index = ProgressNotification

---@class ProgressNotificationOpts
---@field message string
---@field level? number
---@field notify_opts? table<string, any>
---@field interval? integer
---@field spinner? fun(): string
---@field spinner_field? string

local function noice_message(notification)
  if type(notification) ~= "table" or not notification.id then
    return
  end

  local ok, manager = pcall(require, "noice.message.manager")
  if not ok then
    return
  end

  return manager.get_by_id(notification.id), manager
end

---@private
function ProgressNotification:stop_timer()
  if self.timer and not self.timer:is_closing() then
    self.timer:stop()
    self.timer:close()
  end
  self.timer = nil
end

---@param opts {message: string, level?: number, notify_opts?: table<string, any>}
function ProgressNotification:finish(opts)
  if not self.active then
    return
  end

  self.active = false
  self:stop_timer()

  local message, manager = noice_message(self.notification)
  if message then
    message:set(opts.message)
    message.level = opts.level == vim.log.levels.ERROR and "error" or "info"
    message.opts = vim.tbl_extend("force", message.opts, opts.notify_opts or {})
    message.opts.keep = nil
    manager.add(message)
    return
  end

  vim.notify(opts.message, opts.level, opts.notify_opts)
end

---@param opts ProgressNotificationOpts
---@return ProgressNotification
function M.start(opts)
  local progress = setmetatable({ active = true }, ProgressNotification)
  local notify_opts = vim.tbl_extend("force", {}, opts.notify_opts or {})
  notify_opts.keep = function()
    return progress.active
  end
  progress.notification =
    vim.notify(opts.message, opts.level or vim.log.levels.INFO, notify_opts)

  local message, manager = noice_message(progress.notification)
  if not (message and opts.spinner and opts.spinner_field) then
    return progress
  end

  progress.timer = vim.uv.new_timer()
  if not progress.timer then
    return progress
  end

  local interval = opts.interval or 80
  progress.timer:start(
    interval,
    interval,
    vim.schedule_wrap(function()
      if not progress.active then
        return
      end
      local current = manager.get_by_id(progress.notification.id)
      if current then
        current.opts[opts.spinner_field] = opts.spinner()
        manager.add(current)
      end
    end)
  )

  return progress
end

return M
