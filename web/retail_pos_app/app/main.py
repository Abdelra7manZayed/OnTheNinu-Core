import os
from pathlib import Path
from dotenv import load_dotenv
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware

PROJECT_ROOT = Path(__file__).resolve().parents[1]
load_dotenv(PROJECT_ROOT / ".env")

from .database import Base, engine
from .routes import api, auth_routes, reports, web

app = FastAPI(
    title="On The Ninu Retail POS",
    description="Local FastAPI + SQLite retail/POS CRUD and reporting system based on the ERD.",
    version="1.0.0",
)

app.add_middleware(
    SessionMiddleware,
    secret_key=os.getenv("SESSION_SECRET_KEY", "change-this-secret-key-in-env"),
    same_site="lax",
    https_only=False,
)

app.mount("/static", StaticFiles(directory=str(PROJECT_ROOT / "app" / "static")), name="static")
templates = Jinja2Templates(directory=str(PROJECT_ROOT / "app" / "templates"))

app.include_router(auth_routes.router)
app.include_router(web.router)
app.include_router(reports.router)
app.include_router(api.router)

@app.on_event("startup")
def startup():
    Base.metadata.create_all(bind=engine)

@app.exception_handler(403)
async def forbidden_handler(request: Request, exc):
    return templates.TemplateResponse("error.html", {"request": request, "status_code": 403, "message": getattr(exc, "detail", "Permission denied")}, status_code=403)

@app.exception_handler(404)
async def not_found_handler(request: Request, exc):
    return templates.TemplateResponse("error.html", {"request": request, "status_code": 404, "message": getattr(exc, "detail", "Page not found")}, status_code=404)
