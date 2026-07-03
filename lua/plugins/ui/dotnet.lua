---@type LazySpec[]
return {
  {
    "Orbit-Lua/dotnet-cli.nvim",
    dependencies = { "Orbit-Lua/comet.nvim" },
    cmd = {
      "DotnetManager",
      "DotnetBuild",
      "DotnetPublish",
      "DotnetGlobalJson",
    },
    keys = {
      { "<leader>ud", "<cmd>DotnetManager<CR>", desc = "open dotnet manager" },
    },
    ft = "cs",
    opts = {},
  },
}
