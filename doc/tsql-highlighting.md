# T-SQL highlighting

SQL buffers keep the `sql` filetype and the generic SQL parser. OrbitVim extends Tree-sitter queries for stable T-SQL nodes and uses a bounded Vim syntax fallback where the parser recovers through unusable `ERROR` nodes. Both apply inside Markdown `sql` fences.

## Configuration

`runtime.treesitter.start(buf)` starts Tree-sitter on filetype events, then enables SQL syntax or the contained Markdown fallback. Defaults live in `lua/config/treesitter.lua`:

```lua
sql = {
  dialect = "tsql",
  markdown_fenced_fallback = true,
  syntax_fallback = true,
}
```

Dialect precedence is buffer-local `b:sql_type_override`, global `g:sql_type_default`, then the configured default. Existing choices are preserved. For example, select Oracle before startup with:

```lua
vim.b.sql_type_override = "sqloracle"
```

Disable all legacy fallback while retaining Tree-sitter:

```lua
require("config.treesitter").sql.syntax_fallback = false
```

Or disable it only in Markdown:

```lua
require("config.treesitter").sql.markdown_fenced_fallback = false
```

OrbitVim adds a dialect mapping to `g:markdown_fenced_languages` while preserving other languages and explicit SQL mappings such as `sql=sqloracle`. LuaSnip and SQLFluff continue using `sql`.

## Query corrections

[`after/queries/sql/highlights.scm`](../after/queries/sql/highlights.scm) begins with `; extends`, preserving upstream captures. It corrects omitted keywords, `TOP`, surviving `NOCOUNT` / `XACT_ABORT` identifiers, built-in calls, local/system variables and SQL Server types in stable definition or cast positions.

Corrections use higher priority to override generic captures. Built-in function/type corrections exclude schema-qualified names so user-defined objects keep their original classification. Use `:InspectTree` to establish stable structure before extending the query.

## Lexical fallback

[`syntax/tsql.vim`](../syntax/tsql.vim) covers batch separators, control-flow keywords, variables, bracketed identifiers, built-in types and functions that error recovery can discard. Strings and comments shield their contents from keyword matches.

Markdown loads the fallback in a contained cluster; it must not affect prose, inline code or other languages. Keep patterns lexical and bounded. Model stable syntax with queries, and avoid Vim regions for nested procedures, transactions or dynamic SQL. An overlap is justified only where parser recovery can remove the queryable node.

## Validation contract

The integration suite executes queries and syntax groups to verify precedence, opt-outs, containment, corrections and string/comment shielding. Every `sql` fence in [the conventions](tsql-conventions.md) also runs through Markdown injection and highlighting coverage, including each fallback category.

The corpus checks visible coverage rather than requiring error-free SQL parse trees. Adding an example changes that input; existing integration tests must pass with the example in place.
