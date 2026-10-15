local M = {}

local tools = require("config.tools")
local order = require("tool.order")
local mason = require("tool.mason")
local state_mod = require("tool.state")
local category_handlers = require("tool.category")

---@param meta Tool.Definition
---@param ft string?
---@return boolean
function M.supports_ft(meta, ft)
  if not ft or ft == "" then
    return false
  end
  return vim.tbl_contains(meta.ft or {}, ft)
end

---@param category ToolCategory
---@param ft string?
---@return { name: string, meta: Tool.Definition }[]
function M.tool_entries(category, ft)
  local flat = {}
  for name, meta in pairs(tools[category] or {}) do
    if not ft or M.supports_ft(meta, ft) then
      table.insert(flat, { name = name, meta = meta })
    end
  end
  table.sort(flat, function(a, b)
    return a.name < b.name
  end)
  return flat
end

---@param category ToolCategory
---@return { total: integer, enabled: integer, disabled: integer }
function M.state_summary(category)
  local handler = category_handlers[category]
  if handler and handler.summary then
    return handler.summary(tools[category] or {})
  end

  local total = 0
  local enabled = 0
  for name in pairs(tools[category] or {}) do
    total = total + 1
    if state_mod.is_enabled(category, name) then
      enabled = enabled + 1
    end
  end
  return { total = total, enabled = enabled, disabled = total - enabled }
end

local runtime_labels = {
  ["no binary"] = "Missing executable",
  ["missing definition"] = "Missing definition",
  ["error"] = "Failed",
  ["ok"] = "Configured",
  ["no ft"] = "No filetypes",
}

local function runtime_label(value)
  if type(value) ~= "string" then
    return "Unknown"
  end
  return runtime_labels[value] or value:gsub("^%l", string.upper)
end

---Read installation and runtime independently; saved enablement only selects the
---primary label, never hides the underlying facts in details.
---@param category ToolCategory
---@param name string
---@param meta Tool.Definition
---@param filetype? string
---@return table
function M.health_status(category, name, meta, filetype)
  local handler = category_handlers[category]
  local toggleable = handler.capabilities.toggle
  local enabled
  if toggleable then
    enabled = state_mod.is_enabled(category, name)
  end
  local source = category == "parser" and "Tree-sitter"
    or (meta.mason and "Mason")
    or meta.source
    or "External"
  local installed, install_error
  if category == "parser" then
    installed, install_error = handler.installation_status(name)
  elseif meta.mason or category == "package" then
    installed, install_error = mason.package_status(meta.mason or name)
  end
  local installing = (meta.mason or category == "package")
      and mason.is_installing(meta.mason or name)
    or false
  local installation
  if installing then
    installation = "installing"
  elseif install_error then
    installation = "unavailable"
  elseif installed == true then
    installation = "installed"
  elseif installed == false then
    installation = "missing"
  elseif category ~= "parser" and not meta.mason and category ~= "package" then
    installation = "external"
  else
    installation = "unknown"
  end

  local runtime, runtime_highlight, facts
  if toggleable then
    runtime, runtime_highlight, facts = handler.entry_status({
      name = name,
      meta = meta,
      filetype = filetype,
    })
  end
  local runtime_text = toggleable and runtime_label(runtime) or "Not applicable"
  local label, severity = runtime_text, runtime_highlight or "DiagnosticWarn"
  local glyphs = require("config.icons").tool_manager
  local icon = glyphs.enabled
  if facts and facts.diagnostics then
    local diagnostics = facts.diagnostics
    label = string.format(
      "Diagnostics: %d errors, %d warnings",
      diagnostics.error_count,
      diagnostics.warn_count
    )
    runtime_text = label
    severity = "DiagnosticInfo"
    icon = glyphs.info
  elseif runtime == "no binary" then
    severity = "DiagnosticWarn"
  end
  if installing then
    label, severity, icon = "Installing…", "DiagnosticInfo", glyphs.installing
  elseif enabled == false then
    label, severity, icon = "Disabled", "Comment", glyphs.disabled
  elseif installation == "missing" then
    label, severity, icon = "Not installed", "DiagnosticWarn", glyphs.warning
  elseif installation == "unavailable" or installation == "unknown" then
    label, severity, icon = "Unknown", "DiagnosticWarn", glyphs.unknown
  elseif not toggleable then
    label, severity = "Installed", "Comment"
  elseif runtime == "disabled" then
    label, severity, icon = "Not active", "DiagnosticWarn", glyphs.warning
  elseif runtime == "idle" then
    icon, severity = glyphs.idle, "Comment"
  elseif severity == "DiagnosticError" then
    icon = glyphs.error
  elseif severity == "DiagnosticWarn" then
    icon = glyphs.warning
  end
  return {
    label = label,
    severity = severity,
    icon = icon,
    enabled = enabled,
    installation = installation,
    source = source,
    runtime = runtime_text,
    reason = install_error,
    attention = severity == "DiagnosticError" or severity == "DiagnosticWarn",
  }
end

---@param category ToolCategory
---@param ft? string
---@return Tool.FtGroup[]
function M.build_ft_groups(category, ft)
  local groups = order.build_ft_groups(category)
  if not ft or ft == "" then
    return groups
  end

  return vim.tbl_filter(function(group)
    return group.ft == ft
  end, groups)
end

return M
