local Popup = require("nui.popup")
local Line = require("nui.line")
local config = require("config.tool_manager")
local str = require("utils.str")

local M = {}

function M.close(view)
  if view.details then
    local popup = view.details
    view.details = nil
    view.details_tool = nil
    popup:unmount()
  end
end

function M.show(view, tool)
  if view.details then
    if view.details.winid and vim.api.nvim_win_is_valid(view.details.winid) then
      vim.api.nvim_set_current_win(view.details.winid)
      return
    end
    M.close(view)
  end
  local width = math.max(1, math.min(config.details.width, vim.o.columns - 4))
  local lines = {}
  local function add(text, highlight)
    local line = Line()
    line:append(str.trunc(" " .. text, width), highlight or "Normal")
    table.insert(lines, line)
  end
  add(tool.name, "Title")
  add("Filetypes: " .. table.concat(tool.meta.ft or {}, ", "), "Comment")
  add("Package: " .. (tool.meta.mason or tool.meta.source or "external"))
  if tool.meta.runtime_name then
    add("Runtime: " .. tool.meta.runtime_name)
  end
  add("Status: " .. tool.status, tool.status_hl)
  if tool.meta.note then
    add(tool.meta.note, "Comment")
  end
  if view:category() == "linter" and tool.enabled then
    for _, entry in
      ipairs(require("utils.logger").get_entries("linter", tool.name))
    do
      add(
        entry.level .. " " .. entry.message,
        entry.level == "ERROR" and "DiagnosticError" or "DiagnosticWarn"
      )
    end
    local diagnostics =
      require("tool.category").linter.get_linter_diagnostics(tool.name)
    for index, diagnostic in ipairs(diagnostics.messages) do
      if index > config.details.max_messages then
        add(
          "+"
            .. (#diagnostics.messages - config.details.max_messages)
            .. " more",
          "Comment"
        )
        break
      end
      add(
        string.format(
          "%s:%d %s",
          diagnostic.file,
          diagnostic.lnum,
          diagnostic.message
        ),
        diagnostic.severity == vim.diagnostic.severity.ERROR
            and "DiagnosticError"
          or "DiagnosticWarn"
      )
    end
  end
  local height =
    math.max(1, math.min(#lines, vim.o.lines - vim.o.cmdheight - 4))
  local popup = Popup({
    enter = true,
    relative = "editor",
    position = "50%",
    size = { width = width, height = height },
    border = {
      style = require("config.borders").default,
      text = { top = " Tool details ", top_align = "center" },
    },
    zindex = 100,
    buf_options = { filetype = "ToolManagerDetails", buflisted = false },
    win_options = { wrap = false },
  })
  view.details = popup
  view.details_tool = tool
  popup:mount()
  for index, line in ipairs(lines) do
    line:render(popup.bufnr, popup.ns_id, index)
  end
  vim.bo[popup.bufnr].modifiable = false
  local function close()
    M.close(view)
    if view:active() then
      vim.api.nvim_set_current_win(view.body.winid)
    end
  end
  for _, key in ipairs({ "q", "<Esc>" }) do
    popup:map("n", key, close, { nowait = true, silent = true })
  end
  popup:map("n", "K", "<nop>")
  popup:on("BufWipeout", function()
    vim.schedule(function()
      if view.details == popup then
        M.close(view)
      end
    end)
  end, { once = true })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = view.group,
    pattern = tostring(popup.winid),
    once = true,
    callback = function()
      vim.schedule(function()
        if view.details == popup then
          M.close(view)
        end
      end)
    end,
  })
end

function M.resize(view)
  if not view.details then
    return
  end
  local tool = view.details_tool
  local previous = vim.api.nvim_get_current_win()
  local focused = previous == view.details.winid
  M.close(view)
  M.show(view, tool)
  if focused then
    vim.api.nvim_set_current_win(view.details.winid)
  elseif vim.api.nvim_win_is_valid(previous) then
    vim.api.nvim_set_current_win(previous)
  end
end

return M
