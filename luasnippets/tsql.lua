local parse = require("luasnip").parser.parse_snippet

local families = {
  require("config.snippets.tsql.database_objects_and_schema_changes"),
  require("config.snippets.tsql.indexes_and_sequences"),
  require("config.snippets.tsql.programmable_objects"),
  require("config.snippets.tsql.queries_joins_ctes_and_windows"),
  require("config.snippets.tsql.data_modification"),
  require(
    "config.snippets.tsql.control_flow_temporary_storage_and_transactions"
  ),
  require("config.snippets.tsql.dynamic_sql"),
  require("config.snippets.tsql.security_and_object_lifecycle"),
  require("config.snippets.tsql.constraint_and_column_fragments"),
  require("config.snippets.tsql.common_expressions_and_statement_fragments"),
}
local snippets = {}
for _, family in ipairs(families) do
  for _, declaration in ipairs(family) do
    local trigger, name, body = unpack(declaration)
    snippets[#snippets + 1] =
      parse({ trig = trigger, name = name, dscr = name }, vim.trim(body))
  end
end
return snippets
