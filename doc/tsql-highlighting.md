# T-SQL highlighting

SQL buffers keep the `sql` filetype and the generic SQL parser. OrbitVim extends Tree-sitter queries for stable T-SQL nodes. Where the parser recovers through unusable `ERROR` nodes, it uses a bounded Vim syntax fallback. Both apply inside Markdown `sql` fences.

## Configuration

`runtime.treesitter.start(buf)` starts Tree-sitter on filetype events. Then it enables SQL syntax or the contained Markdown fallback. Defaults live in `lua/config/treesitter.lua`:

```lua
sql = {
  dialect = "tsql",
  markdown_fenced_fallback = true,
  syntax_fallback = true,
}
```

Dialect precedence is buffer-local `b:sql_type_override`, then global `g:sql_type_default`, then the configured default. Existing choices stay. For example, to select Oracle before startup:

```lua
vim.b.sql_type_override = "sqloracle"
```

To disable all legacy fallback and keep Tree-sitter:

```lua
require("config.treesitter").sql.syntax_fallback = false
```

To disable it only in Markdown:

```lua
require("config.treesitter").sql.markdown_fenced_fallback = false
```

OrbitVim adds a dialect mapping to `g:markdown_fenced_languages`. Other languages and explicit SQL mappings, such as `sql=sqloracle`, stay. LuaSnip and SQLFluff continue to use `sql`.

## Query corrections

[`after/queries/sql/highlights.scm`](../after/queries/sql/highlights.scm) begins with `; extends`, so upstream captures stay. In stable definition or cast positions, it corrects these items:

- Omitted keywords and `TOP`.
- Surviving `NOCOUNT` / `XACT_ABORT` identifiers.
- Built-in calls and local/system variables.
- SQL Server types.

Corrections use a higher priority to override generic captures. Built-in function/type corrections exclude schema-qualified names. Thus user-defined objects keep their original classification. Before you extend the query, use `:InspectTree` to find a stable structure.

## Lexical fallback

[`syntax/tsql.vim`](../syntax/tsql.vim) covers the items that error recovery can discard: batch separators, control-flow keywords, variables, bracketed identifiers, built-in types and functions. Strings and comments shield their contents from keyword matches.

Markdown loads the fallback in a contained cluster. It must not affect prose, inline code or other languages. Keep patterns lexical and bounded. Model stable syntax with queries. Do not use Vim regions for nested procedures, transactions or dynamic SQL. Add an overlap only where parser recovery can remove the queryable node.

## Validation contract

The integration suite executes queries and syntax groups. It verifies precedence, opt-outs, containment, corrections and string/comment shielding. Each `sql` fence in [the conventions](tsql-conventions.md) also runs through Markdown injection and highlighting coverage, with each fallback category.

The corpus checks visible coverage. It does not require error-free SQL parse trees. A new example changes that input. The existing integration tests must pass with the new example.
