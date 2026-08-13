local ls = require("luasnip")

local parse = ls.parser.parse_snippet

local function snippet(trigger, name, body)
  return parse({
    trig = trigger,
    name = name,
    dscr = name,
  }, vim.trim(body))
end

return {
  -- Database objects and schema changes.
  snippet(
    "cdb",
    "Create database",
    [[
CREATE DATABASE ${1:ApplicationDatabase};
GO

USE $1;
GO
$0
]]
  ),

  snippet(
    "cschema",
    "Create schema",
    [[
CREATE SCHEMA ${1:app};
GO
$0
]]
  ),

  snippet(
    "ctable",
    "Create table",
    [[
CREATE TABLE ${1:dbo}.${2:Entity}
(
    ${2}Id BIGINT IDENTITY(1, 1) NOT NULL,

    Code NVARCHAR(50) NOT NULL,
    Name NVARCHAR(100) NOT NULL,

    Status TINYINT NOT NULL
        CONSTRAINT DF_${2}_Status
        DEFAULT (1),

    CreatedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_${2}_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    UpdatedAt DATETIME2(3) NULL,

    CONSTRAINT PK_$2
        PRIMARY KEY CLUSTERED (${2}Id),

    CONSTRAINT UQ_${2}_Code
        UNIQUE (Code)
);
$0
]]
  ),

  snippet(
    "ctablefk",
    "Create table with foreign key",
    [[
CREATE TABLE ${1:dbo}.${2:RelatedEntity}
(
    ${2}Id BIGINT IDENTITY(1, 1) NOT NULL,
    ${3:Entity}Id BIGINT NOT NULL,

    CreatedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_${2}_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_$2
        PRIMARY KEY (${2}Id),

    CONSTRAINT FK_${2}_$3
        FOREIGN KEY (${3}Id)
        REFERENCES ${4:dbo}.${3}(${3}Id)
);
$0
]]
  ),

  snippet(
    "altaddcol",
    "Alter table add column",
    [[
ALTER TABLE ${1:dbo}.${2:Entity}
ADD ${3:Notes} ${4:NVARCHAR(500)} ${5:NULL};
$0
]]
  ),

  snippet(
    "altcol",
    "Alter table alter column",
    [[
ALTER TABLE ${1:dbo}.${2:Entity}
ALTER COLUMN ${3:Name} ${4:NVARCHAR(200)} ${5:NOT NULL};
$0
]]
  ),

  snippet(
    "altdropcol",
    "Alter table drop column",
    [[
ALTER TABLE ${1:dbo}.${2:Entity}
DROP COLUMN ${3:Notes};
$0
]]
  ),

  snippet(
    "altaddcon",
    "Alter table add constraint",
    [[
ALTER TABLE ${1:dbo}.${2:Entity}
ADD CONSTRAINT ${3:UQ_Entity_Name}
    ${4:UNIQUE (Name)};
$0
]]
  ),

  snippet(
    "altdropcon",
    "Alter table drop constraint",
    [[
ALTER TABLE ${1:dbo}.${2:Entity}
DROP CONSTRAINT ${3:UQ_Entity_Name};
$0
]]
  ),

  snippet(
    "droptable",
    "Drop table if it exists",
    [[
DROP TABLE IF EXISTS ${1:dbo}.${2:Entity};
$0
]]
  ),

  snippet(
    "truncate",
    "Truncate table",
    [[
TRUNCATE TABLE ${1:dbo}.${2:EntityLog};
$0
]]
  ),

  -- Indexes and sequences.
  snippet(
    "idx",
    "Create nonclustered index",
    [[
CREATE INDEX IX_${1:Entity}_${2:Name}
ON ${3:dbo}.$1($2);
$0
]]
  ),

  snippet(
    "idxcomp",
    "Create composite index",
    [[
CREATE INDEX IX_${1:Entity}_${2:Status}_${3:CreatedAt}
ON ${4:dbo}.$1
(
    $2,
    $3
);
$0
]]
  ),

  snippet(
    "idxinc",
    "Create index with included columns",
    [[
CREATE INDEX IX_${1:Entity}_${2:Status}
ON ${3:dbo}.$1($2)
INCLUDE
(
    ${4:Code},
    ${5:Name},
    ${6:CreatedAt}
);
$0
]]
  ),

  snippet(
    "idxuniq",
    "Create unique index",
    [[
CREATE UNIQUE INDEX UX_${1:Entity}_${2:Code}
ON ${3:dbo}.$1($2);
$0
]]
  ),

  snippet(
    "idxfilter",
    "Create filtered index",
    [[
CREATE INDEX IX_${1:Entity}_${2:Active}
ON ${3:dbo}.$1(${4:Code})
WHERE ${5:Status = 1};
$0
]]
  ),

  snippet(
    "cseq",
    "Create sequence",
    [[
CREATE SEQUENCE ${1:dbo}.${2:EntityIdSequence}
    AS ${3:BIGINT}
    START WITH ${4:1}
    INCREMENT BY ${5:1};
$0
]]
  ),

  -- Programmable objects.
  snippet(
    "cview",
    "Create or alter view",
    [[
CREATE OR ALTER VIEW ${1:dbo}.${2:v_Entity}
AS
    SELECT
        ${3:e.EntityId},
        ${4:e.Code},
        ${5:e.Name},
        ${6:e.CreatedAt}
    FROM ${7:dbo}.${8:Entity} AS ${9:e}
    WHERE ${10:e.Status = 1};
GO
$0
]]
  ),

  snippet(
    "cprocr",
    "Create read-only stored procedure",
    [[
CREATE OR ALTER PROCEDURE ${1:dbo}.${2:GetEntity}
    ${3:@EntityId BIGINT}
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ${4:e.EntityId},
        ${5:e.Code},
        ${6:e.Name},
        ${7:e.Status}
    FROM ${8:dbo}.${9:Entity} AS ${10:e}
    WHERE ${11:e.EntityId = @EntityId};
END;
GO
$0
]]
  ),

  snippet(
    "cprocw",
    "Create transactional stored procedure",
    [[
CREATE OR ALTER PROCEDURE ${1:dbo}.${2:ProcessEntity}
    ${3:@EntityId BIGINT}
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        ${4:-- Database unit of work.}

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
$0
]]
  ),

  snippet(
    "cproco",
    "Create stored procedure with output parameter",
    [[
CREATE OR ALTER PROCEDURE ${1:dbo}.${2:CreateEntity}
    ${3:@Code NVARCHAR(50)},
    ${4:@Name NVARCHAR(100)},
    ${5:@EntityId BIGINT OUTPUT}
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    INSERT INTO ${6:dbo}.${7:Entity}
    (
        ${8:Code},
        ${9:Name}
    )
    VALUES
    (
        ${10:@Code},
        ${11:@Name}
    );

    SET ${12:@EntityId} = CONVERT(BIGINT, SCOPE_IDENTITY());
END;
GO
$0
]]
  ),

  snippet(
    "cfunc",
    "Create scalar function",
    [[
CREATE OR ALTER FUNCTION ${1:dbo}.${2:FormatEntityName}
(
    ${3:@Prefix NVARCHAR(50)},
    ${4:@Name NVARCHAR(100)}
)
RETURNS ${5:NVARCHAR(151)}
AS
BEGIN
    RETURN ${6:CONCAT(@Prefix, N' ', @Name)};
END;
GO
$0
]]
  ),

  snippet(
    "citvf",
    "Create inline table-valued function",
    [[
CREATE OR ALTER FUNCTION ${1:dbo}.${2:GetEntitiesByStatus}
(
    ${3:@Status TINYINT}
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        ${4:e.EntityId},
        ${5:e.Code},
        ${6:e.Name},
        ${7:e.CreatedAt}
    FROM ${8:dbo}.${9:Entity} AS ${10:e}
    WHERE ${11:e.Status = @Status}
);
GO
$0
]]
  ),

  snippet(
    "ctrig",
    "Create or alter set-based trigger",
    [[
CREATE OR ALTER TRIGGER ${1:dbo}.${2:TR_Entity_Update}
ON ${3:dbo}.${4:Entity}
AFTER ${5:UPDATE}
AS
BEGIN
    SET NOCOUNT ON;

    ${6:-- Handle all rows in inserted and deleted with set-based logic.}
END;
GO
$0
]]
  ),

  -- Queries, joins, common table expressions, and window functions.
  snippet(
    "sel",
    "Select explicit columns",
    [[
SELECT
    ${1:e.EntityId},
    ${2:e.Code},
    ${3:e.Name}
FROM ${4:dbo}.${5:Entity} AS ${6:e}
WHERE ${7:e.EntityId = @EntityId}
ORDER BY
    ${8:e.EntityId};
$0
]]
  ),

  snippet(
    "seld",
    "Select distinct values",
    [[
SELECT DISTINCT
    ${1:e.Category}
FROM ${2:dbo}.${3:Entity} AS ${4:e};
$0
]]
  ),

  snippet(
    "seltop",
    "Select deterministic top rows",
    [[
SELECT TOP (${1:10})
    ${2:e.EntityId},
    ${3:e.Name}
FROM ${4:dbo}.${5:Entity} AS ${6:e}
ORDER BY
    ${7:e.EntityId DESC};
$0
]]
  ),

  snippet(
    "selpage",
    "Select with offset pagination",
    [[
DECLARE @Page INT = ${1:1};
DECLARE @PageSize INT = ${2:20};

SELECT
    ${3:e.EntityId},
    ${4:e.Name}
FROM ${5:dbo}.${6:Entity} AS ${7:e}
WHERE ${8:e.Status = @Status}
ORDER BY
    ${9:e.EntityId}
OFFSET (@Page - 1) * @PageSize ROWS
FETCH NEXT @PageSize ROWS ONLY;
$0
]]
  ),

  snippet(
    "drange",
    "Half-open date range predicate",
    [[
WHERE ${1:e.CreatedAt} >= ${2:@StartAt}
    AND $1 < ${3:@EndAt}$0
]]
  ),

  snippet(
    "case",
    "Searched case expression",
    [[
CASE
    WHEN ${1:Score >= 90} THEN ${2:N'A'}
    WHEN ${3:Score >= 80} THEN ${4:N'B'}
    ELSE ${5:N'F'}
END$0
]]
  ),

  snippet(
    "ijoin",
    "Inner join",
    [[
INNER JOIN ${1:dbo}.${2:RelatedEntity} AS ${3:r}
    ON ${4:r.EntityId = e.EntityId}$0
]]
  ),

  snippet(
    "ljoin",
    "Left join",
    [[
LEFT JOIN ${1:dbo}.${2:RelatedEntity} AS ${3:r}
    ON ${4:r.EntityId = e.EntityId}$0
]]
  ),

  snippet(
    "fjoin",
    "Full outer join",
    [[
FULL OUTER JOIN ${1:dbo}.${2:TargetEntity} AS ${3:t}
    ON ${4:t.EntityId = s.EntityId}$0
]]
  ),

  snippet(
    "xjoin",
    "Cross join",
    [[
CROSS JOIN ${1:dbo}.${2:Period} AS ${3:p}$0
]]
  ),

  snippet(
    "xapply",
    "Cross apply latest related row",
    [[
CROSS APPLY
(
    SELECT TOP (1)
        ${1:r.RelatedEntityId}
    FROM ${2:dbo}.${3:RelatedEntity} AS ${4:r}
    WHERE ${5:r.EntityId = e.EntityId}
    ORDER BY
        ${6:r.CreatedAt DESC},
        ${7:r.RelatedEntityId DESC}
) AS ${8:x}$0
]]
  ),

  snippet(
    "exists",
    "Where exists",
    [[
WHERE EXISTS
(
    SELECT 1
    FROM ${1:dbo}.${2:RelatedEntity} AS ${3:r}
    WHERE ${4:r.EntityId = e.EntityId}
)$0
]]
  ),

  snippet(
    "nexists",
    "Where not exists",
    [[
WHERE NOT EXISTS
(
    SELECT 1
    FROM ${1:dbo}.${2:RelatedEntity} AS ${3:r}
    WHERE ${4:r.EntityId = e.EntityId}
)$0
]]
  ),

  snippet(
    "groupby",
    "Grouped aggregate query",
    [[
SELECT
    ${1:r.EntityId},
    ${2:COUNT(*) AS RelatedCount}
FROM ${3:dbo}.${4:RelatedEntity} AS ${5:r}
WHERE ${6:r.Status = @Status}
GROUP BY
    ${7:r.EntityId}
HAVING ${8:COUNT(*) >= 1}
ORDER BY
    ${9:RelatedCount DESC};
$0
]]
  ),

  snippet(
    "cte",
    "Common table expression",
    [[
;WITH ${1:ActiveEntity} AS
(
    SELECT
        ${2:e.EntityId},
        ${3:e.Name}
    FROM ${4:dbo}.${5:Entity} AS ${6:e}
    WHERE ${7:e.Status = 1}
)
SELECT
    ${8:e.EntityId},
    ${9:e.Name}
FROM $1 AS ${10:e};
$0
]]
  ),

  snippet(
    "mcte",
    "Multiple common table expressions",
    [[
;WITH ${1:ActiveEntity} AS
(
    SELECT
        ${2:e.EntityId},
        ${3:e.Name}
    FROM ${4:dbo}.${5:Entity} AS ${6:e}
    WHERE ${7:e.Status = 1}
),
${8:RelatedCount} AS
(
    SELECT
        ${9:r.EntityId},
        ${10:COUNT(*) AS RelatedCount}
    FROM ${11:dbo}.${12:RelatedEntity} AS ${13:r}
    GROUP BY
        ${14:r.EntityId}
)
SELECT
    ${15:e.EntityId},
    ${16:e.Name},
    ${17:ISNULL(r.RelatedCount, 0) AS RelatedCount}
FROM $1 AS ${18:e}
LEFT JOIN $8 AS ${19:r}
    ON ${20:r.EntityId = e.EntityId};
$0
]]
  ),

  snippet(
    "rcte",
    "Recursive common table expression",
    [[
;WITH ${1:EntityTree} AS
(
    SELECT
        ${2:e.EntityId},
        ${3:e.ParentEntityId},
        ${4:e.Name},
        0 AS [Level]
    FROM ${5:dbo}.${6:HierarchicalEntity} AS ${7:e}
    WHERE ${8:e.ParentEntityId IS NULL}

    UNION ALL

    SELECT
        ${9:e.EntityId},
        ${10:e.ParentEntityId},
        ${11:e.Name},
        p.[Level] + 1
    FROM ${12:dbo}.${13:HierarchicalEntity} AS ${14:e}
    INNER JOIN $1 AS ${15:p}
        ON ${16:p.EntityId = e.ParentEntityId}
)
SELECT
    ${17:EntityId},
    ${18:ParentEntityId},
    ${19:Name},
    ${20:[Level]}
FROM $1;
$0
]]
  ),

  snippet(
    "subq",
    "Subquery predicate",
    [[
WHERE ${1:e.EntityId} IN
(
    SELECT ${2:r.EntityId}
    FROM ${3:dbo}.${4:RelatedEntity} AS ${5:r}
    WHERE ${6:r.Status = @Status}
)$0
]]
  ),

  snippet(
    "derived",
    "Derived table",
    [[
SELECT
    ${1:x.EntityId},
    ${2:x.RelatedCount}
FROM
(
    SELECT
        ${3:r.EntityId},
        ${4:COUNT(*) AS RelatedCount}
    FROM ${5:dbo}.${6:RelatedEntity} AS ${7:r}
    GROUP BY
        ${8:r.EntityId}
) AS ${9:x}
WHERE ${10:x.RelatedCount >= 3};
$0
]]
  ),

  snippet(
    "union",
    "Union queries",
    [[
SELECT
    ${1:s.EntityId}
FROM ${2:dbo}.${3:SourceEntity} AS ${4:s}

UNION

SELECT
    ${5:t.EntityId}
FROM ${6:dbo}.${7:TargetEntity} AS ${8:t};
$0
]]
  ),

  snippet(
    "unionall",
    "Union all queries",
    [[
SELECT
    ${1:s.EntityId}
FROM ${2:dbo}.${3:SourceEntity} AS ${4:s}

UNION ALL

SELECT
    ${5:t.EntityId}
FROM ${6:dbo}.${7:TargetEntity} AS ${8:t};
$0
]]
  ),

  snippet(
    "intersect",
    "Intersect queries",
    [[
SELECT
    ${1:s.EntityId}
FROM ${2:dbo}.${3:SourceEntity} AS ${4:s}

INTERSECT

SELECT
    ${5:t.EntityId}
FROM ${6:dbo}.${7:TargetEntity} AS ${8:t};
$0
]]
  ),

  snippet(
    "except",
    "Except queries",
    [[
SELECT
    ${1:s.EntityId}
FROM ${2:dbo}.${3:SourceEntity} AS ${4:s}

EXCEPT

SELECT
    ${5:t.EntityId}
FROM ${6:dbo}.${7:TargetEntity} AS ${8:t};
$0
]]
  ),

  snippet(
    "rownum",
    "Row number",
    [[
ROW_NUMBER() OVER
(
    ORDER BY ${1:e.EntityId}
) AS ${2:RowNo}$0
]]
  ),

  snippet(
    "rowpart",
    "Latest row per group",
    [[
;WITH ${1:RankedEntity} AS
(
    SELECT
        ${2:r.RelatedEntityId},
        ${3:r.EntityId},
        ${4:r.CreatedAt},
        ROW_NUMBER() OVER
        (
            PARTITION BY ${5:r.EntityId}
            ORDER BY
                ${6:r.CreatedAt DESC},
                ${7:r.RelatedEntityId DESC}
        ) AS RowNo
    FROM ${8:dbo}.${9:RelatedEntity} AS ${10:r}
)
SELECT
    ${11:r.RelatedEntityId},
    ${12:r.EntityId},
    ${13:r.CreatedAt}
FROM $1 AS ${14:r}
WHERE ${15:r.RowNo = 1};
$0
]]
  ),

  snippet(
    "rank",
    "Rank rows",
    [[
RANK() OVER
(
    ORDER BY ${1:e.Score DESC}
) AS ${2:Ranking}$0
]]
  ),

  snippet(
    "lag",
    "Lag value",
    [[
LAG(${1:e.Amount}) OVER
(
    ORDER BY ${2:e.EntityId}
) AS ${3:PreviousAmount}$0
]]
  ),

  -- Data modification.
  snippet(
    "ins",
    "Insert explicit columns",
    [[
INSERT INTO ${1:dbo}.${2:Entity}
(
    ${3:Code},
    ${4:Name},
    ${5:Status}
)
VALUES
(
    ${6:@Code},
    ${7:@Name},
    ${8:@Status}
);
$0
]]
  ),

  snippet(
    "insmulti",
    "Insert multiple rows",
    [[
INSERT INTO ${1:dbo}.${2:Entity}
(
    ${3:Code},
    ${4:Name}
)
VALUES
    (${5:N'E001'}, ${6:N'Value A'}),
    (${7:N'E002'}, ${8:N'Value B'}),
    (${9:N'E003'}, ${10:N'Value C'});
$0
]]
  ),

  snippet(
    "inssel",
    "Insert from select",
    [[
INSERT INTO ${1:dbo}.${2:EntityArchive}
(
    ${3:EntityId},
    ${4:Code},
    ${5:Name}
)
SELECT
    ${6:e.EntityId},
    ${7:e.Code},
    ${8:e.Name}
FROM ${9:dbo}.${10:Entity} AS ${11:e}
WHERE ${12:e.Status = 0};
$0
]]
  ),

  snippet(
    "inso",
    "Insert with output",
    [[
INSERT INTO ${1:dbo}.${2:Entity}
(
    ${3:Code},
    ${4:Name}
)
OUTPUT
    ${5:inserted.EntityId},
    ${6:inserted.Code},
    ${7:inserted.Name}
VALUES
(
    ${8:@Code},
    ${9:@Name}
);
$0
]]
  ),

  snippet(
    "upd",
    "Update with alias",
    [[
UPDATE ${1:e}
SET
    ${2:e.Name = @Name},
    ${3:e.UpdatedAt = SYSUTCDATETIME()}
FROM ${4:dbo}.${5:Entity} AS $1
WHERE ${6:e.EntityId = @EntityId};
$0
]]
  ),

  snippet(
    "updj",
    "Update with join",
    [[
UPDATE ${1:e}
SET
    ${2:e.Status = 0},
    ${3:e.UpdatedAt = SYSUTCDATETIME()}
FROM ${4:dbo}.${5:Entity} AS $1
INNER JOIN ${6:dbo}.${7:EntityState} AS ${8:s}
    ON ${9:s.EntityId = e.EntityId}
WHERE ${10:s.IsInactive = 1};
$0
]]
  ),

  snippet(
    "updo",
    "Update with output",
    [[
UPDATE ${1:e}
SET
    ${2:e.Name = @Name}
OUTPUT
    ${3:deleted.Name AS OldName},
    ${4:inserted.Name AS NewName}
FROM ${5:dbo}.${6:Entity} AS $1
WHERE ${7:e.EntityId = @EntityId};
$0
]]
  ),

  snippet(
    "del",
    "Delete with alias",
    [[
DELETE ${1:e}
FROM ${2:dbo}.${3:Entity} AS $1
WHERE ${4:e.EntityId = @EntityId};
$0
]]
  ),

  snippet(
    "delj",
    "Delete with join",
    [[
DELETE ${1:r}
FROM ${2:dbo}.${3:RelatedEntity} AS $1
INNER JOIN ${4:dbo}.${5:Entity} AS ${6:e}
    ON ${7:e.EntityId = r.EntityId}
WHERE ${8:e.Status = 0};
$0
]]
  ),

  snippet(
    "delo",
    "Delete with output",
    [[
DELETE ${1:e}
OUTPUT
    ${2:deleted.EntityId},
    ${3:deleted.Code},
    ${4:deleted.Name}
FROM ${5:dbo}.${6:Entity} AS $1
WHERE ${7:e.EntityId = @EntityId};
$0
]]
  ),

  snippet(
    "upsert",
    "Transactional update then insert",
    [[
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE ${1:e}
    SET
        ${2:e.Name = @Name},
        ${3:e.UpdatedAt = SYSUTCDATETIME()}
    FROM ${4:dbo}.${5:Entity} AS $1
    WHERE ${6:e.Code = @Code};

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO $4.$5
        (
            ${7:Code},
            ${8:Name}
        )
        VALUES
        (
            ${9:@Code},
            ${10:@Name}
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
$0
]]
  ),

  -- Control flow, temporary storage, and transactions.
  snippet(
    "declare",
    "Declare variable",
    [[
DECLARE ${1:@EntityId} ${2:BIGINT}${3: = 1};
$0
]]
  ),

  snippet(
    "ifelse",
    "If else block",
    [[
IF ${1:@Status = 1}
BEGIN
    ${2:-- True branch.}
END
ELSE
BEGIN
    ${3:-- False branch.}
END;
$0
]]
  ),

  snippet(
    "ifexists",
    "If exists block",
    [[
IF EXISTS
(
    SELECT 1
    FROM ${1:dbo}.${2:Entity} AS ${3:e}
    WHERE ${4:e.EntityId = @EntityId}
)
BEGIN
    ${5:-- Statement.}
END;
$0
]]
  ),

  snippet(
    "while",
    "While loop",
    [[
DECLARE ${1:@Index} INT = ${2:1};

WHILE $1 <= ${3:10}
BEGIN
    ${4:PRINT @Index;}

    SET $1 += 1;
END;
$0
]]
  ),

  snippet(
    "temptable",
    "Create and use temporary table",
    [[
CREATE TABLE #${1:Entity}
(
    ${2:EntityId BIGINT NOT NULL},
    ${3:Name NVARCHAR(100) NOT NULL}
);

INSERT INTO #$1
(
    ${4:EntityId},
    ${5:Name}
)
SELECT
    ${6:e.EntityId},
    ${7:e.Name}
FROM ${8:dbo}.${9:Entity} AS ${10:e};

SELECT
    ${11:EntityId},
    ${12:Name}
FROM #$1;

DROP TABLE IF EXISTS #$1;
$0
]]
  ),

  snippet(
    "selinto",
    "Select into temporary table",
    [[
SELECT
    ${1:e.EntityId},
    ${2:e.Name}
INTO #${3:Entity}
FROM ${4:dbo}.${5:Entity} AS ${6:e}
WHERE ${7:e.Status = 1};
$0
]]
  ),

  snippet(
    "tablevar",
    "Declare and populate table variable",
    [[
DECLARE @${1:Entity} TABLE
(
    ${2:EntityId BIGINT NOT NULL},
    ${3:Name NVARCHAR(100) NOT NULL}
);

INSERT INTO @$1
(
    ${4:EntityId},
    ${5:Name}
)
SELECT
    ${6:e.EntityId},
    ${7:e.Name}
FROM ${8:dbo}.${9:Entity} AS ${10:e};
$0
]]
  ),

  snippet(
    "txn",
    "Transaction with error handling",
    [[
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    ${1:-- Database unit of work.}

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
$0
]]
  ),

  snippet(
    "trycatch",
    "Try catch block",
    [[
BEGIN TRY
    ${1:-- Statement.}
END TRY
BEGIN CATCH
    THROW;
END CATCH;
$0
]]
  ),

  snippet(
    "throw",
    "Throw custom error",
    [[
IF ${1:@EntityId IS NULL}
BEGIN
    THROW ${2:50001}, ${3:'EntityId is required.'}, ${4:1};
END;
$0
]]
  ),

  -- Dynamic SQL with parameterized values and whitelisted identifiers.
  snippet(
    "dynsql",
    "Parameterized dynamic SQL",
    [[
DECLARE @Sql NVARCHAR(MAX);

SET @Sql = N'
    SELECT
        ${1:e.EntityId},
        ${2:e.Name}
    FROM ${3:dbo}.${4:Entity} AS ${5:e}
    WHERE ${6:e.Status = @Status}
        AND ${7:e.Name LIKE @NamePattern};
';

EXEC sys.sp_executesql
    @Sql,
    N'
        ${8:@Status TINYINT},
        ${9:@NamePattern NVARCHAR(200)}
    ',
    ${10:@Status = @Status},
    ${11:@NamePattern = @NamePattern};
$0
]]
  ),

  snippet(
    "dynident",
    "Dynamic SQL with whitelisted identifier",
    [[
IF ${1:@SortColumn} NOT IN
(
    ${2:N'EntityId'},
    ${3:N'Name'},
    ${4:N'CreatedAt'}
)
BEGIN
    THROW ${5:50001}, ${6:'Invalid sort column.'}, 1;
END;

DECLARE @Sql NVARCHAR(MAX);

SET @Sql = N'
    SELECT
        ${7:EntityId},
        ${8:Name},
        ${9:CreatedAt}
    FROM ${10:dbo}.${11:Entity}
    ORDER BY ' + QUOTENAME($1) + N';
';

EXEC sys.sp_executesql @Sql;
$0
]]
  ),

  -- Security and object lifecycle.
  snippet(
    "grantobj",
    "Grant object permission",
    [[
GRANT ${1:EXECUTE}
ON OBJECT::${2:dbo}.${3:CreateEntity}
TO ${4:ApplicationUser};
$0
]]
  ),

  snippet(
    "grantschema",
    "Grant schema permission",
    [[
GRANT ${1:EXECUTE}
ON SCHEMA::${2:dbo}
TO ${3:ApplicationUser};
$0
]]
  ),

  snippet(
    "revoke",
    "Revoke object permission",
    [[
REVOKE ${1:SELECT}
ON OBJECT::${2:dbo}.${3:Entity}
FROM ${4:ApplicationUser};
$0
]]
  ),

  snippet(
    "deny",
    "Deny object permission",
    [[
DENY ${1:DELETE}
ON OBJECT::${2:dbo}.${3:Entity}
TO ${4:ApplicationUser};
$0
]]
  ),

  snippet(
    "objif",
    "Check object existence",
    [[
IF OBJECT_ID(N'${1:dbo}.${2:Entity}', N'${3:U}') IS NOT NULL
BEGIN
    ${4:-- Statement.}
END;
$0
]]
  ),

  snippet(
    "dropobj",
    "Drop object if it exists",
    [[
DROP ${1:PROCEDURE} IF EXISTS ${2:dbo}.${3:GetEntity};
$0
]]
  ),

  -- Constraint and column fragments.
  snippet(
    "fk",
    "Named foreign key constraint",
    [[
CONSTRAINT FK_${1:RelatedEntity}_${2:Entity}
    FOREIGN KEY (${2}Id)
    REFERENCES ${3:dbo}.$2(${2}Id)$0
]]
  ),

  snippet(
    "checkcon",
    "Named check constraint",
    [[
CONSTRAINT CK_${1:Entity}_${2:Status}
    CHECK ($2 IN (${3:0, 1, 2}))$0
]]
  ),

  snippet(
    "defaultcon",
    "Named default constraint",
    [[
${1:Status} ${2:TINYINT} NOT NULL
    CONSTRAINT DF_${3:Entity}_$1
    DEFAULT (${4:1})$0
]]
  ),

  snippet(
    "computed",
    "Persisted computed column",
    [[
${1:TotalAmount} AS
    (${2:Quantity * UnitPrice}) PERSISTED$0
]]
  ),

  snippet(
    "utccol",
    "UTC timestamp column",
    [[
${1:CreatedAt} DATETIME2(3) NOT NULL
    CONSTRAINT DF_${2:Entity}_$1
    DEFAULT (SYSUTCDATETIME())$0
]]
  ),

  snippet(
    "nextseq",
    "Get next sequence value",
    [[
SELECT NEXT VALUE FOR ${1:dbo}.${2:EntityIdSequence};
$0
]]
  ),

  -- Common expressions and statement fragments.
  snippet(
    "setvar",
    "Set variable",
    [[
SET ${1:@EntityId} = ${2:1};
$0
]]
  ),

  snippet(
    "selectvars",
    "Assign variables from query",
    [[
SELECT
    ${1:@EntityId = e.EntityId},
    ${2:@Name = e.Name}
FROM ${3:dbo}.${4:Entity} AS ${5:e}
WHERE ${6:e.Code = @Code};
$0
]]
  ),

  snippet(
    "orderby",
    "Deterministic order by",
    [[
ORDER BY
    ${1:e.CreatedAt DESC},
    ${2:e.EntityId DESC}$0
]]
  ),

  snippet(
    "aggregate",
    "Aggregate query",
    [[
SELECT
    COUNT(*) AS ${1:TotalCount},
    COUNT(${2:e.OptionalValue}) AS ${3:NonNullCount},
    SUM(${4:e.Amount}) AS ${5:TotalAmount},
    AVG($4) AS ${6:AverageAmount},
    MIN($4) AS ${7:MinimumAmount},
    MAX($4) AS ${8:MaximumAmount}
FROM ${9:dbo}.${10:Entity} AS ${11:e};
$0
]]
  ),

  snippet(
    "isnull",
    "Is null predicate",
    [[
${1:e.OptionalValue} IS NULL$0
]]
  ),

  snippet(
    "notnull",
    "Is not null predicate",
    [[
${1:e.OptionalValue} IS NOT NULL$0
]]
  ),

  snippet(
    "coalesce",
    "Coalesce expression",
    [[
COALESCE(
    ${1:e.PrimaryValue},
    ${2:e.SecondaryValue},
    ${3:N''}
)$0
]]
  ),

  snippet(
    "nullif",
    "Nullif expression",
    [[
${1:TotalAmount} / NULLIF(${2:ItemCount}, 0)$0
]]
  ),

  snippet(
    "cast",
    "Cast expression",
    [[
CAST(${1:@Value} AS ${2:INT})$0
]]
  ),

  snippet(
    "convert",
    "Convert expression with style",
    [[
CONVERT(${1:VARCHAR(10)}, ${2:@Date}, ${3:23})$0
]]
  ),

  snippet(
    "trycast",
    "Try cast expression",
    [[
TRY_CAST(${1:Value} AS ${2:INT})$0
]]
  ),

  snippet(
    "concat",
    "Null-safe string concatenation",
    [[
CONCAT(
    ${1:e.Prefix},
    ${2:N' '},
    ${3:e.Name}
)$0
]]
  ),

  snippet(
    "denserank",
    "Dense rank rows",
    [[
DENSE_RANK() OVER
(
    ORDER BY ${1:e.Score DESC}
) AS ${2:Ranking}$0
]]
  ),

  snippet(
    "lead",
    "Lead value",
    [[
LEAD(${1:e.Amount}) OVER
(
    ORDER BY ${2:e.EntityId}
) AS ${3:NextAmount}$0
]]
  ),

  snippet(
    "oapply",
    "Outer apply latest related row",
    [[
OUTER APPLY
(
    SELECT TOP (1)
        ${1:r.RelatedEntityId}
    FROM ${2:dbo}.${3:RelatedEntity} AS ${4:r}
    WHERE ${5:r.EntityId = e.EntityId}
    ORDER BY
        ${6:r.CreatedAt DESC},
        ${7:r.RelatedEntityId DESC}
) AS ${8:x}$0
]]
  ),

  snippet(
    "nocount",
    "Enable NOCOUNT",
    [[
SET NOCOUNT ON;
$0
]]
  ),

  snippet(
    "xactabort",
    "Enable XACT_ABORT",
    [[
SET XACT_ABORT ON;
$0
]]
  ),

  snippet(
    "go",
    "Batch separator",
    [[
GO
$0
]]
  ),
}
