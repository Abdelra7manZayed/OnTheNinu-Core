from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from ..auth import api_require_permission
from ..crud import create_record, delete_record, get_table_config, list_records, serialize_instance, serialize_many, update_record
from ..database import get_db

router = APIRouter(prefix="/api", tags=["Generic CRUD API"])


@router.get("/{slug}")
async def api_list(slug: str, request: Request, q: str = "", limit: int = 100, offset: int = 0, db: Session = Depends(get_db)):
    api_require_permission(request, slug, "read")
    config = get_table_config(slug)
    if not config:
        raise HTTPException(status_code=404, detail="Table not found")
    rows, total = list_records(db, config["model"], q=q, search_columns=config.get("search"), limit=limit, offset=offset)
    return {"table": slug, "total": total, "rows": serialize_many(rows)}


@router.get("/{slug}/{record_id}")
async def api_get(slug: str, record_id: int, request: Request, db: Session = Depends(get_db)):
    api_require_permission(request, slug, "read")
    config = get_table_config(slug)
    if not config:
        raise HTTPException(status_code=404, detail="Table not found")
    obj = db.get(config["model"], record_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Record not found")
    return serialize_instance(obj)


@router.post("/{slug}")
async def api_create(slug: str, payload: dict, request: Request, db: Session = Depends(get_db)):
    api_require_permission(request, slug, "create")
    config = get_table_config(slug)
    if not config:
        raise HTTPException(status_code=404, detail="Table not found")
    try:
        obj = create_record(db, config["model"], payload)
        return serialize_instance(obj)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@router.put("/{slug}/{record_id}")
async def api_update(slug: str, record_id: int, payload: dict, request: Request, db: Session = Depends(get_db)):
    api_require_permission(request, slug, "update")
    config = get_table_config(slug)
    if not config:
        raise HTTPException(status_code=404, detail="Table not found")
    try:
        obj = update_record(db, config["model"], record_id, payload)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    if not obj:
        raise HTTPException(status_code=404, detail="Record not found")
    return serialize_instance(obj)


@router.delete("/{slug}/{record_id}")
async def api_delete(slug: str, record_id: int, request: Request, db: Session = Depends(get_db)):
    api_require_permission(request, slug, "delete")
    config = get_table_config(slug)
    if not config:
        raise HTTPException(status_code=404, detail="Table not found")
    ok, message = delete_record(db, config["model"], record_id)
    if not ok:
        raise HTTPException(status_code=400, detail=message)
    return {"detail": message}
