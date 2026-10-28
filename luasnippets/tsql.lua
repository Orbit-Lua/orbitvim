local parse = require("luasnip").parser.parse_snippet

local families = {
  require("features.snippets.config.tsql.database_objects_and_schema_changes"),
  require("features.snippets.config.tsql.indexes_and_sequences"),
  require("features.snippets.config.tsql.programmable_objects"),
  require("features.snippets.config.tsql.queries_joins_ctes_and_windows"),
  require("features.snippets.config.tsql.data_modification"),
  require(
    "features.snippets.config.tsql.control_flow_temporary_storage_and_transactions"
  ),
  require("features.snippets.config.tsql.dynamic_sql"),
  require("features.snippets.config.tsql.security_and_object_lifecycle"),
  require("features.snippets.config.tsql.constraint_and_column_fragments"),
  require(
    "features.snippets.config.tsql.common_expressions_and_statement_fragments"
  ),
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
