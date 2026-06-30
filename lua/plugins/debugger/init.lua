---@type LazySpec[]
return {
  {
    -- "mfussenegger/nvim-dap",
    -- WORKAROUND: use my forked version to fix breakpoints not working on windows
    -- refer to: https://github.com/mfussenegger/nvim-dap/issues/1551
    "Orbit-Lua/nvim-dap",
    config = function()
      local config = require("plugins.debugger.config")
      local dap = require("dap")

      for name, adapter in pairs(config.adapters) do
        dap.adapters[name] = adapter
      end

      for ft, configurations in pairs(config.configurations) do
        dap.configurations[ft] = configurations
      end
    end,
    keys = {
      {
        "<leader>dt",
        "<cmd>DapToggleBreakpoint<CR>",
        desc = "DAP Toggle Breakpoint",
      },
      {
        "<leader>ds",
        "<cmd>DapNew<CR>",
        desc = "DAP New Session",
      },
      {
        "<leader>dR",
        "<cmd>DapToggleRepl<CR>",
        desc = "DAP Toggle REPL",
      },

      {
        "<leader>dc",
        "<cmd>DapContinue<CR>",
        desc = "DAP Continue",
      },
      {
        "<leader>dl",
        "<cmd>DapShowLog<CR>",
        desc = "DAP Show Log",
      },
      {
        "<leader>dn",
        "<cmd>DapStepOver<CR>",
        desc = "DAP Step Over",
      },
      {
        "<leader>di",
        "<cmd>DapStepInto<CR>",
        desc = "DAP Step Into",
      },
      {
        "<leader>do",
        "<cmd>DapStepOut<CR>",
        desc = "DAP Step Out",
      },
      {
        "<leader>dw",
        "<cmd>DapViewWatch<CR>",
        desc = "DAP Open Watch window",
      },
    },
  },

  -- https://github.com/rcarriga/nvim-dap-ui
  {
    "rcarriga/nvim-dap-ui",
    keys = {
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "DAP Toggle UI",
      },
      {
        "<leader>dr",
        function()
          require("dap").restart()
        end,
        desc = "DAP Restart",
      },
    },
    dependencies = { "Orbit-Lua/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup(opts)
      dap.set_log_level("TRACE")

      dap.listeners.before.terminate["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
}
