from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import func, text
from sqlalchemy.orm import Session

from .. import models
from ..auth import current_user, flash, is_allowed, pop_flash, require_permission
from ..crud import build_form_fields, create_record, delete_record, get_model, get_table_config, list_records, model_columns, primary_key_name, serialize_instance, update_record
from ..database import get_db
from ..table_config import TABLES, nav_groups

router = APIRouter()
templates = Jinja2Templates(directory="app/templates")


def template_context(request: Request):
    user = current_user(request)
    return {
        "request": request,
        "current_user": user,
        "flash_messages": pop_flash(request),
        "nav_groups": nav_groups(),
        "is_allowed": lambda resource, action="read": is_allowed(user, resource, action),
        "app_name": "On The Ninu Supermarket",
    }


@router.get("/")
async def home(request: Request):
    if current_user(request):
        return RedirectResponse(url="/dashboard", status_code=303)
    return RedirectResponse(url="/login", status_code=303)


@router.get("/dashboard")
async def dashboard(request: Request, db: Session = Depends(get_db)):
    require_permission(request, "dashboard", "read")
    counts = {
        "Products": db.query(models.Product).count(),
        "Customers": db.query(models.Customer).count(),
        "Sales": db.query(models.Sale).count(),
        "Employees": db.query(models.Employee).count(),
        "Suppliers": db.query(models.Supplier).count(),
        "Purchase Orders": db.query(models.PurchaseOrder).count(),
    }
    recent_sales = db.query(models.Sale).order_by(models.Sale.id.desc()).limit(8).all()
    low_stock = db.query(models.Product).filter(models.Product.stock_qty <= models.Product.reorder_level).order_by(models.Product.stock_qty.asc()).limit(8).all()
    sales_by_day = db.execute(text("""
        SELECT date(sale_date) AS day, ROUND(SUM(final_amount), 2) AS total
        FROM sale
        GROUP BY date(sale_date)
        ORDER BY day DESC
        LIMIT 10
    """)).mappings().all()[::-1]
    payment_mix = db.execute(text("""
        SELECT pay_method AS method, ROUND(SUM(amount), 2) AS total
        FROM payment
        GROUP BY pay_method
        ORDER BY total DESC
    """)).mappings().all()
    top_products = db.execute(text("""
        SELECT p.product_name, ROUND(SUM(si.qty), 2) AS qty
        FROM sale_item si
        JOIN product p ON p.id = si.product_id
        GROUP BY p.id, p.product_name
        ORDER BY qty DESC
        LIMIT 8
    """)).mappings().all()
    ctx = template_context(request)
    ctx.update({
        "counts": counts,
        "recent_sales": recent_sales,
        "low_stock": low_stock,
        "sales_by_day": [dict(r) for r in sales_by_day],
        "payment_mix": [dict(r) for r in payment_mix],
        "top_products": [dict(r) for r in top_products],
    })
    return templates.TemplateResponse("dashboard.html", ctx)


@router.get("/tables/{slug}")
async def table_list(slug: str, request: Request, q: str = "", page: int = 1, db: Session = Depends(get_db)):
    require_permission(request, slug, "read")
    config = get_table_config(slug)
    if not config:
        raise HTTPException(status_code=404, detail="Table not found")
    model = config["model"]
    limit = 25
    offset = max(page - 1, 0) * limit
    rows, total = list_records(db, model, q=q, search_columns=config.get("search"), limit=limit, offset=offset)
    columns = [c.name for c in model_columns(model)]
    ctx = template_context(request)
    ctx.update({"slug": slug, "config": config, "rows": rows, "columns": columns, "q": q, "page": page, "limit": limit, "total": total})
    return templates.TemplateResponse("generic/list.html", ctx)


@router.get("/tables/{slug}/new")
async def new_record(slug: str, request: Request, db: Session = Depends(get_db)):
    require_permission(request, slug, "create")
    config = get_table_config(slug)
    if not config:
        raise HTTPException(status_code=404, detail="Table not found")
    fields = build_form_fields(db, config["model"])
    ctx = template_context(request)
    ctx.update({"slug": slug, "config": config, "fields": fields, "mode": "new", "record": None})
    return templates.TemplateResponse("generic/form.html", ctx)


@router.post("/tables/{slug}/new")
async def create_record_page(slug: str, request: Request, db: Session = Depends(get_db)):
    require_permission(request, slug, "create")
    config = get_table_config(slug)
    if not config:
        raise HTTPException(status_code=404, detail="Table not found")
    form = dict(await request.form())
    try:
        create_record(db, config["model"], form)
        flash(request, "success", "Record created successfully.")
        return RedirectResponse(url=f"/tables/{slug}", status_code=303)
    except ValueError as exc:
        fields = build_form_fields(db, config["model"])
        ctx = template_context(request)
        ctx.update({"slug": slug, "config": config, "fields": fields, "mode": "new", "error": str(exc), "record": None})
        return templates.TemplateResponse("generic/form.html", ctx, status_code=400)


@router.get("/tables/{slug}/{record_id}/edit")
async def edit_record(slug: str, record_id: int, request: Request, db: Session = Depends(get_db)):
    require_permission(request, slug, "update")
    config = get_table_config(slug)
    if not config:
        raise HTTPException(status_code=404, detail="Table not found")
    model = config["model"]
    obj = db.get(model, record_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Record not found")
    fields = build_form_fields(db, model, obj)
    ctx = template_context(request)
    ctx.update({"slug": slug, "config": config, "fields": fields, "mode": "edit", "record": obj})
    return templates.TemplateResponse("generic/form.html", ctx)


@router.post("/tables/{slug}/{record_id}/edit")
async def update_record_page(slug: str, record_id: int, request: Request, db: Session = Depends(get_db)):
    require_permission(request, slug, "update")
    config = get_table_config(slug)
    if not config:
        raise HTTPException(status_code=404, detail="Table not found")
    form = dict(await request.form())
    try:
        update_record(db, config["model"], record_id, form)
        flash(request, "success", "Record updated successfully.")
        return RedirectResponse(url=f"/tables/{slug}", status_code=303)
    except ValueError as exc:
        obj = db.get(config["model"], record_id)
        fields = build_form_fields(db, config["model"], obj)
        ctx = template_context(request)
        ctx.update({"slug": slug, "config": config, "fields": fields, "mode": "edit", "record": obj, "error": str(exc)})
        return templates.TemplateResponse("generic/form.html", ctx, status_code=400)


@router.post("/tables/{slug}/{record_id}/delete")
async def delete_record_page(slug: str, record_id: int, request: Request, db: Session = Depends(get_db)):
    require_permission(request, slug, "delete")
    config = get_table_config(slug)
    if not config:
        raise HTTPException(status_code=404, detail="Table not found")
    ok, message = delete_record(db, config["model"], record_id)
    flash(request, "success" if ok else "danger", message)
    return RedirectResponse(url=f"/tables/{slug}", status_code=303)
