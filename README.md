# On The Ninu Retail POS App

A complete local web application built from the corrected Retail/POS ERD and database schema.

The app includes:

- FastAPI backend
- SQLite local database
- SQLAlchemy ORM models
- Jinja + Bootstrap web interface
- Full CRUD pages
- REST API endpoints
- Dashboard and reports
- Chart.js charts
- CSV report export
- Login/logout system
- Role-based access control
- SQLite schema version
- SQL Server schema version

---

## Quick run commands

Use these commands after downloading the ZIP file:

```bash
unzip retail_pos_app.zip
cd retail_pos_app

python -m venv .venv
source .venv/bin/activate   # Windows: .\.venv\Scripts\Activate.ps1

pip install -r requirements.txt
cp .env.example .env   # Windows PowerShell: Copy-Item .env.example .env

python scripts/init_db.py --drop
python scripts/seed_data.py

python -m uvicorn app.main:app --reload
```

Then open:

```text
http://127.0.0.1:8000
```

API docs:

```text
http://127.0.0.1:8000/docs
```

---

## Windows CMD alternative

If you use Windows CMD instead of PowerShell/Git Bash:

```cmd
cd retail_pos_app
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python scripts\init_db.py --drop
python scripts\seed_data.py
python -m uvicorn app.main:app --reload
```

---

## Login accounts

After running `python scripts/seed_data.py`, use one of these accounts:

| Username | Password | Role |
|---|---|---|
| admin | Admin@12345 | Admin |
| manager | Manager@12345 | Manager |
| cashier | Cashier@12345 | Cashier |
| inventory | Inventory@12345 | Inventory Clerk |

The login passwords are not displayed on the web frontend.

---

## Project structure

```text
retail_pos_app/
├── app/
│   ├── main.py
│   ├── database.py
│   ├── models.py
│   ├── schemas.py
│   ├── crud.py
│   ├── auth.py
│   ├── table_config.py
│   ├── routes/
│   ├── templates/
│   └── static/
├── scripts/
│   ├── init_db.py
│   ├── seed_data.py
│   ├── retail_pos_erd_aligned_sqlite_schema_seed.sql
│   └── retail_pos_erd_aligned_sqlserver_schema_seed.sql
├── PROJECT_ANALYSIS.md
├── SQLSERVER_SCHEMA_NOTES.md
├── VALIDATION_REPORT.md
├── requirements.txt
├── README.md
├── .env.example
└── retail_pos.db
```

---

## Database files

The app runs with SQLite by default:

```text
scripts/retail_pos_erd_aligned_sqlite_schema_seed.sql
```

The SQL Server version is also included:

```text
scripts/retail_pos_erd_aligned_sqlserver_schema_seed.sql
```

The SQL Server file is for SSMS / SQL Server only. The FastAPI app uses SQLite unless you change `DATABASE_URL` in `.env`.

---

## Main pages

- `/login` — Login page
- `/` — Dashboard
- `/crud/{table_name}` — CRUD page for each table
- `/reports` — Reports list
- `/reports/sales` — Sales report
- `/reports/inventory` — Inventory report
- `/reports/purchase-orders` — Purchase orders report
- `/reports/returns` — Returns report
- `/docs` — FastAPI Swagger API documentation

---

## Role access

| Role | Access |
|---|---|
| Admin | Full system access |
| Manager | Products, sales, customers, payments, reports |
| Cashier | Sales, payments, customers, returns |
| Inventory Clerk | Products, suppliers, inventory, purchase orders |

---

## Notes

`python scripts/init_db.py --drop` drops and recreates the SQLAlchemy tables.

`python scripts/seed_data.py` loads the corrected ERD-aligned SQLite schema, inserts sample data, and creates login users.

If the port is busy, run:

```bash
python -m uvicorn app.main:app --reload --port 8001
```


---

## Easy Windows run

For the first run, double-click:

```text
RUN_FIRST_TIME.bat
```

For later runs, double-click:

```text
RUN_AFTER_FIRST_TIME.bat
```

If PowerShell blocks activation, you do not need activation when using the BAT files because they run `.venv\Scripts\python.exe` directly.

## Database location check

To confirm where the web app is saving records, run:

```bash
python scripts/check_db.py
```

By default, the app saves data in this file inside the project folder:

```text
retail_pos.db
```
