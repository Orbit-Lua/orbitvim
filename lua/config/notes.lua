return {
  legacy_commands = false,
  workspaces = {
    {
      name = "knowledge base",
      path = vim.fn.expand("~") .. "/OneDrive/Knowledge_Base",
    },
  },

  -- ref: https://obsidian.md/help/properties
  frontmatter = {
    func = function(note)
      return require("runtime.notes").frontmatter(note)
    end,
  },
}
