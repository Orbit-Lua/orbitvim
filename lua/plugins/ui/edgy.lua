---@module "edgy"
---@type LazySpec[]
return {
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>ue",
        function()
          require("edgy").toggle()
        end,
        desc = "edgy toggle",
      },
      {
        "<leader>uE",
        function()
          require("edgy").select()
        end,
        desc = "edgy select window",
      },
    },
    opts = function()
      return require("config.ui.edgy").build()
    end,
  },
}
