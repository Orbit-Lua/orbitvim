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

return {
  lsp = require("tool.category.lsp"),
  dap = require("tool.category.dap"),
  linter = require("tool.category.linter"),
  formatter = require("tool.category.formatter"),
  parser = require("tool.category.parser"),
  package = require("tool.category.package"),
}
