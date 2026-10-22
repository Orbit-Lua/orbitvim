local Line = require("nui.line")
local Tree = require("nui.tree")
local config = require("config.tool_manager")
local icons = require("config.icons").tool_manager
local str = require("utils.str")

local M = {}

local function write(popup, lines)
  local buffer = popup.bufnr
  vim.bo[buffer].readonly = false
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_clear_namespace(buffer, popup.ns_id, 0, -1)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {})
  for index, line in ipairs(lines) do
    line:render(buffer, popup.ns_id, index)
  end
  vim.bo[buffer].modifiable = false
end

function M.chrome(view, snapshot)
  local width = vim.api.nvim_win_get_width(view.header.winid)
  local tabs = Line()
  local current = view.state.category
  local active_highlight = "ToolManagerCategoryActive"
  if width < 75 then
    tabs:append(
      str.trunc(
        " " .. current .. " " .. config.labels[view:category()] .. " ",
        width
      ),
      active_highlight
    )
    tabs:append(
      str.trunc(" · Tab switch", math.max(0, width - tabs:width())),
      "Comment"
    )
  else
    for index, category in ipairs(config.categories) do
      local selected = index == current
      tabs:append(
        " " .. index .. " " .. config.labels[category] .. " ",
        selected and active_highlight or "ToolManagerCategoryInactive"
      )
      tabs:append(" ", "Normal")
    end
  end
  local context = Line()
  local buffer_scope = view.state.scope == "buffer"
  context:append(
    str.trunc(buffer_scope and " Buffer" or " All", width),
    "Title"
  )
  context:append(
    str.trunc(
      " · " .. #snapshot.tools .. " tools",
      math.max(0, width - context:width())
    ),
    "Normal"
  )
  if buffer_scope then
    local source = view.source
    local filename = source.name == "" and "[No Name]"
      or vim.fs.basename(source.name)
    local filetype = source.filetype == "" and "no filetype" or source.filetype
    context:append(
      str.trunc(
        " · " .. filetype .. " · " .. filename,
        math.max(0, width - context:width())
      ),
      "Comment"
    )
  end
  if snapshot.summary and (snapshot.summary.attention or 0) > 0 then
    context:append(
      str.trunc(
        " · " .. snapshot.summary.attention .. " need attention",
        math.max(0, width - context:width())
      ),
      "DiagnosticWarn"
    )
  end
  local function separator()
    local line = Line()
    line:append(string.rep("─", width), "FloatBorder")
    return line
  end
  local header = { tabs, context }
  if vim.api.nvim_win_get_height(view.header.winid) > 2 then
    table.insert(header, separator())
  end
  write(view.header, header)
  local hints = Line()
  local category = view:category()
  local actions = width < 50
      and { { "?", "help" }, { "s", "scope" }, { "q", "close" } }
    or {
      { "Space", "toggle" },
      { "i", "install" },
      { "K", "details" },
      { "s", "scope" },
      { "?", "help" },
      { "q", "close" },
    }
  if category == "parser" or category == "package" then
    actions = vim.tbl_filter(function(action)
      return action[1] ~= "Space"
    end, actions)
  end
  if width >= 75 and (category == "formatter" or category == "linter") then
    table.insert(actions, 1, { "[/]", "priority" })
  end
  for _, action in ipairs(actions) do
    local text = " " .. action[1] .. " " .. action[2]
    if hints:width() + vim.fn.strdisplaywidth(text) > width then
      break
    end
    hints:append(" " .. action[1], "Special")
    hints:append(" " .. action[2], "Comment")
  end
  local footer = {}
  if vim.api.nvim_win_get_height(view.footer.winid) > 1 then
    table.insert(footer, separator())
  end
  table.insert(footer, hints)
  write(view.footer, footer)
end

local function node_line(node, width)
  local line = Line()
  local indent = string.rep("  ", node:get_depth() - 1)
  local arrow = node:has_children()
      and (node:is_expanded() and icons.expanded or icons.collapsed)
    or " "
  if node.kind ~= "columns" then
    line:append(
      indent .. arrow .. " ",
      node.kind == "detail" and "Comment" or "Title"
    )
  end
  if node.kind == "group" then
    line:append(
      str.trunc(
        node.filetype .. " (" .. #node.names .. " tools)",
        math.max(1, width - line:width())
      ),
      "Title"
    )
  elseif node.kind == "columns" then
    local enabled_width = math.min(10, math.max(7, math.floor(width * 0.14)))
    local tool_width =
      math.max(1, math.min(math.floor(width * 0.48), width - enabled_width - 5))
    local status_width = math.max(1, width - tool_width - enabled_width - 4)
    line:append(str.rpad("Tool", tool_width), "Title")
    line:append("  " .. str.rpad("Enabled", enabled_width), "Title")
    line:append("  " .. str.trunc("Status", status_width), "Title")
  elseif node.kind == "detail" then
    line:append(
      str.trunc(node.text, math.max(1, width - line:width())),
      "Comment"
    )
  elseif node.kind == "empty" then
    line:append(
      str.trunc(node.text, math.max(1, width - line:width())),
      "Comment"
    )
  else
    local tool = node.tool
    local health = tool.health_status
    local status = health and health.label or tool.status or "Unknown"
    local severity = health and health.severity or tool.status_hl
    local icon = tool.enabled and icons.enabled or icons.disabled
    if health and health.installation == "installing" then
      icon = icons.installing
    elseif
      health
      and health.enabled == false
      and severity ~= "DiagnosticError"
    then
      icon = icons.disabled
    elseif
      health
      and (
        health.installation == "unknown"
        or health.installation == "unavailable"
      )
    then
      icon = icons.unknown
    elseif severity == "DiagnosticError" then
      icon = icons.error
    elseif severity == "DiagnosticWarn" then
      icon = icons.warning
    elseif tool.enabled and health and health.runtime == "Idle" then
      icon = icons.idle
    elseif tool.enabled and severity == "DiagnosticInfo" then
      icon = icons.info
    end
    local name = node.rank and (node.rank .. ". " .. tool.name) or tool.name
    local enabled_text = (
      node.category == "parser" or node.category == "package"
    )
        and "N/A"
      or (tool.enabled and "On" or "Off")
    local enabled_width = math.min(10, math.max(7, math.floor(width * 0.14)))
    local available = math.max(1, width - line:width())
    local tool_width = math.max(
      1,
      math.min(math.floor(width * 0.48), available - enabled_width - 5)
    )
    local status_width = math.max(1, available - tool_width - enabled_width - 4)
    line:append(
      str.rpad(str.trunc(icon .. " " .. name, tool_width), tool_width),
      tool.enabled and "Normal" or "Comment"
    )
    line:append(
      "  " .. str.rpad(str.trunc(enabled_text, enabled_width), enabled_width),
      tool.enabled and "Normal" or "Comment"
    )
    line:append("  " .. str.trunc(status, status_width), severity)
  end
  return line
end

function M.tree(view, snapshot)
  local by_name = {}
  for _, tool in ipairs(snapshot.tools) do
    by_name[tool.name] = tool
  end
  local nodes = {}
  local category = snapshot.category
  local function tool_node(tool, filetype, rank)
    local id = category
      .. ":"
      .. tool.name
      .. (filetype and ":" .. filetype or "")
    local node = Tree.Node({
      id = id,
      kind = "tool",
      category = category,
      tool = tool,
      filetype = filetype,
      rank = rank,
    })
    if view.state.expanded[id] then
      node:expand()
    end
    return node
  end
  if category == "formatter" or category == "linter" then
    if view.state.scope == "buffer" then
      for _, group in ipairs(snapshot.groups) do
        for rank, name in ipairs(group.names) do
          if by_name[name] then
            table.insert(nodes, tool_node(by_name[name], group.ft, rank))
          end
        end
      end
    else
      for _, group in ipairs(snapshot.groups) do
        local children = {}
        for rank, name in ipairs(group.names) do
          if by_name[name] then
            table.insert(children, tool_node(by_name[name], group.ft, rank))
          end
        end
        local id = category .. ":ft:" .. group.ft
        local node = Tree.Node({
          id = id,
          kind = "group",
          filetype = group.ft,
          names = group.names,
        }, children)
        if view.state.expanded[id] then
          node:expand()
        end
        table.insert(nodes, node)
      end
    end
  else
    for _, tool in ipairs(snapshot.tools) do
      table.insert(nodes, tool_node(tool))
    end
  end
  if #snapshot.tools == 0 then
    table.insert(
      nodes,
      Tree.Node({
        id = category .. ":empty",
        kind = "empty",
        text = "No managed tools for this "
          .. (
            view.state.scope == "buffer" and "buffer filetype." or "category."
          ),
      })
    )
  end
  table.insert(
    nodes,
    1,
    Tree.Node({ id = category .. ":columns", kind = "columns" })
  )
  vim.bo[view.body.bufnr].readonly = false
  vim.bo[view.body.bufnr].modifiable = true
  vim.api.nvim_buf_clear_namespace(view.body.bufnr, view.body.ns_id, 0, -1)
  vim.api.nvim_buf_set_lines(view.body.bufnr, 0, -1, false, {})
  local width = vim.api.nvim_win_get_width(view.body.winid)
  view.tree = Tree({
    bufnr = view.body.bufnr,
    ns_id = view.body.ns_id,
    nodes = nodes,
    get_node_id = function(node)
      return node.id
    end,
    prepare_node = function(node)
      return node_line(node, width)
    end,
  })
  view.tree:render()
  vim.bo[view.body.bufnr].modifiable = false
end

function M.help(view)
  local width = vim.api.nvim_win_get_width(view.body.winid)
  local lines = {}
  local function add(text, highlight)
    local line = Line()
    line:append(str.trunc(text, width), highlight)
    table.insert(lines, line)
  end
  add(" Tool Manager · Help", "Title")
  add("", "Normal")
  add(
    " 1–6  Select category (LSP, DAP, Linter, Formatter, Parser, Package)",
    "Normal"
  )
  for _, mapping in ipairs(config.mappings) do
    add(
      " " .. table.concat(mapping.keys, " / ") .. "  " .. mapping.description,
      "Normal"
    )
  end
  add("", "Normal")
  add(
    " Parsers and packages can be installed; they cannot be toggled.",
    "Comment"
  )
  add(" Formatter and linter priorities are saved per filetype.", "Comment")
  write(view.body, lines)
  view.tree = nil
end

return M
