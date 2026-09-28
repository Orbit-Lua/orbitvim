local M = {}

local cfg = require("tool.config")

---@param ctx Tool.UIContext
---@return ToolCategory
local function current_category(ctx)
  return cfg.tool_categories[ctx.ui.category_idx]
end

---@param ctx Tool.UIContext
---@return nil
local function schedule_render(ctx)
  vim.schedule(function()
    if
      ctx.ui.live_augroup
      and ctx.ui.win
      and vim.api.nvim_win_is_valid(ctx.ui.win)
      and not ctx.ui.help_open
    then
      ctx.render()
    end
  end)
end

---@param ctx Tool.UIContext
---@return nil
local function close_timer(ctx)
  if ctx.debounce_timer then
    ctx.debounce_timer:stop()
    ctx.debounce_timer:close()
    ctx.debounce_timer = nil
  end
end

---@param ctx Tool.UIContext
---@return nil
local function schedule_render_debounced(ctx)
  close_timer(ctx)
  ctx.debounce_timer = vim.uv.new_timer()
  ctx.debounce_timer:start(cfg.live_update.debounce_ms, 0, function()
    close_timer(ctx)
    schedule_render(ctx)
  end)
end

---@param ctx Tool.UIContext
---@param spec Tool.Config.LiveUpdateEvent
---@param callback fun()
local function create_autocmd(ctx, spec, callback)
  vim.api.nvim_create_autocmd(spec.event, {
    pattern = spec.pattern,
    group = ctx.ui.live_augroup,
    callback = callback,
  })
end

---@param ctx Tool.UIContext
---@param spec Tool.Config.LiveUpdateEvent
---@return boolean
local function applies_to_current_category(ctx, spec)
  return not spec.category or spec.category == current_category(ctx)
end

---@param ctx Tool.UIContext
---@return nil
function M.start(ctx)
  if ctx.ui.live_augroup then
    return
  end
  ctx.ui.live_augroup = vim.api.nvim_create_augroup(cfg.live_update.augroup, {
    clear = true,
  })

  for _, spec in ipairs(cfg.live_update.render_events) do
    create_autocmd(ctx, spec, function()
      schedule_render(ctx)
    end)
  end

  for _, spec in ipairs(cfg.live_update.debounced_render_events) do
    create_autocmd(ctx, spec, function()
      if not applies_to_current_category(ctx, spec) then
        return
      end
      schedule_render_debounced(ctx)
    end)
  end
end

---@param ctx Tool.UIContext
---@return nil
function M.stop(ctx)
  close_timer(ctx)
  if ctx.ui.live_augroup then
    pcall(vim.api.nvim_del_augroup_by_id, ctx.ui.live_augroup)
    ctx.ui.live_augroup = nil
  end
end

return M
