<!-- markdownlint-disable MD013 -->

# T-SQL Conventions and Templates

A practical set of conventions and reusable templates for Microsoft SQL Server / T-SQL projects.

The goal is to keep database objects, queries, migrations, stored procedures, and application-facing SQL consistent, readable, and predictable.

---

## 1. General Principles

Use the following conventions across the project:

```text
- Always specify the schema explicitly.
- Always specify column names explicitly.
- Prefer ANSI JOIN syntax.
- Terminate statements with semicolons.
- Use CREATE OR ALTER for supported programmable objects.
- Use SET NOCOUNT ON in stored procedures and triggers.
- Use SET XACT_ABORT ON when a stored procedure owns a transaction.
- Use TRY...CATCH + THROW for error propagation.
- Prefer THROW over RAISERROR for new code.
- Prefer set-based operations over loops.
- Parameterize dynamic SQL with sys.sp_executesql.
- Whitelist dynamic identifiers and wrap them with QUOTENAME.
- Avoid SELECT * in application and production queries.
- Do not rely on implicit row ordering.
- Prefer UTC timestamps for persisted system timestamps.
- Use Unicode string literals when working with NVARCHAR/NCHAR.
```

---

## 2. Naming Conventions

### 2.1 Database Objects

Recommended naming:

```text
Schema:
    dbo
    app
    auth
    reporting

Tables:
    Entity
    RelatedEntity
    ParentEntity

Views:
    v_Entity
    v_ActiveEntity

Stored Procedures:
    GetEntity
    CreateEntity
    UpdateEntity
    DeleteEntity

Functions:
    GetEntityValue
    GetEntitiesByStatus

Triggers:
    TR_Entity_Update
    TR_Entity_Delete
```

Avoid object names that depend on temporary implementation details.

Prefer domain-oriented names.

---

### 2.2 Constraints

Use explicit constraint names.

Recommended pattern:

```text
PK_<Table>
FK_<Table>_<ReferencedTable>
UQ_<Table>_<Column>
CK_<Table>_<Column>
DF_<Table>_<Column>
```

Example:

```sql
CONSTRAINT PK_Entity
CONSTRAINT FK_RelatedEntity_Entity
CONSTRAINT UQ_Entity_Code
CONSTRAINT CK_Entity_Status
CONSTRAINT DF_Entity_Status
```

---

### 2.3 Indexes

Recommended pattern:

```text
IX_<Table>_<Columns>
UX_<Table>_<Columns>
```

Examples:

```sql
IX_Entity_Status
IX_Entity_Status_CreatedAt
UX_Entity_Code
```

Use `UX_` when the index is unique.

---

### 2.4 Parameters and Variables

Use descriptive PascalCase names prefixed with `@`.

```sql
@EntityId
@EntityCode
@Status
@StartAt
@EndAt
@Page
@PageSize
```

Prefer one declaration per line:

```sql
DECLARE @EntityId BIGINT;
DECLARE @Name NVARCHAR(100);
DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();
```

---

### 2.5 Table Aliases

Use short, meaningful aliases.

```sql
FROM dbo.Entity AS e
INNER JOIN dbo.RelatedEntity AS r
    ON r.EntityId = e.EntityId
```

Avoid arbitrary aliases such as:

```sql
FROM dbo.Entity AS a1
```

unless generated SQL makes this necessary.

---

## 3. Formatting Conventions

### 3.1 SELECT Layout

Recommended order:

```sql
SELECT
    ...
FROM ...
INNER JOIN ...
    ON ...
LEFT JOIN ...
    ON ...
WHERE ...
GROUP BY
    ...
HAVING ...
ORDER BY
    ...
OFFSET ...
FETCH ...;
```

Example:

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

---

### 3.2 Column Lists

Place one column per line for non-trivial statements.

Preferred:

```sql
SELECT
    e.EntityId,
    e.Code,
    e.Name,
    e.Status
FROM dbo.Entity AS e;
```

Avoid:

```sql
SELECT e.EntityId, e.Code, e.Name, e.Status FROM dbo.Entity e;
```

---

### 3.3 INSERT Column Lists

Always specify inserted columns.

Preferred:

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

Avoid:

```sql
INSERT INTO dbo.Entity
VALUES (...);
```

---

## 4. Recommended Data Types

### 4.1 Identifiers

Typical choices:

```text
INT
BIGINT
UNIQUEIDENTIFIER
```

For identity-based keys:

```sql
EntityId BIGINT IDENTITY(1, 1) NOT NULL
```

Choose the key type based on the domain and expected scale rather than habit.

---

### 4.2 Strings

Prefer Unicode types for application data:

```sql
NVARCHAR(100)
NVARCHAR(255)
NVARCHAR(MAX)
```

Use Unicode literals:

```sql
N'Value'
```

Avoid relying on implicit conversion between `VARCHAR` and `NVARCHAR`.

---

### 4.3 Date and Time

Prefer:

```sql
DATE
TIME
DATETIME2(3)
DATETIME2(7)
DATETIMEOFFSET
```

For system timestamps:

```sql
SYSUTCDATETIME()
```

Prefer `DATETIME2` over legacy `DATETIME` for new schema design.

---

### 4.4 Decimal Values

Use explicit precision and scale:

```sql
DECIMAL(18, 2)
DECIMAL(19, 4)
```

Do not rely on unspecified decimal precision.

---

### 4.5 Boolean-Like Values

SQL Server has no native Boolean data type for regular table columns.

Use:

```sql
BIT
```

Example:

```sql
IsActive BIT NOT NULL
```

---

## 5. CREATE DATABASE

Basic template:

```sql
CREATE DATABASE ApplicationDatabase;
GO
```

Switch database:

```sql
USE ApplicationDatabase;
GO
```

Production database files, filegroups, recovery mode, and collation should normally be handled explicitly by deployment or DBA-managed scripts.

---

## 6. CREATE SCHEMA

```sql
CREATE SCHEMA app;
GO
```

Possible organization:

```text
app.Entity
app.RelatedEntity

auth.Account
auth.Role
auth.Permission

reporting.EntitySummary
```

For smaller systems, using `dbo` consistently is also acceptable.

---

## 7. CREATE TABLE

Recommended base template:

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

---

## 8. FOREIGN KEY

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

Use cascading actions only when they accurately model domain behavior.

Example:

```sql
CONSTRAINT FK_ChildEntity_ParentEntity
    FOREIGN KEY (ParentEntityId)
    REFERENCES dbo.ParentEntity(ParentEntityId)
    ON DELETE CASCADE
```

Do not enable cascading deletes merely for convenience.

---

## 9. CHECK CONSTRAINT

```sql
CONSTRAINT CK_Entity_Status
    CHECK (Status IN (0, 1, 2))
```

Example:

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

---

## 10. COMPUTED COLUMN

```sql
CREATE TABLE dbo.LineItem
(
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18, 2) NOT NULL,

    TotalAmount AS
        (Quantity * UnitPrice) PERSISTED
);
```

---

## 11. ALTER TABLE

Add column:

```sql
ALTER TABLE dbo.Entity
ADD Notes NVARCHAR(500) NULL;
```

Alter column:

```sql
ALTER TABLE dbo.Entity
ALTER COLUMN Name NVARCHAR(200) NOT NULL;
```

Drop column:

```sql
ALTER TABLE dbo.Entity
DROP COLUMN Notes;
```

Add constraint:

```sql
ALTER TABLE dbo.Entity
ADD CONSTRAINT UQ_Entity_Name
    UNIQUE (Name);
```

Drop constraint:

```sql
ALTER TABLE dbo.Entity
DROP CONSTRAINT UQ_Entity_Name;
```

---

## 12. DROP AND TRUNCATE

Drop a table safely:

```sql
DROP TABLE IF EXISTS dbo.Entity;
```

Remove all rows:

```sql
TRUNCATE TABLE dbo.EntityLog;
```

Delete selected rows:

```sql
DELETE FROM dbo.EntityLog
WHERE CreatedAt < @ExpiredAt;
```

---

## 13. INDEXES

### 13.1 Basic Nonclustered Index

```sql
CREATE INDEX IX_Entity_Name
ON dbo.Entity(Name);
```

---

### 13.2 Composite Index

```sql
CREATE INDEX IX_Entity_Status_CreatedAt
ON dbo.Entity
(
    Status,
    CreatedAt
);
```

Index column order should be driven by actual query predicates and sorting requirements.

---

### 13.3 Included Columns

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

Use included columns when they help cover common queries without unnecessarily increasing the index key.

---

### 13.4 Unique Index

```sql
CREATE UNIQUE INDEX UX_Entity_Name
ON dbo.Entity(Name);
```

---

### 13.5 Filtered Index

```sql
CREATE INDEX IX_Entity_Active
ON dbo.Entity(Code)
WHERE Status = 1;
```

Use filtered indexes when a stable subset is queried frequently.

---

## 14. SEQUENCE

```sql
CREATE SEQUENCE dbo.EntityIdSequence
    AS BIGINT
    START WITH 1
    INCREMENT BY 1;
```

Use:

```sql
SELECT NEXT VALUE FOR dbo.EntityIdSequence;
```

---

## 15. VIEW

Prefer `CREATE OR ALTER`.

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

Usage:

```sql
SELECT
    e.EntityId,
    e.Name
FROM dbo.v_ActiveEntity AS e;
```

Do not use views merely to hide poorly structured joins.

---

## 16. READ-ONLY STORED PROCEDURE

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

---

## 17. WRITE STORED PROCEDURE

Recommended transaction template:

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

Use this template when the procedure owns the transaction.

---

## 18. STORED PROCEDURE OUTPUT PARAMETER

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

Usage:

```sql
DECLARE @EntityId BIGINT;

EXEC dbo.CreateEntity
    @Code = N'E001',
    @Name = N'Example',
    @EntityId = @EntityId OUTPUT;

SELECT @EntityId;
```

---

## 19. SCALAR FUNCTION

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

Usage:

```sql
SELECT dbo.FormatEntityName(N'Prefix', N'Value');
```

Do not create scalar functions for trivial expressions unless abstraction provides real value.

---

## 20. INLINE TABLE-VALUED FUNCTION

Prefer inline TVFs over multi-statement TVFs when possible.

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

Usage:

```sql
SELECT
    e.EntityId,
    e.Name
FROM dbo.GetEntitiesByStatus(1) AS e;
```

---

## 21. BASIC SELECT

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

Avoid:

```sql
SELECT *
FROM dbo.Entity;
```

---

## 22. DISTINCT

```sql
SELECT DISTINCT
    e.Category
FROM dbo.Entity AS e;
```

Use `DISTINCT` because duplicates are logically unwanted, not as a repair for an incorrect join.

---

## 23. TOP

```sql
SELECT TOP (10)
    e.EntityId,
    e.Name
FROM dbo.Entity AS e
ORDER BY
    e.EntityId DESC;
```

Use `ORDER BY` with `TOP` whenever the selected rows must be deterministic.

---

## 24. WHERE

Common predicates:

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

---

## 25. DATE RANGE FILTERING

Prefer half-open intervals:

```sql
WHERE e.CreatedAt >= @StartAt
    AND e.CreatedAt < @EndAt;
```

For one calendar day:

```sql
WHERE e.CreatedAt >= '2026-01-01'
    AND e.CreatedAt < '2026-01-02';
```

Avoid constructing `23:59:59.xxx` end-of-day boundaries.

---

## 26. CASE

Simple form:

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

Conditional form:

```sql
CASE
    WHEN Score >= 90 THEN N'A'
    WHEN Score >= 80 THEN N'B'
    WHEN Score >= 70 THEN N'C'
    ELSE N'F'
END
```

---

## 27. JOIN CONVENTIONS

Use ANSI JOIN syntax.

Preferred:

```sql
SELECT
    e.EntityId,
    e.Name,
    r.RelatedEntityId
FROM dbo.Entity AS e
INNER JOIN dbo.RelatedEntity AS r
    ON r.EntityId = e.EntityId;
```

Avoid legacy comma joins:

```sql
FROM dbo.Entity AS e,
     dbo.RelatedEntity AS r
WHERE r.EntityId = e.EntityId;
```

---

## 28. INNER JOIN

```sql
SELECT
    e.EntityId,
    e.Name,
    r.RelatedEntityId
FROM dbo.Entity AS e
INNER JOIN dbo.RelatedEntity AS r
    ON r.EntityId = e.EntityId;
```

---

## 29. LEFT JOIN

```sql
SELECT
    e.EntityId,
    e.Name,
    r.RelatedEntityId
FROM dbo.Entity AS e
LEFT JOIN dbo.RelatedEntity AS r
    ON r.EntityId = e.EntityId;
```

Use when rows from the left side must be preserved even if no match exists.

---

## 30. RIGHT JOIN

`RIGHT JOIN` is valid, but prefer rewriting it as `LEFT JOIN` when practical.

Instead of:

```sql
FROM dbo.Entity AS e
RIGHT JOIN dbo.RelatedEntity AS r
    ON r.EntityId = e.EntityId;
```

Prefer:

```sql
FROM dbo.RelatedEntity AS r
LEFT JOIN dbo.Entity AS e
    ON e.EntityId = r.EntityId;
```

This keeps join direction more consistent across a codebase.

---

## 31. FULL OUTER JOIN

```sql
SELECT
    a.EntityId AS LeftEntityId,
    b.EntityId AS RightEntityId
FROM dbo.SourceEntity AS a
FULL OUTER JOIN dbo.TargetEntity AS b
    ON b.EntityId = a.EntityId;
```

Useful for reconciliation and comparison queries.

---

## 32. CROSS JOIN

```sql
SELECT
    e.EntityId,
    p.PeriodId
FROM dbo.Entity AS e
CROSS JOIN dbo.Period AS p;
```

Use only when a Cartesian product is intentional.

---

## 33. CROSS APPLY

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
        r.CreatedAt DESC
) AS x;
```

Use `OUTER APPLY` when the left-side row must remain even if the applied query returns no rows.

---

## 34. EXISTS

For existence checks:

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

---

## 35. NOT EXISTS

Preferred anti-join pattern:

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

---

## 36. GROUP BY

```sql
SELECT
    r.EntityId,
    COUNT(*) AS RelatedCount
FROM dbo.RelatedEntity AS r
GROUP BY
    r.EntityId;
```

---

## 37. HAVING

```sql
SELECT
    r.EntityId,
    COUNT(*) AS RelatedCount
FROM dbo.RelatedEntity AS r
GROUP BY
    r.EntityId
HAVING COUNT(*) >= 10;
```

Conceptually:

```text
WHERE    -> filters rows
GROUP BY -> forms groups
HAVING   -> filters groups
```

---

## 38. AGGREGATE FUNCTIONS

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

---

## 39. CTE

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

If all preceding statements are already terminated with semicolons, the leading semicolon is not required.

---

## 40. MULTIPLE CTEs

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

---

## 41. RECURSIVE CTE

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

---

## 42. SUBQUERY

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

Prefer `EXISTS` when the actual requirement is only existence testing.

---

## 43. DERIVED TABLE

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

---

## 44. SET OPERATORS

## UNION

Removes duplicates:

```sql
SELECT EntityId
FROM dbo.SourceEntity

UNION

SELECT EntityId
FROM dbo.TargetEntity;
```

---

## UNION ALL

Preserves duplicates:

```sql
SELECT EntityId
FROM dbo.SourceEntity

UNION ALL

SELECT EntityId
FROM dbo.TargetEntity;
```

Prefer `UNION ALL` unless duplicate elimination is part of the requirement.

---

## INTERSECT

```sql
SELECT EntityId
FROM dbo.SourceEntity

INTERSECT

SELECT EntityId
FROM dbo.TargetEntity;
```

---

## EXCEPT

```sql
SELECT EntityId
FROM dbo.SourceEntity

EXCEPT

SELECT EntityId
FROM dbo.TargetEntity;
```

Useful for data reconciliation and migration validation.

---

## 45. ORDER BY

```sql
SELECT
    e.EntityId,
    e.Name
FROM dbo.Entity AS e
ORDER BY
    e.CreatedAt DESC,
    e.EntityId DESC;
```

Never assume row order without `ORDER BY`.

---

## 46. PAGINATION

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

For large datasets and deep pages, consider keyset pagination instead of large `OFFSET` values.

---

## 47. ROW_NUMBER

```sql
SELECT
    ROW_NUMBER() OVER
    (
        ORDER BY e.EntityId
    ) AS RowNo,
    e.EntityId,
    e.Name
FROM dbo.Entity AS e;
```

---

## 48. ROW_NUMBER WITH PARTITION

Common latest-row-per-group pattern:

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
            ORDER BY r.CreatedAt DESC
        ) AS RowNo
    FROM dbo.RelatedEntity AS r
)
SELECT
    RelatedEntityId,
    EntityId,
    CreatedAt
FROM RankedEntity
WHERE RowNo = 1;
```

---

## 49. RANK AND DENSE_RANK

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

Use:

```sql
DENSE_RANK()
```

when gaps between ranking numbers are not desired.

---

## 50. LAG AND LEAD

Previous value:

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

Next value:

```sql
LEAD(e.Amount) OVER
(
    ORDER BY e.EntityId
)
```

Useful for trend, temporal, and sequential comparisons.

---

## 51. INSERT

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

Always specify target columns.

---

## 52. MULTI-ROW INSERT

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

---

## 53. INSERT SELECT

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

---

## 54. INSERT OUTPUT

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

Prefer `OUTPUT` when the application needs inserted identifiers or generated values immediately.

---

## 55. UPDATE

```sql
UPDATE e
SET
    e.Name = @Name,
    e.UpdatedAt = SYSUTCDATETIME()
FROM dbo.Entity AS e
WHERE e.EntityId = @EntityId;
```

For non-trivial updates, this alias-based form keeps syntax consistent with joined updates.

---

## 56. UPDATE WITH JOIN

```sql
UPDATE e
SET
    e.Status = 0
FROM dbo.Entity AS e
INNER JOIN dbo.EntityState AS s
    ON s.EntityId = e.EntityId
WHERE s.IsInactive = 1;
```

---

## 57. UPDATE OUTPUT

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

---

## 58. DELETE

```sql
DELETE e
FROM dbo.Entity AS e
WHERE e.EntityId = @EntityId;
```

---

## 59. DELETE WITH JOIN

```sql
DELETE r
FROM dbo.RelatedEntity AS r
INNER JOIN dbo.Entity AS e
    ON e.EntityId = r.EntityId
WHERE e.Status = 0;
```

---

## 60. DELETE OUTPUT

```sql
DELETE e
OUTPUT
    deleted.EntityId,
    deleted.Code,
    deleted.Name
FROM dbo.Entity AS e
WHERE e.EntityId = @EntityId;
```

---

## 61. UPSERT

For ordinary application CRUD, prefer an explicit transaction instead of defaulting to `MERGE`.

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

Concurrency-sensitive upserts must also rely on proper uniqueness constraints and an appropriate isolation/locking strategy.

Do not assume `IF EXISTS` alone makes an upsert race-free.

---

## 62. IF / ELSE

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

---

## 63. IF EXISTS

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

---

## 64. SET

```sql
SET @EntityId = 1;
```

Assigning multiple variables from a query:

```sql
SELECT
    @EntityId = e.EntityId,
    @Name = e.Name
FROM dbo.Entity AS e
WHERE e.Code = @Code;
```

---

## 65. WHILE

```sql
DECLARE @Index INT = 1;

WHILE @Index <= 10
BEGIN
    PRINT @Index;

    SET @Index += 1;
END;
```

Prefer set-based operations whenever practical.

Use loops only when iteration is genuinely required.

---

## 66. TEMP TABLE

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

---

## 67. SELECT INTO TEMP TABLE

```sql
SELECT
    e.EntityId,
    e.Name
INTO #Entity
FROM dbo.Entity AS e
WHERE e.Status = 1;
```

Indexes may be added afterward:

```sql
CREATE INDEX IX_Entity_EntityId
ON #Entity(EntityId);
```

---

## 68. TABLE VARIABLE

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

Do not rely on a simplistic rule such as:

```text
small data -> table variable
large data -> temp table
```

Choose based on query plans, statistics, indexing requirements, data volume, reuse, and SQL Server version.

---

## 69. TRANSACTION

Basic transaction:

```sql
BEGIN TRANSACTION;

...

COMMIT TRANSACTION;
```

Rollback:

```sql
ROLLBACK TRANSACTION;
```

Recommended transaction handling:

```sql
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    ...

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

---

## 70. TRY...CATCH

Without a transaction:

```sql
BEGIN TRY
    ...
END TRY
BEGIN CATCH
    THROW;
END CATCH;
```

Capture diagnostic information only when needed:

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

---

## 71. THROW

Custom error:

```sql
IF @EntityId IS NULL
BEGIN
    THROW 50001, 'EntityId is required.', 1;
END;
```

Rethrow the original error:

```sql
BEGIN CATCH
    THROW;
END CATCH;
```

Prefer `THROW` over `RAISERROR` in new code.

---

## 72. XACT_STATE

Use:

```sql
IF XACT_STATE() <> 0
BEGIN
    ROLLBACK TRANSACTION;
END;
```

Interpretation:

```text
XACT_STATE() =  1
    An active transaction exists and can be committed.

XACT_STATE() = -1
    An active transaction exists but cannot be committed.

XACT_STATE() =  0
    No active transaction exists.
```

When the procedure's error policy is "any failure aborts the unit of work", rolling back for both `1` and `-1` is appropriate.

---

## 73. NESTED TRANSACTION CONSIDERATIONS

SQL Server nested transactions are not independent transactions.

A plain:

```sql
ROLLBACK TRANSACTION;
```

can roll back the outer transaction as well.

Therefore, distinguish between:

```text
Procedure owns transaction
Procedure participates in caller-owned transaction
```

When reusable procedures may execute inside an existing transaction, design transaction ownership explicitly.

Do not assume each `BEGIN TRANSACTION` creates an independently rollbackable nested transaction.

---

## 74. DYNAMIC SQL

Avoid string-concatenating values directly.

Avoid:

```sql
DECLARE @Sql NVARCHAR(MAX);

SET @Sql =
    N'SELECT *
      FROM dbo.Entity
      WHERE Name = ''' + @Name + N'''';

EXEC (@Sql);
```

Preferred:

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

Rules:

```text
Values      -> parameters
Identifiers -> whitelist + QUOTENAME
```

---

## 75. DYNAMIC IDENTIFIERS

Column and table names cannot be parameterized like values.

Use a whitelist:

```sql
IF @SortColumn NOT IN
(
    N'EntityId',
    N'Name',
    N'CreatedAt'
)
BEGIN
    THROW 50001, 'Invalid sort column.', 1;
END;
```

Then:

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

Never treat `QUOTENAME` alone as authorization.

Whitelist first.

---

## 76. NULL

Incorrect:

```sql
WHERE e.OptionalValue = NULL
```

Correct:

```sql
WHERE e.OptionalValue IS NULL
```

or:

```sql
WHERE e.OptionalValue IS NOT NULL
```

---

## 77. ISNULL AND COALESCE

SQL Server-specific two-value replacement:

```sql
SELECT
    ISNULL(e.Name, N'') AS Name
FROM dbo.Entity AS e;
```

Multiple fallback values:

```sql
SELECT
    COALESCE(
        e.PrimaryValue,
        e.SecondaryValue,
        N''
    )
FROM dbo.Entity AS e;
```

Be aware that `ISNULL` and `COALESCE` can differ in type resolution and nullability semantics.

---

## 78. NULLIF

Useful for avoiding division by zero:

```sql
SELECT
    TotalAmount / NULLIF(ItemCount, 0)
FROM dbo.EntityStatistics;
```

---

## 79. CAST AND CONVERT

General type conversion:

```sql
CAST(@Value AS INT)
```

SQL Server-specific formatting/style conversion:

```sql
CONVERT(VARCHAR(10), @Date, 23)
```

Use `CAST` by default when no SQL Server-specific conversion style is required.

---

## 80. TRY_CAST AND TRY_CONVERT

Useful when processing external or untrusted data:

```sql
SELECT TRY_CAST(Value AS INT);
```

Invalid conversions return `NULL` instead of raising a conversion error.

---

## 81. STRING CONCATENATION

Preferred for nullable values:

```sql
SELECT
    CONCAT(
        e.Prefix,
        N' ',
        e.Name
    )
FROM dbo.Entity AS e;
```

This is often safer than:

```sql
e.Prefix + N' ' + e.Name
```

when nullable values are involved.

---

## 82. PERMISSIONS

Grant procedure execution:

```sql
GRANT EXECUTE
ON OBJECT::dbo.CreateEntity
TO ApplicationUser;
```

Grant table read:

```sql
GRANT SELECT
ON OBJECT::dbo.Entity
TO ApplicationUser;
```

Grant schema execution:

```sql
GRANT EXECUTE
ON SCHEMA::dbo
TO ApplicationUser;
```

Prefer least privilege.

Application accounts should receive only the permissions required for their runtime responsibilities.

---

## 83. REVOKE AND DENY

Revoke:

```sql
REVOKE SELECT
ON OBJECT::dbo.Entity
FROM ApplicationUser;
```

Explicitly deny:

```sql
DENY DELETE
ON OBJECT::dbo.Entity
TO ApplicationUser;
```

Use `DENY` intentionally because it overrides granted permissions in many permission-resolution paths.

---

## 84. TRIGGER

Use set-based logic.

Do not assume `inserted` or `deleted` contains only one row.

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

Prefer explicit application logic over triggers when triggers would make behavior difficult to discover or debug.

---

## 85. OBJECT EXISTENCE CHECKS

Legacy or migration scenarios may still require explicit checks.

Table:

```sql
IF OBJECT_ID(N'dbo.Entity', N'U') IS NOT NULL
BEGIN
    ...
END;
```

Procedure:

```sql
IF OBJECT_ID(N'dbo.GetEntity', N'P') IS NOT NULL
BEGIN
    ...
END;
```

For programmable objects, prefer `CREATE OR ALTER` where supported.

---

## 86. DROP OBJECTS

```sql
DROP PROCEDURE IF EXISTS dbo.GetEntity;
DROP VIEW IF EXISTS dbo.v_Entity;
DROP FUNCTION IF EXISTS dbo.GetEntityValue;
DROP TABLE IF EXISTS dbo.Entity;
DROP SEQUENCE IF EXISTS dbo.EntitySequence;
```

---

## 87. CREATE OR ALTER CONVENTION

Prefer:

```sql
CREATE OR ALTER PROCEDURE
CREATE OR ALTER FUNCTION
CREATE OR ALTER VIEW
CREATE OR ALTER TRIGGER
```

This avoids separate create-vs-alter branching in deployment scripts.

---

## 88. GO

`GO` is a client-side batch separator, not a T-SQL statement.

Use it between object definitions when the deployment tool supports it.

Example:

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

Do not send `GO` through APIs such as `SqlCommand` as if it were a SQL Server statement.

---

## 89. NOCOUNT

Stored procedures:

```sql
SET NOCOUNT ON;
```

Triggers:

```sql
SET NOCOUNT ON;
```

This suppresses row-count informational messages such as:

```text
(1 row affected)
```

Use it by default for programmable database code unless row-count messages themselves are intentionally consumed.

---

## 90. XACT_ABORT

For procedures that own a transaction:

```sql
SET XACT_ABORT ON;
```

Recommended combination:

```sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
```

Do not add `SET XACT_ABORT OFF` at the end of a stored procedure solely to "restore" the caller's setting.

---

## 91. OUTPUT IN DML

Use `OUTPUT` when generated, changed, or deleted values are needed.

Insert:

```sql
INSERT INTO dbo.Entity
(
    Code,
    Name
)
OUTPUT
    inserted.EntityId
VALUES
(
    @Code,
    @Name
);
```

Update:

```sql
UPDATE e
SET
    e.Name = @Name
OUTPUT
    deleted.Name,
    inserted.Name
FROM dbo.Entity AS e
WHERE e.EntityId = @EntityId;
```

Delete:

```sql
DELETE e
OUTPUT
    deleted.EntityId
FROM dbo.Entity AS e
WHERE e.EntityId = @EntityId;
```

---

## 92. APPLICATION-FACING QUERY RULES

Application SQL should normally follow these rules:

```text
- Explicit schema.
- Explicit columns.
- Explicit aliases.
- Parameterized values.
- Deterministic ORDER BY when ordering matters.
- No SELECT *.
- No concatenated user input.
- No implicit date conversion assumptions.
- No reliance on physical row order.
- No legacy comma joins.
```

---

## 93. DATETIME STORAGE CONVENTION

For system-generated persisted timestamps, prefer UTC.

Example:

```sql
CreatedAt DATETIME2(3) NOT NULL
    CONSTRAINT DF_Entity_CreatedAt
    DEFAULT (SYSUTCDATETIME())
```

Convert to the user's local timezone at the application or reporting boundary unless the data model specifically requires local civil time.

---

## 94. TEMPORAL RANGE CONVENTION

Prefer:

```text
Start inclusive
End exclusive
```

Example:

```sql
WHERE e.CreatedAt >= @StartAt
    AND e.CreatedAt < @EndAt
```

This avoids precision-specific end-time calculations and composes cleanly across adjacent time ranges.

---

## 95. SET-BASED OVER ITERATIVE LOGIC

Prefer:

```sql
UPDATE e
SET
    e.Status = 0
FROM dbo.Entity AS e
WHERE e.ExpiredAt < SYSUTCDATETIME();
```

over row-by-row processing.

Use cursors or loops only when the operation fundamentally requires sequential stateful processing.

---

## 96. SELECT STAR CONVENTION

Avoid:

```sql
SELECT *
FROM dbo.Entity;
```

Prefer:

```sql
SELECT
    e.EntityId,
    e.Code,
    e.Name,
    e.Status
FROM dbo.Entity AS e;
```

Benefits include:

```text
- Stable application contracts
- Clear dependencies
- Reduced unnecessary I/O
- Safer schema evolution
- Easier code review
```

---

## 97. DISTINCT CONVENTION

Do not use `DISTINCT` as a default fix for duplicate rows caused by incorrect joins.

Incorrect reasoning:

```sql
SELECT DISTINCT ...
```

because a join unexpectedly duplicated rows.

Instead, verify:

```text
- Join cardinality
- Missing join predicates
- One-to-many relationships
- Duplicate source data
```

Use `DISTINCT` only when duplicate elimination is part of the query's intended semantics.

---

## 98. TRANSACTION SCOPE

Keep transactions as short as practical.

Avoid doing unrelated work inside a transaction:

```text
- Network calls
- User interaction
- Long-running reports
- Unnecessary read operations
- External API work
```

Transaction scope should cover only the database unit of work that requires atomicity.

---

## 99. ERROR PROPAGATION

Prefer preserving the original SQL Server error:

```sql
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
```

Avoid reconstructing the error through:

```sql
RAISERROR(ERROR_MESSAGE(), ...)
```

unless there is a specific legacy compatibility requirement.

---

## 100. CORE PROJECT TEMPLATE

A typical write procedure:

```sql
CREATE OR ALTER PROCEDURE dbo.UpdateEntity
    @EntityId BIGINT,
    @Name NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE e
        SET
            e.Name = @Name,
            e.UpdatedAt = SYSUTCDATETIME()
        FROM dbo.Entity AS e
        WHERE e.EntityId = @EntityId;

        IF @@ROWCOUNT = 0
        BEGIN
            THROW 50001, 'Entity was not found.', 1;
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
END;
GO
```

---

## 101. CORE READ QUERY TEMPLATE

```sql
SELECT
    e.EntityId,
    e.Code,
    e.Name,
    e.Status,
    e.CreatedAt
FROM dbo.Entity AS e
WHERE e.Status = @Status
    AND e.CreatedAt >= @StartAt
    AND e.CreatedAt < @EndAt
ORDER BY
    e.CreatedAt DESC,
    e.EntityId DESC;
```

---

## 102. CORE PAGED QUERY TEMPLATE

```sql
SELECT
    e.EntityId,
    e.Code,
    e.Name,
    e.CreatedAt
FROM dbo.Entity AS e
WHERE e.Status = @Status
ORDER BY
    e.EntityId
OFFSET (@Page - 1) * @PageSize ROWS
FETCH NEXT @PageSize ROWS ONLY;
```

---

## 103. CORE LATEST-ROW-PER-GROUP TEMPLATE

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

When ordering may contain ties, add a deterministic tie-breaker.

---

## 104. CORE DYNAMIC SQL TEMPLATE

```sql
DECLARE @Sql NVARCHAR(MAX);

SET @Sql = N'
    SELECT
        e.EntityId,
        e.Name
    FROM dbo.Entity AS e
    WHERE e.Status = @Status
        AND e.Name LIKE @NamePattern;
';

EXEC sys.sp_executesql
    @Sql,
    N'
        @Status TINYINT,
        @NamePattern NVARCHAR(200)
    ',
    @Status = @Status,
    @NamePattern = @NamePattern;
```

---

## 105. CORE TABLE TEMPLATE

```sql
CREATE TABLE dbo.Entity
(
    EntityId BIGINT IDENTITY(1, 1) NOT NULL,

    Code NVARCHAR(50) NOT NULL,
    Name NVARCHAR(100) NOT NULL,

    Status TINYINT NOT NULL
        CONSTRAINT DF_Entity_Status
        DEFAULT (1),

    CreatedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Entity_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    UpdatedAt DATETIME2(3) NULL,

    CONSTRAINT PK_Entity
        PRIMARY KEY CLUSTERED (EntityId),

    CONSTRAINT UQ_Entity_Code
        UNIQUE (Code)
);
```

---

## 106. CORE READ PROCEDURE TEMPLATE

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
        e.Status,
        e.CreatedAt,
        e.UpdatedAt
    FROM dbo.Entity AS e
    WHERE e.EntityId = @EntityId;
END;
GO
```

---

## 107. CORE TRANSACTION PROCEDURE TEMPLATE

```sql
CREATE OR ALTER PROCEDURE dbo.ProcessEntity
    @EntityId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Database unit of work.

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

---

## 108. CORE INLINE TVF TEMPLATE

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

---

## 109. CORE VIEW TEMPLATE

```sql
CREATE OR ALTER VIEW dbo.v_Entity
AS
    SELECT
        e.EntityId,
        e.Code,
        e.Name,
        e.Status,
        e.CreatedAt
    FROM dbo.Entity AS e;
GO
```

---

## 110. ANTI-PATTERNS

Avoid these unless there is a specific justified reason.

## Legacy comma joins

```sql
FROM dbo.Entity AS e,
     dbo.RelatedEntity AS r
WHERE r.EntityId = e.EntityId
```

Use ANSI joins instead.

---

## SELECT *

```sql
SELECT *
FROM dbo.Entity;
```

Use explicit columns.

---

## Dynamic SQL with concatenated values

```sql
SET @Sql = N'
    SELECT *
    FROM dbo.Entity
    WHERE Name = ''' + @Name + N'''
';
```

Use `sp_executesql` parameters.

---

## Comparing NULL with equality

```sql
WHERE Value = NULL
```

Use:

```sql
WHERE Value IS NULL
```

---

## Using DISTINCT to hide join errors

```sql
SELECT DISTINCT ...
```

Fix the join or source data unless distinctness is intentional.

---

## Assuming TOP is deterministic without ORDER BY

```sql
SELECT TOP (10)
    ...
FROM dbo.Entity;
```

Use an explicit `ORDER BY`.

---

## Assuming physical row order

Never rely on the apparent current row order of a table.

---

## Blind cascade deletes

Do not apply `ON DELETE CASCADE` everywhere.

---

## Long transactions

Do not hold transactions open while performing unrelated work.

---

## Rebuilding caught errors with RAISERROR

Prefer:

```sql
THROW;
```

for modern error propagation.

---

## Assuming nested transactions are independent

They are not independently rollbackable in the way many application developers initially expect.

---

## 111. PROJECT-WIDE DEFAULTS

A concise project-wide standard:

```text
Object naming
    Explicit schema.
    Consistent singular or plural table naming.
    Explicit constraint names.
    Explicit index names.

Queries
    Explicit columns.
    ANSI JOIN.
    Stable aliases.
    Parameterized predicates.
    Explicit ORDER BY.
    Half-open date ranges.

Stored procedures
    CREATE OR ALTER.
    BEGIN...END body.
    SET NOCOUNT ON.
    SET XACT_ABORT ON when owning a transaction.
    TRY...CATCH.
    XACT_STATE() rollback check.
    THROW.

Functions
    Prefer inline TVFs when table-valued abstraction is needed.
    Avoid unnecessary scalar UDFs.

Data modification
    Explicit target columns.
    OUTPUT when generated values are needed.
    Short transactions.
    Set-based operations.

Dynamic SQL
    sys.sp_executesql.
    Parameterized values.
    Whitelisted identifiers.
    QUOTENAME for identifiers.

Schema design
    Named PK/FK/UQ/CK/DF constraints.
    DATETIME2 for new timestamp columns.
    UTC for system timestamps where appropriate.
    DECIMAL with explicit precision and scale.
    NVARCHAR for Unicode application data.

Performance
    Index for actual query patterns.
    Avoid SELECT *.
    Avoid unnecessary DISTINCT.
    Review execution plans for non-trivial queries.
    Do not assume temp tables and table variables are interchangeable.
```

---

## 112. RECOMMENDED FILE ORGANIZATION

A SQL project can keep reusable templates under a structure such as:

```text
database/
├── tables/
├── views/
├── functions/
├── procedures/
├── triggers/
├── indexes/
├── migrations/
├── security/
└── templates/
```

Suggested template files:

```text
templates/
├── create-table.sql
├── create-view.sql
├── create-function.sql
├── create-procedure-read.sql
├── create-procedure-write.sql
├── create-trigger.sql
├── transaction.sql
├── pagination.sql
├── latest-row-per-group.sql
├── dynamic-sql.sql
└── temp-table.sql
```

---

## 113. FINAL BASELINE

If only a small number of rules are enforced, prioritize these:

```text
1. Explicit schema.
2. Explicit columns.
3. ANSI JOIN only.
4. Semicolon-terminated statements.
5. SET NOCOUNT ON in procedures and triggers.
6. SET XACT_ABORT ON for procedure-owned transactions.
7. TRY...CATCH + XACT_STATE() + THROW.
8. CREATE OR ALTER for programmable objects.
9. Parameterized dynamic SQL with sp_executesql.
10. Whitelist dynamic identifiers.
11. DATETIME2 + UTC for system timestamps.
12. Half-open date ranges.
13. Named constraints and indexes.
14. Set-based operations over loops.
15. Never rely on implicit row order.
16. Avoid SELECT *.
17. Avoid DISTINCT as a join repair mechanism.
18. Keep transactions short.
19. Treat nested transactions explicitly.
20. Design indexes from real access patterns.
```
