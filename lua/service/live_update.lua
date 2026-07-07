local M = {}

local cfg = require("service.config")

---@class Service.LiveUpdate.State
---@field ui Service.UI?
---@field render (fun())?
---@field debounce_timer uv_timer_t?

---@type Service.LiveUpdate.State
local _state = { ui = nil, render = nil, debounce_timer = nil }

---@param opts { ui: Service.UI, render: fun() }
function M.init(opts)
  _state.ui = opts.ui
  _state.render = opts.render
end

---@return ServiceCategory
local function current_category()
  return cfg.service_categories[_state.ui.category_idx]
end

---@return nil
local function schedule_render()
  vim.schedule(function()
    if
      _state.ui.win
      and vim.api.nvim_win_is_valid(_state.ui.win)
      and not _state.ui.help_open
    then
      _state.render()
    end
  end)
end

---@return nil
local function close_timer()
  if _state.debounce_timer then
    _state.debounce_timer:stop()
    _state.debounce_timer:close()
    _state.debounce_timer = nil
  end
end

---@return nil
local function schedule_render_debounced()
  close_timer()
  _state.debounce_timer = vim.uv.new_timer()
  _state.debounce_timer:start(cfg.live_update.debounce_ms, 0, function()
    close_timer()
    schedule_render()
  end)
end

---@param spec Service.Config.LiveUpdateEvent
---@param callback fun()
local function create_autocmd(spec, callback)
  vim.api.nvim_create_autocmd(spec.event, {
    pattern = spec.pattern,
    group = _state.ui.live_augroup,
    callback = callback,
  })
end

---@param spec Service.Config.LiveUpdateEvent
---@return boolean
local function applies_to_current_category(spec)
  return not spec.category or spec.category == current_category()
end

---@return nil
function M.start()
  if _state.ui.live_augroup then
    return
  end
  _state.ui.live_augroup =
    vim.api.nvim_create_augroup(cfg.live_update.augroup, { clear = true })

  for _, spec in ipairs(cfg.live_update.render_events) do
    create_autocmd(spec, schedule_render)
  end

  for _, spec in ipairs(cfg.live_update.debounced_render_events) do
    create_autocmd(spec, function()
      if not applies_to_current_category(spec) then
        return
      end
      schedule_render_debounced()
    end)
  end
end

---@return nil
function M.stop()
  close_timer()
  if _state.ui.live_augroup then
    pcall(vim.api.nvim_del_augroup_by_id, _state.ui.live_augroup)
    _state.ui.live_augroup = nil
  end
end

return M
