# SQL Server version created from the fixed ERD schema

I kept the SQLite version unchanged and created a separate SQL Server version.

## Files

- `retail_pos_erd_aligned_sqlite_schema_seed.sql` — original fixed SQLite schema used by the FastAPI app.
- `retail_pos_erd_aligned_sqlserver_schema_seed.sql` — new SQL Server version of the same schema and seed data.

## Main conversions

| SQLite version | SQL Server version |
|---|---|
| `TEXT` | `NVARCHAR(...)` or `NVARCHAR(MAX)` |
| `INTEGER` | `INT` or `BIT` for active flags |
| `REAL` | `DECIMAL(18,2)` |
| `CURRENT_TIMESTAMP` | `SYSUTCDATETIME()` |
| `PRAGMA foreign_keys` | removed; SQL Server uses normal FK constraints |
| Inline/circular FKs | moved to `ALTER TABLE` after table creation |
| `DROP TABLE IF EXISTS` | kept in SQL Server format with `[dbo]` schema |

## Extra app table

The SQL Server script includes `user_account` because the FastAPI project uses it for login. It is not part of the original ERD, but it is required for the login system requested in the project.

## Important note

The FastAPI app currently runs on SQLite. The SQL Server file is for SQL Server Management Studio / SQL Server database creation. To make the FastAPI app connect to SQL Server instead of SQLite, the database connection string and driver would need to be changed.
