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
      vim.opt_local.conceallevel = 2

      require("vim.treesitter.query").set(
        "markdown",
        "highlights",
        "(fenced_code_block_delimiter) @punctuation.delimiter"
      )

      -- WORKAROUND: Code blocks with conceallevel
      -- ref:
      -- https://github.com/epwalsh/obsidian.nvim/issues/492
      -- https://github.com/epwalsh/obsidian.nvim/issues/492#issuecomment-2738571132
      require("vim.treesitter.query").set(
        "markdown",
        "highlights",
        [[
          ;From MDeiml/tree-sitter-markdown & Helix
          (setext_heading
            (paragraph) @markup.heading.1
            (setext_h1_underline) @markup.heading.1)

          (setext_heading
            (paragraph) @markup.heading.2
            (setext_h2_underline) @markup.heading.2)

          (atx_heading
            (atx_h1_marker)) @markup.heading.1

          (atx_heading
            (atx_h2_marker)) @markup.heading.2

          (atx_heading
            (atx_h3_marker)) @markup.heading.3

          (atx_heading
            (atx_h4_marker)) @markup.heading.4

          (atx_heading
            (atx_h5_marker)) @markup.heading.5

          (atx_heading
            (atx_h6_marker)) @markup.heading.6

          (info_string) @label

          (pipe_table_header
            (pipe_table_cell) @markup.heading)

          (pipe_table_header
            "|" @punctuation.special)

          (pipe_table_row
            "|" @punctuation.special)

          (pipe_table_delimiter_row
            "|" @punctuation.special)

          (pipe_table_delimiter_cell) @punctuation.special

          ; Code blocks (conceal backticks and language annotation)
          (indented_code_block) @markup.raw.block

          ((fenced_code_block) @markup.raw.block
            (#set! priority 90))

          (fenced_code_block
            (fenced_code_block_delimiter) @punctuation.delimiter)

          (fenced_code_block
            (info_string
              (language) @label))

          (link_destination) @markup.link.url

          [
            (link_title)
            (link_label)
          ] @markup.link.label

          ((link_label)
            .
            ":" @punctuation.delimiter)

          [
            (list_marker_plus)
            (list_marker_minus)
            (list_marker_star)
            (list_marker_dot)
            (list_marker_parenthesis)
          ] @markup.list

          (thematic_break) @punctuation.special

          (task_list_marker_unchecked) @markup.list.unchecked

          (task_list_marker_checked) @markup.list.checked

          ((block_quote) @markup.quote
            (#set! priority 90))

          ([
            (plus_metadata)
            (minus_metadata)
          ] @keyword.directive
            (#set! priority 90))

          [
            (block_continuation)
            (block_quote_marker)
          ] @punctuation.special

          (backslash_escape) @string.escape

          (inline) @spell
        ]]
      )

      require("obsidian").setup(opts)
    end,
  },
}
