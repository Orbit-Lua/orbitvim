<!-- markdownlint-disable MD013 -->

# T-SQL snippets

OrbitVim provides 104 project-local LuaSnip templates for Microsoft SQL Server.
They follow the practices in the
[T-SQL conventions](tsql-conventions.md) and replace the generic SQL collection
from `friendly-snippets`.

The source of truth is [`luasnippets/tsql.lua`](../luasnippets/tsql.lua).

## Using a snippet

Open a `.sql` file, enter a trigger such as `sel`, and select the snippet from
the completion menu.

| Key | Action |
| --- | --- |
| `<CR>` or `<C-y>` | Accept the selected snippet |
| `<Tab>` | Move to the next placeholder |
| `<S-Tab>` | Move to the previous placeholder |

Placeholders start with useful defaults. Repeated placeholders stay linked, so
changing an object name such as `Entity` also updates its related constraint
names. The final cursor position is represented by `$0` in the source.

SQL buffers keep Neovim's `sql` filetype. LuaSnip internally extends it with
the `tsql` collection, so Treesitter and SQLFluff continue to use the normal
SQL toolchain.

## Choosing a trigger

Triggers use short, predictable prefixes:

| Prefix or suffix | Meaning |
| --- | --- |
| `c` | Create an object |
| `alt` | Alter an existing object |
| `idx` | Create an index |
| `sel` | Select or populate from a query |
| `ins`, `upd`, `del` | Insert, update, or delete |
| `j` suffix | Joined DML variant |
| `o` suffix | DML variant with `OUTPUT` |
| `dyn` | Dynamic SQL |

For example, `upd` creates an alias-based update, `updj` adds a join, and
`updo` returns changed values with `OUTPUT`.

## Snippet catalog

### Database objects and schema changes

| Trigger | Expansion |
| --- | --- |
| `cdb` | Create a database, switch to it, and separate batches with `GO` |
| `cschema` | Create a schema |
| `ctable` | Create a conventional table with identity key, audit columns, and named constraints |
| `ctablefk` | Create a related table with a named foreign key |
| `altaddcol` | Add a column |
| `altcol` | Alter a column definition |
| `altdropcol` | Drop a column |
| `altaddcon` | Add a named constraint |
| `altdropcon` | Drop a named constraint |
| `droptable` | Drop a table with `IF EXISTS` |
| `truncate` | Truncate a table |

### Indexes and sequences

| Trigger | Expansion |
| --- | --- |
| `idx` | Create a nonclustered index |
| `idxcomp` | Create a composite index |
| `idxinc` | Create an index with included columns |
| `idxuniq` | Create a unique index |
| `idxfilter` | Create a filtered index |
| `cseq` | Create a sequence |

### Programmable objects

| Trigger | Expansion |
| --- | --- |
| `cview` | Create or alter a view |
| `cprocr` | Create or alter a read-only stored procedure with `NOCOUNT` |
| `cprocw` | Create or alter a transaction-owning stored procedure |
| `cproco` | Create or alter a stored procedure with an output parameter |
| `cfunc` | Create or alter a scalar function |
| `citvf` | Create or alter an inline table-valued function |
| `ctrig` | Create or alter a set-based trigger with `NOCOUNT` |

### Queries, joins, CTEs, and window functions

| Trigger | Expansion |
| --- | --- |
| `sel` | Select explicit columns with a predicate and deterministic ordering |
| `seld` | Select logically distinct values |
| `seltop` | Select deterministic `TOP` rows |
| `selpage` | Select with `OFFSET`/`FETCH` pagination |
| `drange` | Add a half-open date range predicate |
| `case` | Add a searched `CASE` expression |
| `ijoin` | Add an inner join |
| `ljoin` | Add a left join |
| `fjoin` | Add a full outer join |
| `xjoin` | Add an intentional cross join |
| `xapply` | Add `CROSS APPLY` for the latest related row |
| `oapply` | Add `OUTER APPLY` for the latest optional related row |
| `exists` | Add an existence predicate |
| `nexists` | Add an anti-join with `NOT EXISTS` |
| `groupby` | Create a grouped aggregate query with `HAVING` |
| `cte` | Create a common table expression |
| `mcte` | Create multiple common table expressions |
| `rcte` | Create a recursive common table expression |
| `subq` | Add an `IN` subquery predicate |
| `derived` | Query a derived table |
| `union` | Combine queries with `UNION` |
| `unionall` | Combine queries with `UNION ALL` |
| `intersect` | Find rows shared by two queries |
| `except` | Find rows present only in the first query |
| `rownum` | Add `ROW_NUMBER` |
| `rowpart` | Create a deterministic latest-row-per-group query |
| `rank` | Add `RANK` |
| `denserank` | Add `DENSE_RANK` |
| `lag` | Read the previous ordered value with `LAG` |
| `lead` | Read the next ordered value with `LEAD` |

### Data modification

| Trigger | Expansion |
| --- | --- |
| `ins` | Insert one row with explicit target columns |
| `insmulti` | Insert multiple rows with explicit target columns |
| `inssel` | Insert the result of a query |
| `inso` | Insert and return generated values with `OUTPUT` |
| `upd` | Update through an explicit table alias |
| `updj` | Update with a join |
| `updo` | Update and return old and new values with `OUTPUT` |
| `del` | Delete through an explicit table alias |
| `delj` | Delete with a join |
| `delo` | Delete and return removed values with `OUTPUT` |
| `upsert` | Update then insert inside a guarded transaction |

### Control flow, temporary storage, and transactions

| Trigger | Expansion |
| --- | --- |
| `declare` | Declare one variable |
| `ifelse` | Add an `IF`/`ELSE` block |
| `ifexists` | Add an `IF EXISTS` block |
| `while` | Add an explicit loop when set-based logic is unsuitable |
| `temptable` | Create, populate, read, and drop a temporary table |
| `selinto` | Populate a temporary table with `SELECT INTO` |
| `tablevar` | Declare and populate a table variable |
| `txn` | Own a transaction with `XACT_ABORT`, `TRY`/`CATCH`, rollback, and `THROW` |
| `trycatch` | Add error handling without transaction ownership |
| `throw` | Validate input and throw a custom error |

### Dynamic SQL

| Trigger | Expansion |
| --- | --- |
| `dynsql` | Execute dynamic SQL with parameterized values through `sys.sp_executesql` |
| `dynident` | Whitelist a dynamic identifier, wrap it with `QUOTENAME`, and execute it |

Values belong in `sp_executesql` parameters. Identifiers cannot be
parameterized, so `dynident` validates the identifier before applying
`QUOTENAME`; quoting alone is not authorization.

### Security and object lifecycle

| Trigger | Expansion |
| --- | --- |
| `grantobj` | Grant an object-level permission |
| `grantschema` | Grant a schema-level permission |
| `revoke` | Revoke an object-level permission |
| `deny` | Explicitly deny an object-level permission |
| `objif` | Check object existence with `OBJECT_ID` |
| `dropobj` | Drop a programmable object with `IF EXISTS` |

### Constraints and column fragments

| Trigger | Expansion |
| --- | --- |
| `fk` | Add a conventionally named foreign key |
| `checkcon` | Add a conventionally named check constraint |
| `defaultcon` | Add a column with a named default constraint |
| `computed` | Add a persisted computed column |
| `utccol` | Add a UTC `DATETIME2(3)` column with a named default |
| `nextseq` | Select the next value from a sequence |

### Expressions and statement fragments

| Trigger | Expansion |
| --- | --- |
| `setvar` | Assign one variable |
| `selectvars` | Assign multiple variables from a query |
| `orderby` | Add deterministic ordering with a tie-breaker |
| `aggregate` | Select common aggregate values |
| `isnull` | Add an `IS NULL` predicate |
| `notnull` | Add an `IS NOT NULL` predicate |
| `coalesce` | Add a multi-value fallback with `COALESCE` |
| `nullif` | Prevent division by zero with `NULLIF` |
| `cast` | Convert a value with ANSI `CAST` |
| `convert` | Convert a value with a SQL Server style code |
| `trycast` | Attempt a conversion without raising on invalid input |
| `concat` | Concatenate nullable values safely |
| `nocount` | Enable `NOCOUNT` |
| `xactabort` | Enable `XACT_ABORT` |
| `go` | Insert a client-side batch separator |

## Safety notes

- Review `droptable`, `dropobj`, `truncate`, `del`, `delj`, and `delo` before
  execution. Snippets generate text; they do not confirm destructive actions.
- `cprocw`, `txn`, and `upsert` assume ownership of the transaction. Reusable
  procedures that participate in a caller-owned transaction need an explicit
  transaction-ownership design.
- `GO` is understood by clients such as `sqlcmd` and SQL Server Management
  Studio. Do not send it through application APIs such as `SqlCommand`.
- `upsert` still requires an appropriate unique constraint and concurrency
  strategy; the template does not make an unsafe data model race-free.
- Index templates are starting points. Choose keys, includes, and filters from
  real predicates, ordering needs, and execution plans.

## Maintaining the collection

Add snippets to `luasnippets/tsql.lua` with the local helper:

```lua
snippet("trigger", "Completion menu name", [[
SELECT
    ${1:e.EntityId}
FROM ${2:dbo}.${3:Entity} AS ${4:e}
WHERE ${5:e.EntityId = @EntityId};
$0
]]),
```

Keep triggers unique and lowercase, give every placeholder a useful default,
terminate complete T-SQL statements with semicolons, and retain `$0` as the
final cursor position. Update the catalog and the expected collection size in
`lua/test/spec/tsql_snippets_spec.lua`, then run:

```bash
make all
nvim --headless "+qall"
```
