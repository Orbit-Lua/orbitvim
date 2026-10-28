return {
  legacy_commands = false,
  workspaces = {
    {
      name = "knowledge base",
      path = vim.fn.expand(
        require("features.settings.config").get().notes.vault
      ),
    },
  },

  -- ref: https://obsidian.md/help/properties
  frontmatter = {
    func = function(note)
      return require("features.notes.runtime").frontmatter(note)
    end,
  },
}
