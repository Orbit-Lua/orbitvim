local Popup = require("nui.popup")
local Line = require("nui.line")
local config = require("config.tool_manager")

local M = {}

local installation_labels = {
  installed = "Installed",
  missing = "Not installed",
  installing = "Installing…",
  external = "Externally managed",
  unavailable = "Unknown",
  unknown = "Unknown",
}

local function health_lines(tool, category)
  local health = tool.health_status or {}
  local toggleable = category ~= "parser" and category ~= "package"
  local enabled = "N/A"
  if toggleable then
    local value = health.enabled
    if value == nil then
      value = tool.enabled
    end
    enabled = value and "On" or "Off"
  end
  local source = health.source
    or tool.meta.source
    or (category == "parser" and "Tree-sitter")
    or (tool.meta.mason and "Mason")
    or "External"
  local lines = {
    { "Enabled: " .. enabled, "Normal" },
    {
      "Installation: "
        .. (
          installation_labels[health.installation]
          or health.installation
          or tool.status
          or "Unknown"
        ),
      "Normal",
    },
    { "Source: " .. source, "Normal" },
    {
      "Runtime: "
        .. (health.runtime or (toggleable and tool.status) or "Not applicable"),
      "Normal",
    },
  }
  if health.reason then
    table.insert(lines, { health.reason, "DiagnosticWarn" })
  end
  return lines
end

local function content(view, tool)
  local lines = { { tool.name, "Title" } }
  for _, item in ipairs(health_lines(tool, view:category())) do
    table.insert(lines, item)
  end
  table.insert(lines, {
    "Filetypes: " .. table.concat(tool.meta.ft or {}, ", "),
    "Comment",
  })
  local node = view:current()
  if view:category() ~= "parser" and view:category() ~= "package" then
    table.insert(lines, { "Enablement: Global", "Comment" })
  end
  if node and node.rank then
    table.insert(
      lines,
      { string.format("Priority: %s #%d", node.filetype, node.rank), "Comment" }
    )
  end
  if tool.meta.runtime_name then
    table.insert(lines, { "Backend: " .. tool.meta.runtime_name, "Comment" })
  end
  if tool.meta.mason then
    table.insert(lines, { "Mason package: " .. tool.meta.mason, "Comment" })
  end
  if tool.meta.note then
    table.insert(lines, { "", "Normal" })
    table.insert(lines, { tool.meta.note, "Comment" })
  end
  if view:category() == "linter" and tool.enabled then
    local facts =
      require("tool.manager").details({ category = "linter", name = tool.name })
    for _, entry in ipairs(facts.logs) do
      table.insert(lines, {
        entry.level .. " " .. entry.message,
        entry.level == "ERROR" and "DiagnosticError" or "DiagnosticWarn",
      })
    end
    local diagnostics = facts.diagnostics
    for index, diagnostic in ipairs(diagnostics.messages) do
      if index > config.details.max_messages then
        table.insert(lines, {
          "+"
            .. (#diagnostics.messages - config.details.max_messages)
            .. " more diagnostics",
          "Comment",
        })
        break
      end
      table.insert(lines, {
        string.format(
          "%s:%d %s",
          diagnostic.file,
          diagnostic.lnum,
          diagnostic.message
        ),
        diagnostic.severity == vim.diagnostic.severity.ERROR
            and "DiagnosticError"
          or "DiagnosticWarn",
      })
    end
  end
  return lines
end

local function geometry(view)
  local columns = vim.o.columns
  local rows = vim.o.lines - vim.o.cmdheight - 2
  local width = math.max(20, math.min(config.details.width, columns - 4))
  local height = math.max(4, math.min(rows - 2, 22))
  if columns >= 150 and rows >= 20 then
    return width, height, "right"
  elseif columns >= 85 and rows >= 20 then
    local frame_position = vim.api.nvim_win_get_position(view.frame.winid)
    local frame_height = vim.api.nvim_win_get_height(view.frame.winid)
    local detail_row = frame_position[1] + frame_height + 2
    local remaining = vim.o.lines - vim.o.cmdheight - detail_row - 3
    if remaining >= 4 then
      return width, math.min(height, 14, remaining), "bottom"
    end
  end
  return math.min(width, columns - 2), math.min(height, rows - 2), "popup"
end

local function close_popup(view, expected)
  if view.details then
    local popup = view.details
    if expected and popup ~= expected then
      return
    end
    view.details = nil
    view.details_tool = nil
    view.details_mode = nil
    popup:unmount()
  end
end

local function redraw(view)
  local popup = view.details
  if
    not popup
    or not popup.winid
    or not vim.api.nvim_win_is_valid(popup.winid)
  then
    return
  end
  local width, height, placement = geometry(view)
  local row, col
  if placement == "right" then
    row = math.max(1, math.floor((vim.o.lines - height) / 2) - 1)
    local frame_position = vim.api.nvim_win_get_position(view.frame.winid)
    col = frame_position[2] + vim.api.nvim_win_get_width(view.frame.winid) + 2
    width = math.min(width, vim.o.columns - col - 2)
  elseif placement == "bottom" then
    width = math.min(width, vim.o.columns - 4)
    local frame_position = vim.api.nvim_win_get_position(view.frame.winid)
    row = frame_position[1] + vim.api.nvim_win_get_height(view.frame.winid) + 2
    if row + height > vim.o.lines - vim.o.cmdheight - 2 then
      row = vim.o.lines - vim.o.cmdheight - height - 2
    end
    col = math.floor((vim.o.columns - width) / 2)
  else
    width = math.min(width, vim.o.columns - 4)
    height = math.min(height, vim.o.lines - vim.o.cmdheight - 4)
    row = math.floor((vim.o.lines - height) / 2) - 1
    col = math.floor((vim.o.columns - width) / 2)
  end
  popup:update_layout({
    position = { row = row, col = col },
    size = { width = width, height = height },
  })
  vim.api.nvim_win_set_option(popup.winid, "wrap", true)
  vim.api.nvim_win_set_option(popup.winid, "linebreak", true)
  vim.bo[popup.bufnr].modifiable = true
  vim.api.nvim_buf_clear_namespace(popup.bufnr, popup.ns_id, 0, -1)
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, {})
  for index, item in ipairs(content(view, view.details_tool)) do
    local line = Line()
    line:append(item[1], item[2])
    line:render(popup.bufnr, popup.ns_id, index)
  end
  vim.bo[popup.bufnr].modifiable = false
end

function M.close(view)
  close_popup(view)
end

function M.preview(view, tool, force)
  if not tool then
    close_popup(view)
    return
  end
  local _, _, placement = geometry(view)
  if placement == "popup" and not force and view.details_mode ~= "focused" then
    close_popup(view)
    return
  end
  view.details_tool = tool
  if not view.details then
    view.details_mode = view.details_mode or "preview"
    view.details = Popup({
      enter = false,
      relative = "editor",
      position = { row = 1, col = 1 },
      size = { width = 40, height = 10 },
      border = require("config.borders").default,
      zindex = 60,
      buf_options = { filetype = "ToolManagerDetails", buflisted = false },
      win_options = { wrap = true, linebreak = true },
    })
    view.details:mount()
    local popup = view.details
    local function close()
      close_popup(view, popup)
      if view:active() then
        vim.api.nvim_set_current_win(view.body.winid)
      end
    end
    for _, key in ipairs({ "q", "<Esc>" }) do
      popup:map("n", key, close, { nowait = true, silent = true })
    end
    popup:on("BufWipeout", function()
      vim.schedule(function()
        if not view.closed then
          close_popup(view, popup)
        end
      end)
    end, { once = true })
    vim.api.nvim_create_autocmd("WinClosed", {
      group = view.group,
      pattern = tostring(popup.winid),
      once = true,
      callback = function()
        vim.schedule(function()
          if not view.closed then
            close_popup(view, popup)
          end
        end)
      end,
    })
  end
  redraw(view)
end

function M.show(view, tool)
  view.details_mode = "focused"
  M.preview(view, tool, true)
  if view.details and vim.api.nvim_win_is_valid(view.details.winid) then
    vim.api.nvim_set_current_win(view.details.winid)
  end
end

function M.resize(view)
  if view.details then
    local _, _, placement = geometry(view)
    if placement == "popup" and view.details_mode ~= "focused" then
      close_popup(view)
    else
      redraw(view)
    end
  end
end

return M
