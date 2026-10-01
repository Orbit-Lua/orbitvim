---@type LazySpec[]
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    keys = {
      {
        "<leader>fm",
        function()
          require("runtime.formatter").format()
        end,
        desc = "format file",
        mode = { "n", "x" },
      },
    },
    opts = function()
      return require("runtime.formatter").options()
    end,
  },
}
