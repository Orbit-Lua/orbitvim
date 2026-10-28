local M = {}

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
