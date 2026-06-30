---@alias ServiceCategory "lsp" | "dap" | "linter" | "formatter"
---@alias Service.MissingPackagePolicy "auto" | "manual"

---@class Service.Meta
---@field ft string[]?
---@field mason string?
---@field note string?

---@class Service.Entry
---@field name string
---@field meta Service.Meta
---@field kind "service"|"detail"|"ft_group"?
---@field ft string?
---@field order_names string[]?
---@field icon_byte integer
---@field status_byte integer
---@field status_hl string

---@class Service.UI
---@field buf integer?
---@field win integer?
---@field category_idx integer
---@field help_open boolean
---@field line_map table<integer, Service.Entry>
---@field live_augroup integer?
---@field expanded table<string, boolean>?

---@class Service.FtGroup
---@field ft string
---@field names string[]

---@class Service.ApplyRuntimeOpts
---@field name string
---@field meta Service.Meta
---@field is_enabled boolean

---@class Service.EntryStatusOpts
---@field name string
---@field meta Service.Meta
---@field installed boolean?

---@class Service.ApplyOrderOpts
---@field ft string
---@field enabled_names string[]

---@class Service.CategoryHandler
---@field apply_runtime fun(opts: Service.ApplyRuntimeOpts)
---@field entry_status fun(opts: Service.EntryStatusOpts): string?, string?
---@field apply_order (fun(opts: Service.ApplyOrderOpts))?

---@class Service.Config.Tooltip
---@field max_w integer   max display-column width for each tooltip message line
---@field max_messages integer   max number of diagnostic messages shown before "+ N more"

---@class Service.Config.Icons
---@field enabled string
---@field disabled string
---@field expanded string
---@field collapsed string

---@class Service.Config
---@field max_w integer
---@field min_w integer
---@field max_h integer
---@field min_h integer
---@field col_name integer
---@field col_ft integer
---@field col_status integer
---@field col_tool integer
---@field pad_flat integer
---@field pad_tool integer
---@field service_categories ServiceCategory[]
---@field cat_label table<ServiceCategory, string>
---@field tooltip Service.Config.Tooltip
---@field icons Service.Config.Icons
---@field missing_package_policy Service.MissingPackagePolicy

---@type Service.Config
local cfg = {
  max_w = 120,
  min_w = 120,
  max_h = 40,
  min_h = 40,
  col_name = 32,
  col_ft = 32,
  col_status = 64,
  col_package = 24,
  col_tool = 26,
  pad_flat = 2,
  pad_tool = 4,
  service_categories = { "lsp", "dap", "linter", "formatter" },
  cat_label = {
    lsp = "LSP",
    dap = "DAP",
    linter = "Linter",
    formatter = "Formatter",
  },
  tooltip = {
    max_w = 70,
    max_messages = 8,
  },
  icons = {
    enabled = "",
    disabled = "",
    expanded = "▾",
    collapsed = "▸",
  },
  missing_package_policy = "auto",
}

return cfg
