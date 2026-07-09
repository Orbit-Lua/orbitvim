local utils = require("utils")
local utils_cmp = require("utils.cmp")

---@type LazySpec[]
local specs = {

  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      {
        -- https://github.com/copilotlsp-nvim/copilot-lsp/blob/main/README.md
        -- for nes (next edit suggestions) support
        "copilotlsp-nvim/copilot-lsp",
        init = function()
          vim.g.copilot_nes_debounce = 500
        end,
        opts = {
          nes = {
            move_count_threshold = 10,
          },
        },
      },
    },

    cmd = "Copilot",
    build = ":Copilot auth",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      suggestion = {
        enabled = not vim.g.ai_cmp,
        auto_trigger = true,
        hide_during_completion = vim.g.ai_cmp,
        keymap = {
          accept = false, -- handled by blink.cmp
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
      copilot_model = vim.g.copilot_model,

      -- https://github.com/zbirenbaum/copilot.lua#nes-next-edit-suggestion
      nes = {
        enabled = false,
        auto_trigger = true,
        keymap = {
          accept_and_goto = "<leader>p",
          accept = false,
          dismiss = "<esc>",
        },
      },
    },
  },

  -- add ai_accept action
  {
    "zbirenbaum/copilot.lua",
    opts = function()
      utils_cmp.actions.ai_accept = function()
        if require("copilot.suggestion").is_visible() then
          utils.create_undo()
          require("copilot.suggestion").accept()
          return true
        end
      end

      vim.keymap.set(
        "i",
        "<M-l>",
        utils_cmp.actions.ai_accept,
        { desc = "accept ai suggestion" }
      )
    end,
  },
}

-- refer to: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/ai/copilot.lua
if vim.g.ai_cmp then
  table.insert(specs, {
    -- copilot blink.cmp source
    "saghen/blink.cmp",
    optional = true,
    dependencies = {
      "giuxtaposition/blink-cmp-copilot",
    },
    ---@param opts blink.cmp.Config
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or {}
      opts.sources.providers = opts.sources.providers or {}

      table.insert(opts.sources.default, 1, "copilot")
      opts.sources.providers.copilot = {
        name = "copilot",
        module = "blink-cmp-copilot",
        score_offset = 100,
        async = true,
      }
    end,
  })
end

return specs
