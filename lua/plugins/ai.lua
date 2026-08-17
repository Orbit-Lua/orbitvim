local utils = require("utils")
local utils_cmp = require("utils.cmp")
local endpoint = require("ai.endpoint")
local service = require("ai.service")

---@type LazySpec[]
local specs = {
  {
    "milanglacier/minuet-ai.nvim",
    lazy = true,
    init = function()
      service.activate(endpoint.current())
    end,
    opts = {
      provider = "openai_fim_compatible",
      n_completions = 1,
      context_window = 8192,
      request_timeout = 3,
      throttle = 1500,
      debounce = 500,
      virtualtext = {
        auto_trigger_ft = vim.g.ai_cmp and {} or { "*" },
        keymap = {
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
      provider_options = {
        openai_fim_compatible = {
          api_key = function()
            return "ollama"
          end,
          name = "Ollama",
          end_point = endpoint.current(),
          model = "qwen2.5-coder:7b-base-q6_K",
          transform = { endpoint.transform_request },
          optional = {
            max_tokens = 96,
            top_p = 0.9,
          },
        },
      },
      enable_predicates = {
        service.is_ready,
        function()
          return vim.bo.buftype == "" and vim.bo.modifiable
        end,
      },
    },
    config = function(_, opts)
      require("minuet").setup(opts)

      utils_cmp.actions.ai_accept = function()
        local action = require("minuet.virtualtext").action
        if action.is_visible() then
          utils.create_undo()
          action.accept()
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

if vim.g.ai_cmp then
  table.insert(specs, {
    "saghen/blink.cmp",
    optional = true,
    ---@param opts blink.cmp.Config
    opts = function(_, opts)
      opts.keymap = opts.keymap or {}
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or {}
      opts.sources.providers = opts.sources.providers or {}
      opts.completion = opts.completion or {}
      opts.completion.trigger = opts.completion.trigger or {}

      table.insert(opts.sources.default, 1, "minuet")
      opts.sources.providers.minuet = {
        name = "Minuet",
        module = "ai.blink",
        enabled = service.is_ready,
        score_offset = 100,
        async = true,
        timeout_ms = 3000,
      }
      opts.completion.trigger.prefetch_on_insert = false
      opts.keymap["<M-y>"] = {
        function(cmp)
          if service.is_ready() then
            cmp.show({ providers = { "minuet" } })
          end
        end,
      }
    end,
  })
end

return specs
