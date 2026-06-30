---@module "edgy"
---@type LazySpec[]
return {
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    init = function()
      vim.opt.laststatus = 3
      vim.opt.splitkeep = "screen"
    end,
    keys = {
      {
        "<leader>ue",
        function()
          require("edgy").toggle()
        end,
        desc = "Edgy Toggle",
      },
      {
        "<leader>uE",
        function()
          require("edgy").select()
        end,
        desc = "Edgy Select Window",
      },
    },
    opts = function()
      local opts = {
        ---@type (Edgy.View.Opts|string)[]
        bottom = {},

        animate = {
          enabled = false,
        },
      }

      -- luacheck: ignore
      -- ref: https://github.com/LazyVim/LazyVim/blob/fa88241e2f633feb530b09dc014fc51dcff5f5a8/lua/lazyvim/plugins/extras/ui/edgy.lua#L99
      for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
        opts[pos] = opts[pos] or {}
        ---@type Edgy.View.Opts
        local new_opts = {
          ft = "trouble",
          filter = function(_, win)
            return vim.w[win].trouble
              and vim.w[win].trouble.position == pos
              and vim.w[win].trouble.type == "split"
              and vim.w[win].trouble.relative == "editor"
              and not vim.w[win].trouble_preview
          end,
          size = (pos == "left" or pos == "right") and { width = 0.3 }
            or { height = 0.3 },
        }
        table.insert(opts[pos], new_opts)
      end

      return opts
    end,
  },
}
