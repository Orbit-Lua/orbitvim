-- Composition root for Tool Manager: OrbitVim's registry, settings, paths and
-- runtime owners. Startup reads tool state while plugins load, so this runs
-- before Lazy.
local M = {}

---@return Tool.Options
function M.options()
  return {
    registry = require("config.tools"),
    defaults = function()
      local settings = require("config.settings").get().tools
      return {
        formatter = settings.formatter_defaults,
        linter = settings.linter_defaults,
      }
    end,
    state_path = function()
      return vim.g.tool_state_path or (vim.fn.stdpath("data") .. "/tools.json")
    end,
    legacy_state_path = function()
      if vim.g.tool_state_path then
        return nil
      end
      return vim.fn.stdpath("data") .. "/service.json"
    end,
    ui = require("config.tool_manager"),
    icons = require("config.icons").tool_manager,
    border = require("config.borders").default,
    adapters = {
      dap = {
        runtime = function()
          return require("runtime.dap")
        end,
        options = function()
          return require("config.dap")
        end,
      },
      activation = {
        formatter = function()
          return require("config.formatter").formatters_by_ft
        end,
        linter = function()
          return require("config.linter").linters_by_ft
        end,
      },
    },
  }
end

---@param overrides? table top-level options that replace the OrbitVim ones
function M.setup(overrides)
  require("tool").setup(vim.tbl_extend("force", M.options(), overrides or {}))
end

return M
