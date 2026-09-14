local M = {}

local sql_marker = "^//%s*language%s*=%s*sql%s*$"

local function select_markdown_sql_syntax()
  local config = require("config.treesitter").sql
  local mapping = "sql=" .. config.dialect
  local languages = vim.g.markdown_fenced_languages
  languages = type(languages) == "table" and vim.deepcopy(languages) or {}
  local explicit_mapping = false

  for _, language in ipairs(languages) do
    if type(language) == "string" and language:match("^sql=") then
      explicit_mapping = true
      break
    end
  end

  if explicit_mapping then
    vim.g.markdown_fenced_languages = vim.tbl_filter(function(language)
      return language ~= "sql"
    end, languages)
    return
  end

  for index, language in ipairs(languages) do
    if language == "sql" then
      languages[index] = mapping
      vim.g.markdown_fenced_languages = languages
      return
    end
  end

  table.insert(languages, mapping)
  vim.g.markdown_fenced_languages = languages
end

local function select_sql_syntax_dialect(buf)
  if vim.b[buf].sql_type_override ~= nil or vim.g.sql_type_default ~= nil then
    return
  end

  local dialect = require("config.treesitter").sql.dialect
  vim.b[buf].sql_type_override = dialect
end

local function load_legacy_syntax(buf, syntax)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("syntax clear")
    vim.b.current_syntax = nil
    vim.cmd.runtime({ "syntax/" .. syntax .. ".vim", bang = true })
  end)
end

local function start_sql_syntax_fallback(buf)
  local config = require("config.treesitter").sql
  if config.syntax_fallback ~= true then
    return
  end

  select_sql_syntax_dialect(buf)
  load_legacy_syntax(buf, "sql")
end

local function start_markdown_sql_syntax_fallback(buf)
  local config = require("config.treesitter").sql
  if
    config.syntax_fallback ~= true
    or config.markdown_fenced_fallback ~= true
  then
    return
  end

  select_markdown_sql_syntax()
  load_legacy_syntax(buf, "markdown")
end

local function is_sql_marker(node, source)
  return node ~= nil
    and node:type() == "comment"
    and vim.treesitter.get_node_text(node, source):lower():match(sql_marker)
      ~= nil
end

local function is_sql_variable(node, source)
  if node == nil then
    return false
  end

  local name = vim.treesitter.get_node_text(node, source)
  return name:lower():match("^sql") ~= nil
end

local function has_doubled_quotes(text, content_start)
  return text:sub(content_start, -2):find('""', 1, true) ~= nil
end

local function is_supported_sql_string(node, source)
  if node == nil then
    return true
  end

  for child in node:iter_children() do
    if child:type() == "escape_sequence" then
      return false
    end
  end

  local node_type = node:type()
  local text = vim.treesitter.get_node_text(node, source)
  if node_type == "verbatim_string_literal" then
    return not has_doubled_quotes(text, 3)
  end
  if
    node_type == "interpolated_string_expression"
    and (text:sub(1, 3) == '$@"' or text:sub(1, 3) == '@$"')
  then
    return not has_doubled_quotes(text, 4)
  end

  return true
end

local function has_sql_marker(node, source)
  while node do
    local node_type = node:type()
    if
      node_type == "local_declaration_statement"
      or node_type == "expression_statement"
      or node_type == "field_declaration"
    then
      return is_sql_marker(node:prev_named_sibling(), source)
    end
    node = node:parent()
  end

  return false
end

function M.setup()
  vim.treesitter.query.add_predicate(
    "orbitvim-sql-string-supported?",
    function(match, _, source, predicate)
      local nodes = match[predicate[2]]
      return is_supported_sql_string(nodes and nodes[1], source)
    end,
    { force = true }
  )

  vim.treesitter.query.add_predicate(
    "orbitvim-sql-comment-injection-enabled?",
    function(match, _, source, predicate)
      local config = require("config.treesitter").sql_injections
      local nodes = match[predicate[2]]
      return config.comment == true
        and nodes ~= nil
        and is_sql_marker(nodes[1], source)
    end,
    { force = true }
  )

  vim.treesitter.query.add_predicate(
    "orbitvim-sql-auto-injection-enabled?",
    function(match, _, source, predicate)
      local config = require("config.treesitter").sql_injections
      if config.auto ~= true then
        return false
      end

      local nodes = match[predicate[2]]
      local node = nodes and nodes[1]
      return is_sql_variable(node, source)
        and not (config.comment == true and has_sql_marker(node, source))
    end,
    { force = true }
  )
end

function M.start(buf)
  buf = buf or 0
  pcall(vim.treesitter.start, buf)

  local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
  local restore_syntax
  if filetype == "sql" then
    restore_syntax = start_sql_syntax_fallback
  elseif filetype == "markdown" then
    restore_syntax = start_markdown_sql_syntax_fallback
  end

  if restore_syntax == nil then
    return
  end

  restore_syntax(buf)
  vim.schedule(function()
    if
      vim.api.nvim_buf_is_valid(buf)
      and vim.api.nvim_get_option_value("filetype", { buf = buf }) == filetype
    then
      restore_syntax(buf)
    end
  end)
end

return M
