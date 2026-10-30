# T-SQL conventions and templates

SQL Server conventions used by [OrbitVim snippets](tsql-snippets.md). Examples are templates or syntax fragments, not a migration to execute as one script. Each `sql` fence also exercises Markdown SQL injection and highlighting. Thus the fences are executable parser fixtures. Keep them unchanged during wording-only edits.

## Common rules

- Use explicit schemas, target columns and meaningful aliases.
- Terminate statements with semicolons.
- Prefer ANSI joins and set-based operations.
- Order results when the order affects their meaning.
- Use `CREATE OR ALTER` for supported programmable objects.
- Use `SET NOCOUNT ON` in procedures and triggers.

- Keep transactions short.
- Define whether a procedure owns or joins the transaction of its caller.
- Use `XACT_ABORT`, `TRY`/`CATCH` and `THROW` for transaction-owning code.
- Parameterize dynamic values.
- Allowlist identifiers before `QUOTENAME`.

## Names and data types

| Resource | Convention |
| --- | --- |
| Schema | Explicit domain such as `app`, `auth`, `reporting`, or consistent `dbo` |
| Table | Domain name such as `Entity` or `RelatedEntity` |
| View | `v_ActiveEntity` |
| Procedure / function | Operation name such as `GetEntity` or `CreateEntity` |
| Trigger | `TR_<Table>_<Operation>` |
| Constraint | `PK_<Table>`, `FK_<Table>_<ReferencedTable>`, `UQ_<Table>_<Column>`, `CK_<Table>_<Column>`, `DF_<Table>_<Column>` |
| Index | `IX_<Table>_<Columns>`; `UX_` for unique indexes |
| Parameter / variable | Descriptive PascalCase prefixed with `@` |

Declare one variable per line. Choose key types for domain and scale rather than habit:

```sql
DECLARE @EntityId BIGINT;
DECLARE @Name NVARCHAR(100);
DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();
```

| Data | Choice |
| --- | --- |
| Identifier | `INT`, `BIGINT` or `UNIQUEIDENTIFIER` according to domain |
| Unicode text | Sized `NVARCHAR`, using `N'...'` literals; avoid implicit conversion from `VARCHAR` |
| Date/time | `DATE`, `TIME`, `DATETIME2` or `DATETIMEOFFSET`; prefer UTC for persisted system timestamps |
| Decimal | Explicit precision and scale, such as `DECIMAL(18, 2)` |
| Boolean-like column | `BIT` |

Convert UTC to presentation time at the application boundary unless the domain requires local civil time.

## Schema objects

### Database

Let deployment or DBA-managed scripts choose production files, recovery mode and collation. `GO` is a client batch separator.

```sql
CREATE DATABASE ApplicationDatabase;
GO
```

```sql
USE ApplicationDatabase;
GO
```

### Schema

Use domain schemas when they are useful. Consistent `dbo` also suits smaller systems.

```sql
CREATE SCHEMA app;
GO
```

### Table

Name primary, unique and default constraints explicitly.

```sql
CREATE TABLE dbo.Entity
(
    EntityId BIGINT IDENTITY(1, 1) NOT NULL,

    Code NVARCHAR(50) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,

    Status TINYINT NOT NULL
        CONSTRAINT DF_Entity_Status DEFAULT (1),

    CreatedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Entity_CreatedAt DEFAULT (SYSUTCDATETIME()),

    UpdatedAt DATETIME2(3) NULL,

    CONSTRAINT PK_Entity
        PRIMARY KEY CLUSTERED (EntityId),

    CONSTRAINT UQ_Entity_Code
        UNIQUE (Code)
);
```

### Foreign key

Enable cascading actions only when the domain requires them.

```sql
CREATE TABLE dbo.RelatedEntity
(
    RelatedEntityId BIGINT IDENTITY(1, 1) NOT NULL,
    EntityId BIGINT NOT NULL,

    CreatedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_RelatedEntity_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_RelatedEntity
        PRIMARY KEY (RelatedEntityId),

    CONSTRAINT FK_RelatedEntity_Entity
        FOREIGN KEY (EntityId)
        REFERENCES dbo.Entity(EntityId)
);
```

```sql
CONSTRAINT FK_ChildEntity_ParentEntity
    FOREIGN KEY (ParentEntityId)
    REFERENCES dbo.ParentEntity(ParentEntityId)
    ON DELETE CASCADE
```

### Check constraint

Represent valid domain values as named constraints.

```sql
CREATE TABLE dbo.Item
(
    ItemId BIGINT IDENTITY(1, 1) NOT NULL,
    Amount DECIMAL(18, 2) NOT NULL,

    CONSTRAINT PK_Item
        PRIMARY KEY (ItemId),

    CONSTRAINT CK_Item_Amount
        CHECK (Amount >= 0)
);
```

### Computed column

Persist an expression only when its storage and query behavior fit the workload.

```sql
CREATE TABLE dbo.LineItem
(
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18, 2) NOT NULL,

    TotalAmount AS
        (Quantity * UnitPrice) PERSISTED
);
```

### Alter table

Review existing rows and dependent objects before changing or dropping columns and constraints.

```sql
ALTER TABLE dbo.Entity
ADD Notes NVARCHAR(500) NULL;
```

```sql
ALTER TABLE dbo.Entity
ALTER COLUMN Name NVARCHAR(200) NOT NULL;
```

```sql
ALTER TABLE dbo.Entity
DROP COLUMN Notes;
```

```sql
ALTER TABLE dbo.Entity
ADD CONSTRAINT UQ_Entity_Name
    UNIQUE (Name);
```

```sql
ALTER TABLE dbo.Entity
DROP CONSTRAINT UQ_Entity_Name;
```

### Drop and truncate

`IF EXISTS` suppresses a missing-object error. It does not make deletion safe. Review data loss and foreign-key dependencies before execution.

```sql
DROP TABLE IF EXISTS dbo.Entity;
```

```sql
TRUNCATE TABLE dbo.EntityLog;
```

```sql
DELETE FROM dbo.EntityLog
WHERE CreatedAt < @ExpiredAt;
```

### Indexes

Choose key order from predicates and sorting. Includes can cover queries without extending the key. Filtered indexes suit stable queried subsets.

```sql
CREATE INDEX IX_Entity_Name
ON dbo.Entity(Name);
```

```sql
CREATE INDEX IX_Entity_Status_CreatedAt
ON dbo.Entity
(
    Status,
    CreatedAt
);
```

```sql
CREATE INDEX IX_Entity_Status
ON dbo.Entity(Status)
INCLUDE
(
    Code,
    Name,
    CreatedAt
);
```

```sql
CREATE UNIQUE INDEX UX_Entity_Name
ON dbo.Entity(Name);
```

```sql
CREATE INDEX IX_Entity_Active
ON dbo.Entity(Code)
WHERE Status = 1;
```

### Sequence

A sequence supplies identifiers independently of a table identity column.

```sql
CREATE SEQUENCE dbo.EntityIdSequence
    AS BIGINT
    START WITH 1
    INCREMENT BY 1;
```

```sql
SELECT NEXT VALUE FOR dbo.EntityIdSequence;
```

### View

Use a view for a reusable query contract.

```sql
CREATE OR ALTER VIEW dbo.v_ActiveEntity
AS
    SELECT
        e.EntityId,
        e.Code,
        e.Name,
        e.CreatedAt
    FROM dbo.Entity AS e
    WHERE e.Status = 1;
GO
```

### Read procedure

Use parameters and explicit result columns. Suppress informational row counts.

```sql
CREATE OR ALTER PROCEDURE dbo.GetEntity
    @EntityId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.EntityId,
        e.Code,
        e.Name,
        e.Status
    FROM dbo.Entity AS e
    WHERE e.EntityId = @EntityId;
END;
GO
```

### Write procedure

This template owns its transaction. A caller-owned transaction needs a separate ownership design.

```sql
CREATE OR ALTER PROCEDURE dbo.CreateEntity
    @Code NVARCHAR(50),
    @Name NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.Entity
        (
            Code,
            Name
        )
        VALUES
        (
            @Code,
            @Name
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO
```

### Output parameter

Return an inserted identity through a typed output parameter.

```sql
CREATE OR ALTER PROCEDURE dbo.CreateEntity
    @Code NVARCHAR(50),
    @Name NVARCHAR(100),
    @EntityId BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    INSERT INTO dbo.Entity
    (
        Code,
        Name
    )
    VALUES
    (
        @Code,
        @Name
    );

    SET @EntityId = CONVERT(BIGINT, SCOPE_IDENTITY());
END;
GO
```

```sql
DECLARE @EntityId BIGINT;

EXEC dbo.CreateEntity
    @Code = N'E001',
    @Name = N'Example',
    @EntityId = @EntityId OUTPUT;

SELECT @EntityId;
```

### Scalar function

Use a scalar function when the abstraction earns its runtime cost.

```sql
CREATE OR ALTER FUNCTION dbo.FormatEntityName
(
    @Prefix NVARCHAR(50),
    @Name NVARCHAR(100)
)
RETURNS NVARCHAR(151)
AS
BEGIN
    RETURN CONCAT(@Prefix, N' ', @Name);
END;
GO
```

```sql
SELECT dbo.FormatEntityName(N'Prefix', N'Value');
```

### Inline table-valued function

Prefer inline TVFs when a reusable table-valued expression fits.

```sql
CREATE OR ALTER FUNCTION dbo.GetEntitiesByStatus
(
    @Status TINYINT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        e.EntityId,
        e.Code,
        e.Name,
        e.CreatedAt
    FROM dbo.Entity AS e
    WHERE e.Status = @Status
);
GO
```

## Queries

### Select layout

List nontrivial projections one column per line. Keep join predicates beside their joins, then filter, group, filter aggregates and order.

```sql
SELECT
    e.EntityId,
    e.Name,
    COUNT(r.RelatedEntityId) AS RelatedCount
FROM dbo.Entity AS e
LEFT JOIN dbo.RelatedEntity AS r
    ON r.EntityId = e.EntityId
WHERE e.Status = @Status
    AND e.CreatedAt >= @StartAt
    AND e.CreatedAt < @EndAt
GROUP BY
    e.EntityId,
    e.Name
HAVING COUNT(r.RelatedEntityId) >= 1
ORDER BY
    RelatedCount DESC,
    e.EntityId;
```

### Explicit projection

Avoid application `SELECT *`: schema changes should not silently change a result contract.

```sql
SELECT
    e.EntityId,
    e.Code,
    e.Name,
    e.Status
FROM dbo.Entity AS e
WHERE e.Status = 1
ORDER BY
    e.EntityId;
```

### Distinct

Remove duplicates only when distinctness is required. Repair incorrect joins and cardinality separately.

```sql
SELECT DISTINCT
    e.Category
FROM dbo.Entity AS e;
```

### Top

Use `ORDER BY` and a unique tie-breaker when the selected rows must be deterministic.

```sql
SELECT TOP (10)
    e.EntityId,
    e.Name
FROM dbo.Entity AS e
ORDER BY
    e.EntityId DESC;
```

### Predicates

Choose predicates for the required equality, range, membership, text or null semantics.

```sql
WHERE e.EntityId = @EntityId

WHERE e.EntityId <> @EntityId

WHERE e.Amount >= 0

WHERE e.Status IN (1, 2, 3)

WHERE e.Status NOT IN (4, 5)

WHERE e.Name LIKE N'%value%'

WHERE e.Email IS NULL

WHERE e.Email IS NOT NULL
```

### Date ranges

Use half-open ranges: start inclusive, end exclusive. Avoid precision-dependent end-of-day values.

```sql
WHERE e.CreatedAt >= @StartAt
    AND e.CreatedAt < @EndAt;
```

### Case

Use simple `CASE` for value matching and searched `CASE` for conditions.

```sql
SELECT
    e.EntityId,
    CASE e.Status
        WHEN 0 THEN N'Disabled'
        WHEN 1 THEN N'Active'
        WHEN 2 THEN N'Archived'
        ELSE N'Unknown'
    END AS StatusName
FROM dbo.Entity AS e;
```

```sql
CASE
    WHEN Score >= 90 THEN N'A'
    WHEN Score >= 80 THEN N'B'
    WHEN Score >= 70 THEN N'C'
    ELSE N'F'
END
```

### Inner join

Match related rows through explicit ANSI join predicates.

```sql
SELECT
    e.EntityId,
    e.Name,
    r.RelatedEntityId
FROM dbo.Entity AS e
INNER JOIN dbo.RelatedEntity AS r
    ON r.EntityId = e.EntityId;
```

### Left join

Preserve left rows without a match. Prefer reversing a right join into this form for consistent reading direction.

```sql
SELECT
    e.EntityId,
    e.Name,
    r.RelatedEntityId
FROM dbo.Entity AS e
LEFT JOIN dbo.RelatedEntity AS r
    ON r.EntityId = e.EntityId;
```

### Full outer join

Retain unmatched rows from both sources for reconciliation.

```sql
SELECT
    a.EntityId AS LeftEntityId,
    b.EntityId AS RightEntityId
FROM dbo.SourceEntity AS a
FULL OUTER JOIN dbo.TargetEntity AS b
    ON b.EntityId = a.EntityId;
```

### Cross join

Use only for an intentional Cartesian product.

```sql
SELECT
    e.EntityId,
    p.PeriodId
FROM dbo.Entity AS e
CROSS JOIN dbo.Period AS p;
```

### Apply

Use `CROSS APPLY` for a correlated relation. Use `OUTER APPLY` when unmatched left rows must remain. Add a unique ordering tie-breaker when selecting one row.

```sql
SELECT
    e.EntityId,
    e.Name,
    x.RelatedEntityId
FROM dbo.Entity AS e
CROSS APPLY
(
    SELECT TOP (1)
        r.RelatedEntityId
    FROM dbo.RelatedEntity AS r
    WHERE r.EntityId = e.EntityId
    ORDER BY
        r.CreatedAt DESC,
        r.RelatedEntityId DESC
) AS x;
```

### Exists

Test existence without projecting related rows.

```sql
SELECT
    e.EntityId,
    e.Name
FROM dbo.Entity AS e
WHERE EXISTS
(
    SELECT 1
    FROM dbo.RelatedEntity AS r
    WHERE r.EntityId = e.EntityId
);
```

### Not exists

Use an anti-join when matching related rows must be absent.

```sql
SELECT
    e.EntityId,
    e.Name
FROM dbo.Entity AS e
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.RelatedEntity AS r
    WHERE r.EntityId = e.EntityId
);
```

### Grouping and having

`WHERE` filters input rows. `GROUP BY` forms groups. `HAVING` filters the aggregates.

```sql
SELECT
    r.EntityId,
    COUNT(*) AS RelatedCount
FROM dbo.RelatedEntity AS r
GROUP BY
    r.EntityId
HAVING COUNT(*) >= 10;
```

### Aggregates

`COUNT(*)` counts rows. `COUNT(column)` excludes null values.

```sql
SELECT
    COUNT(*) AS TotalCount,
    COUNT(e.OptionalValue) AS NonNullCount,
    SUM(e.Amount) AS TotalAmount,
    AVG(e.Amount) AS AverageAmount,
    MIN(e.Amount) AS MinimumAmount,
    MAX(e.Amount) AS MaximumAmount
FROM dbo.Entity AS e;
```

### Common table expression

Terminate the preceding statement before `WITH`. A leading semicolon makes a standalone fragment safe to append.

```sql
;WITH ActiveEntity AS
(
    SELECT
        e.EntityId,
        e.Name
    FROM dbo.Entity AS e
    WHERE e.Status = 1
)
SELECT
    e.EntityId,
    e.Name
FROM ActiveEntity AS e;
```

### Multiple CTEs

Separate related CTE definitions with commas.

```sql
;WITH ActiveEntity AS
(
    SELECT
        e.EntityId,
        e.Name
    FROM dbo.Entity AS e
    WHERE e.Status = 1
),
RelatedCount AS
(
    SELECT
        r.EntityId,
        COUNT(*) AS RelatedCount
    FROM dbo.RelatedEntity AS r
    GROUP BY
        r.EntityId
)
SELECT
    e.EntityId,
    e.Name,
    ISNULL(r.RelatedCount, 0) AS RelatedCount
FROM ActiveEntity AS e
LEFT JOIN RelatedCount AS r
    ON r.EntityId = e.EntityId;
```

### Recursive CTE

Combine anchor and recursive members for hierarchy traversal. Production recursion needs a termination and depth policy.

```sql
;WITH EntityTree AS
(
    SELECT
        e.EntityId,
        e.ParentEntityId,
        e.Name,
        0 AS [Level]
    FROM dbo.HierarchicalEntity AS e
    WHERE e.ParentEntityId IS NULL

    UNION ALL

    SELECT
        e.EntityId,
        e.ParentEntityId,
        e.Name,
        p.[Level] + 1
    FROM dbo.HierarchicalEntity AS e
    INNER JOIN EntityTree AS p
        ON p.EntityId = e.ParentEntityId
)
SELECT
    EntityId,
    ParentEntityId,
    Name,
    [Level]
FROM EntityTree;
```

### Subquery

Use a subquery for membership. Prefer `EXISTS` when only existence matters.

```sql
SELECT
    e.EntityId,
    e.Name
FROM dbo.Entity AS e
WHERE e.EntityId IN
(
    SELECT r.EntityId
    FROM dbo.RelatedEntity AS r
);
```

### Derived table

Name the derived relation and expose only the required columns.

```sql
SELECT
    x.EntityId,
    x.RelatedCount
FROM
(
    SELECT
        r.EntityId,
        COUNT(*) AS RelatedCount
    FROM dbo.RelatedEntity AS r
    GROUP BY
        r.EntityId
) AS x
WHERE x.RelatedCount >= 3;
```

### Set operators

`UNION` removes duplicates, `UNION ALL` preserves them, `INTERSECT` returns common rows and `EXCEPT` subtracts rows. Avoid duplicate elimination when it is not required.

```sql
SELECT EntityId
FROM dbo.SourceEntity

UNION

SELECT EntityId
FROM dbo.TargetEntity;
```

```sql
SELECT EntityId
FROM dbo.SourceEntity

UNION ALL

SELECT EntityId
FROM dbo.TargetEntity;
```

```sql
SELECT EntityId
FROM dbo.SourceEntity

INTERSECT

SELECT EntityId
FROM dbo.TargetEntity;
```

```sql
SELECT EntityId
FROM dbo.SourceEntity

EXCEPT

SELECT EntityId
FROM dbo.TargetEntity;
```

### Ordering

Add a unique tie-breaker when values can tie. Physical row order is not a result guarantee.

```sql
SELECT
    e.EntityId,
    e.Name
FROM dbo.Entity AS e
ORDER BY
    e.CreatedAt DESC,
    e.EntityId DESC;
```

### Pagination

Validate page arguments. Consider keyset pagination for deep pages instead of large offsets.

```sql
DECLARE @Page INT = 1;
DECLARE @PageSize INT = 20;

SELECT
    e.EntityId,
    e.Name
FROM dbo.Entity AS e
ORDER BY
    e.EntityId
OFFSET (@Page - 1) * @PageSize ROWS
FETCH NEXT @PageSize ROWS ONLY;
```

### Latest row per group

Use a deterministic order within each partition.

```sql
;WITH RankedEntity AS
(
    SELECT
        r.RelatedEntityId,
        r.EntityId,
        r.CreatedAt,
        ROW_NUMBER() OVER
        (
            PARTITION BY r.EntityId
            ORDER BY
                r.CreatedAt DESC,
                r.RelatedEntityId DESC
        ) AS RowNo
    FROM dbo.RelatedEntity AS r
)
SELECT
    r.RelatedEntityId,
    r.EntityId,
    r.CreatedAt
FROM RankedEntity AS r
WHERE r.RowNo = 1;
```

### Ranking

`RANK` leaves gaps after ties. `DENSE_RANK` does not.

```sql
SELECT
    e.EntityId,
    e.Score,
    RANK() OVER
    (
        ORDER BY e.Score DESC
    ) AS Ranking
FROM dbo.Entity AS e;
```

```sql
DENSE_RANK()
```

### Previous and next values

`LAG` and `LEAD` read adjacent values in the declared order.

```sql
SELECT
    e.EntityId,
    e.Amount,
    LAG(e.Amount) OVER
    (
        ORDER BY e.EntityId
    ) AS PreviousAmount
FROM dbo.Entity AS e;
```

```sql
LEAD(e.Amount) OVER
(
    ORDER BY e.EntityId
)
```

## Data modification

### Insert

Specify target columns.

```sql
INSERT INTO dbo.Entity
(
    Code,
    Name,
    Status
)
VALUES
(
    @Code,
    @Name,
    @Status
);
```

### Multiple rows

List each row explicitly.

```sql
INSERT INTO dbo.Entity
(
    Code,
    Name
)
VALUES
    (N'E001', N'Value A'),
    (N'E002', N'Value B'),
    (N'E003', N'Value C');
```

### Insert from query

Keep target and source projections aligned.

```sql
INSERT INTO dbo.EntityArchive
(
    EntityId,
    Code,
    Name
)
SELECT
    e.EntityId,
    e.Code,
    e.Name
FROM dbo.Entity AS e
WHERE e.Status = 0;
```

### Inserted values

Use `OUTPUT` to return generated values.

```sql
INSERT INTO dbo.Entity
(
    Code,
    Name
)
OUTPUT
    inserted.EntityId,
    inserted.Code,
    inserted.Name
VALUES
(
    @Code,
    @Name
);
```

### Update

Alias-based updates extend naturally to joined modifications.

```sql
UPDATE e
SET
    e.Name = @Name,
    e.UpdatedAt = SYSUTCDATETIME()
FROM dbo.Entity AS e
WHERE e.EntityId = @EntityId;
```

### Joined update

Review join cardinality and the affected-row predicate.

```sql
UPDATE e
SET
    e.Status = 0
FROM dbo.Entity AS e
INNER JOIN dbo.EntityState AS s
    ON s.EntityId = e.EntityId
WHERE s.IsInactive = 1;
```

### Changed values

`deleted` supplies prior values and `inserted` supplies new values.

```sql
UPDATE e
SET
    e.Name = @Name
OUTPUT
    deleted.Name AS OldName,
    inserted.Name AS NewName
FROM dbo.Entity AS e
WHERE e.EntityId = @EntityId;
```

### Delete

Scope deletions with an explicit predicate.

```sql
DELETE e
FROM dbo.Entity AS e
WHERE e.EntityId = @EntityId;
```

### Joined delete

Name the alias whose rows are removed.

```sql
DELETE r
FROM dbo.RelatedEntity AS r
INNER JOIN dbo.Entity AS e
    ON e.EntityId = r.EntityId
WHERE e.Status = 0;
```

### Deleted values

Return removed values through `OUTPUT`.

```sql
DELETE e
OUTPUT
    deleted.EntityId,
    deleted.Code,
    deleted.Name
FROM dbo.Entity AS e
WHERE e.EntityId = @EntityId;
```

### Update then insert

This template owns the transaction but still needs a unique constraint and an appropriate isolation or locking strategy. An existence check alone does not prevent concurrent insertion races.

```sql
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE e
    SET
        e.Name = @Name,
        e.UpdatedAt = SYSUTCDATETIME()
    FROM dbo.Entity AS e
    WHERE e.Code = @Code;

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO dbo.Entity
        (
            Code,
            Name
        )
        VALUES
        (
            @Code,
            @Name
        );
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
```

## Control flow and temporary storage

### If and else

Keep branches in explicit blocks.

```sql
IF @Status = 1
BEGIN
    ...
END
ELSE
BEGIN
    ...
END;
```

### Conditional existence

Use `EXISTS` when a branch depends on related data.

```sql
IF EXISTS
(
    SELECT 1
    FROM dbo.Entity AS e
    WHERE e.EntityId = @EntityId
)
BEGIN
    ...
END;
```

### Assignment

Use `SET` for one value and `SELECT` for related query results.

```sql
SET @EntityId = 1;
```

```sql
SELECT
    @EntityId = e.EntityId,
    @Name = e.Name
FROM dbo.Entity AS e
WHERE e.Code = @Code;
```

### Iteration

Prefer set-based changes. Use loops only for sequential state.

```sql
DECLARE @Index INT = 1;

WHILE @Index <= 10
BEGIN
    PRINT @Index;

    SET @Index += 1;
END;
```

### Temporary table

Declare the shape explicitly when indexes or constraints matter.

```sql
CREATE TABLE #Entity
(
    EntityId BIGINT NOT NULL,
    Name NVARCHAR(100) NOT NULL
);

INSERT INTO #Entity
(
    EntityId,
    Name
)
SELECT
    e.EntityId,
    e.Name
FROM dbo.Entity AS e;

SELECT
    EntityId,
    Name
FROM #Entity;

DROP TABLE IF EXISTS #Entity;
```

### Select into temporary table

Add indexes after population when appropriate.

```sql
SELECT
    e.EntityId,
    e.Name
INTO #Entity
FROM dbo.Entity AS e
WHERE e.Status = 1;
```

```sql
CREATE INDEX IX_Entity_EntityId
ON #Entity(EntityId);
```

### Table variable

Choose table variables or temporary tables using execution plans, statistics, indexing, reuse, volume and SQL Server version.

```sql
DECLARE @Entity TABLE
(
    EntityId BIGINT NOT NULL,
    Name NVARCHAR(100) NOT NULL
);

INSERT INTO @Entity
(
    EntityId,
    Name
)
SELECT
    e.EntityId,
    e.Name
FROM dbo.Entity AS e;
```

## Transactions and errors

The write-procedure template above shows transaction ownership with `XACT_ABORT`, `TRY`/`CATCH`, rollback and `THROW`. Keep only the atomic database unit inside that transaction. Keep user interaction, network calls and unrelated reports outside it.

SQL Server nested transactions are not independently rollbackable. A plain rollback can abort the caller's transaction, so reusable procedures need an explicit ownership policy.

### Catch and preserve errors

Use `THROW` to preserve the original error. Capture diagnostics only when needed.

```sql
BEGIN TRY
    ...
END TRY
BEGIN CATCH
    THROW;
END CATCH;
```

```sql
BEGIN CATCH
    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine,
        ERROR_MESSAGE() AS ErrorMessage;

    THROW;
END CATCH;
```

### Custom error

Use an application error number and a specific validation message.

```sql
IF @EntityId IS NULL
BEGIN
    THROW 50001, 'EntityId is required.', 1;
END;
```

### Transaction state

`XACT_STATE()` is 1 for committable, -1 for uncommittable and 0 for no active transaction. An owner whose policy aborts on any failure rolls back both active states.

```sql
IF XACT_STATE() <> 0
BEGIN
    ROLLBACK TRANSACTION;
END;
```

## Dynamic SQL

### Values

Pass values to `sys.sp_executesql`. Do not concatenate user data or quoted value strings.

```sql
DECLARE @Sql NVARCHAR(MAX);

SET @Sql = N'
    SELECT
        e.EntityId,
        e.Name
    FROM dbo.Entity AS e
    WHERE e.Name = @Name;
';

EXEC sys.sp_executesql
    @Sql,
    N'@Name NVARCHAR(100)',
    @Name = @Name;
```

### Identifiers

Identifiers cannot be parameters. Validate them against an allowlist before `QUOTENAME`. Quoting alone grants no authorization. Reject missing identifiers as part of input validation.

```sql
IF @SortColumn IS NULL OR @SortColumn NOT IN
(
    N'EntityId',
    N'Name',
    N'CreatedAt'
)
BEGIN
    THROW 50001, 'Invalid sort column.', 1;
END;
```

```sql
DECLARE @Sql NVARCHAR(MAX);

SET @Sql = N'
    SELECT
        EntityId,
        Name,
        CreatedAt
    FROM dbo.Entity
    ORDER BY ' + QUOTENAME(@SortColumn) + N';
';

EXEC sys.sp_executesql @Sql;
```

## Expressions

### Null tests

Use `IS NULL` or `IS NOT NULL`, never equality with null.

```sql
WHERE e.OptionalValue IS NULL
```

```sql
WHERE e.OptionalValue IS NOT NULL
```

### Fallback values

`ISNULL` and `COALESCE` have different type and nullability rules. Choose one deliberately.

```sql
SELECT
    ISNULL(e.Name, N'') AS Name
FROM dbo.Entity AS e;
```

```sql
SELECT
    COALESCE(
        e.PrimaryValue,
        e.SecondaryValue,
        N''
    )
FROM dbo.Entity AS e;
```

### Zero denominator

`NULLIF` can convert a zero denominator to null.

```sql
SELECT
    TotalAmount / NULLIF(ItemCount, 0)
FROM dbo.EntityStatistics;
```

### Conversion

Use `CAST` for general conversion. Use `CONVERT` when a SQL Server style code is necessary.

```sql
CAST(@Value AS INT)
```

```sql
CONVERT(VARCHAR(10), @Date, 23)
```

### Tolerant conversion

`TRY_CAST` returns null for an invalid permitted conversion.

```sql
SELECT TRY_CAST(Value AS INT);
```

### Nullable concatenation

`CONCAT` handles null values without propagating them through `+`.

```sql
SELECT
    CONCAT(
        e.Prefix,
        N' ',
        e.Name
    )
FROM dbo.Entity AS e;
```

## Permissions and object lifecycle

### Grant

Give application accounts only the object or schema permissions they require.

```sql
GRANT EXECUTE
ON OBJECT::dbo.CreateEntity
TO ApplicationUser;
```

```sql
GRANT SELECT
ON OBJECT::dbo.Entity
TO ApplicationUser;
```

```sql
GRANT EXECUTE
ON SCHEMA::dbo
TO ApplicationUser;
```

### Revoke and deny

`REVOKE` removes a grant. `DENY` explicitly blocks permission through many resolution paths.

```sql
REVOKE SELECT
ON OBJECT::dbo.Entity
FROM ApplicationUser;
```

```sql
DENY DELETE
ON OBJECT::dbo.Entity
TO ApplicationUser;
```

### Trigger

Handle multirow `inserted` and `deleted` sets. Prefer explicit application logic when a trigger would obscure behavior.

```sql
CREATE OR ALTER TRIGGER dbo.TR_Entity_Update
ON dbo.Entity
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.EntityAudit
    (
        EntityId,
        OldName,
        NewName,
        ChangedAt
    )
    SELECT
        d.EntityId,
        d.Name,
        i.Name,
        SYSUTCDATETIME()
    FROM deleted AS d
    INNER JOIN inserted AS i
        ON i.EntityId = d.EntityId
    WHERE ISNULL(d.Name, N'') <> ISNULL(i.Name, N'');
END;
GO
```

### Existence checks

Use object checks for legacy or migration cases. Prefer `CREATE OR ALTER` for supported programmable objects.

```sql
IF OBJECT_ID(N'dbo.Entity', N'U') IS NOT NULL
BEGIN
    ...
END;
```

```sql
IF OBJECT_ID(N'dbo.GetEntity', N'P') IS NOT NULL
BEGIN
    ...
END;
```

### Drop objects

Review dependencies and data loss before executing these operations.

```sql
DROP PROCEDURE IF EXISTS dbo.GetEntity;
DROP VIEW IF EXISTS dbo.v_Entity;
DROP FUNCTION IF EXISTS dbo.GetEntityValue;
DROP TABLE IF EXISTS dbo.Entity;
DROP SEQUENCE IF EXISTS dbo.EntitySequence;
```

### Client batches

`GO` separates batches in supporting clients such as sqlcmd and SSMS. Application APIs such as SqlCommand must split batches themselves.

```sql
CREATE OR ALTER VIEW dbo.v_Entity
AS
    SELECT
        e.EntityId,
        e.Name
    FROM dbo.Entity AS e;
GO

CREATE OR ALTER PROCEDURE dbo.GetEntity
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.EntityId,
        e.Name
    FROM dbo.v_Entity AS e;
END;
GO
```
