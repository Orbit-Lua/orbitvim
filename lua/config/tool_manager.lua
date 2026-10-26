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
