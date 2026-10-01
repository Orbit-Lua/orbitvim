---@alias ToolCategory "lsp"|"dap"|"linter"|"formatter"|"parser"|"package"
---@class Tool.Definition
---@field ft string[]?
---@field mason string?
---@field runtime_name string?
---@field note string?
---@field source string?
---@class Tool.FtGroup
---@field ft string
---@field names string[]
---@class Tool.ApplyRuntimeOpts
---@field name string
---@field meta Tool.Definition
---@field is_enabled boolean
---@class Tool.StatusOpts
---@field name string
---@field meta Tool.Definition
---@field installed boolean?
---@class Tool.ApplyOrderOpts
---@field ft string
---@field enabled_names string[]

return {
  width = 120,
  height = 40,
  missing_package_policy = "auto",
  categories = { "lsp", "dap", "linter", "formatter", "parser", "package" },
  labels = {
    lsp = "LSP",
    dap = "DAP",
    linter = "Linter",
    formatter = "Formatter",
    parser = "Parser",
    package = "Package",
  },
  icons = {
    enabled = "",
    disabled = "",
    warning = "",
    error = "",
    expanded = "",
    collapsed = "",
  },
  details = { width = 70, max_messages = 8 },
  refresh = { debounce_ms = 500 },
  -- The view installs these mappings and renders the same descriptions in help.
  mappings = {
    {
      keys = { "q", "<Esc>" },
      action = "close",
      description = "Close Tool Manager",
    },
    { keys = { "?", "g?" }, action = "help", description = "Toggle help" },
    {
      keys = { "s" },
      action = "scope",
      description = "Current buffer / all tool states",
    },
    { keys = { "<Tab>" }, action = "next", description = "Next category" },
    {
      keys = { "<S-Tab>" },
      action = "previous",
      description = "Previous category",
    },
    {
      keys = { "<Space>" },
      action = "toggle",
      description = "Enable / disable selected tool",
    },
    {
      keys = { "i" },
      action = "install",
      description = "Install selected tool",
    },
    {
      keys = { "[" },
      action = "up",
      description = "Move formatter / linter earlier",
    },
    {
      keys = { "]" },
      action = "down",
      description = "Move formatter / linter later",
    },
    {
      keys = { "o", "<CR>", "za" },
      action = "expand",
      description = "Expand / collapse entry",
    },
    { keys = { "K" }, action = "details", description = "Show tool details" },
  },
}
