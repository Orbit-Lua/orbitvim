local M = {}

function M.setup_snacks(opts)
  local snacks = require("snacks")
  if not M.redraw_wrapped then
    local redraw_range = snacks.util.redraw_range
    snacks.util.redraw_range = function(...)
      local ok, err = pcall(redraw_range, ...)
      if not ok and not tostring(err):match("Invalid window id: %d+") then
        error("Snacks redraw failed: " .. tostring(err), 0)
      end
    end
    M.redraw_wrapped = true
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
