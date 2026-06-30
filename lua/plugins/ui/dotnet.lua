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
    ft = "cs",
    opts = {},
  },
}
