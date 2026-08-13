# T-SQL highlighting

OrbitVim extends the generic `tree-sitter-sql` highlighter for Microsoft SQL
Server while keeping the standard Neovim `sql` filetype. The implementation
uses two complementary layers:

1. `after/queries/sql/highlights.scm` extends the upstream Tree-sitter query
   for constructs that the parser exposes as stable syntax nodes.
2. `syntax/tsql.vim` supplies a deliberately small legacy syntax fallback for
   T-SQL constructs that the generic parser reduces to unusable `ERROR` nodes.

Both layers also apply to fenced `sql` blocks in Markdown. Tree-sitter injects
the SQL parser into each fence, while Neovim's Markdown syntax includes the
`tsql` fallback only inside the same fenced regions.

This keeps Tree-sitter responsible for normal SQL structure and avoids the
maintenance cost of a separate T-SQL grammar.

## Runtime behavior

Every `FileType` event calls `require("utils.treesitter").start(buf)`. The
module starts Tree-sitter first. For an `sql` buffer, it then selects the
configured legacy SQL dialect and enables Vim syntax alongside Tree-sitter. For
a Markdown buffer, it maps the `sql` fence label to the configured dialect and
enables the contained fallback.

The default configuration is declared in `lua/config/treesitter.lua`:

```lua
sql = {
  dialect = "tsql",
  markdown_fenced_fallback = true,
  syntax_fallback = true,
}
```

The filetype remains `sql`; `tsql` is only the legacy syntax dialect selected
by Neovim's `syntax/sql.vim` dispatcher. Consequently, the SQL Tree-sitter
parser, SQLFluff, formatter and linter mappings, and the T-SQL LuaSnip
collection continue to use their existing SQL integration.

## Dialect precedence

Neovim's SQL syntax dispatcher recognizes a buffer-local override and a global
default. OrbitVim follows the same precedence:

1. An existing `b:sql_type_override` wins.
2. Otherwise, an existing `g:sql_type_default` wins.
3. When neither exists, OrbitVim sets `b:sql_type_override` to the configured
   `sql.dialect`, which defaults to `tsql`.

This means project or user configuration is not overwritten. For example, an
individual buffer can select Oracle syntax before the highlighting starter
runs:

```lua
vim.b.sql_type_override = "sqloracle"
```

To disable all legacy syntax fallback while retaining Tree-sitter highlighting:

```lua
require("config.treesitter").sql.syntax_fallback = false
```

To retain the fallback in SQL buffers but disable it in Markdown fences:

```lua
require("config.treesitter").sql.markdown_fenced_fallback = false
```

OrbitVim adds `sql=tsql` to `g:markdown_fenced_languages` without replacing
other configured languages. An explicit SQL mapping such as `sql=sqloracle`
wins and is left unchanged.

## Tree-sitter query extension

The query file begins with `; extends`, so Neovim appends it to the installed
`queries/sql/highlights.scm` instead of replacing upstream SQL highlighting.
It currently covers semantic cases for which the parser provides reliable
nodes:

- `ENABLE` and `DISABLE`, whose keyword nodes are omitted by the upstream
  highlights query.
- `TOP`, which the parser currently classifies as a function invocation.
- `NOCOUNT` and `XACT_ABORT`, which survive error recovery as object-reference
  identifiers in `SET` statements.

The corrective captures use a higher query priority so that they win over an
incorrect generic capture on the same range.

Add a construct to the query when its parser node is stable and its context can
be matched without classifying unrelated identifiers. Inspect the syntax tree
with `:InspectTree`, then prefer a structural pattern over a global identifier
name match.

## Legacy syntax fallback

The fallback handles lexical constructs for which `tree-sitter-sql` currently
does not expose a useful node:

- standalone `GO` batch separators and optional repeat counts;
- T-SQL control-flow and statement keywords such as `TRY`, `CATCH`, `THROW`,
  `EXEC`, `OUTPUT`, and `APPLY`;
- `NOCOUNT` and `XACT_ABORT` when parser error recovery drops their otherwise
  query-highlightable identifier nodes;
- commonly used SQL Server types not recognized by the generic grammar;
- local variables, system variables, and bracket-delimited identifiers.

The syntax file also defines SQL strings and comments. These regions shield
fallback keywords and variables from matching inside quoted text or comments;
Tree-sitter remains the primary source of their visible highlighting.

In Markdown, Neovim loads the same syntax file through a contained syntax
cluster. Fallback matches therefore stay within fenced `sql` blocks and cannot
leak into headings, prose, inline code, or other fenced languages.

Keep fallback patterns lexical and bounded. A lexical fallback may overlap a
query correction when the node sometimes disappears during parser error
recovery. Do not model procedure bodies, transactions, dynamic SQL, or nested
control flow with Vim syntax regions. Those patterns are difficult to
synchronize and are likely to conflict with Tree-sitter. When the upstream
parser exposes a construct reliably, retain its query capture and remove the
redundant legacy rule.

## Validation

Focused coverage lives in `lua/test/spec/treesitter_tsql_spec.lua`. It verifies
the query corrections, dialect precedence, opt-out behavior, syntax groups,
Markdown containment, and protection of strings and comments.

`lua/test/spec/treesitter_tsql_corpus_spec.lua` treats every `sql` fence in
`doc/tsql-conventions.md` as an executable highlighting corpus. It verifies
that every fence receives a SQL injection, every uppercase SQL/T-SQL lexeme is
covered by either a Tree-sitter capture or a contained fallback group, and the
document exercises every fallback category. New convention examples are
included automatically; do not pin the test to a fixed fence count.

The corpus deliberately does not require error-free parse trees. The generic
SQL grammar may recover T-SQL constructs through `ERROR` nodes; the relevant
contract is complete visual highlighting through the two layers.

Before committing a change, run the full suite and startup smoke test:

```bash
make all
nvim --headless "+qall"
```
