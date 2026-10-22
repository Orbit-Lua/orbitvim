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
---@field filetype string?
---@field bufnr integer?
---@class Tool.ApplyOrderOpts
---@field ft string
---@field enabled_names string[]

---@class Tool.CategoryHandler
---@field capabilities {toggle: boolean, install: boolean, reorder: boolean}
---@field apply_runtime? fun(opts: Tool.ApplyRuntimeOpts): boolean?, string?
---@field apply_order? fun(opts: Tool.ApplyOrderOpts): boolean?, string?
---@field entry_status? fun(opts: Tool.StatusOpts): string?, string?, table?
---@field install? fun(name: string, on_complete?: fun(success: boolean, err?: string)): boolean
---@field installation_status? fun(name: string): boolean?, string?
---@field wiring_status? fun(opts: Tool.StatusOpts): string?, string?

return vim.tbl_extend("force", {
  categories = { "lsp", "dap", "linter", "formatter", "parser", "package" },
  labels = {
    lsp = "LSP",
    dap = "DAP",
    linter = "Linter",
    formatter = "Formatter",
    parser = "Parser",
    package = "Package",
  },
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
}, require("config.settings").get().tool_manager)
