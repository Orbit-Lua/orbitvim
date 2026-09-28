vim.filetype.add({
  filename = {
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
  },

  extension = {
    -- issue: https://github.com/nvim-treesitter/nvim-treesitter/issues/1019#issuecomment-1087077196
    jsx = "jsx",
  },
})
