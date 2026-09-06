import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from sqlalchemy import text
from app.auth import hash_password
from app.database import Base, SessionLocal, engine
from app.models import Branch, Department, Employee, UserAccount

SEED_SQL = Path(__file__).with_name("retail_pos_erd_aligned_sqlite_schema_seed.sql")


def main():
    sql_script = SEED_SQL.read_text(encoding="utf-8")
    with engine.begin() as connection:
        raw = connection.connection
        raw.executescript(sql_script)

    # Create the added authentication table after the ERD seed script creates core tables.
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        # Brand-specific manager requested for the supermarket project.
        manager = db.get(Employee, 1)
        if manager:
            manager.first_n = "Gemy"
            manager.last_n = "Zayed"
            manager.email = "gemy.zayed@ontheninu.local"
            manager.role_id = 1
            manager.is_active = 1
        branch = db.get(Branch, 30) or db.get(Branch, 1)
        if branch:
            branch.name = "On The Ninu - Ismailia Ring Road"
            branch.address = "Ring Road, Suez Canal University, beside Faculty of Pharmacy gate"
            branch.manager_id = 1
        department = db.get(Department, 1)
        if department:
            department.manager_id = 1

        accounts = [
            (1, "admin", "Admin@12345"),
            (2, "manager", "Manager@12345"),
            (3, "cashier", "Cashier@12345"),
            (4, "inventory", "Inventory@12345"),
        ]
        db.query(UserAccount).delete()
        for employee_id, username, password in accounts:
            db.add(UserAccount(employee_id=employee_id, username=username, password_hash=hash_password(password), is_active=1))
        db.commit()
        print("Seed data loaded successfully.")
        print("Login users created: admin, manager, cashier, inventory")
    finally:
        db.close()


if __name__ == "__main__":
    main()
