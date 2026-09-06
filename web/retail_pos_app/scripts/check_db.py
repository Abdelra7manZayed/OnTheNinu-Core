import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from app.database import DATABASE_URL, engine
from sqlalchemy import text

print("Project folder:", ROOT)
print("Database URL:", DATABASE_URL)
with engine.connect() as conn:
    try:
        tables = conn.execute(text("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")).fetchall()
        print("Tables found:", len(tables))
        for row in tables:
            print("-", row[0])
    except Exception as exc:
        print("Database check failed:", exc)
