-- Composition root for hangar.nvim: OrbitVim's registry, settings, paths,
-- runtime owners and linter logs. The hangar spec calls it at startup, before
-- the event-loaded readers of tool state.
local M = {}

---@return Hangar.Options
function M.options()
  return {
    registry = require("features.hangar.config"),
    defaults = function()
      local settings = require("features.settings.config").get().tools
      return {
        formatter = settings.formatter_defaults,
        linter = settings.linter_defaults,
      }
    end,
    state_path = function()
      return vim.g.tool_state_path or (vim.fn.stdpath("data") .. "/tools.json")
    end,
    ui = require("features.hangar.config.view"),
    icons = require("shared.icons").tool_manager,
    border = require("shared.borders").default,
    adapters = {
      dap = {
        runtime = function()
          return require("features.dap.runtime")
        end,
        options = function()
          return require("features.dap.config")
        end,
      },
      activation = {
        formatter = function()
          return require("features.formatter.config").formatters_by_ft
        end,
        linter = function()
          return require("features.linter.config").linters_by_ft
        end,
      },
      linter = {
        logs = function(name)
          return require("utils.logger").get_entries("linter", name)
        end,
      },
    },
  }
end

---@param overrides? table top-level options that replace the OrbitVim ones
function M.setup(overrides)
  require("hangar").setup(vim.tbl_extend("force", M.options(), overrides or {}))
end

return M
