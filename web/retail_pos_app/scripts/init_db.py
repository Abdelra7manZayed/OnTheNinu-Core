import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from app.database import Base, engine
from app import models  # noqa: F401 - imports all SQLAlchemy models


def drop_sqlite_tables():
    """Drop SQLite tables safely, including schemas with circular foreign keys."""
    with engine.begin() as connection:
        connection.exec_driver_sql("PRAGMA foreign_keys=OFF")
        tables = connection.exec_driver_sql(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        ).fetchall()
        for (table_name,) in tables:
            connection.exec_driver_sql(f'DROP TABLE IF EXISTS "{table_name}"')
        connection.exec_driver_sql("PRAGMA foreign_keys=ON")


def main():
    parser = argparse.ArgumentParser(description="Initialize the local Retail POS database.")
    parser.add_argument(
        "--drop",
        action="store_true",
        help="Drop all existing tables before creating them again.",
    )
    args = parser.parse_args()

    if args.drop:
        if engine.dialect.name == "sqlite":
            drop_sqlite_tables()
        else:
            Base.metadata.drop_all(bind=engine)
        print("Existing tables dropped.")

    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully.")


if __name__ == "__main__":
    main()
