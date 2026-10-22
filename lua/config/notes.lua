return {
  legacy_commands = false,
  workspaces = {
    {
      name = "knowledge base",
      path = vim.fn.expand(require("config.settings").get().notes.vault),
    },
  },

  -- ref: https://obsidian.md/help/properties
  frontmatter = {
    func = function(note)
      return require("runtime.notes").frontmatter(note)
    end,
  },
}
