local M = {}

local sql_marker = "^//%s*language%s*=%s*sql%s*$"

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

return M
