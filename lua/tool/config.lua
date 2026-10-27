---@class Tool.Options
---@field registry table<string, table> logical tools by category, plus `<category>_defaults` orders
---@field defaults fun(): { formatter: table<string, string[]>, linter: table<string, string[]> } user default orders
---@field state_path fun(): string
---@field legacy_state_path fun(): string?
---@field ui table live view options; `core.settings` updates this table in place
---@field icons table<string, string>
---@field border any
---@field adapters Tool.Adapters

---@class Tool.Adapters
---@field dap { runtime: fun(): table, options: fun(): table } debugger owner and adapter options
---@field activation table<"formatter"|"linter", fun(): table<string, string[]>> initial runtime names by filetype

local M = {}

---@type Tool.Options?
local options

local function check(value, kind, path)
  if type(value) ~= kind then
    error("tool.setup: " .. path .. " must be a " .. kind, 3)
  end
end

---@param opts Tool.Options
function M.validate(opts)
  check(opts, "table", "options")
  check(opts.registry, "table", "registry")
  check(opts.defaults, "function", "defaults")
  check(opts.state_path, "function", "state_path")
  check(opts.legacy_state_path, "function", "legacy_state_path")
  check(opts.ui, "table", "ui")
  check(opts.icons, "table", "icons")
  check(opts.adapters, "table", "adapters")
  check(opts.adapters.dap, "table", "adapters.dap")
  check(opts.adapters.dap.runtime, "function", "adapters.dap.runtime")
  check(opts.adapters.dap.options, "function", "adapters.dap.options")
  check(opts.adapters.activation, "table", "adapters.activation")
  check(
    opts.adapters.activation.formatter,
    "function",
    "adapters.activation.formatter"
  )
  check(
    opts.adapters.activation.linter,
    "function",
    "adapters.activation.linter"
  )
end

---@return Tool.Options
function M.get()
  if not options then
    error("Tool Manager is not configured: call require('tool').setup()", 2)
  end
  return options
end

---@return boolean
function M.configured()
  return options ~= nil
end

---@param opts Tool.Options
function M.set(opts)
  options = opts
end

return M
