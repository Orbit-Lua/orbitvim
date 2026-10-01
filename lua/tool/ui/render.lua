local Line = require("nui.line")
local Tree = require("nui.tree")
local config = require("config.tool_manager")
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
  if width >= 100 and (category == "formatter" or category == "linter") then
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
      and (node:is_expanded() and config.icons.expanded or config.icons.collapsed)
    or " "
  line:append(
    indent .. arrow .. " ",
    node.kind == "detail" and "Comment" or "Title"
  )
  if node.kind == "group" then
    line:append(
      str.trunc(
        node.filetype .. " (" .. #node.names .. " tools)",
        math.max(1, width - line:width())
      ),
      "Title"
    )
  elseif node.kind == "detail" then
    line:append(
      str.trunc(node.text, math.max(1, width - line:width())),
      "Comment"
    )
  else
    local tool = node.tool
    local icon = tool.enabled and config.icons.enabled or config.icons.disabled
    if tool.enabled and tool.status_hl == "DiagnosticError" then
      icon = config.icons.error
    elseif tool.enabled and tool.status_hl == "DiagnosticWarn" then
      icon = config.icons.warning
    end
    line:append(icon .. " ", tool.enabled and tool.status_hl or "Comment")
    local name = node.rank and (node.rank .. ". " .. tool.name) or tool.name
    local remaining = math.max(1, width - line:width())
    local name_width =
      math.min(remaining, 32, math.max(8, math.floor(remaining * 0.48)))
    line:append(str.rpad(str.trunc(name, name_width), name_width), "Normal")
    local status_width = width - line:width() - 2
    if status_width > 0 then
      line:append(
        "  " .. str.trunc(tool.status or "", status_width),
        tool.status_hl
      )
    end
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
    local children = {}
    if not filetype then
      for _, ft in ipairs(tool.meta.ft or {}) do
        table.insert(
          children,
          Tree.Node({
            id = id .. ":ft:" .. ft,
            kind = "detail",
            text = "ft: " .. ft,
            tool = tool,
            filetype = ft,
          })
        )
      end
    end
    local node = Tree.Node(
      { id = id, kind = "tool", tool = tool, filetype = filetype, rank = rank },
      children
    )
    if view.state.expanded[id] then
      node:expand()
    end
    return node
  end
  if category == "formatter" or category == "linter" then
    for _, group in ipairs(snapshot.groups) do
      local children = {}
      for rank, name in ipairs(group.names) do
        if by_name[name] then
          table.insert(children, tool_node(by_name[name], group.ft, rank))
        end
      end
      local id = category .. ":ft:" .. group.ft
      local node = Tree.Node(
        { id = id, kind = "group", filetype = group.ft, names = group.names },
        children
      )
      local expanded = view.state.expanded[id]
      if
        expanded == true or (expanded == nil and view.state.scope == "buffer")
      then
        node:expand()
      end
      table.insert(nodes, node)
    end
  else
    for _, tool in ipairs(snapshot.tools) do
      table.insert(nodes, tool_node(tool))
    end
  end
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
  if #nodes == 0 then
    vim.bo[view.body.bufnr].readonly = false
    vim.bo[view.body.bufnr].modifiable = true
    local empty = Line()
    empty:append(
      str.trunc(
        " No managed tools for this "
          .. (
            view.state.scope == "buffer" and "buffer filetype." or "category."
          ),
        width
      ),
      "Comment"
    )
    empty:render(view.body.bufnr, view.body.ns_id, 1)
  end
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
