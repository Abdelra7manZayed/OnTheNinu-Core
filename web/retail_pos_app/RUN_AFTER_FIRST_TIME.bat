@echo off
cd /d "%~dp0"
if not exist .venv\Scripts\python.exe (
    echo Virtual environment not found. Run RUN_FIRST_TIME.bat first.
    pause
    exit /b 1
)
if not exist .env copy .env.example .env
.venv\Scripts\python.exe scripts\check_db.py
echo Starting app at http://127.0.0.1:8000
.venv\Scripts\python.exe -m uvicorn app.main:app --reload
pause
