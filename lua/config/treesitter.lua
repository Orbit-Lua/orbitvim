return {
  sql = {
    dialect = "tsql",
    syntax_fallback = true,
  },

  -- Tree-sitter sees C# source text rather than decoded string values. SQL
  -- strings that require escape decoding are skipped; prefer raw strings.
  sql_injections = {
    comment = true,
    auto = true,
  },
}
