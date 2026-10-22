---@type LazySpec[]
return {
  {
    -- "mfussenegger/nvim-dap",
    -- WORKAROUND: use my forked version to fix breakpoints not working on windows
    -- refer to: https://github.com/mfussenegger/nvim-dap/issues/1551
    "Orbit-Lua/nvim-dap",
    config = function()
      require("runtime.dap").setup(
        require("dap"),
        require("config.dap"),
        require("tool.state")
      )
    end,
    keys = {
      {
        "<leader>dt",
        "<cmd>DapToggleBreakpoint<CR>",
        desc = "dap toggle breakpoint",
      },
      {
        "<leader>ds",
        "<cmd>DapNew<CR>",
        desc = "dap new session",
      },
      {
        "<leader>dR",
        "<cmd>DapToggleRepl<CR>",
        desc = "dap toggle repl",
      },

      {
        "<leader>dc",
        "<cmd>DapContinue<CR>",
        desc = "dap continue",
      },
      {
        "<leader>dl",
        "<cmd>DapShowLog<CR>",
        desc = "dap show log",
      },
      {
        "<leader>dn",
        "<cmd>DapStepOver<CR>",
        desc = "dap step over",
      },
      {
        "<leader>di",
        "<cmd>DapStepInto<CR>",
        desc = "dap step into",
      },
      {
        "<leader>do",
        "<cmd>DapStepOut<CR>",
        desc = "dap step out",
      },
      {
        "<leader>dw",
        "<cmd>DapViewWatch<CR>",
        desc = "dap open watch window",
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
        desc = "dap toggle ui",
      },
      {
        "<leader>dr",
        function()
          require("dap").restart()
        end,
        desc = "dap restart",
      },
    },
    dependencies = { "Orbit-Lua/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function(_, opts)
      require("runtime.dap").setup_ui(opts)
    end,
  },
}
