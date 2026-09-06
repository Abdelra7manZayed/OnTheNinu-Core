@echo off
cd /d "%~dp0"
echo Creating virtual environment...
python -m venv .venv
if errorlevel 1 pause & exit /b 1

echo Installing requirements...
.venv\Scripts\python.exe -m pip install --upgrade pip
.venv\Scripts\python.exe -m pip install -r requirements.txt
if errorlevel 1 pause & exit /b 1

if not exist .env copy .env.example .env

echo Creating and seeding database...
.venv\Scripts\python.exe scripts\init_db.py --drop
.venv\Scripts\python.exe scripts\seed_data.py
.venv\Scripts\python.exe scripts\check_db.py

echo Starting app at http://127.0.0.1:8000
.venv\Scripts\python.exe -m uvicorn app.main:app --reload
pause
