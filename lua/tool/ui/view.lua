local Popup = require("nui.popup")
local Layout = require("nui.layout")
local config = require("config.tool_manager")
local manager = require("tool.manager")
local render = require("tool.ui.render")
local details = require("tool.ui.details")

local View = {}
View.__index = View

function View:category()
  return config.categories[self.state.category]
end

function View:active()
  return not self.closed
    and self.body.winid
    and vim.api.nvim_win_is_valid(self.body.winid)
end

local function dimensions()
  return {
    width = math.max(3, math.min(config.width, vim.o.columns - 4)),
    height = math.max(
      5,
      math.min(config.height, vim.o.lines - vim.o.cmdheight - 4)
    ),
  }
end

local function sections(view, height)
  local compact = height < 8
  return Layout.Box({
    Layout.Box(view.header, { size = compact and 2 or 3 }),
    Layout.Box(view.body, { grow = 1 }),
    Layout.Box(view.footer, { size = compact and 1 or 2 }),
  }, { dir = "col" })
end

function View:current()
  if self.state.help or not self.tree or not self:active() then
    return nil
  end
  return self.tree:get_node(vim.api.nvim_win_get_cursor(self.body.winid)[1])
end

function View:refresh(first, identity)
  if not self:active() then
    return
  end
  local selected = self:current()
  local selected_id = identity or selected and selected.id
  selected_id = selected_id or self.saved_selection
  local position = vim.api.nvim_win_get_cursor(self.body.winid)
  local size = dimensions()
  self.frame:update_layout({ size = size })
  self.layout:update({}, sections(self, size.height))
  local snapshot = manager.snapshot({
    category = self:category(),
    scope = self.state.scope,
    source = self.source,
  })
  render.chrome(self, snapshot)
  if self.state.help then
    render.help(self)
  else
    render.tree(self, snapshot)
    local selected_line
    if selected_id then
      local _, line = self.tree:get_node(selected_id)
      selected_line = line
    end
    local count = vim.api.nvim_buf_line_count(self.body.bufnr)
    vim.api.nvim_win_set_cursor(
      self.body.winid,
      { first and 1 or selected_line or math.min(position[1], count), 0 }
    )
  end
end

function View:schedule_refresh(debounce)
  if self.closed then
    return
  end
  if debounce then
    if not self.timer then
      self.timer = vim.uv.new_timer()
    end
    self.timer:stop()
    self.timer:start(config.refresh.debounce_ms, 0, function()
      vim.schedule(function()
        if not self.closed then
          self:refresh()
        end
      end)
    end)
  elseif not self.pending_refresh then
    self.pending_refresh = true
    vim.schedule(function()
      self.pending_refresh = false
      self:refresh()
    end)
  end
end

function View:close()
  if self.closed then
    return
  end
  self.closed = true
  if self.timer then
    self.timer:stop()
    self.timer:close()
    self.timer = nil
  end
  if self.unsubscribe then
    self.unsubscribe()
    self.unsubscribe = nil
  end
  if self.group then
    vim.api.nvim_del_augroup_by_id(self.group)
    self.group = nil
  end
  details.close(self)
  self.layout:unmount()
  self.frame:unmount()
  self.on_close(self)
end

function View:action(action)
  if action == "close" then
    self:close()
    return
  end
  if action == "help" then
    details.close(self)
    local selected = self:current()
    if selected then
      self.saved_selection = selected.id
    end
    self.state.help = not self.state.help
    self:refresh()
    return
  end
  if action == "scope" then
    details.close(self)
    self.state.scope = self.state.scope == "buffer" and "states" or "buffer"
    self:refresh(true)
    return
  end
  if action == "next" or action == "previous" then
    details.close(self)
    self.state.category = (
      (self.state.category - 1 + (action == "next" and 1 or -1))
      % #config.categories
    ) + 1
    self:refresh(true)
    return
  end
  local node = self:current()
  if not node then
    return
  end
  if action == "expand" then
    while not node:has_children() and node:get_parent_id() do
      node = self.tree:get_node(node:get_parent_id())
    end
    if node:has_children() then
      self.state.expanded[node.id] = not node:is_expanded()
      self.saved_selection = node.id
      self:refresh(false, node.id)
    end
    return
  end
  if not node.tool then
    return
  end
  if action == "details" then
    details.show(self, node.tool)
    return
  end
  local selection = {
    category = self:category(),
    name = node.tool.name,
    filetype = node.filetype,
  }
  local function completed(success, err)
    if success == false and err then
      vim.notify("ToolManager: " .. err, vim.log.levels.WARN)
    end
    -- The operation outlives the view; this callback only updates its own session.
    self:schedule_refresh()
  end
  if action == "toggle" then
    manager.toggle(selection, completed)
  elseif action == "install" then
    manager.install(selection, completed)
  elseif action == "up" or action == "down" then
    selection.direction = action == "up" and -1 or 1
    manager.reorder(selection, completed)
  end
  self:refresh()
end

local function popup(filetype, border)
  return Popup({
    border = border or "none",
    focusable = filetype == "ToolManager",
    buf_options = { filetype = filetype, buflisted = false },
    win_options = {
      wrap = false,
      number = false,
      relativenumber = false,
      signcolumn = "no",
    },
  })
end

function View.new(source, state, on_close)
  local self =
    setmetatable({ source = source, state = state, on_close = on_close }, View)
  local size = dimensions()
  self.frame = Popup({
    relative = "editor",
    position = "50%",
    size = size,
    border = require("config.borders").default,
    focusable = false,
    zindex = 49,
    buf_options = { filetype = "ToolManagerFrame", buflisted = false },
    win_options = { wrap = false },
  })
  self.header = popup("ToolManagerNavigation")
  self.body = popup("ToolManager")
  self.footer = popup("ToolManagerStatus")
  self.layout = Layout(self.frame, sections(self, size.height))
  self.layout:mount()
  -- Native title keeps the frame a single window, including external-close cleanup.
  vim.api.nvim_win_set_config(self.frame.winid, {
    title = " Tool Manager ",
    title_pos = "center",
  })
  vim.wo[self.body.winid].cursorline = true
  vim.api.nvim_set_current_win(self.body.winid)
  self.group = vim.api.nvim_create_augroup(
    "ToolManagerSession" .. self.body.bufnr,
    { clear = true }
  )
  self.unsubscribe = require("tool.mason").observe(function()
    self:schedule_refresh()
  end)
  for _, mapping in ipairs(config.mappings) do
    for _, key in ipairs(mapping.keys) do
      self.body:map("n", key, function()
        self:action(mapping.action)
      end, { nowait = true, silent = true, desc = mapping.description })
    end
  end
  for index = 1, #config.categories do
    self.body:map("n", tostring(index), function()
      details.close(self)
      self.state.category = index
      self:refresh(true)
    end, { nowait = true, silent = true })
  end
  for _, component in ipairs({ self.frame, self.header, self.body, self.footer }) do
    vim.api.nvim_create_autocmd("WinClosed", {
      group = self.group,
      pattern = tostring(component.winid),
      once = true,
      callback = function()
        vim.schedule(function()
          self:close()
        end)
      end,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
      group = self.group,
      buffer = component.bufnr,
      once = true,
      callback = function()
        vim.schedule(function()
          self:close()
        end)
      end,
    })
  end
  vim.api.nvim_create_autocmd(
    { "LspAttach", "LspDetach", "VimResized", "ColorScheme" },
    {
      group = self.group,
      callback = function(event)
        if event.event == "VimResized" then
          details.resize(self)
        end
        self:schedule_refresh()
      end,
    }
  )
  vim.api.nvim_create_autocmd("User", {
    group = self.group,
    pattern = { "TSUpdate", "ToolManagerChanged" },
    callback = function()
      self:schedule_refresh()
    end,
  })
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = self.group,
    callback = function()
      if self:category() == "linter" then
        self:schedule_refresh(true)
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = self.group,
    pattern = "NvimLintRunPost",
    callback = function()
      if self:category() == "linter" then
        self:schedule_refresh(true)
      end
    end,
  })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = self.group,
    buffer = self.body.bufnr,
    callback = function()
      details.close(self)
    end,
  })
  self:refresh(true)
  return self
end

return View
