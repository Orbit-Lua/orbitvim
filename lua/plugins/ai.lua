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
          accept = false, -- handled by nvim-cmp / blink.cmp
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
        enabled = true,
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
    -- copilot cmp source
    "hrsh7th/nvim-cmp",
    optional = true,
    dependencies = { -- this will only be evaluated if nvim-cmp is enabled
      {
        "zbirenbaum/copilot-cmp",
        opts = {},
        config = function(_, opts)
          local copilot_cmp = require("copilot_cmp")
          copilot_cmp.setup(opts)
          -- attach cmp source whenever copilot attaches
          -- fixes lazy-loading issues with the copilot cmp source
          require("snacks").util.lsp.on({ name = "copilot" }, function()
            copilot_cmp._on_insert_enter({})
          end)
        end,
        specs = {
          {
            "hrsh7th/nvim-cmp",
            optional = true,
            ---@param opts cmp.ConfigSchema
            opts = function(_, opts)
              table.insert(opts.sources, 1, {
                name = "copilot",
                group_index = 1,
                priority = 100,
              })
            end,
          },
        },
      },
    },
  })
end

return specs
