local os_utils = require("utils.os")

---@type LazySpec[]
return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    cond = vim.fn.isdirectory(vim.fn.expand("~") .. "/OneDrive/Knowledge_Base")
      == 1,
    lazy = true,
    ft = "markdown",
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
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
          if
            note.id == "AGENTS"
            or note.id == "CLAUDE"
            or note.id == "SKILL"
          then
            return {}
          end

          local out = {
            id = note.id,
            aliases = note.aliases,
            tags = note.tags,
            created = os_utils.get_datetime(),
            modified = os_utils.get_datetime(),
          }

          if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
            for k, v in pairs(note.metadata) do
              out[k] = v
            end

            if note.metadata.modified ~= nil then
              out.modified = os_utils.get_datetime()
            end
          end

          return out
        end,
      },
    },
    config = function(_, opts)
      require("runtime.notes").setup(opts)
    end,
  },
}
