---@type LazySpec[]
return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function(plugin)
      require("features.markdown.runtime").build_preview(plugin)
    end,
    keys = {
      {
        "<leader>mp",
        "<cmd>MarkdownPreviewToggle<cr>",
        desc = "markdown preview toggle",
      },
    },
  },
}
