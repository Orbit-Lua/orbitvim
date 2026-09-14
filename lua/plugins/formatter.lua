---@type LazySpec[]
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    keys = {
      {
        "<leader>fm",
        function()
          require("config.formatter.runtime").format()
        end,
        desc = "format file",
        mode = { "n", "x" },
      },
    },
    opts = function()
      return require("config.formatter")
    end,
  },
}
