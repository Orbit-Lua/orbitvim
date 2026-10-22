local M = {}

function M.setup_snacks(opts)
  local snacks = require("snacks")
  local redraw_range = snacks.util.redraw_range

  -- Wrap to suppress invalid window id error popups.
  snacks.util.redraw_range = function(...)
    pcall(redraw_range, ...)
  end

  snacks.setup(opts)
end

function M.open_lsp_references()
  local trouble = require("trouble")
  trouble.close({ mode = "lsp" })
  trouble.open({
    mode = "lsp",
    auto_refresh = false,
    win = { position = "right" },
    focus = false,
  })
end

return M
