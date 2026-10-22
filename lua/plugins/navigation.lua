---@type LazySpec[]
return {
  {
    "stevearc/oil.nvim",
    event = "VeryLazy",
    cmd = "Oil",
    keys = {
      {
        "-",
        function()
          require("oil").toggle_float(nil, { preview = {} })
        end,
        desc = "oil toggle floating",
      },
    },

    ---@type oil.SetupOpts
    opts = function()
      return require("config.navigation").oil
    end,
  },

  -- doc: https://github.com/nvim-tree/nvim-tree.lua
  {
    "nvim-tree/nvim-tree.lua",
    init = function()
      require("core.theme").load_cache("nvimtree")
    end,
    ---@type nvim_tree.config
    opts = function()
      return require("config.nvimtree")
    end,
    keys = {
      { "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "nvimtree toggle window" },
      {
        "<leader>fe",
        "<cmd>NvimTreeFocus<CR>",
        desc = "nvimtree focus window",
      },
      {
        "<C-Right>",
        "<cmd>NvimTreeResize +5<CR>",
        desc = "nvimtree resize +5",
      },
      {
        "<C-Left>",
        "<cmd>NvimTreeResize -5<CR>",
        desc = "nvimtree resize -5",
      },
      {
        "<leader>fC",
        function()
          require("nvim-tree.api").fs.create()
        end,
        desc = "create file",
      },
    },
    config = function(_, opts)
      require("nvim-tree").setup(opts)

      local api = require("nvim-tree.api")
      local Event = api.events.Event

      api.events.subscribe(Event.FileCreated, function(_)
        vim.api.nvim_exec_autocmds("User", { pattern = "CreateFile" })
      end)
    end,
  },

  {
    "Orbit-Lua/harpoon",
    -- "ThePrimeagen/harpoon",
    keys = {
      { "<C-e>", desc = "toggle harpoon quick menu" },
      { "<M-S-p>", desc = "harpoon previous item" },
      { "<M-S-n>", desc = "harpoon next item" },
      { "<leader>ba", desc = "add buffer to harpoon" },
    },
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    ---@type HarpoonPartialConfig
    opts = function()
      return require("config.navigation").harpoon
    end,
    ---@param opts HarpoonPartialConfig
    config = function(_, opts)
      require("runtime.harpoon").setup(opts)
    end,
  },
}
