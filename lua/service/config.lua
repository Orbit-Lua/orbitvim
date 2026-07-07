---@alias ServiceCategory "lsp" | "dap" | "linter" | "formatter"
---@alias Service.MissingPackagePolicy "auto" | "manual"

---@class Service.Meta
---@field ft string[]?
---@field mason string?
---@field note string?

---@class Service.Entry
---@field name string
---@field meta Service.Meta?
---@field kind "service"|"detail"|"ft_group"?
---@field ft string?
---@field order_names string[]?
---@field tree_byte integer?
---@field tree_end_byte integer?
---@field icon_byte integer
---@field icon_end_byte integer?
---@field icon_hl string?
---@field status_byte integer
---@field status_end_byte integer?
---@field status_hl string

---@class Service.UI
---@field buf integer?
---@field win integer?
---@field category_idx integer
---@field scope "buffer"|"states"
---@field source_buf integer?
---@field source_ft string?
---@field source_name string?
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
---@field enabled_icon string
---@field disabled_icon string
---@field installed_icon string
---@field missing_icon string
---@field separator_line string
---@field close_keys string[]
---@field disabled_keys string[]
---@field zindex integer

---@class Service.Config.LiveUpdateEvent
---@field event string|string[]
---@field pattern string?
---@field category ServiceCategory?

---@class Service.Config.LiveUpdate
---@field augroup string
---@field debounce_ms integer
---@field render_events Service.Config.LiveUpdateEvent[]
---@field debounced_render_events Service.Config.LiveUpdateEvent[]

---@class Service.Config.Icons
---@field enabled string
---@field disabled string
---@field warning string
---@field error string
---@field expanded string
---@field collapsed string

---@class Service.Config.Window
---@field relative string
---@field style string
---@field title string
---@field title_pos string
---@field noautocmd boolean
---@field editor_padding integer
---@field width_margin integer
---@field height_margin integer

---@class Service.Config.Layout
---@field section_margin integer
---@field line_prefix string
---@field separator_char string
---@field separator_inset integer

---@class Service.Config.Table
---@field indent integer
---@field separator string
---@field cell_padding integer
---@field tree_width integer
---@field empty_prefix string

---@class Service.Config.Columns
---@field service string
---@field grouped_service string
---@field package string
---@field status string

---@class Service.Config.Labels
---@field columns Service.Config.Columns
---@field no_name string
---@field no_filetype string
---@field current_buffer string
---@field showing_available string
---@field service_states string
---@field enabled string
---@field disabled string
---@field total string
---@field external string
---@field global_order string
---@field tool_singular string
---@field tool_plural string
---@field no_current_services string
---@field no_category_services string
---@field detail_ft_prefix string
---@field detail_order string
---@field detail_ft_width integer

---@class Service.Config.Tabline
---@field prefix string
---@field item_format string
---@field hint_separator string
---@field buffer_scope_hint string
---@field states_scope_hint string
---@field help_hint string
---@field right_padding integer

---@class Service.Config.HelpRow
---@field [1] string
---@field [2] string

---@class Service.Config.HelpSection
---@field title string
---@field rows Service.Config.HelpRow[]

---@class Service.Config.Help
---@field title string
---@field key_width integer
---@field sections Service.Config.HelpSection[]

---@class Service.Config
---@field max_w integer
---@field min_w integer
---@field max_h integer
---@field min_h integer
---@field col_name integer
---@field col_ft integer
---@field col_status integer
---@field col_package integer
---@field col_tool integer
---@field pad_flat integer
---@field pad_tool integer
---@field service_categories ServiceCategory[]
---@field cat_label table<ServiceCategory, string>
---@field tooltip Service.Config.Tooltip
---@field live_update Service.Config.LiveUpdate
---@field icons Service.Config.Icons
---@field window Service.Config.Window
---@field layout Service.Config.Layout
---@field table Service.Config.Table
---@field labels Service.Config.Labels
---@field tabline Service.Config.Tabline
---@field help Service.Config.Help
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
  col_tool = 32,
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
    enabled_icon = "●",
    disabled_icon = "○",
    installed_icon = "✓",
    missing_icon = "✗",
    separator_line = "────────────────────────────",
    close_keys = { "q", "<Esc>" },
    disabled_keys = { "K" },
    zindex = 100,
  },
  live_update = {
    augroup = "ServiceManagerLive",
    debounce_ms = 500,
    render_events = {
      { event = { "LspAttach", "LspDetach" } },
      { event = "VimResized" },
    },
    debounced_render_events = {
      { event = "DiagnosticChanged", category = "linter" },
      { event = "User", pattern = "NvimLintRunPost", category = "linter" },
    },
  },
  icons = {
    enabled = "",
    disabled = "",
    warning = "",
    error = "",
    expanded = "",
    collapsed = "",
  },
  window = {
    relative = "editor",
    style = "minimal",
    title = " Service Manager ",
    title_pos = "center",
    noautocmd = true,
    editor_padding = 2,
    width_margin = 4,
    height_margin = 2,
  },
  layout = {
    section_margin = 1,
    line_prefix = "  ",
    separator_char = "─",
    separator_inset = 4,
  },
  table = {
    indent = 2,
    separator = "  ",
    cell_padding = 1,
    tree_width = 3,
    empty_prefix = "  ",
  },
  labels = {
    columns = {
      service = "Service",
      grouped_service = "Filetype / Service",
      package = "Package",
      status = "Status",
    },
    no_name = "[No Name]",
    no_filetype = "no filetype",
    current_buffer = "Current buffer",
    showing_available = "showing available services",
    service_states = "Service states",
    enabled = "enabled",
    disabled = "disabled",
    total = "total",
    external = "external",
    global_order = "global order",
    tool_singular = "tool",
    tool_plural = "tools",
    no_current_services = "No managed services for this buffer filetype.",
    no_category_services = "No services registered for this category.",
    detail_ft_prefix = "ft",
    detail_order = "order",
    detail_ft_width = 18,
  },
  tabline = {
    prefix = "  ",
    item_format = "  %d %s  ",
    hint_separator = " · ",
    buffer_scope_hint = "s states",
    states_scope_hint = "s current",
    help_hint = "? help",
    right_padding = 2,
  },
  help = {
    title = "? Help",
    key_width = 18,
    sections = {
      {
        title = "Navigation",
        rows = {
          { "1-4", "Switch tab  LSP / DAP / LINTER / FORMATTER" },
          { "<Tab>", "Next tab" },
          { "<S-Tab>", "Previous tab" },
          { "s", "Switch current-buffer services / all service states" },
        },
      },
      {
        title = "Actions",
        rows = {
          { "<Space>", "Toggle enable / disable" },
          { "<CR> / o / za", "Expand / collapse details" },
          { "i", "Install mason package" },
          { "[ / ]", "Reorder expanded ft detail (LINTER / FORMATTER only)" },
          { "K", "Show full details (all tabs)" },
        },
      },
      {
        title = "General",
        rows = {
          { "? / g?", "Toggle this help page" },
          { "q / <Esc>", "Close Service Manager" },
        },
      },
    },
  },
  missing_package_policy = "auto",
}

return cfg
