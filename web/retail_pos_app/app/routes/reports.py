import csv
import io
from fastapi import APIRouter, Depends, Request
from fastapi.responses import StreamingResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..auth import current_user, is_allowed, pop_flash, require_permission
from ..database import get_db
from ..table_config import nav_groups

router = APIRouter(prefix="/reports")
templates = Jinja2Templates(directory="app/templates")


def base_context(request: Request):
    user = current_user(request)
    return {
        "request": request,
        "current_user": user,
        "flash_messages": pop_flash(request),
        "nav_groups": nav_groups(),
        "is_allowed": lambda resource, action="read": is_allowed(user, resource, action),
        "app_name": "On The Ninu Supermarket",
    }


def csv_export(rows, filename: str):
    output = io.StringIO()
    if rows:
        writer = csv.DictWriter(output, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    else:
        output.write("No data\n")
    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.get("")
async def reports_index(request: Request):
    require_permission(request, "reports", "read")
    return templates.TemplateResponse("reports/index.html", base_context(request))


@router.get("/sales")
async def sales_report(request: Request, start_date: str = "", end_date: str = "", export: str = "", db: Session = Depends(get_db)):
    require_permission(request, "reports", "export" if export else "read")
    conditions = []
    params = {}
    if start_date:
        conditions.append("date(s.sale_date) >= date(:start_date)")
        params["start_date"] = start_date
    if end_date:
        conditions.append("date(s.sale_date) <= date(:end_date)")
        params["end_date"] = end_date
    where_sql = "WHERE " + " AND ".join(conditions) if conditions else ""
    rows = db.execute(text(f"""
        SELECT s.id, s.sale_date, COALESCE(c.cus_name, 'Walk-in') AS customer,
               e.first_n || ' ' || e.last_n AS employee, r.register_code,
               ROUND(s.total_amount, 2) AS total_amount, ROUND(s.tax_amount, 2) AS tax_amount,
               ROUND(s.discount_amount, 2) AS discount_amount, ROUND(s.final_amount, 2) AS final_amount
        FROM sale s
        LEFT JOIN customer c ON c.id = s.customer_id
        JOIN employee e ON e.id = s.employee_id
        JOIN register r ON r.id = s.register_id
        {where_sql}
        ORDER BY s.sale_date DESC, s.id DESC
    """), params).mappings().all()
    summary = db.execute(text(f"""
        SELECT COUNT(*) AS sale_count, ROUND(SUM(final_amount), 2) AS revenue,
               ROUND(AVG(final_amount), 2) AS avg_sale, ROUND(SUM(discount_amount), 2) AS discounts
        FROM sale s {where_sql}
    """), params).mappings().first()
    daily = db.execute(text(f"""
        SELECT date(s.sale_date) AS day, ROUND(SUM(s.final_amount), 2) AS total
        FROM sale s {where_sql}
        GROUP BY date(s.sale_date)
        ORDER BY day
    """), params).mappings().all()
    if export == "csv":
        return csv_export([dict(r) for r in rows], "sales_report.csv")
    ctx = base_context(request)
    ctx.update({"rows": [dict(r) for r in rows], "summary": dict(summary) if summary else {}, "daily": [dict(r) for r in daily], "start_date": start_date, "end_date": end_date})
    return templates.TemplateResponse("reports/sales.html", ctx)


@router.get("/inventory")
async def inventory_report(request: Request, only_low_stock: int = 0, export: str = "", db: Session = Depends(get_db)):
    require_permission(request, "reports", "export" if export else "read")
    where_sql = "WHERE p.stock_qty <= p.reorder_level" if only_low_stock else ""
    rows = db.execute(text(f"""
        SELECT p.id, p.product_name, c.cat_name AS category, COALESCE(s.sup_n, '-') AS supplier,
               p.barcode, ROUND(p.cost_price, 2) AS cost_price, ROUND(p.sell_price, 2) AS sell_price,
               ROUND(p.stock_qty, 2) AS stock_qty, ROUND(p.reorder_level, 2) AS reorder_level,
               CASE WHEN p.stock_qty <= p.reorder_level THEN 'Low stock' ELSE 'OK' END AS status
        FROM product p
        JOIN category c ON c.id = p.category_id
        LEFT JOIN supplier s ON s.id = p.supplier_id
        {where_sql}
        ORDER BY status DESC, p.stock_qty ASC, p.product_name
    """)).mappings().all()
    category_values = db.execute(text("""
        SELECT c.cat_name AS category, ROUND(SUM(p.stock_qty * p.cost_price), 2) AS inventory_value
        FROM product p JOIN category c ON c.id = p.category_id
        GROUP BY c.id, c.cat_name
        ORDER BY inventory_value DESC
    """)).mappings().all()
    if export == "csv":
        return csv_export([dict(r) for r in rows], "inventory_report.csv")
    ctx = base_context(request)
    ctx.update({"rows": [dict(r) for r in rows], "category_values": [dict(r) for r in category_values], "only_low_stock": only_low_stock})
    return templates.TemplateResponse("reports/inventory.html", ctx)


@router.get("/purchase-orders")
async def purchase_orders_report(request: Request, start_date: str = "", end_date: str = "", export: str = "", db: Session = Depends(get_db)):
    require_permission(request, "reports", "export" if export else "read")
    conditions = []
    params = {}
    if start_date:
        conditions.append("date(po.order_date) >= date(:start_date)")
        params["start_date"] = start_date
    if end_date:
        conditions.append("date(po.order_date) <= date(:end_date)")
        params["end_date"] = end_date
    where_sql = "WHERE " + " AND ".join(conditions) if conditions else ""
    rows = db.execute(text(f"""
        SELECT po.id, po.order_date, po.expected_date, sup.sup_n AS supplier,
               e.first_n || ' ' || e.last_n AS employee, ROUND(po.total_amount, 2) AS total_amount, po.status_po
        FROM purchase_order po
        JOIN supplier sup ON sup.id = po.supplier_id
        JOIN employee e ON e.id = po.employee_id
        {where_sql}
        ORDER BY po.order_date DESC, po.id DESC
    """), params).mappings().all()
    by_status = db.execute(text(f"""
        SELECT po.status_po AS status, COUNT(*) AS count, ROUND(SUM(po.total_amount), 2) AS amount
        FROM purchase_order po {where_sql}
        GROUP BY po.status_po
        ORDER BY count DESC
    """), params).mappings().all()
    if export == "csv":
        return csv_export([dict(r) for r in rows], "purchase_orders_report.csv")
    ctx = base_context(request)
    ctx.update({"rows": [dict(r) for r in rows], "by_status": [dict(r) for r in by_status], "start_date": start_date, "end_date": end_date})
    return templates.TemplateResponse("reports/purchase_orders.html", ctx)


@router.get("/returns")
async def returns_report(request: Request, start_date: str = "", end_date: str = "", export: str = "", db: Session = Depends(get_db)):
    require_permission(request, "reports", "export" if export else "read")
    conditions = []
    params = {}
    if start_date:
        conditions.append("date(sr.return_date) >= date(:start_date)")
        params["start_date"] = start_date
    if end_date:
        conditions.append("date(sr.return_date) <= date(:end_date)")
        params["end_date"] = end_date
    where_sql = "WHERE " + " AND ".join(conditions) if conditions else ""
    rows = db.execute(text(f"""
        SELECT sr.id, sr.return_date, sr.sale_id, COALESCE(c.cus_name, '-') AS customer,
               ROUND(sr.total_return, 2) AS total_return, COALESCE(sr.reason, '-') AS reason
        FROM sale_return sr
        LEFT JOIN customer c ON c.id = sr.customer_id
        {where_sql}
        ORDER BY sr.return_date DESC, sr.id DESC
    """), params).mappings().all()
    by_reason = db.execute(text(f"""
        SELECT COALESCE(sr.reason, 'No reason') AS reason, COUNT(*) AS count, ROUND(SUM(sr.total_return), 2) AS amount
        FROM sale_return sr {where_sql}
        GROUP BY COALESCE(sr.reason, 'No reason')
        ORDER BY amount DESC
    """), params).mappings().all()
    if export == "csv":
        return csv_export([dict(r) for r in rows], "returns_report.csv")
    ctx = base_context(request)
    ctx.update({"rows": [dict(r) for r in rows], "by_reason": [dict(r) for r in by_reason], "start_date": start_date, "end_date": end_date})
    return templates.TemplateResponse("reports/returns.html", ctx)
