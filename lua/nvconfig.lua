---@module "ui"

---Do not delete any default fields which is needed for nv-ui
---@type ChadrcConfig
local override = {}

return vim.tbl_deep_extend("force", require("config.nvui"), override)
