local M = {}

function M.setup(opts)
  vim.opt_local.conceallevel = 2
  -- The upstream query conceals code fences; extending it would retain that metadata.
  local query = assert(
    vim.api.nvim_get_runtime_file("lua/config/notes/markdown.scm", false)[1]
  )
  vim.treesitter.query.set(
    "markdown",
    "highlights",
    table.concat(vim.fn.readfile(query), "\n")
  )
  require("obsidian").setup(opts)
end

function M.frontmatter(note)
  local os_utils = require("utils.os")
  if note.id == "AGENTS" or note.id == "CLAUDE" or note.id == "SKILL" then
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
end

return M
