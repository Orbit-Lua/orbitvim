---@alias ToolCategory "lsp" | "dap" | "linter" | "formatter" | "parser" | "package"
---@alias Tool.MissingPackagePolicy "auto" | "manual"

---@class Tool.Definition
---@field ft string[]?
---@field mason string?
---@field note string?
---@field source "mason"|"treesitter"|"external"?
---@field role string?

---@class Tool.UIEntry
---@field name string
---@field meta Tool.Definition?
---@field kind "tool"|"detail"|"ft_group"?
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

---@class Tool.UI
---@field buf integer?
---@field win integer?
---@field category_idx integer
---@field scope "buffer"|"states"
---@field source_buf integer?
---@field source_ft string?
---@field source_name string?
---@field help_open boolean
---@field line_map table<integer, Tool.UIEntry>
---@field live_augroup integer?
---@field expanded table<string, boolean>?

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

---@class Tool.CategoryHandler
---@field capabilities Tool.Capabilities
---@field apply_runtime (fun(opts: Tool.ApplyRuntimeOpts))?
---@field entry_status fun(opts: Tool.StatusOpts): string?, string?
---@field apply_order (fun(opts: Tool.ApplyOrderOpts))?
---@field install (fun(name: string, on_done: fun()?): boolean)?
---@field summary (fun(definitions: table<string, Tool.Definition>): table)?

---@class Tool.Capabilities
---@field toggle boolean
---@field install boolean
---@field reorder boolean

---@class Tool.Config.Tooltip
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

---@class Tool.Config.LiveUpdateEvent
---@field event string|string[]
---@field pattern string?
---@field category ToolCategory?

---@class Tool.Config.LiveUpdate
---@field augroup string
---@field debounce_ms integer
---@field render_events Tool.Config.LiveUpdateEvent[]
---@field debounced_render_events Tool.Config.LiveUpdateEvent[]

---@class Tool.Config.Icons
---@field enabled string
---@field disabled string
---@field warning string
---@field error string
---@field expanded string
---@field collapsed string

---@class Tool.Config.Window
---@field relative string
---@field style string
---@field title string
---@field title_pos string
---@field noautocmd boolean
---@field editor_padding integer
---@field width_margin integer
---@field height_margin integer

---@class Tool.Config.Layout
---@field section_margin integer
---@field line_prefix string
---@field separator_char string
---@field separator_inset integer

---@class Tool.Config.Table
---@field indent integer
---@field separator string
---@field cell_padding integer
---@field tree_width integer
---@field empty_prefix string

---@class Tool.Config.Columns
---@field tool string
---@field grouped_tool string
---@field package string
---@field status string

---@class Tool.Config.Labels
---@field columns Tool.Config.Columns
---@field no_name string
---@field no_filetype string
---@field current_buffer string
---@field showing_available string
---@field tool_states string
---@field enabled string
---@field disabled string
---@field total string
---@field external string
---@field global_order string
---@field tool_singular string
---@field tool_plural string
---@field no_current_tools string
---@field no_category_tools string
---@field detail_ft_prefix string
---@field detail_order string
---@field detail_ft_width integer

---@class Tool.Config.Tabline
---@field prefix string
---@field item_format string
---@field hint_separator string
---@field buffer_scope_hint string
---@field states_scope_hint string
---@field help_hint string
---@field right_padding integer

---@class Tool.Config.HelpRow
---@field [1] string
---@field [2] string

---@class Tool.Config.HelpSection
---@field title string
---@field rows Tool.Config.HelpRow[]

---@class Tool.Config.Help
---@field title string
---@field key_width integer
---@field sections Tool.Config.HelpSection[]

---@class Tool.Config
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
---@field tool_categories ToolCategory[]
---@field cat_label table<ToolCategory, string>
---@field tooltip Tool.Config.Tooltip
---@field live_update Tool.Config.LiveUpdate
---@field icons Tool.Config.Icons
---@field window Tool.Config.Window
---@field layout Tool.Config.Layout
---@field table Tool.Config.Table
---@field labels Tool.Config.Labels
---@field tabline Tool.Config.Tabline
---@field help Tool.Config.Help
---@field missing_package_policy Tool.MissingPackagePolicy

---@type Tool.Config
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
  tool_categories = {
    "lsp",
    "dap",
    "linter",
    "formatter",
    "parser",
    "package",
  },
  cat_label = {
    lsp = "LSP",
    dap = "DAP",
    linter = "Linter",
    formatter = "Formatter",
    parser = "Parser",
    package = "Package",
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
    augroup = "ToolManagerLive",
    debounce_ms = 500,
    render_events = {
      { event = { "LspAttach", "LspDetach" } },
      { event = "User", pattern = "TSUpdate", category = "parser" },
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
    title = " Tool Manager ",
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
      tool = "Tool",
      grouped_tool = "Filetype / Tool",
      package = "Package",
      status = "Status",
    },
    no_name = "[No Name]",
    no_filetype = "no filetype",
    current_buffer = "Current buffer",
    showing_available = "showing available tools",
    tool_states = "Tool states",
    enabled = "enabled",
    disabled = "disabled",
    total = "total",
    external = "external",
    global_order = "global order",
    tool_singular = "tool",
    tool_plural = "tools",
    no_current_tools = "No managed tools for this buffer filetype.",
    no_category_tools = "No tools registered for this category.",
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
          { "1-6", "Switch category tab" },
          { "<Tab>", "Next tab" },
          { "<S-Tab>", "Previous tab" },
          { "s", "Switch current-buffer tools / all tool states" },
        },
      },
      {
        title = "Actions",
        rows = {
          { "<Space>", "Toggle enable / disable" },
          { "<CR> / o / za", "Expand / collapse details" },
          { "i", "Install tool" },
          { "[ / ]", "Reorder expanded ft detail (LINTER / FORMATTER only)" },
          { "K", "Show full details (all tabs)" },
        },
      },
      {
        title = "General",
        rows = {
          { "? / g?", "Toggle this help page" },
          { "q / <Esc>", "Close Tool Manager" },
        },
      },
    },
  },
  missing_package_policy = "auto",
}

return cfg
